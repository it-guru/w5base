#!/bin/bash
sudo sh -c "test -x /etc/profile.local && . /etc/profile.local; \$W5BASEINSTDIR/sbin/W5Server -d"
