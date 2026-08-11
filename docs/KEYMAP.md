# Air75 V3 Keymap

| Action slot | Initial physical key | Runtime behavior |
| --- | --- | --- |
| Agent 1-6 | Unassigned | User-selected key is intercepted while running |
| Quick action / Approve / Decline | Unassigned | User-selected key is intercepted while running |
| New task / Dictation / Send | Unassigned | User-selected key is intercepted while running |

The shipping app never writes the Air75 keymap. Setup starts with twelve
unassigned action slots. The user selects an action and clicks a physical key
in the graphical keyboard. The app persists that HID usage and intercepts it
only while the process is running.

Removing an assignment immediately stops interception and restores that key's
saved RGB value. Quitting restores the complete pre-Agent RGB palette and
lighting mode before termination.

Protected developer recovery tooling can still read, validate, snapshot, and
restore a complete 1,568-byte map, but those operations are not reachable from
the product UI.

Developer recovery writes begin with the official `0xEE` session handshake,
write B3 in chunks, and require a complete B2 byte-for-byte readback. This is
recovery tooling only, not product setup.

The **Keys** page can learn actions onto numbers, letters, the F-row, or
navigation keys. Custom ordinary keys are software mappings: when control is
enabled, a CGEvent session tap consumes the original character, and stopping
the app quits or the assignment is removed. `usage 0xFFFFFFFF` is an HID-array placeholder and must
be rejected by both the learner and runtime.

D2/D8 per-key RGB management uses the current physical HID usage. The ANSI
map excludes three hidden knob entries: F1 is index 1 and the number 1 key is
index 16. Writes require Signal Indicator mode and use exact D2 readback with
recovery on mismatch over USB-C or the official U1 receiver.

Agent conversation assignment uses stable Codex thread IDs. Recent, pinned,
priority, and custom modes do not depend on changing sidebar row numbers.
