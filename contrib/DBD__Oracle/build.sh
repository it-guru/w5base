#!/bin/bash
set -x
cd /tmp 
rm -Rf DBD-Oracle*  2>/dev/null
wget -O DBD-Oracle.tgz \
     http://search.cpan.org/CPAN/authors/id/P/PY/PYTHIAN/DBD-Oracle-1.23.tar.gz
tar -xzvf DBD-Oracle*.tgz
rm DBD-Oracle*.tgz
cd DBD-Oracle*
export ORACLE_HOME=`echo /usr/lib/oracle/10.*/client/lib`
export LD_LIBRARY_PATH=$ORACLE_HOME
export TNS_ADMIN=/etc/oracle
perl Makefile.PL
make
sudo make install



