# Debug-Container

[Container images on GitHub Container Registry (GHCR)](https://github.com/pichuang/debug-container/pkgs/container/debug-container)

[![OpenSSF - Scorecard supply-chain security](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml/badge.svg)](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml)
[![Docker](https://github.com/pichuang/debug-container/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/pichuang/debug-container/actions/workflows/docker-publish.yml)

An interactive shell with tools such as `ping`, `dig`, `mtr`, and `tcpdump` for troubleshooting container, Kubernetes, and host networking.

## Container Image Variants

| Variant | Base Image | Tag | Base Image Provider |
|---|---|---|---|
| **CentOS Stream 9** | `quay.io/centos/centos:stream9` | `master` / `latest` | Community |
| **Azure Linux 3.0 (Microsoft)** | `mcr.microsoft.com/azurelinux/base/core:3.0` | `microsoft` / `microsoft-latest` | Microsoft |

The `microsoft` variant uses Microsoft's Azure Linux base image. Support for this
custom image and its additional tools is not implied by the base image's support policy.

## Included Tools

- Networking:
  - [x] iproute
  - [x] net-tools
  - [x] mtr
  - [x] dig (bind-utils)
  - [x] ping (iputils)
  - [x] ethtool
  - [x] nmap / nmap-ncat
  - [x] tcpdump
  - [x] iperf3
  - [x] curl / wget
- Monitoring:
  - [x] htop
  - [x] sysstat
  - [x] numactl
  - [x] procps-ng
- General:
  - [x] vim
  - [x] git
  - [x] jq
  - [x] python3 / pip3
  - [x] speedtest-cli
  - [x] deadman (`/root/deadman/deadman`, not on `PATH`)
- CentOS Stream 9 only:
  - [x] hping3
  - [x] dnsperf

## Download

Both image variants support **Linux ARM64** (`linux/arm64`) and **Linux x86-64**
(`linux/amd64`). The same GHCR tag serves both architectures; Docker selects the
matching image automatically. For 32-bit x86 (`linux/386`), no image is published.

```bash
# CentOS Stream 9 (default)
docker pull ghcr.io/pichuang/debug-container:master

# Azure Linux 3.0
docker pull ghcr.io/pichuang/debug-container:microsoft
```

## Docker

Start a shell on Docker's default bridge network:

```bash
docker run -it --rm --name debug-container ghcr.io/pichuang/debug-container:master
```

To share an existing container's network namespace, replace `my-container`
with the name of a running container:

```bash
docker run -it --rm --network container:my-container ghcr.io/pichuang/debug-container:master
```

### Advanced: Docker host access

Run only on a trusted Linux Docker host you administer. This command uses
`--privileged`, shares the host's network, PID, and IPC namespaces, and mounts
the host root filesystem at `/host` **with write access**. Use the bridge
example if you do not need host access.

```bash
docker run -it --rm --name debug --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=debug-container -e IMAGE=pichuang/debug-container \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       ghcr.io/pichuang/debug-container:master
```

## Kubernetes (including AKS and Tanzu)

Start a temporary shell in your current namespace. Exit the shell to remove
the Pod. Use `-n YOUR_NAMESPACE` to select another namespace. Restricted
namespaces can reject this example, which uses the image's default root user.

```bash
kubectl run debug-container --restart=Never --rm -it \
  --image=ghcr.io/pichuang/debug-container:master --command -- /bin/bash
```

To use the Pod network on a specific node, run
`kubectl get nodes -L kubernetes.io/hostname` and set `NODE_HOSTNAME` to the
target node's label value:

```bash
NODE_HOSTNAME=my-node
kubectl run debug-container --restart=Never --rm -it \
  --image=ghcr.io/pichuang/debug-container:master \
  --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"${NODE_HOSTNAME}\"}}}" \
  --command -- /bin/bash
```

### Advanced: Kubernetes node access

For node **network** access only, set `NODE_HOSTNAME` as above and use
`hostNetwork: true`. This shares the node's network namespace but does not
mount its filesystem. Your namespace policy must allow host networking.

```bash
NODE_HOSTNAME=my-node
kubectl run debug-container --restart=Never --rm -it \
  --image=ghcr.io/pichuang/debug-container:master \
  --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"hostNetwork\":true,\"nodeSelector\":{\"kubernetes.io/hostname\":\"${NODE_HOSTNAME}\"}}}" \
  --command -- /bin/bash
```

For node **filesystem** access, use `kubectl debug node`. Set `NODE` to the
node's name from `kubectl get nodes` (not its hostname label). The debug Pod
uses host namespaces and mounts the node filesystem at `/host`; `chroot`
requires an appropriate debug profile and cluster policy. After exiting, delete
the debug Pod using the name printed by `kubectl debug`.

```bash
NODE=my-node
kubectl debug "node/${NODE}" -it \
  --image=ghcr.io/pichuang/debug-container:master -- /bin/bash
# Replace DEBUG_POD_NAME with the Pod name printed above.
kubectl delete pod DEBUG_POD_NAME
```

## Red Hat OpenShift

Run `oc project` to check your active project. Start a temporary shell
without requesting extra capabilities. The working directory is `/` so the shell
does not depend on access to `/root` when OpenShift assigns a non-root UID:

```bash
oc run ocp-debug-container --restart=Never --rm -it \
  --image=ghcr.io/pichuang/debug-container:master \
  --override-type=strategic \
  --overrides='{"apiVersion":"v1","spec":{"containers":[{"name":"ocp-debug-container","workingDir":"/"}]}}' \
  --command -- /bin/bash
```

Use `oc rsh POD_NAME` to open a shell in an existing Pod, or
`oc debug pod/POD_NAME` to start a debug copy. For node-level access, use
`oc debug node/NODE_NAME` if permitted by your cluster.

## YAML examples

Run these commands from the repository root. They use your current namespace
or project. All examples use `:master`; change the manifest's image tag to
`:microsoft` for Azure Linux.

**Kubernetes [Pod](pod-debug-container.yaml):** A toolbox for a single
session. It runs as root and requests `NET_RAW` and `NET_ADMIN`; it does not
meet the Restricted Pod Security standard.

```bash
kubectl apply -f pod-debug-container.yaml
kubectl wait --for=condition=Ready pod/debug-container --timeout=90s
kubectl exec -it pod/debug-container -- /bin/bash
kubectl delete -f pod-debug-container.yaml
```

**Kubernetes [Deployment](deployment-debug-container.yaml):** Keeps one
toolbox replica available until deleted. It also runs as root, but does not
explicitly add capabilities.

```bash
kubectl apply -f deployment-debug-container.yaml
kubectl rollout status deployment/debug-container --timeout=90s
kubectl exec -it deployment/debug-container -- /bin/bash
kubectl delete -f deployment-debug-container.yaml
```

**[OpenShift Pod](pod-ocp-debug-container.yaml):** Lets OpenShift assign the
UID, but still requires a Security Context Constraint (SCC) that permits
`NET_RAW` and `NET_ADMIN`. The default restricted SCC does not allow this
capability set.

```bash
oc apply -f pod-ocp-debug-container.yaml
oc wait --for=condition=Ready pod/ocp-debug-container --timeout=90s
oc rsh ocp-debug-container
oc delete -f pod-ocp-debug-container.yaml
```

The Deployment uses `imagePullPolicy: Always` to check the registry for the
current digest when a container starts. Both standalone Pods use Kubernetes'
default `IfNotPresent` for `:master` and may reuse a cached image.

## How to build the container images?

- CentOS Stream 9 (default):
```bash
make build-docker
```

- Azure Linux 3.0:
```bash
make build-docker-microsoft
```

- Azure Linux 3.0 with internal package mirror:
```bash
docker build -f Dockerfile-microsoft \
  --build-arg PACKAGE_REPO_URL=https://internal.example.com/azurelinux \
  -t debug-container:microsoft .
```

- CentOS Stream 9 with Buildah:
```bash
make build-buildah
```

Both Dockerfiles use multi-stage builds to exclude deadman's Git history from
the final image. CI builds and runs both variants on native `amd64` and `arm64`
runners before publishing. Publishing runs on pushes to `master`, matching
Git tags (such as `v1.2.3`), and the weekly schedule; pull requests verify without
publishing. A Git version tag triggers publishing but does not produce a
same-named image tag.
CentOS uses `master` / `latest` and
dated `vYYYYMMDD` tags; Azure Linux uses `microsoft` / `microsoft-latest` and
dated `vYYYYMMDD-microsoft` tags.

Push a `test-publish/*` branch to run the same checks and publish signed
`test-<run-id>-<attempt>-centos` and `test-<run-id>-<attempt>-microsoft` tags
without updating any stable tags.
To publish the regular tags from a selected ref, manually run the Docker
workflow with `publish_stable=true`. It reruns all four architecture checks
before publishing. A manual run without that option publishes only test tags.

To build for a specific architecture locally, use Docker Buildx. For example, on
an ARM64 host with x86-64 emulation enabled:

```bash
docker buildx build --platform linux/amd64 --load -t debug-container:amd64 .
docker buildx build --platform linux/amd64 --load -f Dockerfile-microsoft -t debug-container:microsoft-amd64 .
```

Replace `linux/amd64` with `linux/arm64` to target ARM64.

## Security

- Base images pinned with SHA256 digest
- Git dependencies pinned to specific commits
- pip packages pinned to exact versions
- All CI workflow actions pinned to commit SHA
- Container images signed with [cosign](https://github.com/sigstore/cosign)
- SBOM generated with [Anchore Syft](https://github.com/anchore/syft)
- Vulnerability scanning with [Snyk](https://snyk.io/)
- Supply chain security assessed with [OpenSSF Scorecard](https://securityscorecards.dev/)

## Author
* **Phil Huang** <phil.huang@microsoft.com>

