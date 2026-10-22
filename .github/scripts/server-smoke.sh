#!/usr/bin/env bash
set -euo pipefail

server_install=${1:?usage: server-smoke.sh <server-install-directory>}
repo_root=${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}
mod_id=FracturedBonesStronger
mod_name="Fractured Bones Stronger"
mod_source="$repo_root/Contents/mods/$mod_id"
user_zomboid="$HOME/Zomboid"
server_config="$user_zomboid/Server/ci-smoke.ini"
console_log=${RUNNER_TEMP:-/tmp}/pz-server-console.log
console_input=${RUNNER_TEMP:-/tmp}/pz-server-console.in

[[ -f "$mod_source/mod.info" ]] || { echo "Missing mod package: $mod_source" >&2; exit 1; }
[[ -x "$server_install/start-server.sh" ]] || { echo "Missing PZ start-server.sh in $server_install" >&2; exit 1; }

mkdir -p "$user_zomboid/mods" "$user_zomboid/Server"
ln -sfn "$mod_source" "$user_zomboid/mods/$mod_id"
cat > "$server_config" <<EOF
Mods=$mod_id
WorkshopItems=
Public=false
PauseEmpty=true
SteamVAC=false
EOF

cd "$server_install"
rm -f "$console_input"
mkfifo "$console_input"
timeout --signal=INT --kill-after=30s 360s ./start-server.sh \
  -servername ci-smoke \
  -adminpassword ci-smoke-password \
  <"$console_input" >"$console_log" 2>&1 &
server_pid=$!
exec 3>"$console_input"

stop_server() {
  if kill -0 "$server_pid" 2>/dev/null; then
    printf 'quit\n' >&3 2>/dev/null || true
    exec 3>&- || true
    wait "$server_pid" || true
  fi
  wait "$server_pid" 2>/dev/null || true
  rm -f "$console_input"
}
trap stop_server EXIT

ready=0
for _ in $(seq 1 180); do
  if grep -Eiq 'SERVER STARTED' "$console_log"; then
    ready=1
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    break
  fi
  sleep 2
done

if [[ "$ready" != 1 ]]; then
  cat "$console_log"
  echo "Project Zomboid dedicated server did not reach SERVER STARTED" >&2
  exit 1
fi

if ! grep -Eiq "($mod_id|$mod_name)" "$console_log"; then
  cat "$console_log"
  echo "Server started, but its console did not confirm loading $mod_id" >&2
  exit 1
fi

echo "Project Zomboid server started and reported loading $mod_id."
