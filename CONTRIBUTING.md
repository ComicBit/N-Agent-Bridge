# Contributing to N Agent Bridge

Contributions that improve Air75 V3 reliability, diagnostics, documentation,
or future keyboard support are welcome through a fork and pull request.

## Workflow

1. Fork `bohu8264/N-Agent-Bridge`.
2. Create a focused branch from the latest `main`, for example `feature/air96-v3-profile`.
3. Keep the scope explicit and update code, tests, and documentation together.
4. Run the software self-test. For hardware work, include a redacted model, connection, firmware version, ACK, readback, and recovery result.
5. Open a pull request describing the root cause, user impact, validation, and remaining unverified limits.

## Development checks

```sh
swift build --disable-sandbox --product Air75AgentBridge
swift build --disable-sandbox --product air75
swift run --disable-sandbox Air75CoreSelfTest --software-only
```

When full Xcode is available, also run `swift test`. Use the repository’s
`xcsift` workflow for Swift build and test output when it is installed.

## Adding a keyboard model

Follow [Adding a NuPhy keyboard](docs/ADDING-NUPHY-KEYBOARD.md):

- keep device recognition profiles separate from hardware write drivers;
- keep an unknown protocol read-only instead of guessing from a related model;
- save a complete, validated original state before any write;
- require ACK and complete readback after every write;
- verify the recovery path;
- validate USB, 2.4G, and Bluetooth independently;
- never commit serial numbers, user paths, chat content, or private captures.

Anything that cannot be verified on physical hardware must be marked
`REQUIRES HARDWARE VERIFICATION` in the UI and documentation.

## Code and privacy requirements

- Do not expand ordinary keyboard text collection.
- Do not read or record Codex prompts, responses, tokens, or API keys.
- Synthetic events must remain targeted at the intended application.
- Do not commit certificates, private keys, notarization credentials, `.env` files, Application Support backups, or build outputs.
- Preserve upstream attribution and publish only code and technical notes that we have the right to distribute.

## Commits and pull requests

- Use short imperative commit messages.
- Keep one concern per pull request when practical.
- Describe the root cause, not only the visible symptom.
- Protocol changes must include failure recovery and evidence that the change remains isolated from other models.

Contributions are released under the repository’s [MIT License](LICENSE).
