#!/bin/bash
# Clean up a docker testing environment:
# 1. Forcibly remove containers
# 2. Remove volumes
# 3. Remove untagged images (generally temporary or old builds)
docker ps -qa | xargs -r docker rm -f
docker volume ls -f dangling=true -q | xargs -r docker volume rm
docker images -f dangling=true -q | xargs -r docker rmi
