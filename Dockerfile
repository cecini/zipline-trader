#
# Dockerfile for an image with the currently checked out version of zipline installed. To build:
#
#    docker build -t quantopian/zipline .
#
# To run the container:
#
#    docker run -v /path/to/your/notebooks:/projects -v ~/.zipline:/root/.zipline -p 8888:8888/tcp --name zipline -it quantopian/zipline
#
# To access Jupyter when running docker locally (you may need to add NAT rules):
#
#    https://127.0.0.1
#
# default password is jupyter.  to provide another, see:
#    http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#preparing-a-hashed-password
#
# once generated, you can pass the new value via `docker run --env` the first time
# you start the container.
#
# You can also run an algo using the docker exec command.  For example:
#
#    docker exec -it zipline zipline run -f /projects/my_algo.py --start 2015-1-1 --end 2016-1-1 -o /projects/result.pickle
#
FROM python:3.6.10

#
# set up environment
#
ENV TINI_VERSION v0.10.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

ENV PROJECT_DIR=/projects \
    NOTEBOOK_PORT=8888 \
    PW_HASH="u'sha1:31cb67870a35:1a2321318481f00b0efdf3d1f71af523d3ffc505'" \
    CONFIG_PATH=/root/.jupyter/jupyter_notebook_config.py

#
# install TA-Lib and other prerequisites
#

RUN mkdir ${PROJECT_DIR} \
    && apt-get -y update \
    && apt-get -y install libfreetype6-dev libpng-dev libopenblas-dev liblapack-dev gfortran libhdf5-dev \
    && curl -L https://downloads.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz | tar xvz \
    && curl -O https://codeload.github.com/JaysonAlbert/tdx/zip/master -O && unzip master

#
# build and install zipline from source.  install TA-Lib after to ensure
# numpy is available.
#

WORKDIR /ta-lib


# should requirement -c etc/requirements_locked.txt
RUN pip install 'numpy==1.14.1' \
  && pip install 'scipy==1.0.0' \
  && pip install 'pandas==0.22.0' \
  && pip install 'pandas_datareader==0.4.0' \
  && pip install 'dask==0.17.1' \
  && pip install 'statsmodels==0.9.0' \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && pip install TA-Lib \
  && pip install matplotlib \
  && pip install jupyter

#WORKDIR /tdx-master
#RUN { rm setup.py && awk '{gsub("0.19", "=0.22.0", $0); print}' > setup.py; } < setup.py && pip install -e .
#
# This is then only file we need from source to remain in the
# image after build and install.
#

ADD ./etc/docker_cmd.sh /

#
# make port available. /zipline is made a volume
# for developer testing.
#
EXPOSE ${NOTEBOOK_PORT}

#
# build and install the zipline package into the image
#
RUN mkdir -p /ziplinedeps/etc
COPY  ./etc/ /ziplinedeps/etc/
WORKDIR /ziplinedeps

RUN pip3 install setuptools==45 && pip install pip-tools 

RUN pip install -e  git://github.com/cecini/tdx.git@192935e39862992953a05d80b8e7112c0e9128fa#egg=tdx-wrapper 

RUN pip-compile --no-emit-index-url --output-file=etc/requirements_locked.txt etc/requirements.in etc/requirements_blaze.in etc/requirements_build.in etc/requirements_dev.in etc/requirements_docs.in etc/requirements_talib.in  etc/requirements_tdx.in -P numpy==1.14.1 -P scipy==1.0.0 -P pandas==0.22.0 -P pandas_datareader==0.4.0 -P dask==0.17.1 -P statsmodels==0.9.0  


ADD . /zipline

WORKDIR /zipline

RUN cp /ziplinedeps/etc/requirements_locked.txt /zipline/etc && pip install -e . --default-timeout=200


#
# start the jupyter server
#

WORKDIR ${PROJECT_DIR}
CMD /docker_cmd.sh
