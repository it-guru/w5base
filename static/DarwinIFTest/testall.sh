#!/bin/bash
W5EVPARAM=$*
W5EVENT=/opt/w5base/sbin/W5Event

CHKLIST=$(cat <<EOF
aws::NetworkInterface idpath     eni-002fd55e210abaefc@163126355411@eu-central-1

base::grp             fullname      admin
base::user            posix         hvogler
tscape::archappl      archapplid    ICTO-4175
tsAuditSrv::system    systemname    EDE15Q
FLEXERAatW5W::system  systemname    ede15q
tssm::dev             configitemid  S33162327
tsacinv::system       systemname    EDE15Q
tsadopt::vfarm        name          dcppt-fra01-s01-cl01
tsciam::user          email         Peter.Testuser@external.telekom.de
caiman::user          email         Peter.Testuser@external.telekom.de
ewu2::system          systemname    dcplnx22483873
tsdina::system        name          qde8hv
tssmartcube::tcc      systemname    qde8hv
EOF
)

echo ""

echo "$CHKLIST" | ( while read l; do
   set -- $l
   DATAOBJ=$1
   SFIELD=$2
   SVALUE=$3
   if [ ! -z "$DATAOBJ" ]; then
      printf "Checking %-20s ..." "$DATAOBJ"
      $W5EVENT $W5EVPARAM -t 5 W5ServerMONI $DATAOBJ $SFIELD $SVALUE >/dev/null 2>&1
      BK=$?
      if [ $BK == 0 ]; then
         echo -e  "\b\b\b            OK done";
      else
         echo -e  "\b\b\b            FAIL";
      fi
   fi
done
)
echo ""
