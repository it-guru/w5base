#!/usr/bin/env sh

echo "Initializing enviroment for bbserver"
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:../sbin
export PATH

PERLLIB=/opt/w5base2/lib
export PERLLIB

bbserver $*

