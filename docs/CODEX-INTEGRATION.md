# Codex Integration

The preferred integration order is: a stable public SDK (if a stable Swift or
HTTP surface appears), then the stable CLI, then app-server, then a custom
client. The upstream workstation record had Codex CLI 0.144.6 logged into
ChatGPT. `codex exec --json` was stable, but non-interactive approvals failed
closed and could not provide an Approve/Decline experience. App-server V2
exposed real thread, turn, and approval state, but the CLI labeled it
experimental.

`CodexAppServerBackend` starts the official CLI stdio app-server and sends
`initialize`, `thread/start`, `turn/start`, and `turn/interrupt`. It holds
command, file, and permissions approval requests for the UI. Only an explicit
user Approve or Decline returns `accept` or `decline`. Defaults are
`workspace-write` sandboxing, `on-request` approval policy, and the user
reviewer.

The integration does not control Codex with mouse coordinates or screenshot
recognition.
