#!/usr/bin/env bash
set -euo pipefail

image=${1:?image reference required}
version=
case ${2:?image variant required} in
    centos) os=centos ;;
    microsoft) os=azurelinux; version=3.0 ;;
    azurelinux4) os=azurelinux; version=4.0 ;;
    ubuntu) os=ubuntu; version=24.04 ;;
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
    -es -- "$os" "$machine" "$version" <<'BASH'
grep -Fx "ID=\"$1\"" /etc/os-release || grep -Fx "ID=$1" /etc/os-release
if [ -n "$3" ]; then
    grep -Fx "VERSION_ID=\"$3\"" /etc/os-release || grep -Fx "VERSION_ID=$3" /etc/os-release
fi
if [ "$1:$3" = azurelinux:4.0 ]; then
    wget2 --version
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
