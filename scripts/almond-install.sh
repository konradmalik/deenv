#!/bin/bash

# need to override hadoop to support http!
./almond --install --global \
--predef-code " 
  val jars = java.nio.file.Files.list(java.nio.file.Paths.get(\"${SPARK_HOME}/jars\")).toArray.map(_.toString)
    .map { fname =>
        val path = java.nio.file.FileSystems.getDefault().getPath(fname)
        ammonite.ops.Path(path)
    }
  interp.load.cp(jars)
  import \$ivy.\`sh.almond::almond-spark:${ALMOND_VERSION}\`
  " 
