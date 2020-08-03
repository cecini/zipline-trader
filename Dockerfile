# syntax = docker/dockerfile:experimental

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
FROM python:3.6.10 AS zipline-base

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

WORKDIR /

FROM zipline-base AS zipline-maindep
#
# install TA-Lib and other prerequisites
#

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt  mkdir ${PROJECT_DIR} \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends libfreetype6-dev libpng-dev libopenblas-dev liblapack-dev gfortran libhdf5-dev \
    && curl -L https://downloads.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz | tar xvz 

#
# build and install zipline from source.  install TA-Lib after to ensure
# numpy is available.
#


WORKDIR /ta-lib


# should requirement -c etc/requirements_locked.txt
# matplotlib > 3.3.0 depend numpy> 1.15.1
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip cache list
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip install 'numpy==1.14.1' \
  && pip install 'scipy==1.0.0' \
  && pip install 'pandas==0.22.0' \
  && pip install 'pandas_datareader==0.4.0' \
  && pip install 'dask==0.17.1' \
  && pip install 'statsmodels==0.9.0' \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && pip install TA-Lib \
  && pip install 'matplotlib==3.2.2' \
  && pip install jupyter

#WORKDIR /tdx-master
#RUN { rm setup.py && awk '{gsub("0.19", "=0.22.0", $0); print}' > setup.py; } < setup.py && pip install -e .
#
# This is then only file we need from source to remain in the
# image after build and install.
#




FROM zipline-maindep AS zipline-compile
#
# build and install the zipline package into the image
#
RUN mkdir -p /ziplinedeps/etc
COPY  ./etc/ /ziplinedeps/etc/
WORKDIR /ziplinedeps

run --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip cache list
run --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip3 install setuptools==45 && pip install pip-tools 
# or pip install -r etc/requirments_tdx.in -c etc/requirements_locked.txt after the pip-compile
#RUN pip install -e  git://github.com/cecini/tdx.git@192935e39862992953a05d80b8e7112c0e9128fa#egg=tdx-wrapper 
#-e git://github.com/cecini/cn_stock_holidays.git@master#egg=cn-stock-holidays

RUN --mount=type=cache,target=/root/.cache/pip-compile pip-compile --no-emit-index-url --output-file=etc/requirements_locked.txt etc/requirements.in etc/requirements_blaze.in etc/requirements_build.in etc/requirements_dev.in etc/requirements_docs.in etc/requirements_talib.in  etc/requirements_tdx.in -P numpy==1.14.1 -P scipy==1.0.0 -P pandas==0.22.0 -P pandas_datareader==0.4.0 -P dask==0.17.1 -P statsmodels==0.9.0  


ADD . /zipline

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip cp /ziplinedeps/etc/requirements_locked.txt /zipline/etc && pip install -r etc/requirements_tdx.in 
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip install -e git://github.com/cython/cython.git@3.0a6#egg=Cython

WORKDIR /zipline
#RUN git clean -xfd
ENV PYTHONPATH=/ziplinedeps:/zipline 
#ENV PYTHONPATH=/zipline
#RUN pip install -r etc/requirments_tdx.in -c etc/requirements_locked.txt 
#RUN pip install -r etc/requirments_tdx.in 
#RUN cp /ziplinedeps/etc/requirements_locked.txt /zipline/etc && pip install -r etc/requirements_tdx.in && cd /ta-lib && python /zipline/setup.py -v build_ext -f --inplace &&  python /zipline/setup.py develop
#RUN cp /ziplinedeps/etc/requirements_locked.txt /zipline/etc && pip install -r etc/requirements_tdx.in 

RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip pip install -r requirs
RUN --mount=type=cache,id=custom-pip,target=/root/.cache/pip python /zipline/setup.py -v build_ext -b /ziplinedeps
#RUN cd /usr/local/lib/python3.6/site-packages 
RUN --mount=type=cache,id=custom-pip1,target=/root/.cache/pip1 python /zipline/setup.py develop 
#RUN --mount=type=bind,id=custom-pip1,target=/root/.cache/pip1 python /zipline/setup.py develop 
#RUN python setup.py develop --egg-path ./../ziplinedeps
#RUN python setup.py develop --install-dir /ziplinedeps
#RUN pip install -e .


ADD ./etc/docker_cmd.sh /

#
# make port available. /zipline is made a volume
# for developer testing.
#
EXPOSE ${NOTEBOOK_PORT}
#
# start the jupyter server
#

WORKDIR ${PROJECT_DIR}
CMD /docker_cmd.sh
