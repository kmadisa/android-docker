FROM ubuntu:16.04

# Update the repo info
RUN apt-get update

# Change installation dialogs policy to noninteractive, otherwise
# debconf raises errors: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

# Install the Java Runtime Environment (JRE).
RUN apt-get install -y default-jre
#  Install the JDK
RUN apt-get install -y default-jdk 

ENV ANDROID_COMPILE_SDK=26
ENV ANDROID_BUILD_TOOLS=26.0.0
ENV ANDROID_SDK_TOOLS=27.0.1

RUN apt-get install --yes wget tar unzip lib32stdc++6 lib32z1

RUN wget --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
RUN unzip android-sdk.zip -d android-sdk-linux
RUN wget --output-document=android-ndk.zip https://dl.google.com/android/repository/android-ndk-r17-linux-x86_64.zip
RUN unzip android-ndk.zip -d ndk-bundle

# Some questionable parts
RUN mkdir /root/.android/
RUN touch /root/.android/repositories.cfg

RUN mkdir android-sdk-linux/licenses
RUN printf "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > android-sdk-linux/licenses/android-sdk-license
RUN printf "84831b9409646a918e30573bab4c9c91346d8abd" > android-sdk-linux/licenses/android-sdk-preview-license

RUN android-sdk-linux/tools/bin/sdkmanager --update > update.log
RUN android-sdk-linux/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" "build-tools;${ANDROID_BUILD_TOOLS}" "extras;google;m2repository" "extras;android;m2repository" > installPlatform.log

ENV ANDROID_HOME=$PWD/android-sdk-linux
ENV ANDROID_NDK_HOME=$PWD/ndk-bundle/android-ndk-r17/
ENV PATH=$PATH:$PWD/android-sdk-linux/platform-tools/

RUN echo y | android-sdk-linux/tools/bin/sdkmanager "emulator"
RUN echo y | android-sdk-linux/tools/bin/sdkmanager "system-images;android-${ANDROID_COMPILE_SDK};google_apis;x86"
RUN echo no | android-sdk-linux/tools/bin/avdmanager -v create avd -n test -k "system-images;android-${ANDROID_COMPILE_SDK};google_apis;x86" -f

RUN apt-get update

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker

#RUN groupadd kvm
RUN usermod -G kvm -a root
RUN echo 'KERNEL=="kvm",GROUP="kvm",MODE="0660"' >> /etc/udev/rules.d/androidUseKVM.rules
#RUN modeprobe kvm
RUN systemctl enable --now libvirt-bin
#https://github.com/boot2docker/boot2docker/issues/1138
#RUN mknod /dev/kvm c 10 232


#RUN mkdir -p /root/.android/avd/test.avd/
#RUN cp -r android-sdk-linux/system-images/android-${ANDROID_COMPILE_SDK}/google_apis/x86/* /root/.android/avd/test.avd

#RUN android-sdk-linux/tools/emulator -avd test -no-window -no-audio -initdata /root/.android/avd/test.avd/userdata.img &