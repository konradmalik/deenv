#!/bin/bash

docker run --rm -it \
	--name deenv \
    --volume `pwd`/data:/home/deenv/data \
	--publish 4040:4040 \
    --ipc host \
	konradmalik/deenv bash 
