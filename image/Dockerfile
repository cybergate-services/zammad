FROM ruby:2.3.1-slim
MAINTAINER Bertrand Gouny <bertrand.gouny@osixia.net>

ENV ZAMMAD_DIR /home/zammad
ENV ZAMMAD_USER zammad
ENV RAILS_ENV production
ENV RAILS_SERVER puma

ARG GIT_URL=https://github.com/zammad/zammad.git
ARG GIT_BRANCH=stable
ARG GOSU_VERSION=1.10

ARG LIGHT_BASEIMAGE_VERSION=jessie-v1.0.1
ARG WEB_BASEIMAGE_VERSION=1.0.0

# MariaDB version
ARG MARIADB_MAJOR=10.1

# Install light-baseimage and web-baseimage
RUN apt update \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
      ca-certificates \
      curl  \
    && curl -L -o light-baseimage.tar.gz https://github.com/osixia/docker-light-baseimage/archive/${LIGHT_BASEIMAGE_VERSION}.tar.gz \
    && mkdir -p container \
    && tar -xf light-baseimage.tar.gz -C container --strip-components 2 docker-light-baseimage-${LIGHT_BASEIMAGE_VERSION}/image \
    && cd container \
    && ./build.sh \
    && cd - \
    && rm -rf light-baseimage light-baseimage.tar.gz \
    && curl -L -o web-baseimage.tar.gz https://github.com/osixia/docker-web-baseimage/archive/v${WEB_BASEIMAGE_VERSION}.tar.gz \
    && tar -xf web-baseimage.tar.gz -C container/service-available --strip-components 3 docker-web-baseimage-${WEB_BASEIMAGE_VERSION}/image/service-available \
    && rm -rf web-baseimage.tar.gz

ENTRYPOINT ["/container/tool/run"]

# Add MariaDB repository
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8 \
    && echo "deb http://ftp.igh.cnrs.fr/pub/mariadb/repo/$MARIADB_MAJOR/debian jessie main" > /etc/apt/sources.list.d/mariadb.list \
    && { \
		     echo 'Package: *'; \
		     echo 'Pin: release o=MariaDB'; \
		     echo 'Pin-Priority: 999'; \
	     } > /etc/apt/preferences.d/mariadb

# Install dependencies, GOSU & zammad
RUN BUILD_DEPENDENCIES="git build-essential libffi-dev libpq5 libpq-dev" \
    GOSU_DEPENDENCIES="ca-certificates wget" \
    set -ex \
	  && apt-get -y update \
    && /container/tool/add-multiple-process-stack \
    && /container/tool/add-service-available :nginx :ssl-tools \
    && apt-get install -y --force-yes --no-install-recommends ${BUILD_DEPENDENCIES} ${GOSU_DEPENDENCIES} mariadb-client-$MARIADB_MAJOR libmariadbclient-dev && rm -rf /var/lib/apt/lists/* \
	  && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	  && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	  && export GNUPGHOME="$(mktemp -d)" \
	  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	  && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
	  && chmod +x /usr/local/bin/gosu \
	  && gosu nobody true \
    && useradd -M -d ${ZAMMAD_DIR} -s /bin/bash ${ZAMMAD_USER} \
    && cd $(dirname ${ZAMMAD_DIR}) \
    && git clone --depth 1 -b "${GIT_BRANCH}" "${GIT_URL}" \
    && cd ${ZAMMAD_DIR} \
    && bundle install --without test development postgres \
    && contrib/packager.io/fetch_locales.rb \
    && sed -e 's#.*adapter: postgresql#  adapter: nulldb#g' < config/database.yml.pkgr > config/database.yml \
    && bundle exec rake assets:precompile \
    && sed -e 's#.*adapter: postgresql#  adapter: mysql2#g' -e 's#.*database:.*#  database: {{ ZAMMAD_DB_NAME }}#g'  -e 's#.*username:.*#  username: {{ ZAMMAD_DB_USER }}#g' -e 's#.*password:.*#  password: {{ ZAMMAD_DB_PASSWORD }}\n  host: {{ ZAMMAD_DB_HOST }}\n#g' < config/database.yml.pkgr > config/database.yml \
    && rm -r tmp/cache \
    && chown -R ${ZAMMAD_USER}:${ZAMMAD_USER} ${ZAMMAD_DIR}

# Add service directory to /container/service
ADD service /container/service

# Use baseimage install-service script
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/install-service
RUN /container/tool/install-service

# Add default env variables
ADD environment /container/environment/99-default

# Expose default https port
EXPOSE 443