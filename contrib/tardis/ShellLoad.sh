#!/usr/bin/bash
#  Sample curl/jq loader programm to access SM.now over Tardis
#  Copyright (C) 2026  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# Generall requirement is to have jq and curl installied and in PATH. If
# you need to use PROXY set to access Tardis, you have also need to set
# HTTPS_PROXY and maybe NO_PROXY .

TOKENBASE="https://iris.prod.dhei.telekom.de"

# add ClientID and Client Secret to ~/.netrc for host part in TOKENBASE!
# f.e.:
#   machine iris.prod.dhei.telekom.de
#   login plm--saatflex--saatflexera
#   password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

APIBASE="https://stargate.prod.dhei.telekom.de"
APINAME="/it4tel-it/sm-now/config-api/v1"

SNMODULE="cmdb_ci_server"
FIELDS="company,correlation_id,cost_center,discovery_source,used_for,life_cycle_stage,life_cycle_stage_status,location,name,object_id,sys_class_name,sys_id,sys_updated_on"




#
# getTardisAccessToken: gets a valid Tardis AccessToken with BasicAuth
#                       processing over .netrc .
#
getTardisAccessToken()
{
   # We always create a new access token, to ensure it's valid also 
   # in long paging request sequences

   TOKENPATH="/auth/realms/default/protocol/openid-connect/token"
   _ACCESS_TOKEN=$(curl -n -s -X POST "${TOKENBASE}/${TOKENPATH}" \
                       -H 'Content-Type: application/x-www-form-urlencoded' \
                       -d "grant_type=client_credentials" \
                  |jq -r '.token_type + " " + .access_token')
   echo ${_ACCESS_TOKEN}
}

typeset -i pageNumber=1
typeset -i maxPages=1
while true; do
    ACCESS_TOKEN=$(getTardisAccessToken)
    if [ $(echo "${ACCESS_TOKEN}" | wc -c) -lt 100 ]; then
       echo "ERROR: invalid ACCESS_TOKEN = '${ACCESS_TOKEN}'" >&2
       exit 1
    fi 
    #echo "ACCESS_TOKEN=$ACCESS_TOKEN"
    # do data request
    D=$( curl -s -G -X GET "${APIBASE}${APINAME}/get/${SNMODULE}" \
              -d "pageSize=500" \
              -d "pageNumber=${pageNumber}" \
              -H 'Content-Type: application/x-www-form-urlencoded' \
              -H "Authorization: ${ACCESS_TOKEN}" \
           | jq
    )
    currentPage=${pageNumber}    # store current page number
    if [ "${pageNumber}" == "1" ]; then
       maxPages=$(echo "$D" | jq '.paging.maxPages')
    fi
    nextPage=$(echo "$D" | jq '.paging.nextPage')
    ####################################################################


    # Data (D) Processing 
    N=$(echo "$D" | wc -c)
    if [ ${N} -gt 1000 ]; then
       echo "${FIELDS}" | tr ',' ';'
    fi
    echo "$D" | jq -r --arg cols "$FIELDS" '
       ($cols | split(",")) as $headers |
       .data[] |
       [$headers[] as $col | .[$col] // ""] |
       @csv
    ' | tr ',' ';'
    #echo -ne "\n\n-----------------------------------\n"
    #echo "currentPage        = ${currentPage} of ${maxPages}"
    #echo "resultCharCount    = ${N}"
    #echo "nextPage           = ${nextPage}"
    #echo "-----------------------------------"
    ####################################################################


    # calculate break expression and/or pageNumber for next loop
    if [ "${nextPage}" != "" -a "${nextPage}" != "null" ]; then
       pageNumber=${nextPage}
    else
       break
    fi
    ####################################################################
done 

exit 0


