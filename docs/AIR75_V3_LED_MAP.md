# Air75 V3 ANSI per-key RGB read map

This is the ANSI key map currently exposed by `SignalLightLayout` for layout
ID `nuphy.air75-v3.ansi-d8`. The index is the logical D2 RGB read address, not
a USB HID usage. The legacy layout ID is retained for configuration
compatibility; it does not authorize a D8 write.

The list is **ANSI-only**. ISO and JIS positions are unknown and must not be
guessed. Keys absent from this table are not verified addressable by the
current driver; the numeric gaps are firmware-reserved or hidden positions.

| Physical key | HID usage | D2 index |
| --- | ---: | ---: |
| Esc | `0x29` | 0 |
| F1 / F13 | `0x3A` / installed-layer alias | 1 |
| F2 / F14 | `0x3B` / installed-layer alias | 2 |
| F3 / F15 | `0x3C` / installed-layer alias | 3 |
| F4 / F16 | `0x3D` / installed-layer alias | 4 |
| F5 / F17 | `0x3E` / installed-layer alias | 5 |
| F6 / F18 | `0x3F` / installed-layer alias | 6 |
| F7 / F19 | `0x40` / installed-layer alias | 7 |
| F8 / F20 | `0x41` / installed-layer alias | 8 |
| F9 / F21 | `0x42` / installed-layer alias | 9 |
| F10 / F22 | `0x43` / installed-layer alias | 10 |
| F11 / F23 | `0x44` / installed-layer alias | 11 |
| F12 / F24 | `0x45` / installed-layer alias | 12 |
| Print Screen | `0x46` | 13 |
| Insert | `0x49` | 14 |
| Backtick | `0x35` | 15 |
| 1-0 | `0x1E-0x27` | 16-25 |
| Minus | `0x2D` | 26 |
| Equals | `0x2E` | 27 |
| Backspace | `0x2A` | 28 |
| Page Up | `0x4B` | 29 |
| Tab | `0x2B` | 30 |
| Q-P | `0x14, 0x1A, 0x08, 0x15, 0x17, 0x1C, 0x18, 0x0C, 0x12, 0x13` | 31-40 |
| Left Bracket | `0x2F` | 41 |
| Right Bracket | `0x30` | 42 |
| Return | `0x28` | 43 |
| Page Down | `0x4E` | 44 |
| Caps Lock | `0x39` | 45 |
| A-L | `0x04, 0x16, 0x07, 0x09, 0x0A, 0x0B, 0x0D, 0x0E, 0x0F` | 46-54 |
| Semicolon | `0x33` | 55 |
| Apostrophe | `0x34` | 56 |
| Backslash | `0x31` | 57 |
| Home | `0x4A` | 58 |
| Z-M | `0x1D, 0x1B, 0x06, 0x19, 0x05, 0x11, 0x10` | 60-66 |
| Comma | `0x36` | 67 |
| Period | `0x37` | 68 |
| Slash | `0x38` | 69 |
| Up | `0x52` | 71 |
| End | `0x4D` | 72 |
| Space | `0x2C` | 76 |
| Left | `0x50` | 80 |
| Down | `0x51` | 81 |
| Right | `0x4F` | 82 |

The source map does not expose modifier positions as assignable keys, but
their LEDs still occupy indexes in the physical row order. Omitting those
positions from the index count previously made End target left Control.
The source map otherwise intentionally omits modifier positions and other physical
positions that are not present in the D2 read mapping. Do not infer those
indexes from the gaps.

## CLI resolution

The independent CLI resolves names through this map:

```sh
swift run --disable-sandbox air75 led map
swift run --disable-sandbox air75 led get F1
swift run --disable-sandbox air75 led get F13
```

`F1` and `F13` resolve to the same physical F1 key because the installed
hardware profile changes the HID event name without moving the RGB read
address. `led get` accepts only names resolved by this map. D8 per-key writes
are verified through exact D2 readback over USB-C and the official U1 receiver.
