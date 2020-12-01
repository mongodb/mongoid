FROM debian:10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get -y install git ruby-bundler make gcc ruby-dev \
    libxml2-dev zlib1g-dev

WORKDIR /app

COPY . .
