#!/bin/bash

docker run --rm -it \
    --name deenv \
    --publish 8192:8192 \
	--publish 4040:4040 \
	--publish 3000:3000 \
	--publish 8080:8080 \
    --ipc host \
    --volume `pwd`/data:/home/deenv/data \
	konradmalik/deenv /usr/local/polynote/polynote.py

