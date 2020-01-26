# VERSION 1.10.6
# AUTHOR: Matthieu "Puckel_" Roisil
# FORK: Asaf Levy
# FORK_SOURCE: https://github.com/asaf400/docker-airflow
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim-buster
LABEL maintainer="Asaf Levy"

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.6
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

ARG SPLIT1=default

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
    ' \
    && apt-get update -yqq \
    && apt-get install curl gnupg2 -yqq --no-install-recommends\
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
    git \
    cmake \
    rsync \
    nodejs \
    netcat \
    locales \
    apt-utils \
    pkg-config \
    $buildDeps \
    freetds-bin \
    dh-autoreconf \
    build-essential \
    librabbitmq-dev \
    default-libmysqlclient-dev \
    python-pip \
    python-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && cat /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && dpkg-reconfigure locales \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install flask-oauthlib \
    && curl -Ls https://github.com/alanxz/rabbitmq-c/archive/v0.9.0.tar.gz | tar -zxv \
    && cd rabbitmq-c-0.9.0 && mkdir build && cd build && cmake .. && cmake --build . --config Release --target install && cd ../.. && rm -rf rabbitmq-c-0.9.0 \
    && pip install git+git://github.com/asaf400/airflow@allow_fab_environment_variables#egg=apache-airflow[statsd,google_auth,crypto,celery,postgres,jdbc,mysql,ssh,slack,s3,redis,rabbitmq,password,ldap,hive,hdfs,emr,async${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}] \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && cd /usr/local/lib/python3.7/site-packages \
    && airflow/www_rbac/compile_assets.sh \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base

ARG SPLIT2=unknown

#RUN pip2 install wheel setuptools && pip2 install git+git://github.com/asaf400/airflow@allow_fab_environment_variables#egg=apache-airflow[crypto,celery,mysql,redis]
RUN pip2 install virtualenv
COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg
# https://github.com/teamclairvoyant/airflow-scheduler-failover-controller/blob/master/README.md
# Adds airflow-scheduler-failover-controller by downloading tagged version, init populated default configs in /usr/local/airflow/airflow.cfg, and then sed fixes them
RUN pip install git+git://github.com/asaf400/airflow-scheduler-failover-controller@dev-v1.0.5-envfix2 && scheduler_failover_controller init && sed -i -e 's/enable_proxy_fix = False/enable_proxy_fix = True/g' /usr/local/airflow/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}
ENV TERM xterm

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]

# set default arg for entrypoint
CMD ["webserver"]
