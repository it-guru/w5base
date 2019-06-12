#!/bin/bash
typeset -i c=0
IFS=$'\n'
PS1FILE="PowerView"

for PSFILE in *.ps*; do
   git checkout $PSFILE
done

for F in $(egrep '^(filter|function)' ${PS1FILE}.ps1); do
   c=$c+1;
   MNAME=$(printf "%s_part%03d.ps1" ${PS1FILE} $c)
   #cp ${PS1FILE}.ps1 $MNAME
   FNAME=$(echo "$F" | sed -e 's/^[^ ]* //' -e 's/ .*$//')
   if [ "$FNAME" != "func" \
        -a "$FNAME" != "Get-NetForest" \
        -a "$FNAME" != "Get-NetDomain" \
        -a "$FNAME" != "Get-NetGPO" \
        -a "$FNAME" != "Get-NetGroup" \
        -a "$FNAME" != "struct" ]; then
      NEWFNAME=$(echo "$FNAME"  | sed -e 's/^Get-/Get-XxX/' \
                                      -e 's/^Set-/Set-XxX/' \
                                      -e 's/^Add-/Add-XxX/' \
                                      -e 's/^Invoke-/Invoke-XxX/' \
                                      -e 's/^New-/New-XxX/' \
                                      -e 's/^Find-/Find-XxX/')
      echo "OLDFNAME=$FNAME NEWFNAME=$NEWFNAME"
      for PSFILE in *.ps*; do
         sed -i -e "s/$FNAME/$NEWFNAME/g" $PSFILE
      done
   fi
done

sed -i -e "s/Get-Net/Get-XxXNetwork/g" *.ps*

