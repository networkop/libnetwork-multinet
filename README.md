# Building a custom docker daemon with blackjack and deterministric network order

Default implementation of docker networking (libnetwork) uses heap
data structure to store pointers to all connected networks. This makes
the order in which a container is attached to its networks 
(with `docker network connect` or a similar API call)
completely irrelevant as the heap `.pop()` operation reorders the 
elements in a heap tree. One potential fix is to change the `endpoints`
data structure to a simple array. This is what's implemented in
this [patch](https://github.com/docker/libnetwork/issues/2093) with
accompanying [pull request](https://github.com/docker/libnetwork/issues/2093).

> Note that this patch may never get merged and may
  deviate from libnetwork's master branch more as the time goes

## Building a patched docker daemon

The below scripts implements all the steps necessary to
build docker binaries from source

```bash
chmod +x ./build.sh && ./build.sh
```

The above step can be run inside a container (helps with the cleanup)

```bash
docker run --privileged -it centos bash
git clone https://github.com/networkop/libnetwork-multinet.git && cd libnetwork-multinet
chmod +x ./build.sh && ./build.sh
```

The resulting files can be found outside of container:

```bash
# find /var/lib/docker -name dockerd
var/lib/docker/overlay2/22ed554543dc9efb1bee699bcc09917bbe59f5ae42b39a1c71a5b94f4f67dbf5/diff/docker/bundles/binary-daemon/dockerd /usr/bin/dockerd
```

## Replacing the existing docker daemon with the patched one

```bash
yum install which -y
systemctl stop docker.service
DOCKERD=$(which dockerd)
mv $DOCKERD $DOCKERD-old
cp docker/bundles/latest/binary-daemon/dockerd $DOCKERD
systemctl start docker.service
```

Make sure that SELinux security context on both $DOCKERD and $DOCKERD-old are the same 

## Testing

Need to create networks with more than 3 interfaces to
catch that:

```bash
docker network create net1
docker network create net2
docker network create net3
docker network create net4

docker create --name test1 -it alpine sh
docker create --name test2 -it alpine sh

docker network connect net1 test1
docker network connect net2 test1
docker network connect net3 test1
docker network connect net4 test1

docker network connect net1 test2
docker network connect net2 test2
docker network connect net3 test2
docker network connect net4 test2

docker start test1
docker start test2
```

To check the order of interfaces:

```bash
docker exec -it test1 ip a
docker exec -it test2 ip a
```


