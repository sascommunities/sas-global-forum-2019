#!/usr/bin/env bash

FROM centos-ds/base

# Export env settings
ENV TERM=xterm
ENV LANG en_US.UTF-8

ADD /requirements/ /tmp/requirements

RUN pip3.7 install --upgrade pip
RUN pip3.7 install -r /tmp/requirements/requirements.txt
RUN pip3.7 install https://github.com/sassoftware/python-swat/releases/download/v1.5.0/python-swat-1.5.0-linux64.tar.gz

RUN useradd --create-home --home-dir /home/ds --shell /bin/bash ds
RUN usermod -aG wheel ds

ADD run_ipython.sh /home/ds
RUN chmod +x /home/ds/run_ipython.sh
RUN chown ds /home/ds/run_ipython.sh
RUN chgrp ds /home/ds/run_ipython.sh

ADD /security/authinfo /home/ds/.authinfo
ADD /security/cascert.pem /home/ds/cascert.pem
RUN chown ds /home/ds/.authinfo
RUN chown ds /home/ds/cascert.pem
RUN chgrp ds /home/ds/.authinfo
RUN chgrp ds /home/ds/cascert.pem

ADD /security/vault-deployTarget-ca.crt /etc/pki/ca-trust/source/anchors/
ADD /security/httpproxy-deployTarget-ca.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust extract

# add the python module we'll be running.
ADD /modules/Analysis.AnalyticsModule /home/ds/code/Analysis.AnalyticsModule
RUN pip3.7 install -e '/home/ds/code/Analysis.AnalyticsModule'

RUN jupyter-nbextension install rise --py --sys-prefix
RUN jupyter-nbextension enable rise --py --sys-prefix

EXPOSE 8888
RUN echo "ds ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d
USER ds
RUN mkdir -p /home/ds/notebooks
RUN mkdir -p /home/ds/datasets
RUN mkdir -p /home/ds/logs
RUN mkdir -p /home/ds/custom
RUN mkdir -p /home/ds/.jupyter
RUN echo "c.NotebookApp.token = u''" >> /home/ds/.jupyter/jupyter_notebook_config.py
ENV HOME=/home/ds
ENV SHELL=/bin/bash
ENV USER=ds

VOLUME /home/ds/notebooks
WORKDIR /home/ds/notebooks

CMD ["/home/ds/run_ipython.sh"]
