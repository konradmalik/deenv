# ==================================================================
# module list
# ------------------------------------------------------------------
# jupyter hub+lab           latest (pip)
# airflow                   latest (pip)
# dagster                   latest (pip)
# MLflow                    latest (pip)
# polynote                  latest (github tar)
# Dask                      latest (pip)
# Ray                       latest (pip)
# Prefect                   latest (pip)
# ==================================================================

FROM konradmalik/spark:latest
USER root

# ==================================================================
# python
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        setuptools \
        numpy \
        scipy \
        pandas \
        cloudpickle \
		joblib

# ==================================================================
# jupyter hub
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
    npm  nodejs && \
    npm install -g configurable-http-proxy && \
    $PIP_INSTALL \
        jupyterhub jupyterlab && \
    mkdir -p /etc/jupyterhub
COPY configs/jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
    
# ==================================================================
# MLflow 
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
		mlflow && \
		sed -i 's/127.0.0.1/0.0.0.0/g' /usr/local/lib/python${PYTHON_COMPAT_VERSION}/dist-packages/mlflow/cli.py && \
        curl -LO http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
        bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b && \
        rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=${PATH}:/miniconda/bin
RUN conda init && \
        conda config --set auto_activate_base false

# ------------------------------------------------------------------
# Airflow
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
        # mysql
        libmysqlclient-dev \
        # hive
        libsasl2-dev && \
    $PIP_INSTALL \
        apache-airflow[mysql,hive,hdfs,postgres,azure,devel,redis,ssh]
ENV AIRFLOW_HOME=~/airflow

# ==================================================================
# Dagster
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        dagster \
        dagster-airflow \
        dagster-dask \
        dagster-aws \
        dagster-bash \
        dagster-cron \
        dagster-pandas \
        dagster-postgres \
        dagster-pyspark \
        dagster-spark \
        dagster-ssh \
        # must be last
        && $PIP_INSTALL dagit

# ==================================================================
# Dask
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        dask

# ==================================================================
# Ray
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        ray ray[debug]

# ==================================================================
# Prefect
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        prefect

# ==================================================================
# Polynote
# ------------------------------------------------------------------
ENV POLYNOTE_VERSION=0.3.11
ENV POLYNOTE_ARCHIVE=https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/polynote-dist.tar.gz
RUN curl -sL $POLYNOTE_ARCHIVE | tar -zx -C /usr/local/
ENV POLYNOTE_HOME /usr/local/polynote

RUN $PIP_INSTALL \ 
    jep jedi virtualenv

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
RUN ldconfig && \
    apt-get clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# add default user
ENV DEFAULT_USER=deenv
RUN chmod +x add-user.sh && ./add-user.sh $DEFAULT_USER

# make spark dir owned by that user
RUN chown -R $DEFAULT_USER:$DEFAULT_USER $SPARK_HOME

# make jupyter notebook token equal to username by default
ENV JUPYTER_LAB_TOKEN=$DEFAULT_USER

# copy run scripts
COPY scripts/run-* /
RUN chmod +x /run-*

# run as non-root
USER $DEFAULT_USER

# make sure data folder has proper permissions
RUN mkdir -p /home/$DEFAULT_USER/data
VOLUME /home/$DEFAULT_USER/data

# dagit
EXPOSE 3000
# jupyterlab
EXPOSE 8888
# jupyterhub
EXPOSE 8000
# spark ui
EXPOSE 4040
# spark master
EXPOSE 7077
# spark worker
EXPOSE 8081
# polynote
EXPOSE 8192
