[![Build Status](https://travis-ci.com/konradmalik/deenv.svg?branch=master)](https://travis-ci.com/konradmalik/deenv)
# DEEnv

Container for data engineering, data flows/pipelines etc. All-in-one toolbox for a data engineer.

For contents, included libraries etc. see the first couple of lines of the Dockerfile.

## Random notes

* scala kernel for jupyter is provided by almond. In prefdef it automatically imports local spark jars and downloads (if not present) almond libs, so only thing you need to do is to create spark session. Refer to almond's "usage-spark.md" document.

## How to build:
Image is available on dockerhub (konradmalik/deenv).

If you want to build locally, use "make":

```bash
$ make build
```

Then run either bash shell or jupyter server using provided shell scripts.

Run scripts are currently set up to autodelete after exit so all data that is not in the "data" folder will be lost!
