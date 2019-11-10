#!/bin/bash

# need to override hadoop to support http!
./almond --install --global \
--predef-code " 
  import \$ivy.\`org.apache.spark::spark-sql:${SPARK_VERSION}\`
  import \$ivy.\`sh.almond::almond-spark:${ALMOND_VERSION}\`
  " 
