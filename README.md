# Debug-Container

[![Docker Repository on Quay](https://quay.io/repository/tw_pichuang/debug-container/status "Docker Repository on Quay")](https://quay.io/repository/tw_pichuang/debug-container)

[![OpenSSF - Scorecard supply-chain security](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml/badge.svg)](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml)
[![Docker](https://github.com/pichuang/debug-container/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/pichuang/debug-container/actions/workflows/docker-publish.yml)

This container can be thought of as the administrator's shell. Many of the debugging tools (such as ping, traceroute, and mtr) and man pages that an administrator might use to diagnose problems on the host are in this container.

## Container Image Variants

| Variant | Base Image | Tag | Base Image Provider |
|---|---|---|---|
| **CentOS Stream 9** | `quay.io/centos/centos:stream9` | `master` / `latest` | Community |
| **Azure Linux 3.0 (Microsoft)** | `mcr.microsoft.com/azurelinux/base/core:3.0` | `microsoft` | Microsoft |

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

## How to use `debug-container` on specific hosts?

1. Bridge Mode (Container on OS):
```bash
docker run -it --rm --name debug-container ghcr.io/pichuang/debug-container:master
```

2. Host Mode (Container within OS):
```bash
docker run -it --rm --name debug --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=debug-container -e IMAGE=pichuang/debug-container \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       ghcr.io/pichuang/debug-container:master
```

3. Container Mode (Bridge another container)
```bash
docker run -it --rm --name debug-container --net container:<container_name> ghcr.io/pichuang/debug-container:master
```

## How to use `debug-container` on Native Kubernetes/Tanzu Kubernetes Grid Cluster/Azure Kubernetes Service?

1. Namespace Level Debugging: Running one Pod in namespace and `any node`
```bash
kubectl run -n default debug-container --restart=Never --rm -i --tty --image ghcr.io/pichuang/debug-container:master -- /bin/bash
```

2. Namespace Level Debugging: Running one Pod in namespace and `specific node`
```bash
# Show all of nodes
kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-agentpool-40137516-vmss000000   Ready    agent   82m   v1.22.11
aks-agentpool-40137516-vmss000001   Ready    agent   82m   v1.22.11
aks-agentpool-40137516-vmss000002   Ready    agent   82m   v1.22.11

# Run the command
kubectl run -n default debug-container --restart=Never --rm -i --tty --overrides='{ "apiVersion": "v1", "spec": {"nodeSelector":{"kubernetes.io/hostname":"aks-agentpool-40137516-vmss000002"}}}' --image ghcr.io/pichuang/debug-container:master -- /bin/bash
```

3. Node Level Debugging: Running one Pod on `specific node`
```bash
kubectl run -n default debug-container --image ghcr.io/pichuang/debug-container:master \
  --restart=Never -it --attach --rm \
  --overrides='{ "apiVersion": "v1", "spec": { "nodeSelector":{"kubernetes.io/hostname":"aks-agentpool-40137516-vmss000002"}, "hostNetwork": true}}' -- /bin/bash

# or
$ kubectl debug node/aks-agentpool-40137516-vmss000002 -it --image=ghcr.io/pichuang/debug-container:master -- /bin/bash
Creating debugging pod node-debugger-aks-agentpool-40137516-vmss000002-psvms with container debugger on node aks-agentpool-40137516-vmss000002.
If you don't see a command prompt, try pressing enter.

[root@aks-agentpool-14864487-vmss000000 /]# chroot /host /bin/bash
root [ / ]# cat /etc/os-release | head -n 2
```

4. Deploy as a Deployment
```bash
kubectl apply -f deployment-debug-container.yaml
```

## How to use `debug-container` on Red Hat OpenShift?

1. Namespace Level Debugging: Running one Pod in project and `any node`
```bash
oc project <PROJECT NAME>
oc run ocp-debug-container --image ghcr.io/pichuang/debug-container:master \
   --restart=Never --attach -i --tty --rm
```

2. Namespace Level Debugging: Running one Pod in project and `specific node`
```bash
oc project <PROJECT NAME>
oc run ocp-debug-container --image ghcr.io/pichuang/debug-container:master \
   --restart=Never --attach -i --tty --rm \
   --overrides='{ "apiVersion": "v1", "spec": { "nodeSelector":{"kubernetes.io/hostname":"compute-1"}}}'
```
- Remind: Please replace `kubernetes.io/hostname:<hostname>`

3. Node Level Debugging: Running one Pod on `specific node`

```bash
oc project <PROJECT NAME>
oc run ocp-debug-container --image ghcr.io/pichuang/debug-container:master \
  --restart=Never -it --attach --rm \
  --overrides='{ "apiVersion": "v1", "spec": { "nodeSelector":{"kubernetes.io/hostname":"compute-1"}, "hostNetwork": true}}'
```

4. Running Container Level Debugging
```bash
oc project <PROJECT NAME>
oc rsh pod/<POD NAME>
```

5. Running Pods Level Debugging
```bash
oc project <PROJECT NAME>
oc debug pods/<Pod NAME>
```

## How to Import YAML?

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: debug-container
spec:
  containers:
  - image: ghcr.io/pichuang/debug-container:master
    name: debug-container
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 30; done;" ]
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
    securityContext:
      runAsUser: 0
      runAsNonRoot: false
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
        add:
          - NET_RAW
          - NET_ADMIN
```


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

- If you choose buildah...
```bash
make build-buildah
```

Both Dockerfiles use multi-stage builds to exclude deadman's Git history from
the final image. CI builds and runs both variants on native `amd64` and `arm64`
runners before publishing. Publishing runs on pushes to `master`, version tags,
and the weekly schedule; pull requests verify without publishing.
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

