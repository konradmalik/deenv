#!/bin/bash

echo "jupyterhub needs to be run as root"
exec jupyterhub -f /etc/jupyterhub/jupyterhub_config.py
