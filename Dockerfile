FROM ubuntu:artful

MAINTAINER Anders Einar Hilden "hildenae@gmail.com"

# Set local apt mirrors
RUN sed -i -e 's#\(http://archive.ubuntu.com/ubuntu/\|http://security.ubuntu.com/ubuntu/\)#mirror://mirrors.ubuntu.com/mirrors.txt#g' /etc/apt/sources.list

# Set timezone
RUN ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime

#
RUN export DEBIAN_FRONTEND=teletype \
      && apt-get update -y \
      && apt-get upgrade -y \
      && apt-get install -y language-pack-en

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
RUN update-locale LANG=en_US.utf8

ARG USER_NAME=mitm
ARG USER_ID=1000

# Add a non-root user to run browser as
RUN useradd \
      --system \
      --uid $USER_ID \
      --user-group \
      --groups audio,video \
      --create-home \
      $USER_NAME

# tcpdump and some useful tools
RUN export DEBIAN_FRONTEND=teletype \
    && apt-get install -y --no-install-recommends \
    tcpdump iproute2 curl wget bzip2 ca-certificates

# Install deps + add Chrome Stable + purge all the things
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    gnupg \
    --no-install-recommends \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y \
    google-chrome-stable \
    --no-install-recommends \
    && apt-get purge --auto-remove -y gnupg


# Start install of mitmproxy
RUN echo "git+https://github.com/mitmproxy/mitmproxy.git@master" \
      > /tmp/requirements.txt

# E: Unable to locate package su-exec > ignore
# E: Unable to locate package libffi > libffi6
# E: Unable to locate package openssl-dev > libssl-dev
# libstdc++ => libstdc++6
RUN export DEBIAN_FRONTEND=teletype && apt-get install -y \
        git \
        g++ \
        libffi6 \
        libffi-dev \
        openssl \
        libssl-dev \
        python3 \
        python3-dev \
        python3-pip \
    && LDFLAGS=-L/lib pip3 install -r /tmp/requirements.txt \
    && apt-get purge -y \
        git \
        g++ \
        libffi-dev \
        libssl-dev \
        python3-dev \
    && rm /tmp/requirements.txt \
    && rm -rf ~/.cache/pip

RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb
RUN dpkg -i dumb-init_*.deb

RUN apt-get clean -y

VOLUME /home/$USER_NAME/data
VOLUME /home/$USER_NAME/bin

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#EXPOSE 8080 8081
WORKDIR /home/$USER_NAME

#ENTRYPOINT ["/home/mitmproxy/bin/entrypoint.sh"]
# ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/home/$USER_NAME/bin/entrypoint.sh"]
