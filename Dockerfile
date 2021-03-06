# Copyright (c) 2012-2018 Codenvy, S.A. 
# All rights reserved.
# Contributors: 
# Codenvy, S.A. - initial API and implementation

# Modified and Updated by
# fr3akyphantom <rokibhasansagar2014@outlook.com>

# Build environment for Android, based on Ubuntu Bionic

FROM ubuntu:bionic
MAINTAINER fr3akyphantom <rokibhasansagar2014@outlook.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV MAVEN_VERSION=3.6.0 \
    JAVA_VERSION=8u192 \
    JAVA_VERSION_PREFIX=1.8.0_192

ENV JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX \
    M2_HOME=/home/user/apache-maven-$MAVEN_VERSION

ENV TERM xterm
RUN apt-get update -qqy && apt-get install -qqy locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
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

RUN apt-get update -qqy && apt-get install -qqy sudo git subversion curl wput build-essential ncurses-dev && rm -rf /var/lib/apt/lists/* && \
    sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://github.com/akhilnarang/repo/raw/master/repo \
    && sudo chmod a+x /usr/local/bin/repo

# RUN sudo mkdir akhil && \
#     git clone https://github.com/akhilnarang/scripts akhil/ && \
#     cd akhil/ && bash setup/android_build_env.sh 1>/dev/null && rm -rf akhil/

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
    cd /home/user && wget -q "https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" -O android-sdk-linux.zip && unzip -q -d android-sdk-linux/ android-sdk-linux.zip && rm android-sdk-linux.zip

RUN sudo apt-get clean && \
    sudo apt-get -y autoremove && \
    sudo rm -rf /var/lib/apt/lists/* && \
    yes | "${ANDROID_HOME}"/tools/bin/sdkmanager --licenses

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "add-ons;addon-google_apis-google-{22,23}" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "add-ons;addon-google_apis-google-24"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;{25.0.3,26.0.3,27.0.3,28.0.3}"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "cmake;3.6.4111459" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "docs" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "emulator" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;android;gapid;{1,3}" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;google_play_services" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;instantapps" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;google;webdriver"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;android;m2repository"
#     && "${ANDROID_HOME}"/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-{layout,layout-solver};1.0.2" \
#     && "${ANDROID_HOME}"/tools/bin/sdkmanager "lldb;3.1"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "ndk-bundle" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "patcher;v4" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "platform-tools" && \
#     "${ANDROID_HOME}"/tools/bin/sdkmanager "tools"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "platforms;android-{25,26,27,28}"

# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "sources;android-{25,26,27,28}"

# Uncomment the following to install android-25 images
# RUN "${ANDROID_HOME}"/tools/bin/sdkmanager "system-images;android-25;google_apis;{armeabi-v7a,arm64-v8a}"
    
RUN "${ANDROID_HOME}"/tools/bin/sdkmanager --update
    # && echo "no" | "${ANDROID_HOME}"/tools/bin/avdmanager create avd \
    #             --name che --target android-25 --abi arm64-v8a

RUN sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zvx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zvx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    sudo mkdir -p /etc/X11/blackbox && \
    echo "[begin] (Blackbox) \n [exec] (Terminal)     {urxvt -fn "xft:Terminus:size=12"} \n \
          [exec] (Emulator) {emulator64-arm -avd che} \n \
          [end]" | sudo tee -a /etc/X11/blackbox/blackbox-menu && \
    echo -e "#! /bin/bash\n set -e\n sudo /usr/sbin/sshd -D &\n /usr/bin/supervisord -c /opt/supervisord.conf &\n exec \"\$@\"" > /home/user/entrypoint.sh && chmod a+x /home/user/entrypoint.sh

ADD index.html /opt/noVNC/
ADD supervisord.conf /opt/

RUN svn --version && \
    sed -i 's/# store-passwords = no/store-passwords = yes/g' /home/user/.subversion/servers && \
    sed -i 's/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g' /home/user/.subversion/servers

ENTRYPOINT ["/home/user/entrypoint.sh"]

EXPOSE 4403 6080 22

WORKDIR /projects

CMD tail -f /dev/null
