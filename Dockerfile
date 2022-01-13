FROM ubuntu:20.04 as builder

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

ENV SC_VERSION 3.12.0
ENV SC_MAJORVERSION 3.12
ENV SC_PLUGIN_VERSION 3.11.1

RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get install -yq --no-install-recommends \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    git \
    jackd \
    libasound2-dev \
    libavahi-client-dev \
    libcwiid-dev \
    libfftw3-dev \
    libicu-dev \
    libjack-dev \
    libjack0 \
    libreadline6-dev \
    libsndfile1-dev \
    libudev-dev \
    libxt-dev \
    pkg-config \
    unzip \
    wget \
    xvfb \
    libncurses5-dev \
  \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $HOME/src \
  && cd $HOME/src \
  && wget -q https://github.com/supercollider/supercollider/releases/download/Version-$SC_VERSION/SuperCollider-$SC_VERSION-Source.tar.bz2 -O sc.tar.bz2 \
  && tar xvf sc.tar.bz2 \
  && cd SuperCollider* \
  && mkdir -p build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE="Release" -DNATIVE=ON -DBUILD_TESTING=OFF -DSUPERNOVA=OFF -DSC_WII=OFF -DSC_QT=OFF -DSC_ED=OFF -DSC_EL=OFF -DSC_VIM=OFF .. \
  && make -j1 \
  && make install \
  && ldconfig
  #&& ls -R /usr/local/share/SuperCollider \
  #&& rm -f /usr/local/share/SuperCollider/SCClassLibrary/deprecated/$SC_MAJORVERSION/deprecated-$SC_MAJORVERSION.sc \

RUN cd $HOME/src \
  && wget -q https://github.com/supercollider/sc3-plugins/releases/download/Version-$SC_PLUGIN_VERSION/sc3-plugins-$SC_PLUGIN_VERSION-Source.tar.bz2 -O scplugins.tar.bz2 \
  && tar xvf scplugins.tar.bz2 \
  && cd sc3-plugins-$SC_PLUGIN_VERSION-Source \
  && mkdir -p build \
  && cd build \
  && cmake -DSC_PATH=$HOME/src/SuperCollider-$SC_VERSION-Source -DCMAKE_BUILD_TYPE=Release -DHOA_UGENS=OFF -DSUPERNOVA=OFF -DAY=OFF .. \
  && cmake --build . --config Release --target install \
  && rm -rf $HOME/src

COPY install.scd /install.scd
COPY asoundrc /root/.asoundrc
COPY startup.scd /root/.config/SuperCollider/

# Install forego
ENV PATH="${PATH}:/usr/local/go/bin"
RUN wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | tar -xz -C /usr/local && \
	go version && \
	go get -u github.com/ddollar/forego

RUN xvfb-run -a sclang -D /install.scd && \
    echo "ok"

#OSCGROUPS
COPY oscGBuild $HOME/

WORKDIR "$HOME/oscgroups/"

RUN make -j1 \
    && cp bin/OscGroupClient /usr/local/bin/OscGroupClient

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
	apt-get install -y wget software-properties-common && \
    echo deb http://download.opensuse.org/repositories/multimedia:/xiph/xUbuntu_18.04/ ./ >>/etc/apt/sources.list.d/icecast.list && \
	add-apt-repository -y multiverse && \
    wget -qO - https://icecast.org/multimedia-obs.key | apt-key add - && \
	apt-get update && \
    apt-get install -y icecast2 darkice libasound2 libasound2-plugins alsa-utils alsa-oss jackd1 jack-tools xvfb libreadline-dev && \
    apt-get clean

COPY --from=builder /usr/local /usr/local
COPY --from=builder /root /root
#OSCGROUPS
COPY --from=builder /usr/local/bin/OscGroupClient /usr/local/bin/OscGroupClient


COPY icecast.xml /etc/icecast2/icecast.xml
COPY darkice.cfg /etc/darkice.cfg
COPY darkice.sh /etc/darkice.sh
RUN chmod +x /etc/darkice.sh
COPY sclang.sh /etc/sclang.sh
RUN chmod +x /etc/sclang.sh
COPY icecast.sh /etc/icecast.sh
RUN chmod +x /etc/icecast.sh

#SC-HACKS-REDUX
COPY sc-hacks-redux /usr/local/share/SuperCollider/Extensions/sc-hacks-redux

#COPY radio /radio
#COPY config.scd /radio/config.scd

COPY Procfile Procfile

EXPOSE 8000
RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf && \
  usermod -a -G audio root

CMD ["/root/go/bin/forego", "start"]
