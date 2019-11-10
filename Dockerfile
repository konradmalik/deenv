# ==================================================================
# module list
# ------------------------------------------------------------------
# python                    3.7    (apt)
# jupyter hub+lab           latest (pip)
# airflow                   latest (pip)
# dagster                   latest (pip)
# MLflow		            latest (pip)
# Spark+py+koalas+toree     2.4.4  (apt+pip)
# polynote                  latest (github tar)
# ==================================================================

FROM ubuntu:18.04
ENV LANG C.UTF-8
ENV APT_INSTALL="apt-get install -y --no-install-recommends --fix-missing"
ENV PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ENV GIT_CLONE="git clone --depth 10"

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update

# ==================================================================
# tools
# ------------------------------------------------------------------
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
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
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common && \
	add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
	$APT_INSTALL \
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
# Airflow
# ------------------------------------------------------------------
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        # mysql
        libmysqlclient-dev \
        # kerberos
        libkrb5-dev \
        # crypto
        libssl-dev \
        # hive
        libsasl2-dev && \
    $PIP_INSTALL \
        apache-airflow[all]
ENV AIRFLOW_HOME=~/airflow

# ==================================================================
# Dagster
# ------------------------------------------------------------------
RUN $PIP_INSTALL \
        dagster dagit

# ==================================================================
# jupyter hub
# ------------------------------------------------------------------
RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
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
ENV PATH=/miniconda/bin:${PATH}
RUN conda init && \
        conda config --set auto_activate_base false

# ==================================================================
# Spark (with pyspark and koalas)
# ------------------------------------------------------------------
ENV SPARK_VERSION=2.4.4
ENV SPARK_ARCHIVE=https://www-eu.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
ENV JAVA_VERSION=8
# for now this is a must, spark cassandra connector does not work with 2.12
ENV SCALA_VERSION=2.11.12
# compatibility matrix with scala version
ENV ALMOND_VERSION=0.6.0 
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-$SPARK_VERSION-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/sbin

RUN DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        openjdk-$JAVA_VERSION-jdk \
		scala \
        && \
    $PIP_INSTALL \
		pyspark==$SPARK_VERSION \
		findspark \
        koalas
ENV JAVA_HOME /usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64

#Also, make sure your PYTHONPATH can find the PySpark and Py4J under $SPARK_HOME/python/lib:
# not sure if needed but polynote installation guide specifies this
RUN cp $(ls $SPARK_HOME/python/lib/py4j*) $SPARK_HOME/python/lib/py4j-src.zip
ENV PYTHONPATH $SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-src.zip:$PYTHONPATH

# install proper scala/spark kernel 
RUN curl -Lo coursier https://git.io/coursier-cli && \
    chmod +x coursier && \
    ./coursier bootstrap \
        -r jitpack \
        -i user -I user:sh.almond:scala-kernel-api_$SCALA_VERSION:$ALMOND_VERSION \
        sh.almond:scala-kernel_$SCALA_VERSION:$ALMOND_VERSION \
        -o almond
# use existing spark directory to not download all this shit
# https://github.com/almond-sh/almond/issues/227
# last line with ALMOND wont be needed when we move to almond >= 0.7.0
RUN ./almond --install --global --predef-code "
    val jars = java.nio.file.Files.list(java.nio.file.Paths.get(\"${SPARK_HOME}/jars\")).toArray.map(_.toString)
        .map { fname =>
            val path = java.nio.file.FileSystems.getDefault().getPath(fname)
            ammonite.ops.Path(path)
        }
    interp.load.cp(jars)
    import $ivy.`sh.almond::almond-spark:${ALMOND_VERSION}`" && \ 
    rm -rf almond coursier

# ==================================================================
# Polynote
# ------------------------------------------------------------------
ENV POLYNOTE_VERSION=0.2.11
ENV POLYNOTE_ARCHIVE=https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/polynote-dist.tar.gz
RUN curl -sL $POLYNOTE_ARCHIVE | tar -zx -C /usr/local/
ENV POLYNOTE_HOME /usr/local/polynote

RUN $PIP_INSTALL \ 
    jep jedi pyspark==$SPARK_VERSION virtualenv

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# add default user
RUN groupadd -r deenv && \
    useradd -r -p $(openssl passwd -1 deenv) -g deenv -G sudo deenv
RUN mkdir -p /home/deenv && \
    chown -R deenv:deenv /home/deenv
    
# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# run as non-root
USER deenv

# make sure data folder has proper permissions
RUN mkdir -p /home/deenv/data
VOLUME /home/deenv/data
WORKDIR /home/deenv

# airflow
EXPOSE 8080
# dagster
EXPOSE 3000
# jupyterlab
EXPOSE 8888
# jupyterhub
EXPOSE 8000
# spark ui
EXPOSE 4040
#polynote
EXPOSE 8192

CMD bash
