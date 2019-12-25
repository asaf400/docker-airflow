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

RUN set -ex \
    && buildDeps=' \
    freetds-dev \
    libkrb5-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
    curl \
    cmake \
    rsync \
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
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1

# RUN curl -Ls https://github.com/alanxz/rabbitmq-c/archive/v0.8.0.tar.gz | tar -zxv \
#     && cd rabbitmq-c-0.8.0 && autoreconf -i && ./configure && make && make install && cd .. && rm -rf rabbitmq-c-0.8.0

RUN curl -Ls https://github.com/alanxz/rabbitmq-c/archive/v0.9.0.tar.gz | tar -zxv \
    && cd rabbitmq-c-0.9.0 && mkdir build && cd build && cmake .. && cmake --build . --config Release --target install && cd ../.. && rm -rf rabbitmq-c-0.9.0



RUN pip install apache-airflow[crypto,celery,postgres,jdbc,mysql,ssh,slack,s3,redis,rabbitmq,password,ldap,hive,hdfs,async${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
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
CMD ["webserver"] # set default arg for entrypoint
