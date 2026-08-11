# Claude Code Integration

Primary references are the [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview),
[CLI reference](https://code.claude.com/docs/en/cli-reference), and
[hooks documentation](https://code.claude.com/docs/en/hooks). The official
Agent SDK supports Python/TypeScript, sessions, streaming input/output,
approvals, and hooks. Other languages can integrate through
`claude -p --output-format json/stream-json`.

The source workstation did not have the Claude Code CLI installed. The
current `ClaudeCodeBackend` implements executable discovery, print/
stream-json, start/resume/stop, and status boundaries. Without an external
permission callback it always rejects requests and never auto-approves. A
future production integration could embed the permitted TypeScript SDK native
binary or connect `--permission-prompt-tool` to a controlled MCP callback.
