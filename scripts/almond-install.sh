#!/bin/bash

# need to override hadoop to support http!
# we will filter out 'curator' jars as they are then reimported with new hadoop
# also disable logs for 'org' to not pollute all notebook
./almond --install --global \
--predef-code " 
  val jars = java.nio.file.Files.list(java.nio.file.Paths.get(\"${SPARK_HOME}/jars\")).toArray.map(_.toString)
    .filter(_.contains(\"curator\")
    .map { fname =>
        val path = java.nio.file.FileSystems.getDefault().getPath(fname)
        ammonite.ops.Path(path)
    }
  interp.load.cp(jars)
  import \$ivy.\`org.apache.hadoop:hadoop-client:${HADOOP_VERSION}\`
  import \$ivy.\`sh.almond::almond-spark:${ALMOND_VERSION}\`
  import org.apache.log4j.{Level, Logger}
  Logger.getLogger(\"org\").setLevel(Level.OFF)
  " 
