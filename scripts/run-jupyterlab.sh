#!/bin/bash

exec jupyter lab --no-browser --ip=0.0.0.0 --NotebookApp.token=$JUPYTER_LAB_TOKEN --notebook-dir=\"/home/$DEFAULT_USER\"
