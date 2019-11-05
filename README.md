[![Build Status](https://travis-ci.com/konradmalik/deenv.svg?branch=master)](https://travis-ci.com/konradmalik/deenv)
# DEEnv

Container for data engineering, data flows/pipelines etc. All-in-one toolbox for a data engineer.

For contents, included libraries etc. see the first couple of lines of the Dockerfile.

Build container using "make":

```bash
$ make build
```

Then run either bash shell or jupyter server using provided shell scripts.

Run scripts are currently set up to autodelete after exit so all data that is not in the "data" folder will be lost!
