#!/bin/bash

DEBUGOBJ=""

if [[ "$1" =~ :: ]]; then
   DEBUGOBJ=$1
   shift
fi

W5EVPARAM=$*
W5EVENT=/opt/w5base/sbin/W5Event

CHKLIST=$(cat <<EOF
itncmdb::system       id         3K6T8G0QIHQ7G8
aws::NetworkInterface idpath     eni-002fd55e210abaefc@163126355411@eu-central-1
TPC1::project         id         238ae962-cbe5-46e2-9259-9bfd857fc583
TPC2::project         id         0096b537-0f99-43fe-b932-eeb93a7445ee
TPC3::project         id         030db0c8-9a52-4340-be96-674052499f57
TPC4::project         id         2962d5ca-f9b9-40d2-b519-61790ed643d5
TPC6::project         id         034fde2d-8d77-4f09-90f9-372711b36a4a
TPC8::project         id         03e7266a-2c13-40c4-883f-51233e194c6a
TPC10::project        id         1080dbe0-baa9-4bc0-8c81-2fd37d1529c5
azure::subscription   name       dtit_cid0067
tsotc::project        id         772c762b9d48415f8f21f560010425ad
caas::project         id         1BFZmaTCMhwCZBtNEpKm3qdHs1CZGNqYh2
GCP::project          id         de0360-e2e-monitoring-prd
base::grp             fullname      admin
base::user            posix         hvogler
tscape::archappl      archapplid    ICTO-4175
tsAuditSrv::system    systemname    EDE15Q
FLEXERAatW5W::system  systemname    ede188
tsacinv::system       systemname    EDE188
tsadopt::vfarm        name          dcppt-fra01-s01-cl01
tsciam::user          email         Peter.Testuser@external.telekom.de
caiman::user          email         Peter.Testuser@external.telekom.de
ewu2::system          systemname    dcplnx22483873
tssmartcube::tcc      systemname    QDE8HV
EOF
)
echo ""

echo "$CHKLIST" |egrep -v '^#' | ( while read l; do
   set -- $l
   DATAOBJ=$1
   SFIELD=$2
   SVALUE=$3
   if [ ! -z "$DATAOBJ" ]; then
      if [ ! -z "$DEBUGOBJ" -a "$DATAOBJ" != "$DEBUGOBJ" ]; then  
         continue 
      fi
      printf "Checking %-25s ..." "$DATAOBJ"
      BK=0
      if [ -z "$DEBUGOBJ" ]; then
         $W5EVENT $W5EVPARAM -t 10 W5ServerMONI \
                  $DATAOBJ $SFIELD $SVALUE >/dev/null 2>&1
         BK=$?
      else
         $W5EVENT $W5EVPARAM -d -v -t 10 W5ServerMONI $DATAOBJ $SFIELD $SVALUE 
         BK=$?
      fi
      if [ $BK == 0 ]; then
         echo -e  "\b\b\b            OK done";
      else
         echo -e  "\b\b\b            FAIL";
      fi
   fi
done
)
echo ""
