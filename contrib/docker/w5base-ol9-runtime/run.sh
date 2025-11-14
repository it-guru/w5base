#!/bin/bash
W5DBHOST=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' w5db 2>/dev/null)

docker container rm -f w5base 2>/dev/null
docker container prune -f  
docker container run \
       --mount type=bind,source=/opt/w5base,target=/opt/w5base \
       -e "W5DBHOST=$W5DBHOST" \
       --tmpfs /etc/w5base/container:rw,size=1m \
       -it --name w5base it9000/w5base-ol9-runtime:beta
