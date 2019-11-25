#!/bin/bash

# all commands that cannot be run in dockerfile, but need to be run before this container starts
export SPARK_DIST_CLASSPATH=$(hadoop classpath)

exec "$@"
