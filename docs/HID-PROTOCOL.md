# Air75 V3 HID Protocol

This is a short index into the detailed [Air75 V3 protocol baseline](AIR75_V3_PROTOCOL.md).
It describes the reverse-engineered ANSI implementation only.

## Identity and interface

- USB: VID `0x19F5`, PID `0x1028`, product `Air75 V3`.
- U1 receiver: VID `0x19F5`, PID `0x2620`; use only when the target keyboard
  identity can be read back.
- S4 management channel: usage page `0x01`, usage `0x00`, 64-byte input and
  output reports, report ID 0.

## Session

Official firmware 1.0.16.6 requires `0xEE SetSecretKey` before each ordinary
S4 command. The request carries a 56-byte challenge; challenge byte 20 is the
single-byte XOR session key. A fresh handshake per logical transaction
handles reconnects, sleep/wake, and other configuration clients changing the
keyboard’s in-memory key.

Firmware 1.0.16.6 keeps the response route header plain and encrypts the
payload. Older firmware may encrypt both route header and payload. The
decoder validates the command, length, address, handle, and checksum before
accepting either format; it does not guess from data that merely looks
plausible.

## Implemented commands

- `A1`: raw firmware information.
- `B2/B3`: 1,568-byte Air75 V3 keymap read/write.
- `D2`: RGB triples for physical-key indexes.
- `D5/D6`: lighting-zone state read/write; the product writes only macOS
  handle 0.
- `D8`: verified per-key RGB write over USB-C and U1, followed by exact D2
  readback and recovery on mismatch.
- `F3/F5`: sleep configuration read/write.

Older notes mention `D1`, but the current implementation does not send or
decode it. Protocol details, D5 fields, and the D2 read map are in
`docs/AIR75_V3_PROTOCOL.md` and `docs/LIGHTING-PROTOCOL.md`. Any unknown PID,
length, ACK, checksum, or readback result stops a write.
