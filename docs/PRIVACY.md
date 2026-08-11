# Privacy

- `IOHIDManager` adds only supported NuPhy models that the device profile
  identifies with sufficient evidence.
- Outside calibration mode, the input layer publishes only mapped F1-F12 or
  learned usages, candidate knob consumer usages, and vendor-defined usages.
- When USB-C and 2.4G enumerate together, HID reports which verified
  interface was active most recently so lighting uses the right route. This
  signal contains no key usage, value, or text and is not written to history.
- Lighting writes are limited to the verified Air75 V3 USB VID `0x19F5` / PID
  `0x1028` and official U1 receiver VID `0x19F5` / PID `0x2620`, usage `1:0`.
  Other recognized models remain software-only and receive no NuPhyIO write
  report.
- The app does not store ordinary keyboard text, passwords, or other keyboard
  events and does not upload raw HID reports.
- Calibration retains only the most recent 120 events in memory; they vanish
  when the app exits.
- F11 triggers Codex Desktop’s own dictation. N Agent Bridge does not request
  microphone access, record audio, or read dictation results.
- Codex uses the official CLI login. The app does not read or copy tokens.
  Profiles and backups contain no API keys, chat content, or source code.
- To assign recent, pinned, priority, and custom Agents, the app reads local
  Codex indexes for thread IDs, compatible titles, project directories, and
  update times, plus global unread/pinned IDs, project names/order, and
  thread-to-project ownership. The final task display name comes from the
  read-only app-server `thread/list` `Thread.name`; the same response’s
  `preview` is discarded immediately and never enters product state, logs, or
  persistence. Rollouts are read only for tail event names and timestamps;
  prompt and answer bodies are not parsed, recorded, or uploaded.
- To detect Codex confirmation cards that rollout data does not record, the
  app uses user-approved Accessibility only to read `AXButton` titles and
  descriptions, and reads only `active` and `conversationId` from Codex
  Desktop logs. It does not read `AXStaticText`, input fields, chat content,
  or confirmation-question text; it retains only the currently waiting thread
  ID in memory.
- High-risk approval is triggered explicitly by the user’s key press or click.
