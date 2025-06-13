#!/bin/bash
curl -s -n -H 'Accept: application/json' \
     -X GET \
     'https://w5base.net/w5base/auth/AL_TCom/appl/ById/17498174960001' | jq
