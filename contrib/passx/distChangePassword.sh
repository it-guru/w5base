#!/bin/bash
cat ChangePassword | ssh $1 "sudo sh -c 'cat > /usr/local/bin/ChangePassword' && sudo chmod 755 /usr/local/bin/ChangePassword"
