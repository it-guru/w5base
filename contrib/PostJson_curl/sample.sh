#!/bin/bash

curl -n -v \
    -H "Content-Type: application/json" \
    -X POST --data-binary @- \
    https://w5base-devnull.telekom.de/darwin/auth/itil/itcloudarea/Modify <<EOF
{
 "Formated_name": "testarea",
 "Formated_appl": "dina",
 "Formated_cistatusid": "3",
 "Formated_cloud": "AWS",
 "FormatAs": "nativeJSON",
 "OP":"save" 
}
EOF
# "Formated_appl": "W5Warehouse",
