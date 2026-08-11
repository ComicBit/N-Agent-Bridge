#!/bin/zsh
set -euo pipefail

mode=${1:-run}
script_dir=${0:A:h}
project_dir=${script_dir:h}
app_bundle="$project_dir/dist/N Agent Bridge.app"
app_binary="$app_bundle/Contents/MacOS/Air75AgentBridge"
process_name=Air75AgentBridge
bundle_id=com.nagentbridge.mac

pkill -x "$process_name" >/dev/null 2>&1 || true

AIR75_DISABLE_SWIFTPM_SANDBOX=1 \
  "$project_dir/scripts/build-release.sh"

launch_app() {
  /usr/bin/open -n "$app_bundle"
}

case "$mode" in
  run)
    launch_app
    ;;
  --debug|debug)
    lldb -- "$app_binary"
    ;;
  --logs|logs)
    launch_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$process_name\""
    ;;
  --telemetry|telemetry)
    launch_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$bundle_id\""
    ;;
  --verify|verify)
    launch_app
    sleep 2
    pgrep -x "$process_name" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
