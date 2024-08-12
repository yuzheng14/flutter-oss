#!/bin/zsh
set -x

container_name=my-minio

# should use zsh
if [[ $SHELL != "/bin/zsh" ]]; then
  echo "Please use zsh"
  exit 1
fi

# get the status of the container
status=$(docker inspect -f '{{.State.Status}}' ${container_name})

# if the container exists
if [[ $? == 0 ]]; then
  if [[ $status == "running" ]]; then
    echo "Container is already running"
  elif [[ $status == "exited" ]]; then
    docker start ${container_name}
  elif [[ $status == "paused" ]]; then
    docker unpause ${container_name}
  else
    echo "Container is in unknown state:" $status
    exit 1
  fi
else
  # see https://min.io/docs/minio/container/index.html
  # password should longer than 7 characters
  docker run -dit \
    -p 9000:9000 \
    -p 9001:9001 \
    --name ${container_name} \
    -v minio-data:/data \
    -e "MINIO_ROOT_USER=admin" \
    -e "MINIO_ROOT_PASSWORD=admin678" \
    minio/minio server /data --console-address ":9001"
fi
