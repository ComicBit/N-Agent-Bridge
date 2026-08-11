# Air75 V3 Lighting Protocol

The current implementation allows only the NuPhy Air75 V3 ANSI: VID
`0x19F5`, wired PID `0x1028`, official U1 receiver PID `0x2620`, management
usage page/usage `1:0`, and 64-byte input/output reports.

## Frame format

- byte 0: request `0x55`; response `0xAA`;
- byte 1: command;
- byte 3: 8-bit sum of bytes 4-63;
- byte 4: payload length;
- bytes 5-6: little-endian address;
- byte 7: profile handle;
- byte 8 onward: payload.

## `0xEE` session handshake

Official NuPhyIO sends `0xEE SetSecretKey` before an ordinary command. Its
payload is 56 random bytes, and payload byte 20 is the one-byte XOR session
key. Subsequent requests XOR route bytes 4-7 and the payload before the
checksum is computed.

Firmware 1.0.16.6 leaves the response route fields plain and XORs only the
payload. Older firmware may XOR both route fields and payload.
`NuPhyS4ProtocolCodec` accepts both observed response forms. Each logical
transaction establishes a new session instead of reusing a key that NuPhyIO
may have changed in device RAM.

## Implemented commands

- `0xA1 GetFirmwareInfo`
- `0xB2 GetUseKeys` / `0xB3 SetUseKeys`
- `0xD2 GetKeyLightColor`
- `0xD5 GetLightState`
- `0xD6 SetLightState`
- `0xF3 GetSleepInfo` / `0xF5 SetSleepCfg`

`0xD2` reads physical-key RGB triples. `0xD8` writes up to 14 records of
`[index, red, green, blue]` and is accepted only after exact D2 readback. The
write is visible while the backlight is in Signal Indicator mode `0x15`.
USB-C validation changed F1 and restored it. U1 validation copied all 84 key
colors, blinked only F1 red for 60 seconds, then restored the signal palette
and original Static mode.

U1 responses are multi-stage and duplicated. The dongle emits local ACK/echo
frames before the forwarded keyboard response. Read ACK payloads are all zero;
write echoes match the encrypted request payload. The transaction layer
filters those local frames and waits for the forwarded response. D6 requires
exact D5 readback and D8 requires exact D2 readback; an ACK alone proves
nothing.

The product must not send `0xEF SetIapMode`, `0xF1 RestoreFactory`, or another
destructive or guessed command that has not been validated through the product
flow.

## D5 / D6

D5 returns 17 bytes for each handle, containing 9 bytes of backlight state and
8 bytes of side-light state. The app reads and backs up handles 0 and 1 but
writes only macOS handle 0.

Official firmware 1.0.16.6 normalizes unused Windows-profile metadata when
handle 1 is written; upstream physical observation recorded `0x27` becoming
`0x00`. Older logic wrote both handles and falsely reported a D5 mismatch.
The current product leaves handle 1 untouched.

D6 requires a complete echoed ACK, delayed D5 readback, and up to five
read-only retries. If verification fails, the driver restores only the
pre-write handle-0 state and does not repeat a write whose result is unknown.
The upstream record reports physical original-state restore, temporary
brightness change, exact D5 readback, and final recovery on Air75 V3 1.0.16.6.

## D2 per-key RGB reads

The current driver reads RGB bytes for named physical-key indexes. D2 splits
sparse indexes into contiguous windows no larger than 54 payload bytes, so a
distant key never exceeds the one-frame limit. The ANSI map is useful for
inspection, but a D2 read does not prove that the same index is writable.

Per-key writes are enabled for the verified Air75 V3 ANSI layout. Signal
Indicator mode can be selected through verified D6 on USB-C or U1. The app
seeds its 84-key signal palette from the current visible colors before applying
individual Agent-key updates, so unrelated keys and side lights keep their
appearance.

## Sleep configuration

F3 returns `[sleepEnable, sleepTimeMinutes, deepSleepTime]`. F5 changes only
the first two values, preserves the third, requires an ACK, and performs a
delayed exact F3 readback. Failure attempts to restore the original values.
**Always on** changes only `sleepEnable` to 0.

## Transport

USB-C and U1 2.4G use the allow-listed 64-byte S4 management interface.
Bluetooth has no verified S4 configuration characteristic, so the product
does not write live lighting over Bluetooth.
