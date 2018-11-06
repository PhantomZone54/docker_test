# Copyright (c) 2012-2018 Codenvy, S.A. 
# All rights reserved. This program and the accompanying materials 
# are made available under the terms of the Eclipse Public License v1.0 
# which accompanies this distribution, and is available at 
# http://www.eclipse.org/legal/epl-v10.html 
# Contributors: 
# Codenvy, S.A. - initial API and implementation

# Modified and Updated by
# fr3akyphantom <rokibhasansagar2014@outlook.com>

# Build environment for Android, based on Ubuntu Bionic

FROM ubuntu:18.04
MAINTAINER fr3akyphantom <rokibhasansagar2014@outlook.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV MAVEN_VERSION=3.6.0 \
    JAVA_VERSION=8u192 \
    JAVA_VERSION_PREFIX=1.8.0_191

ENV JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX \
    M2_HOME=/home/user/apache-maven-$MAVEN_VERSION

ENV TERM xterm
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
#RUN dpkg-reconfigure locales

ENV PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
ENV ANDROID_HOME=/home/user/android-sdk-linux
ENV PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH

LABEL che:server:6080:ref=VNC che:server:6080:protocol=http

RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*

RUN echo "tzdata tzdata/Areas select Asia" > /tmp/preseed.txt && \
    echo "tzdata tzdata/Zones/Asia select Dhaka" >> /tmp/preseed.txt && \
    sudo debconf-set-selections /tmp/preseed.txt && \
    sudo rm /etc/timezone; sudo rm /etc/localtime; \
    sudo dpkg-reconfigure -f noninteractive tzdata && \
    apt-get update && \
    apt-get install -y tzdata && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    echo "secret\nsecret" | passwd user

USER user

RUN sudo dpkg --add-architecture i386 && \
    sudo apt-get update && sudo apt-get install -y --force-yes expect libswt-gtk-3-java lib32z1 lib32ncurses5 lib32stdc++6 supervisor x11vnc xvfb net-tools \
    blackbox rxvt-unicode xfonts-terminus sudo openssh-server procps \
    #python-software-properties \
    wget unzip mc curl software-properties-common && \
    sudo mkdir /var/run/sshd && \
    sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    sudo add-apt-repository ppa:git-core/ppa && \
    sudo apt-get update && \
    sudo sudo apt-get install git subversion -y

RUN mkdir /home/user/apache-maven-$MAVEN_VERSION && \
    wget \
    --no-cookies \
    --no-check-certificate \
    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    -qO- \
    "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-b12/750e1c8617c5452694857ad95c3ee230/jdk-$JAVA_VERSION-linux-x64.tar.gz" | sudo tar -zx -C /opt/ && \
    wget -qO- "https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    cd /home/user && wget --output-document=android-sdk-linux.zip --quiet "https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" && unzip -d android-sdk-linux android-sdk-linux.zip && rm android-sdk-linux.zip

RUN sudo apt-get clean && \
    sudo apt-get -y autoremove && \
    sudo rm -rf /var/lib/apt/lists/* && \
    echo y | android update sdk --all --force --no-ui && \
    echo "no" | android create avd \
                --name che \
                --target android-27 \
                --abi arm64-v8a && \
    sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    sudo mkdir -p /etc/X11/blackbox && \
    echo "[begin] (Blackbox) \n [exec] (Terminal)     {urxvt -fn "xft:Terminus:size=12"} \n \
          [exec] (Emulator) {emulator64-arm -avd che} \n \
          [end]" | sudo tee -a /etc/X11/blackbox/blackbox-menu && \
    echo "#! /bin/bash\n set -e\n sudo /usr/sbin/sshd -D &\n/usr/bin/supervisord -c /opt/supervisord.conf &\n exec \"\$@\"" > /home/user/entrypoint.sh && chmod a+x /home/user/entrypoint.sh

ADD index.html /opt/noVNC/
ADD supervisord.conf /opt/

RUN svn --version && \
sed -i 's/# store-passwords = no/store-passwords = yes/g' /home/user/.subversion/servers && \
    sed -i 's/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g' /home/user/.subversion/servers

ENTRYPOINT ["/home/user/entrypoint.sh"]

EXPOSE 4403 6080 22 WORKDIR /projects

CMD tail -f /dev/null
