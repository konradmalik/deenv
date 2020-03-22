#!/bin/bash

# all commands that cannot be run in dockerfile, but need to be run before this container starts
export SPARK_DIST_CLASSPATH=$(hadoop classpath)

# make sure home ownership is properly set
for dir in /home/*/; do
    # strip trailing slash
    homedir="${dir%/}"
    # strip all chars up to and including the last slash
    username="${homedir##*/}"

    case $username in
    *.*) continue ;; # skip name with a dot in it
    esac

    chown -R "$username" "$dir"
done

exec "$@"
