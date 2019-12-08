# ==================================================================
# module list
# ------------------------------------------------------------------
# python                    3.7    (apt)
# jupyter hub+lab           latest (pip)
# airflow                   latest (pip)
# dagster                   latest (pip)
# MLflow		            latest (pip)
# Spark+koalas              2.4.4  (apt+pip)
# polynote                  latest (github tar)
# ==================================================================

FROM ubuntu:18.04
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_INSTALL="apt-get update && apt-get install -y --no-install-recommends --fix-missing"
ENV PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ENV GIT_CLONE="git clone --depth 10"

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update

# ==================================================================
# tools
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        sudo \
        wget \
        git \
        vim \
        curl \
        unzip \
        unrar \
        cmake \
		tmux

# ==================================================================
# python
# ------------------------------------------------------------------
ENV PYTHON_COMPAT_VERSION=3.7
RUN eval $APT_INSTALL \
        software-properties-common && \
	add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
	eval $APT_INSTALL \
        python${PYTHON_COMPAT_VERSION} \
        python${PYTHON_COMPAT_VERSION}-dev \
        python3-distutils-extra \
		libblas-dev liblapack-dev libatlas-base-dev gfortran \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python${PYTHON_COMPAT_VERSION} ~/get-pip.py && \
    ln -s /usr/bin/python${PYTHON_COMPAT_VERSION} /usr/local/bin/python3 && \
    ln -s /usr/bin/python${PYTHON_COMPAT_VERSION} /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        numpy \
        scipy \
        pandas \
        cloudpickle \
		joblib

# ==================================================================
# Java and scala
# ------------------------------------------------------------------
ENV JAVA_VERSION=8
ENV SCALA_VERSION=2.11.12
RUN eval $APT_INSTALL \
        openjdk-$JAVA_VERSION-jdk \
		scala \
        && \
    $PIP_INSTALL \
        koalas
ENV JAVA_HOME /usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64

# ==================================================================
# jupyter hub
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
    npm  nodejs && \
    npm install -g configurable-http-proxy && \
    $PIP_INSTALL \
        jupyterhub jupyterlab && \
        jupyterhub --generate-config
    
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

# ==================================================================
# Spark (with pyspark and koalas)
# ------------------------------------------------------------------
# HADOOP
ENV HADOOP_VERSION 2.10.0
ENV HADOOP_ARCHIVE=https://www-eu.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
ENV HADOOP_HOME /usr/local/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -s $HADOOP_ARCHIVE | tar -xz -C /usr/local/

# SPARK
ENV SPARK_VERSION 2.4.4
ENV SPARK_ARCHIVE=https://www-eu.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-without-hadoop.tgz
ENV SPARK_HOME /usr/local/spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_LOG=/tmp
ENV SPARK_HOST=
ENV SPARK_MASTER=
ENV SPARK_WORKER_CORES=
ENV SPARK_WORKER_MEMORY=
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -s $SPARK_ARCHIVE | tar -zx -C /usr/local/

# add here jars necessary to use azure blob storage and amazon s3 with spark
ENV AWS_HADOOP_ARCHIVE=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar
# below version must be exact as maven says that above was compiled with!
ENV AWS_VERSION=1.11.271
ENV AWS_ARCHIVE=https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/$AWS_VERSION/aws-java-sdk-$AWS_VERSION.jar
ENV AZURE_HADOOP_ARCHIVE=https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/$HADOOP_VERSION/hadoop-azure-$HADOOP_VERSION.jar
# below version must be exact as maven says that above was compiled with!
ENV AZURE_VERSION=7.0.0
ENV AZURE_ARCHIVE=https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/$AZURE_VERSION/azure-storage-$AZURE_VERSION.jar
# also add cassandra connector and dependencies
ENV SPARK_CASSANDRA_ARCHIVE=http://dl.bintray.com/spark-packages/maven/datastax/spark-cassandra-connector/2.4.0-s_2.11/spark-cassandra-connector-2.4.0-s_2.11.jar
ENV TWITTER_ARCHIVE=https://repo1.maven.org/maven2/com/twitter/jsr166e/1.1.0/jsr166e-1.1.0.jar
RUN cd $SPARK_HOME/jars && \
    curl -LO $AWS_ARCHIVE && \
    curl -LO $AWS_HADOOP_ARCHIVE && \
    curl -LO $AZURE_ARCHIVE && \
    curl -LO $AZURE_HADOOP_ARCHIVE && \
    curl -LO $SPARK_CASSANDRA_ARCHIVE && \
    curl -LO $TWITTER_ARCHIVE

# Pyspark related stuff
RUN $PIP_INSTALL koalas
# make sure your PYTHONPATH can find the PySpark and Py4J under $SPARK_HOME/python/lib:
RUN cp $(ls $SPARK_HOME/python/lib/py4j*) $SPARK_HOME/python/lib/py4j-src.zip
ENV PYTHONPATH $SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-src.zip:$PYTHONPATH

# almond for scala and spark in jupyter
# compatibility matrix with scala version
ENV ALMOND_VERSION=0.6.0 
# install proper scala/spark kernel 
RUN curl -Lo coursier https://git.io/coursier-cli && \
    chmod +x coursier && \
    ./coursier bootstrap \
        -r jitpack \
        -i user -I user:sh.almond:scala-kernel-api_$SCALA_VERSION:$ALMOND_VERSION \
        sh.almond:scala-kernel_$SCALA_VERSION:$ALMOND_VERSION \
        -o almond
# in script we may want to use existing spark directory to not download all this shit
# https://github.com/almond-sh/almond/issues/227
# last line with ALMOND wont be needed when we move to almond >= 0.7.0
COPY scripts/almond-install.sh almond-install.sh
RUN chmod +x almond-install.sh && \
    ./almond-install.sh && \ 
    rm -rf almond coursier almond-install.sh

# ==================================================================
# Airflow
# ------------------------------------------------------------------
RUN eval $APT_INSTALL \
        # mysql
        libmysqlclient-dev \
        # kerberos
        libkrb5-dev \
        # crypto
        libssl-dev \
        # hive
        libsasl2-dev && \
        # run pymssql separatly due to https://github.com/pymssql/pymssql/issues/668
    $PIP_INSTALL "pymssql<3.0" && \
    $PIP_INSTALL \
        apache-airflow[all]
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
# Polynote
# ------------------------------------------------------------------
ENV POLYNOTE_VERSION=0.2.11
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
COPY scripts/add-user.sh add-user.sh
RUN chmod +x add-user.sh && ./add-user.sh $DEFAULT_USER

# make spark dir owned by that user
RUN chown -R $DEFAULT_USER:$DEFAULT_USER $SPARK_HOME

# make jupyter notebook token equal to username by default
ENV JUPYTER_LAB_TOKEN=$DEFAULT_USER

# Add Tini and entrypoint
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
COPY scripts/docker-entrypoint.sh .
RUN chmod +x /tini && chmod +x docker-entrypoint.sh
ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]

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
