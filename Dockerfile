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
      && apt-get install -y libstdc++6 language-pack-en
RUN update-locale LANG=en_US.utf8

# Perhaps make normal user? UID=1000, safe as default user
RUN addgroup --system mitmproxy \
    && adduser --system --ingroup mitmproxy mitmproxy

RUN export DEBIAN_FRONTEND=teletype \
    && apt-get install -y --no-install-recommends \
    tcpdump curl bzip2 wget ca-certificates libfontconfig
# Perhaps setup tcpdump so it can be run bu normal user?
# https://askubuntu.com/a/632189


RUN mkdir /tmp/phantomjs \
  && F="$(wget --no-verbose -O - http://phantomjs.org/download.html \
  | grep -A 100 'SHA-256 Checksums' | grep linux-x86_64 | awk '{print $2}')" \
  && wget --no-verbose -O - "https://bitbucket.org/ariya/phantomjs/downloads/$F" \
  | tar xj --strip-components=1 -C /tmp/phantomjs \
  && mv /tmp/phantomjs/bin/phantomjs /usr/local/bin \
  && cp -r /tmp/phantomjs/examples/ /home/mitmproxy/phantomjs-examples \
  && rm -r /tmp/phantomjs

#COPY requirements.txt /tmp/requirements.txt
RUN echo "git+https://github.com/mitmproxy/mitmproxy.git@master" \
      > /tmp/requirements.txt


# add our user first to make sure the ID get assigned consistently,
# regardless of whatever dependencies get added
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
RUN export DEBIAN_FRONTEND=teletype && apt-get install -y iproute2
RUN apt-get clean -y

VOLUME /home/mitmproxy/data
VOLUME /home/mitmproxy/bin

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#EXPOSE 8080 8081
WORKDIR /home/mitmproxy
#ENTRYPOINT ["/home/mitmproxy/bin/entrypoint.sh"]
CMD ["/home/mitmproxy/bin/entrypoint.sh", "hild1.no"]
