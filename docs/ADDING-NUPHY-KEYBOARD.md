# Adding a NuPhy keyboard safely

This guide is for a future model. Air75 V3 ANSI remains the only hardware
write profile until a new model completes the entire evidence path.

## Required sequence

1. Add a declarative profile with exact VID/PID, aliases, usage pages, and
   transport rules.
2. Keep the profile software-only until the protocol and layout are verified.
3. Add a driver ID to `KeyboardDriverRegistry` only after packet formats,
   report sizes, ACKs, and readbacks are known from implementation evidence.
4. Define the keymap size, matrix validation, physical knob positions, and
   complete backup/recovery behavior.
5. Define a physical-key to LED map. Do not infer ISO/JIS or another model’s
   map from ANSI or a related keyboard.
6. Keep Bluetooth, USB, and 2.4G as separate acceptance lanes.
7. Add software tests for identity rejection, payload encoding/decoding,
   layout plausibility, recovery, and capability gating.
8. Run a physical no-op, temporary change, exact readback, and final restore
   sequence with the device isolated from NuPhyIO and the app.

## Prohibited shortcuts

- Do not copy a NuPhy S4 packet shape into another model without evidence.
- Do not save an encrypted or partially decoded read as an original backup.
- Do not send raw commands just to discover what they do.
- Do not add a write-capable JSON profile without a registered verified driver.
- Do not claim Bluetooth lighting support without a verified channel and
  readback.

Any missing physical result must be written as:

```text
REQUIRES HARDWARE VERIFICATION
```
