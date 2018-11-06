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
    JAVA_VERSION_PREFIX=1.8.0_192

ENV JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX \
    M2_HOME=/home/user/apache-maven-$MAVEN_VERSION

ENV TERM xterm
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
ENV ANDROID_HOME=/home/user/android-sdk-linux
ENV PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH

LABEL che:server:6080:ref=VNC che:server:6080:protocol=http

RUN echo 'tzdata tzdata/Areas select Asia' | debconf-set-selections && \
    echo 'tzdata tzdata/Zones/Asia select Dhaka' | debconf-set-selections \
    && apt-get update -qqy && apt-get install -qqy --no-install-recommends tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qqy && apt-get install -qqy sudo git curl wput && rm -rf /var/lib/apt/lists/*

RUN sudo mkdir akhil && \
    git clone https://github.com/akhilnarang/scripts akhil/ && \
    cd akhil/ && bash setup/android_build_env.sh 1>/dev/null && rm -rf akhil/

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    echo "secret\nsecret" | passwd user

USER user

RUN sudo dpkg --add-architecture i386 && \
    sudo apt-get update -qqy && sudo apt-get install -qqy --force-yes expect libswt-gtk-3-java lib32z1 lib32ncurses5 lib32stdc++6 supervisor x11vnc xvfb net-tools \
    blackbox rxvt-unicode xfonts-terminus sudo openssh-server procps \
    wget unzip mc software-properties-common && \
    sudo mkdir /var/run/sshd && \
    sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN mkdir /home/user/apache-maven-$MAVEN_VERSION && \
    wget --no-cookies --no-check-certificate \
    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    -qO- \
    "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-b12/750e1c8617c5452694857ad95c3ee230/jdk-$JAVA_VERSION-linux-x64.tar.gz" | sudo tar -zx -C /opt/
RUN wget -qO- "https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/
RUN mkdir -p /home/user/android-sdk-linux && \
    cd /home/user && wget -q -O android-sdk-linux.zip "https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" && unzip -q -d android-sdk-linux/ android-sdk-linux.zip && rm android-sdk-linux.zip

RUN sudo apt-get clean && \
    sudo apt-get -y autoremove && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo mkdir -p ~/.android && echo "" >> ~/.android/repositories.cfg
    # sudo mkdir -p /home/user/.android & sudo touch /home/user/.android/repositories.cfg && \
    yes | "${ANDROID_HOME}"/tools/bin/sdkmanager --licenses 1>/dev/null

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "add-ons;addon-google_apis-google-22" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "add-ons;addon-google_apis-google-23" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "add-ons;addon-google_apis-google-24"

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;25.0.3" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;26.0.3" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;27.0.3" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;28.0.3"

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "cmake;3.6.4111459" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "docs" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "emulator" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;android;gapid;1" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;android;gapid;3" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;google_play_services" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;instantapps" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;webdriver"


RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;android;m2repository" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "lldb;3.1"

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "ndk-bundle" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "patcher;v4" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "platform-tools" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "tools"

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "platforms;android-25" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "platforms;android-26" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "platforms;android-27" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "platforms;android-28"

RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "sources;android-25" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "sources;android-26" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "sources;android-27" && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager "sources;android-28"

# Uncomment the following to install android-25 arm64-v8a image
# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "system-images;android-25;google_apis;arm64-v8a"
    
RUN echo y | "${ANDROID_HOME}"/tools/bin/sdkmanager --update
    # && echo "no" | "${ANDROID_HOME}"/tools/bin/avdmanager create avd \
    #             --name che --target android-25 --abi arm64-v8a

RUN sudo mkdir -p /opt/noVNC/utils/websockify && \
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
