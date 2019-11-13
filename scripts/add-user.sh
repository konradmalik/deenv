#!/bin/bash

USER=$1
echo "creating user $USER"
groupadd -r $USER && \
    useradd -r -p $(openssl passwd -1 $USER) -g $USER -G sudo $USER && \
    mkdir -p /home/$USER && \
    chown -R $USER:$USER /home/$USER && \
    chsh -s /bin/bash $USER
