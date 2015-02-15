#!/bin/sh

SOL_UPD  = "2"
BASE_DIR = "rpool/export/repo"
REPO_DIR = "$BASE_DIR/sol_11_$SOL_UPD"
REPO_ISO = $1
CD_MOUNT = "/mnt/cdrom"

mkdir /mnt/cdrom
zfs create $BASE_DIR
zfs create $REPO_DIR
mount -F hsfs $REPO_ISO $CD_MOUNT
rsync -a $CD_MOUNT* $REPO_DIR
pkgrepo -s $REPO_DIR refresh
pkg set-publisher -G '*' -g $REPO_DIR solaris