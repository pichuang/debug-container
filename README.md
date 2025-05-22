# Debug-Container

[![Docker Repository on Quay](https://quay.io/repository/tw_pichuang/debug-container/status "Docker Repository on Quay")](https://quay.io/repository/tw_pichuang/debug-container)

[![OpenSSF - Scorecard supply-chain security](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml/badge.svg)](https://github.com/pichuang/debug-container/actions/workflows/scorecard.yml)

This container can be thought of as the administrator's shell. Many of the debugging tools (such as ping, traceroute, and mtr) and man pages that an administrator might use to diagnose problems on the host are in this container.

- Networking-related commands:
  - [x] iproute2
  - [x] net-tools
  - [x] mtr-tiny
  - [x] dnsutils (dig)
  - [x] iputils-ping
  - [x] ethtool
  - [x] netcat
  - [x] nmap
  - [x] tcpdump
  - [x] curl
- Generic commands:
  - [x] vim
  - [x] git
  - [x] htop
  - [x] sudo
  - [x] tini (proper init process)

## Download
```
docker pull ghcr.io/pichuang/debug-container:master
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
```
docker run -it --rm --name debug-contaienr --net container:<container_name> ghcr.io/pichuang/debug-container:master
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
kubectl run -n default debug-container --restart=Never --rm -i --tty --overrides='{ "apiVersion": "v1", "spec": {"kubernetes.io/hostname":"aks-agentpool-40137516-vmss000002"}}' --image ghcr.io/pichuang/debug-container:master -- /bin/bash
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
   --overrides='{ "apiVersion": "v1", "spec": { "kubernetes.io/hostname":"compute-1"}}}'
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
oc rsh pod/<PDO NAME>
```

5. Running Pods Level Debugging
```bash
oc project <PROJECT NAME>
oc debug pods/<Pod NAME>
```

## How to Import YAML?

```bash
---
apiVersion: v1
kind: Pod
metadata:
  name: ocp-debug-container
spec:
  containers:
  - image: ghcr.io/pichuang/debug-container:master
    name: ocp-debug-container
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 30; done;" ]
```

## How to build the container images?
- If you choose buildah...
```
make build-buildah
```

- If you choose docker...
```
make build-docker
```

## Security Best Practices

When using debug containers, especially with elevated privileges, consider the following security best practices:

1. **Avoid running privileged containers in production**: The `--privileged` flag gives containers full access to the host, which can be a security risk.

2. **Use non-root users**: The debug container now runs with a non-root user by default. This provides an extra layer of security.

3. **Limit container capabilities**: When possible, specify only the capabilities your container needs rather than running with full privileges.

4. **Time-limit debug sessions**: Always use the `--rm` flag to ensure containers are removed when the session ends.

5. **Restrict volume mounts**: Only mount the volumes necessary for debugging.

6. **Use network isolation**: When possible, use the default bridge network rather than host networking.

7. **Apply resource limits**: Consider setting memory and CPU limits on debug containers.

8. **Monitor container activity**: Keep track of who is using debug containers and monitor their activities.

Example of a more secure debug container run with limited privileges:

```bash
docker run -it --rm --name debug-container \
  --cap-add=NET_ADMIN --cap-add=SYS_PTRACE \
  --security-opt=no-new-privileges \
  ghcr.io/pichuang/debug-container:master
```

## Author
* **Phil Huang** <phil.huang@microsoft.com>

