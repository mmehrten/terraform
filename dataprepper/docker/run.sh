
img=$(docker run -d -v ${PWD}:/usr/share/data-prepper/pipelines/ -it opensearchproject/data-prepper:latest bin/data-prepper)
sleep 60
docker exec -it $img curl -k -XPOST -H "Content-Type: application/json" -d "$(cat cloudtrail-example.json)" http://localhost:2021/log/ingest
sleep 10
docker logs $img
docker stop $img