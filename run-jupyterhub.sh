#!/bin/bash

# jupyterhub needs to be run as root
docker run --rm -it \
    --name deenv \
    --publish 8000:8000 \
	--publish 4040:4040 \
	--publish 3000:3000 \
	--publish 8080:8080 \
    --ipc host \
    --user root:root \
	konradmalik/deenv jupyterhub --ip=0.0.0.0 --no-ssl

