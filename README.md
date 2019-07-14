# Debug-Container

[![Docker Repository on Quay](https://quay.io/repository/pichuang/debug-container/status "Docker Repository on Quay")](https://quay.io/repository/pichuang/debug-container)

This container can be thought of as the administrator’s shell. Many of the debugging tools (such as strace, traceroute, and mtr) and man pages that an administrator might use to diagnose problems on the host are in this container.

- Networking-related commands:
  - [x] iproute
  - [x] net-tools
  - [x] mtr
  - [x] dig
- Generic-related commands:
  - [x] vim
  - [x] git

## Download
```
docker pull quay.io/pichuang/debug-container
```

## How to use `debug-container` on specific hosts?

1. Independent Mode (Container on OS):
```
docker run -it --rm --name debug-container quay.io/pichuang/debug-container
```

2. Mixed Mode (Container within OS):
```
docker run -it --rm --name debug --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=debug-container -e IMAGE=pichuang/debug-container \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       quay.io/pichuang/debug-container
```

## How to use it on Red Hat OpenShift v3?

1. Running one Pod in project and `any node`
```
oc project <PROJECT NAME>
oc run ocp-debug-container --image=quay.io/pichuang/debug-container \
   --restart=Never --attach -i --tty --rm
```

2. Running one Pod in project and `specific node`
```
oc project <PROJECT NAME>
oc run ocp-debug-container --image=quay.io/pichuang/debug-container \
   --restart=Never --attach -i --tty --rm \
   --overrides='{ "apiVersion": "v1", "spec": { "nodeSelector":{"<key>":"<value>"}}}'
```
- Remind: Please replace `<key>:<value>`

## Author
* **Phil Huang** - [Phil Workspace](https://blog.pichuang.com.tw)

