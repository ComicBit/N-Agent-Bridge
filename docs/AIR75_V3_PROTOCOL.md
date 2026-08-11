# NuPhy Air75 V3 protocol baseline

This document extracts the protocol knowledge used by the current code into a
reviewable English reference. It describes the **NuPhy Air75 V3 ANSI** only.
The protocol is reverse-engineered, is not an official NuPhy specification,
and originated in the upstream [N Agent Bridge project](https://github.com/bohu8264/N-Agent-Bridge).
Keep the upstream attribution and MIT license when extending it.

## Evidence labels

- **Confirmed in implementation** — encoded or validated directly by the
  current Swift sources.
- **Reported physical validation** — recorded in the upstream project’s
  release/acceptance notes; this checkout does not reproduce physical writes
  automatically.
- **Inferred** — a useful interpretation of stable behavior, not a guaranteed
  firmware contract.
- **Unknown** — deliberately not decoded or not safe to assume.

When a statement is not backed by the current implementation or a recorded
physical result, it is marked explicitly. Unknown bytes must remain unknown.

## Device identity and transport

| Path | VID | PID | Transport evidence | Write status |
| --- | ---: | ---: | --- | --- |
| Air75 V3 keyboard | `0x19F5` | `0x1028` | USB-C HID | Verified management path |
| Official U1 receiver | `0x19F5` | `0x2620` | USB HID receiver | Verified S4 route when the keyboard responds |
| Bluetooth HID | firmware-dependent | firmware-dependent | Bluetooth keyboard input | No verified S4 management channel |

The management interface is matched by all of:

- vendor ID and product ID above;
- primary usage page `0x01` and primary usage `0x00`;
- 64-byte input and output reports;
- report ID `0` passed to `IOHIDDeviceSetReport`.

The normal input manager does not seize the keyboard. Product discovery and
the developer CLI reuse `HIDDeviceManager` so diagnostics cannot silently
recognize a name-only impostor. Bluetooth can remain available for ordinary
key input, but the code does not invent a BLE lighting characteristic.

## 64-byte frame format

All byte offsets below are offsets within the 64-byte report passed to the HID
API. The report ID is supplied separately as `0`; it is not inserted as an
extra byte in these arrays.

### Request

| Byte(s) | Meaning | Protection |
| --- | --- | --- |
| 0 | Start marker `0x55` | Plain |
| 1 | Command | Plain |
| 2 | Unused by the current codec | Unknown; kept zero by the encoder |
| 3 | Checksum | Sum of bytes 4-63 modulo 256 |
| 4 | Payload length | XOR with session key for ordinary commands |
| 5 | Address low byte | XOR with session key |
| 6 | Address high byte | XOR with session key |
| 7 | Profile/handle | XOR with session key |
| 8-63 | Payload area | Each used payload byte is XORed with the session key |

`NuPhyS4ProtocolCodec.makeReport` emits a zero-filled 64-byte frame and never
writes more than the first 56 payload bytes.

### Response

| Byte(s) | Meaning | Protection |
| --- | --- | --- |
| 0 | Response marker `0xAA` | Plain |
| 1 | Echoed command | Plain |
| 2 | Unused by the current decoder | Unknown |
| 3 | Checksum | Sum of bytes 4-63 modulo 256 |
| 4-7 | Length, address low/high, handle | Plain on 1.0.16.6; may be XORed on older firmware |
| 8-63 | Payload | Requested bytes are XORed with the session key |

The decoder accepts only a frame with the expected marker, command, checksum,
length, address, and handle. It accepts either a plain or keyed route header;
it does not use “looks plausible” data to guess a key.

## `0xEE` session handshake

Every logical transaction starts a new session:

```text
Byte 0: 0x55
Byte 1: 0xEE (SetSecretKey)
Byte 2: 0x00 (encoder default)
Byte 3: checksum of bytes 4-63
Byte 4-7: 0x00 (encoder default)
Byte 8-63: 56-byte random challenge
```

The session key is challenge byte 20, which is report byte 28. If that byte is
zero, the current implementation replaces it with `0xAA` before sending the
challenge so the active key is never zero. The handshake acknowledgement is
validated as a 64-byte `0xAA 0xEE` response with a valid checksum; the
challenge is not assumed to be echoed.

The fresh handshake is intentional. NuPhyIO or another configuration client
can replace the keyboard’s in-memory session key, and firmware 1.0.16.6 does
not make the encrypted payload’s key unambiguous from the response header.

## Implemented commands

The following table reflects commands actually used by the current sources.
Lengths and addresses are the values used by the implementation, not a claim
that the firmware exposes no other commands.

| Command | Direction | Current use | Length/address/handle |
| --- | --- | --- | --- |
| `0xA1` | read | Raw firmware information | length 8, address 0, handle 0 |
| `0xB2` | read | Air75 keymap | up to 56 bytes per request, address is byte offset, handle 0 |
| `0xB3` | write | Changed Air75 keymap chunks | up to 56 bytes per request, address is byte offset, handle 0 |
| `0xD2` | read-only | RGB triples for one or more contiguous physical-key indexes | length is `3 * windowCount`, address is `firstIndex * 3`, handle 0 |
| `0xD5` | read | 17-byte lighting state | length 17, address 0, handles 0 and 1 |
| `0xD6` | write | Lighting state | length 17, address 0, **macOS handle 0 only** |
| `0xF3` | read | Sleep configuration | length 3, address 0, handle 0 |
| `0xF5` | write | Sleep configuration | length 3, address 0, handle 0 |

Older research notes mention `0xD1`, but the current implementation does not
send or decode it. This baseline therefore does not call it verified.

## RGB and lighting payloads

### D2: read RGB state

The current driver reads RGB bytes using windows no larger than 54 bytes so a
window can contain at most 18 RGB triples:

```text
Byte 0: red for LED index N
Byte 1: green for LED index N
Byte 2: blue for LED index N
Byte 3: red for LED index N+1
Byte 4: green for LED index N+1
Byte 5: blue for LED index N+1
...
```

Sparse requested indexes are grouped into contiguous windows and reduced back
to the caller’s original order. Unknown numeric indexes are not exposed by the
`air75` CLI; use the verified names in [the LED map](AIR75_V3_LED_MAP.md).

### Per-key RGB writes

The verified D8 payload is a sequence of four-byte records:

```text
[index, red, green, blue]
```

An echoed D8 frame alone is insufficient. USB-C and U1 writes require exact
D2 readback and automatic recovery. U1 emits duplicated local zero/echo frames
before the forwarded keyboard response; those local frames are filtered by
payload identity. Signal Indicator mode `0x15` is selected through verified
D6, after which per-key D8 updates work through USB-C or U1 2.4G. Full hardware
validation copied all 84 key colors in safe 14-record chunks, blinked only F1,
and restored both the signal palette and original D5 state.

### D5/D6: lighting zones

Each D5 handle returns 17 bytes:

```text
Bytes 0-8:  backlight
  0: mode
  1: brightness (0-100)
  2: speed
  3: direction
  4: RGB flag
  5: color index
  6: red
  7: green
  8: blue

Bytes 9-16: side light
  9: mode
 10: raw brightness (0-255)
 11: speed
 12: RGB flag
 13: color index
 14: red
 15: green
 16: blue
```

The current code reads and backs up handles 0 and 1. It writes only handle 0.
Upstream’s physical validation recorded that official firmware 1.0.16.6
normalizes unused Windows-profile metadata when handle 1 is written; touching
that handle therefore creates a false verification failure and changes state
outside the requested macOS operation.

### F3/F5: sleep configuration

The three-byte payload is:

```text
Byte 0: auto-sleep enabled flag (0 or 1)
Byte 1: idle time in minutes (1-127)
Byte 2: firmware-owned deep-sleep value, preserved by this app
```

F5 requires an echoed payload and delayed F3 readback. Failure attempts to
restore the original three bytes.

## Keymap and knob protocol

The Air75 map is exactly 1,568 bytes: eight layers × 98 entries × two bytes.
The implementation treats each entry as a big-endian `UInt16`.

- B2 reads the complete map in 56-byte chunks at byte offsets 0 through 1567.
- B3 writes only changed chunks and then B2-reads the complete map.
- A candidate original map must pass the complete layout plausibility check
  before it can be persisted as a backup.
- Layer 0 and layer 4 physical F1-F12 entries are set to `0x68...0x73`
  (F13-F24) by the bridge profile.
- Knob press is matrix entry 60, left is 96, and right is 97 in each layer.
  Verified replacement values are press `0x0048` (Pause), left `0x0047`
  (Scroll Lock), and right `0x0046` (Print Screen).
- The only accepted empty exception is layer 8 / entry 60 / `0x0000`, which
  is normalized to `0x0048` for the official 1.0.16.6 variant.

The app never sends IAP, factory-restore, or guessed keymap commands.

## Firmware assumptions and limitations

- The maintained baseline is official Air75 V3 ANSI firmware `1.0.16.6`.
- The decoder’s dual response-header handling exists for compatibility with
  older firmware observed by the upstream project, but other versions are not
  automatically qualified.
- The current LED map is ANSI-only. ISO and JIS maps are unknown.
- The current CLI reports A1 as raw eight-byte hex; it does not claim a parsed
  semantic firmware version.
- Bluetooth input is supported only as input. D5/D6 zone management and D2/D8
  per-key RGB management are verified S4 capabilities over USB-C and U1 only.

## Safety boundary

The following commands are intentionally absent from the product path:

- `0xEF SetIapMode`;
- `0xF1 RestoreFactory`;
- arbitrary raw command/address/handle injection.

The developer CLI uses named keys and the existing transactional driver. The
full physical acceptance sequence remains in `Air75ProtocolProbe` and must be
run only with the keyboard, N Agent Bridge, and NuPhyIO ownership conditions
described in `AGENTS.md`.
