#!/bin/bash

echo "jupyterhub needs to be run as root"
exec jupyterhub --ip=0.0.0.0 --JupyterHub.port=8000 --no-ssl --Spawner.default_url='/lab' --Spawner.env_keep=\"['PATH', 'PYTHONPATH', 'SPARK_HOME', 'CONDA_ROOT', 'CONDA_DEFAULT_ENV', 'VIRTUAL_ENV', 'LANG', 'LC_ALL']\"
