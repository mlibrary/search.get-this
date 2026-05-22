################################################################################
# Node Assets
################################################################################
FROM node:25.9.0@sha256:c69f4e0640e5b065f2694579793e4309f1e0e49868b0f2fea29c44d9c0dc2caf AS assets

# Use non-root "app" user in directory /app
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} -o app
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash app

USER app

WORKDIR /app

# Install packages
COPY package.json package-lock.json ./
RUN npm ci

COPY ./css ./css
COPY ./js ./js

RUN npm run build
################################################################################
# DEVELOPMENT                                           								       # 
################################################################################
FROM ruby:4.0 AS development

ARG UID=1000
ARG GID=1000


RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  ca-certificates \
  gnupg \
  apt-transport-https \
  nodejs \
  vim-tiny

RUN groupadd -g ${GID} -o app
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash app

RUN mkdir -p /gems && chown ${UID}:${GID} /gems
ENV GEM_HOME=/gems
USER app
RUN gem install bundler


#USER root

ENV BUNDLE_PATH=/app/vendor/bundle

WORKDIR /app

################################################################################
# PRODUCTION                                                                   #
################################################################################
FROM development AS production

COPY --chown=${UID}:${GID} . /app
ENV BUNDLE_WITHOUT=development:test

RUN bundle install

COPY --chown=${UID}:{GID} --from=assets /app/public/bundles /app/public/bundles

CMD ["bundle", "exec", "rackup", "-p", "4567", "--host", "0.0.0.0"]
