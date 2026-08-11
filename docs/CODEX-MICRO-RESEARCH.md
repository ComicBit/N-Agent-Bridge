# Codex Micro Research

Verification date: 2026-07-19. Primary sources were the
[OpenAI Codex Micro page](https://openai.com/supply/co-lab/work-louder/) and
[Codex developer documentation](https://developers.openai.com/codex/).

## Explicitly stated by the official material

- Codex Micro supports Bluetooth and USB-C, Mac and Windows, and RGB.
- Each Agent key shows live Codex state; the official text lists thinking,
  running, waiting, and done.
- The joystick starts skills/common workflows; examples include PR review,
  debug, and refactor.
- Explicit command-key examples are accept, reject, push-to-talk, and new
  chat, plus an unspecified “more” group.
- The dial changes reasoning level.
- Hardware specifications list 13 mechanical keys, one touch sensor, one
  rotary encoder, and one planar joystick.

## Not published by the official material

- the complete default mapping and exact grouping/count for each Agent and
  command key;
- the touch-sensor default action;
- RGB values, animation timing, and transport protocol;
- firmware HID reports, authentication protocol, or private Work Louder Input
  interfaces.

## Equivalent mapping used by this project, not an official default

- six Agent slots on F13-F18;
- Quick Action, Approve, Decline, New Chat, Push to Talk, and Send on F19-F24;
- arrow keys as a joystick equivalent, with the knob defaulting to
  context-aware reasoning control;
- status colors based on the product requirements’ suggested palette, not
  presented as official color values.

## Codex integration evidence

The upstream workstation record had Codex CLI 0.144.6 logged into ChatGPT.
The stable CLI provided `codex exec --json`; that installation also exposed
experimental app-server V2 with `thread/start`, `turn/start`,
`turn/interrupt`, streaming notifications, and command/file/permissions
approval callbacks. This project uses app-server for explicit human approval
and retains the protocol-version risk.
