#!/bin/bash
# Build the devbox images on the host.
#   build.sh            build only images that don't exist yet (boot path)
#   build.sh --update   rebuild all images using the layer cache, so only
#                       changed Containerfile steps rerun (used by deploy)
#   build.sh --refresh  rebuild everything from scratch to pick up new
#                       Fedora packages, Claude Code and oh-my-pi releases
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
case ${1:-} in
    "")        mode=missing ;;
    --update)  mode=update ;;
    --refresh) mode=refresh ;;
    *) echo "usage: $0 [--update|--refresh]" >&2; exit 2 ;;
esac

# At boot the user manager can't order after network-online.target, so wait.
for _ in $(seq 60); do
    curl -fsS -o /dev/null --max-time 5 https://registry.fedoraproject.org/v2/ && break
    sleep 5
done

# build NAME PULL: PULL is the --pull policy for the FROM image
# (claude/omp build on the local base image, so they must never pull it).
build() {
    local name=$1 pull=$2 image=localhost/devbox-$1:latest
    if [[ $mode == missing ]] && podman image exists "$image"; then
        echo "devbox-$name: present, skipping"
        return
    fi
    echo "devbox-$name: building"
    local args=(--tag "$image" --pull="$pull")
    [[ $mode == refresh ]] && args+=(--no-cache)
    podman build "${args[@]}" "$here/images/$name"
}

[[ $mode == refresh ]] && base_pull=always || base_pull=missing
build base "$base_pull"
build claude never
build omp never

podman image prune -f >/dev/null
