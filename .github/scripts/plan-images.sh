#!/usr/bin/env bash
set -euo pipefail

today=$(date -u +%F)
verify=true
publish=false
release=false
case "$GITHUB_EVENT_NAME" in
    schedule)
        # GitHub cron is weekly; only release on alternate weeks from this UTC Sunday.
        anchor=$(date -u -d 2026-11-29 +%s)
        now=$(date -u -d "$today" +%s)
        if (( now >= anchor && ((now - anchor) / 604800) % 2 == 0 )); then
            publish=true
            release=true
        else
            verify=false
        fi
        ;;
    workflow_dispatch)
        publish=true
        if [[ "$PUBLISH_STABLE" == true ]]; then
            if [[ "$GITHUB_REF" != "refs/heads/$DEFAULT_BRANCH" ]]; then
                echo 'Stable releases must use the default branch.' >&2
                exit 1
            fi
            release=true
        fi
        ;;
    push) [[ "$GITHUB_REF" != refs/heads/test-publish/* ]] || publish=true ;;
esac

bases='{}'
if [[ "$verify" == true ]]; then
    for file in Dockerfile Dockerfile-*; do
        base=$(sed -n 's/^ARG BASE_IMAGE=//p' "$file")
        if [[ ! "$base" =~ ^[^[:space:]@]+@sha256:[0-9a-f]{64}$ ]]; then
            echo "Missing or invalid base image pin in $file" >&2
            exit 1
        fi
        if [[ "$publish" == true ]]; then
            source=${base%@*}
            digest=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "$source")
            if [[ ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
                echo "Invalid manifest digest for $source" >&2
                exit 1
            fi
            base="$source@$digest"
            docker buildx imagetools inspect --raw "$base" |
                jq -e 'any(.manifests[]; .platform.os == "linux" and .platform.architecture == "amd64") and
                       any(.manifests[]; .platform.os == "linux" and .platform.architecture == "arm64")' >/dev/null
        fi
        bases=$(jq -c --arg file "$file" --arg base "$base" '.[$file] = $base' <<< "$bases")
    done
fi

{
    printf 'verify=%s\npublish=%s\nrelease=%s\ntag=v%s\n' "$verify" "$publish" "$release" "${today//-/}"
    printf 'bases=%s\n' "$bases"
} >> "$GITHUB_OUTPUT"
