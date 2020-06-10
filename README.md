# Debug-Container

[![Docker Repository on Quay](https://quay.io/repository/pichuang/debug-container/status "Docker Repository on Quay")](https://quay.io/repository/pichuang/debug-container)

This container can be thought of as the administrator’s shell. Many of the debugging tools (such as ping, traceroute, and mtr) and man pages that an administrator might use to diagnose problems on the host are in this container.

- Networking-related commands:
  - [x] iproute
  - [x] net-tools
  - [x] mtr
  - [x] dig
  - [x] ping
  - [x] ethtool
  - [x] nmap-ncat
- Generic commands:
  - [x] vim
  - [x] git
  - [x] htop

## Download
```
docker pull quay.io/pichuang/debug-container
```

## How to use `debug-container` on specific hosts?

1. Bridge Mode (Container on OS):
```
docker run -it --rm --name debug-container quay.io/pichuang/debug-container
```

2. Host Mode (Container within OS):
```
docker run -it --rm --name debug --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=debug-container -e IMAGE=pichuang/debug-container \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       quay.io/pichuang/debug-container
```

3. Container Mode (Bridge another container)
```
docker run -it --rm --name debug-contaienr --net container:<container_name> quay.io/pichuang/debug-container
```


## How to use `debug-container` on Red Hat OpenShift?

1. Namespace Level Debugging: Running one Pod in project and `any node`
```
oc project <PROJECT NAME>
oc run ocp-debug-container --image quay.io/pichuang/debug-container \
   --restart=Never --attach -i --tty --rm
```

2. Namespace Level Debugging: Running one Pod in project and `specific node`
```
oc project <PROJECT NAME>
oc run ocp-debug-container --image quay.io/pichuang/debug-container \
   --restart=Never --attach -i --tty --rm \
   --overrides='{ "apiVersion": "v1", "spec": { "kubernetes.io/hostname":"compute-1"}}}'
```
- Remind: Please replace `kubernetes.io/hostname:<hostname>`

3. Node Level Debugging: Running one Pod on `specific node`

```bash
oc project <PROJECT NAME>
oc run ocp-debug-container --image quay.io/pichuang/debug-container \
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

## How to build the container images?
- If you choose buildah...
```
make build-buildah
```

- If you choose docker...
```
make build-docker
```


## Author
* **Phil Huang** <phil.huang@redhat.com>

