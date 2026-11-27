#!/usr/bin/env bash
set -euo pipefail

[[ "$RELEASE_TAG" =~ ^v[0-9]{8}$ ]]
image="${REGISTRY}/${IMAGE_NAME,,}"
staging="test-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
tmp=$(mktemp -d)
trap 'rm -f -- "$tmp/images.json" "$tmp/previous.json" "$tmp/notes.md"; rmdir -- "$tmp"' EXIT

previous=$(gh release list --exclude-drafts --exclude-pre-releases --limit 30 \
    --json tagName --jq 'map(select(.tagName | test("^v[0-9]{8}$"))) | first | .tagName // ""')
if [[ "$PUBLISH_RELEASE" == true ]] && git show-ref --verify --quiet "refs/tags/$RELEASE_TAG"; then
    echo "Release tag $RELEASE_TAG already exists; refusing to overwrite it." >&2
    exit 1
fi

printf '%s\n' '{}' > "$tmp/previous.json"
if [[ -n "$previous" ]]; then
    gh release download "$previous" --pattern images.json --output "$tmp/previous.json" --clobber
    jq -e '(.images | type) == "object"' "$tmp/previous.json" >/dev/null
fi

variants=(centos microsoft ubuntu azurelinux4)
files=(Dockerfile Dockerfile-microsoft Dockerfile-ubuntu Dockerfile-azurelinux4)
aliases=(latest microsoft-latest ubuntu-latest azurelinux4-latest)
stable=(master microsoft ubuntu azurelinux4)
dated=("$RELEASE_TAG" "$RELEASE_TAG-microsoft" "$RELEASE_TAG-ubuntu" "$RELEASE_TAG-azurelinux4")

manifest=$(jq -cn --arg commit "$GITHUB_SHA" '{sourceCommit: $commit, images: {}}')
for i in "${!variants[@]}"; do
    variant=${variants[i]}
    base=$(jq -er --arg file "${files[i]}" '.[$file]' <<< "$BASES")
    digest=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "$image:$staging-$variant")
    [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]
    manifest=$(jq -c --arg v "$variant" --arg base "$base" --arg digest "$digest" \
        --arg tag "${dated[i]}" '.images[$v] = {base: $base, digest: $digest, tag: $tag}' <<< "$manifest")
done
jq . <<< "$manifest" > "$tmp/images.json"

# Markdown code spans below use literal backticks.
# shellcheck disable=SC2016
{
    printf '## What changed\n\n'
    if [[ -n "$previous" ]]; then
        printf 'Compared with [%s](https://github.com/%s/compare/%s...%s).\n\n' \
            "$previous" "$GH_REPO" "$previous" "$GITHUB_SHA"
        if git diff --quiet "$previous" "$GITHUB_SHA"; then
            printf 'No source files changed. All images were rebuilt against current upstream bases and package repositories.\n\n'
        else
            printf 'Source changes (file, added lines, removed lines):\n\n```text\n'
            git diff --numstat "$previous" "$GITHUB_SHA" |
                awk -F '\t' '{printf "%s: +%s / -%s\n", $3, $1, $2}'
            printf '```\n\n'
        fi
    else
        printf '%s\n\n' 'First GitHub Release under the biweekly image workflow. It establishes a baseline for CentOS Stream 9, Azure Linux 3.0, Ubuntu 24.04 LTS, and Azure Linux 4. No prior release is available for comparison.'
    fi
    printf 'Source commit: `%s`. All four images were rebuilt without the layer cache; AMD64 and ARM64 build and smoke checks passed.\n\n' "$GITHUB_SHA"
    printf '## Image changes and pull references\n\n'
    for i in "${!variants[@]}"; do
        variant=${variants[i]}
        base=$(jq -er --arg v "$variant" '.images[$v].base' <<< "$manifest")
        digest=$(jq -er --arg v "$variant" '.images[$v].digest' <<< "$manifest")
        old_base=$(jq -r --arg v "$variant" '.images[$v].base // empty' "$tmp/previous.json")
        old_digest=$(jq -r --arg v "$variant" '.images[$v].digest // empty' "$tmp/previous.json")
        printf '### %s\n\n- Pull: `docker pull %s:%s` (also `%s`, `%s`).\n' \
            "$variant" "$image" "${dated[i]}" "${stable[i]}" "${aliases[i]}"
        if [[ -z "$old_base" ]]; then
            printf -- '- Base: `%s` (first recorded release).\n' "$base"
        elif [[ "$old_base" == "$base" ]]; then
            printf -- '- Base unchanged: `%s`.\n' "$base"
        else
            printf -- '- Base updated from `%s` to `%s`.\n' "$old_base" "$base"
        fi
        if [[ -z "$old_digest" ]]; then
            printf -- '- Signed image digest: `%s` (first recorded release).\n\n' "$digest"
        elif [[ "$old_digest" == "$digest" ]]; then
            printf -- '- Signed image digest unchanged: `%s`.\n\n' "$digest"
        else
            printf -- '- Signed image digest changed from `%s` to `%s`.\n\n' "$old_digest" "$digest"
        fi
    done
} > "$tmp/notes.md"

cat "$tmp/notes.md" >> "$GITHUB_STEP_SUMMARY"
if [[ "$PUBLISH_RELEASE" != true ]]; then
    exit 0
fi

for i in "${!variants[@]}"; do
    digest=$(jq -er --arg v "${variants[i]}" '.images[$v].digest' <<< "$manifest")
    docker buildx imagetools create \
        --tag "$image:${dated[i]}" --tag "$image:${stable[i]}" --tag "$image:${aliases[i]}" \
        "$image@$digest"
    for tag in "${dated[i]}" "${stable[i]}" "${aliases[i]}"; do
        actual=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "$image:$tag")
        [[ "$actual" == "$digest" ]] || { echo "Digest mismatch for $image:$tag" >&2; exit 1; }
    done
done

gh release create "$RELEASE_TAG" "$tmp/images.json" --target "$GITHUB_SHA" \
    --title "Debug Container $RELEASE_TAG" --notes-file "$tmp/notes.md" --latest
