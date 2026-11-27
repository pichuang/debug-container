#!/usr/bin/env bash
set -euo pipefail

image=${1:?image reference required}
case ${2:?image variant required} in
    centos) os=centos ;;
    microsoft) os=azurelinux ;;
    ubuntu) os=ubuntu ;;
    *) echo "Unsupported image variant: $2" >&2; exit 1 ;;
esac
case ${3:?image architecture required} in
    amd64) machine=x86_64 ;;
    arm64) machine=aarch64 ;;
    *) echo "Unsupported image architecture: $3" >&2; exit 1 ;;
esac

actual=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")
if [[ "$actual" != "linux/$3" ]]; then
    echo "Expected linux/$3, got $actual for $image" >&2
    exit 1
fi

docker run --rm -i --network none --platform "linux/$3" --entrypoint /bin/bash "$image" \
    -es -- "$os" "$machine" <<'BASH'
grep -Fx "ID=\"$1\"" /etc/os-release || grep -Fx "ID=$1" /etc/os-release
if [ "$1" = ubuntu ]; then
    grep -Fx 'VERSION_ID="24.04"' /etc/os-release
fi
test "$(uname -m)" = "$2"
test -x /root/deadman/deadman
test ! -e /root/deadman/.git
for tool in ip ping dig mtr nmap ncat tcpdump iperf3 curl git jq speedtest-cli; do
    command -v "$tool"
done
ncat --version
speedtest-cli --version
BASH
