#!/bin/bash
if ! (( ${DISABLE_W5S:-0} )); then 
   echo -ne "\n---\n\n" >&2
   echo "$(date '+%Y-%m-%d %H:%M:%S,%3N') INFO autostart.sh start w5server" >&2
   supervisorctl start w5server
   sleep 3
fi

if ! (( ${DISABLE_W5APP:-0} )); then 
   echo -ne "\n---\n\n" >&2
   echo "$(date '+%Y-%m-%d %H:%M:%S,%3N') INFO autostart.sh start acache" >&2
   supervisorctl start acache
   echo "$(date '+%Y-%m-%d %H:%M:%S,%3N') INFO autostart.sh start httpd" >&2
   supervisorctl start httpd
   sleep 3
fi

exit 0

