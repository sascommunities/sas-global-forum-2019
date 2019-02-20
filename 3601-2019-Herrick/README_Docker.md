centos-ds-containers
==================

A repository of data science containers that use a CentOS base. This works well for replicating enterprise environments that rely on Red Hat Enterprise Linux.

Currently we have the following containers:
1. __base__: This container is the base for all other containers in this repository. It builds from a CentOS 7 image hosted on Docker Hub, and we then install Python 3.6 and SQLite, as well as other necessary yum packages. The intent is that this base image reflect a standard, base Python 3 development configuration. **BUILD THIS CONTAINER FIRST**.

2. __jupyter__:  This container adds the standard data science python packages, Jupyter Notebook, and some notebook extensions. When running, this container exposes port 8888 and we can access Jupyter Notebook hosted by the container on `http://localhost:8888`. There is currently no token security enabled on this notebook instance, since it is intended to run locally only at this time. If you ever expose it outside your local system, make sure to turn the token authorization on again.


Building the containers:
------------------------

There are two simple shell scripts provided to build the two containers.

1. `build_base.sh`: This builds the image `centos-ds/ds-base` and should be run first. After invoking the build, go get coffee or dinner. It takes a while.
2. `build_jupyter.sh`: This builds the image `centos-ds/jupyter`. It builds much faster than the base image.
3. `build_pyspark.sh`: This builds the `centos-ds/pyspark` image. This adds a Spark instance (and `pyspark`) to the Jupyter notebook.

When complete, verify the success of the image builds by typing `docker images` and look for the images you built.

Running the container:
------------------------------
* To run any container based on our Jupyter image, we need to include a mapping to a local folder that contains our notebooks. Anything we add to this folder will be visible inside the container, so we can add notebooks or data files if needed.
* Start the container by typing: `./run_container.sh <your-fully-qualified-path-to-your-notebooks> <container-name>`
    * Don't include `centos-ds` in the container name. In other words, at this time you'd use either `jupyter` or `pyspark`.
* It should echo back a long token, but if the notebook doesn't successfully start, the container silently exits. Thus test for success by typing: `docker container ls`
* If the container is successfully running, open a browser tab and go to: `http://localhost:8888`. You should see the Jupyter notebook home page, with all of your local notebooks showing up in the list.

From this point you can develop as you desire.
