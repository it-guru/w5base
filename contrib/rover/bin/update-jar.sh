#!/bin/bash
BINDIR=$(dirname $0)

cd "$BINDIR/.."

wget -O rover-ctl.tar \
   https://developer.telekom.de/docs/src/tardis_customer_handbook/rover/binaries/roverctl-15.9.1.tar

mkdir tmp 2>/dev/null
cd tmp
tar -xvf ../rover-ctl.tar
JARFILE=$(ls rover-ctl-*/rover-ctl-*.jar)
cd ..
echo ""
echo "Extracting $JARFILE to lib/rover-ctl.jar"
cp tmp/rover-ctl-*/rover-ctl-*.jar lib/rover-ctl.jar && echo -ne "\nOK\n\n"
rm -Rf tmp rover-ctl.tar
