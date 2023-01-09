#!/bin/bash

if [ "$W5BASESITE" = "" ]; then
   W5BASESITE="https://w5base-testenv.telekom.de"
fi

APPL=$1; shift
if [ "$APPL" = "" ]; then
   APPL="sample"
fi

CSRFILE=$1; shift
if [ "$CSRFILE" = "" ]; then
   CSRFILE="my.csr"
fi


if [ ! -f "${CSRFILE}" ]; then
   echo "File not found: ${CSRFILE}">&2
   exit 1
fi


if [ ! -f "${CSRFILE}.id" ]; then
   JSONREQ=$( 
      jq -n \
         --arg OP "save" \
         --arg CV "(id,state)" \
         --arg APPL "${APPL}" \
         --arg CSR "$(cat $CSRFILE)" \
         '{OP: $OP, CurrentView: $CV, sslcert: $CSR, appl: $APPL}' 
   )
   RES=$( curl -X POST "${W5BASESITE}/darwin/auth/CRaS/csr/Modify" \
               -H 'Content-Type: application/json' \
               -H 'Accept: application/json' \
               -n -s \
               -d "${JSONREQ}"
   )
   REQID=$(echo "${RES}" | jq -r '.[0].id')
   echo "Posted: ${REQID}"
   echo "$REQID" > "${CSRFILE}.id"
else
   REQID=$(cat "${CSRFILE}.id")
   echo "Checking: ${REQID} ..."
   JSONREQ=$( 
      jq -n \
         --arg CV "(id,state,ssslcert,ssslcertfilename)" \
         --arg ID "$REQID" \
         '{CurrentView: $CV, search_id: $ID}' 
   )
   RES=$( curl -X POST "${W5BASESITE}/darwin/auth/CRaS/csr/Result" \
               -H 'Content-Type: application/json' \
               -H 'Accept: application/json' \
               -n -s \
               -d "$JSONREQ"
   )
   #echo "JSONREQ:$JSONREQ"
   #echo "RES: $RES"
   STATE=$(echo "${RES}" | jq -r '.[0].state')
   echo -ne "... state is '${STATE}'\n\n"
   if [ "$STATE" = "signed" ]; then
      echo "It looks good. Try to download cert ..."
      CERTPATH=$(echo "${RES}" | jq -r '.[0].ssslcert')
      URLssslcert="${W5BASESITE}/darwin/auth/CRaS/csr/${CERTPATH}"
      #echo "URL='$URLssslcert'"
      SIGNEDCERT=$( curl -X GET "${URLssslcert}" -n -s )
      CERTFILENAME=$( echo "${RES}" | jq -r '.[0].ssslcertfilename' )
      if [ "${SIGNEDCERT}" != "" ]; then
         echo "OK, we have someting :-)"
         if [ "${CERTFILENAME}" != "" ]; then
            echo "    -> (stored in ${CERTFILENAME} )"
            echo "${SIGNEDCERT}" > "${CERTFILENAME}"
         fi
      fi
   fi





#signed
fi
