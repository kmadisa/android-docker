FROM ubuntu:18.04

# Update the repo info
RUN apt-get update

# Change installation dialogs policy to noninteractive, otherwise
# debconf raises errors: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d
RUN apt-get install -y --force-yes software-properties-common debconf-utils

# Install the Java Runtime Environment (JRE).
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN apt-get install --yes oracle-java8-installer
RUN apt-get install oracle-java8-set-default
ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle
ENV JRE_HOME=/usr/lib/jvm/java-8-oracle/JRE

# Install git
RUN apt-get install -y git

# Set androind environment variables.
ENV ANDROID_COMPILE_SDK=28
ENV ANDROID_BUILD_TOOLS=28.0.0
ENV ANDROID_SDK_TOOLS=28.0.0

# Download android sdk and ndk
RUN apt-get install --yes wget tar unzip lib32stdc++6 lib32z1
RUN wget --output-document=android-sdk.zip \
    https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
RUN unzip android-sdk.zip -d android-sdk-linux
RUN wget --output-document=android-ndk.zip \
    https://dl.google.com/android/repository/android-ndk-r19c-linux-x86_64.zip
RUN unzip android-ndk.zip -d ndk-bundle

# Some questionable parts (Need to investigate)
RUN mkdir /root/.android/
RUN touch /root/.android/repositories.cfg

RUN mkdir android-sdk-linux/licenses
RUN printf "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > \
    android-sdk-linux/licenses/android-sdk-license
RUN printf "84831b9409646a918e30573bab4c9c91346d8abd" > \
    android-sdk-linux/licenses/android-sdk-preview-license

# Install the platform-tools package
RUN echo y | android-sdk-linux/tools/bin/sdkmanager --install platform-tools
RUN android-sdk-linux/tools/bin/sdkmanager --update > update.log
RUN android-sdk-linux/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" \ 
                                           "build-tools;${ANDROID_BUILD_TOOLS}" \
                                           "platform-tools" \
                                           "extras;google;m2repository" \
                                           "extras;android;m2repository" > installPlatform.log

# Set android environments.
ENV ANDROID_HOME=$PWD/android-sdk-linux
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV ANDROID_NDK_HOME=$PWD/ndk-bundle/android-ndk-r19c/
ENV PATH=$PATH:$ANDROID_HOME/emulator
ENV PATH=$PATH:$ANDROID_HOME/tools
ENV PATH=$PATH:$ANDROID_HOME/platform-tools


RUN echo y | android-sdk-linux/tools/bin/sdkmanager "emulator"
RUN echo y | android-sdk-linux/tools/bin/sdkmanager \
    "system-images;android-${ANDROID_COMPILE_SDK};google_apis;x86_64"
RUN echo no | android-sdk-linux/tools/bin/avdmanager -v create avd -n test \
    -k "system-images;android-${ANDROID_COMPILE_SDK};google_apis;x86_64" -f

RUN apt-get install -y cpu-checker
RUN apt-get update
RUN apt-get install -y qemu
RUN apt-get install -y qemu-kvm    
RUN apt-get install -y libvirt-bin
RUN apt-get install -y virtinst
RUN apt-get install -y bridge-utils
RUN apt-get install --yes libglu1

#https://github.com/boot2docker/boot2docker/issues/1138
#RUN mknod /dev/kvm c 10 232