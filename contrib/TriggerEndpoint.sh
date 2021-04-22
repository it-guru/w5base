#!/bin/bash

TRIGGERURL="https://w5base-devnull.telekom.de/darwin/auth/azure/subscription"
FUNCTION="TriggerEndpoint"


cat << EOF | curl -sn \
             "$TRIGGERURL/$FUNCTION" \
             --header "Content-Type: application/json" \
             --header "Accept: application/json" \
             --request POST \
             --data-binary @- 
{
   "ResourceId":"/xx/yyy/ccc",
   "SubscriptionId":"00000000-0000-0000-0000-000000000000"
}
EOF


