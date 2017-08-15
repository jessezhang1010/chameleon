#!/bin/bash 

vmac=$1
vnic=$2
vf=$3

tunctl -b -t $vnic
ifconfig $vnic up
brctl addif br0 $vnic

qemu-system-x86_64 \
-enable-kvm \
-daemonize \
-boot c \
-cpu host \
-smp 2 \
-m 2048 \
-hda /home/cc/chameleon-mvapich2-virt-appliance.qcow2 \
-net nic,macaddr=$vmac,model=virtio \
-net tap,ifname=$vnic,script=no \
-device pci-assign,host=$3,id=hostdev0 \
-device ivshmem,shm=mv2-virt,size=512m \
-vnc none

