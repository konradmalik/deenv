#!/bin/bash

docker run --rm -it \
    --name deenv \
    --publish 8192:8192 \
	--publish 4040:4040 \
    --ipc host \
    --volume `pwd`/data:/home/deenv/data \
	konradmalik/deenv ./run-polynote.sh

