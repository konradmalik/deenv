#!/bin/bash

docker run --rm -it \
    --name deenv \
    --publish 8888:8888 \
	--publish 4040:4040 \
    --ipc host \
    --volume `pwd`/data:/home/deenv/data \
	konradmalik/deenv jupyter lab --no-browser --ip=0.0.0.0 --NotebookApp.token=deenv --notebook-dir='/home/deenv

