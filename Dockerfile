FROM ubuntu:focal

ENV APT="apt-get -y"


USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

COPY bionic.list /etc/apt/sources.list.d/
COPY xenial.list /etc/apt/sources.list.d/

RUN ${APT} update && ${APT} upgrade
RUN ${APT} install git sudo wget cmake g++ libusb-dev libusb-1.0-0-dev libgps-dev debhelper libsqlite3-dev libosip2-dev libzmq3-dev libboost-filesystem1.67-dev libboost-date-time1.67-dev libboost-program-options1.67-dev libboost-regex1.67-dev libboost-thread1.67-dev libboost-test1.67-dev sqlite3 ntp ntpdate bind9 resolvconf libreadline-dev gcc-5 g++-5 libreadline6 python3-mako asterisk
# python3-numpy 
# python-pip python-mako python-requests


# For Ettus devices
# RUN ${APT} install libuhd-dev libuhd003.010.003 uhd-host
ENV EXTRA_CONFIGURE_FLAGS="--with-uhd"

RUN ${APT} install vim openssh-server net-tools iputils-ping


#RUN systemctl start ssh
#RUN /etc/init.d/ssh start
RUN sed -i 's/^PermitEmptyPasswords no$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config



RUN adduser --disabled-password cxlbadm
RUN adduser cxlbadm sudo
RUN sed -i -e 's%cxlbadm:\*:%cxlbadm:$6$fEFUE2YaNmTEH51Z$1xRO8/ytEYIo10ajp4NZSsoxhCe1oPLIyjDjqSOujaPZXFQxSSxu8LDHNwbPiLSjc.8u0Y0wEqYkBEEc5/QN5/:%' /etc/shadow

WORKDIR /home/cxlbadm
USER cxlbadm
RUN git clone --recursive https://github.com/EttusResearch/uhd.git


WORKDIR uhd/

#RUN git checkout v3.14.1.1
RUN git checkout master
RUN mkdir host/build
WORKDIR host/build
# RUN cmake -DENABLE_GPSD=ON -DENABLE_PYTHON3=ON ..
RUN cmake ..
RUN make -j


USER root
RUN make install
RUN ldconfig
RUN uhd_images_downloader
USER cxlbadm


# Switch to gcc5; UHD has to be compiled with a newer version.
# update-alternatives --config gcc
# update-alternatives --config g++
USER root
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 10
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 10
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 50
RUN update-alternatives --set gcc /usr/bin/gcc-5
RUN update-alternatives --set g++ /usr/bin/g++-5
USER cxlbadm



WORKDIR /home/cxlbadm
# RUN git clone https://github.com/RangeNetworks/dev.git
RUN mkdir dev



WORKDIR dev
RUN wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/google-coredumper/coredumper-1.2.1.tar.gz
RUN tar -xf coredumper-1.2.1.tar.gz
WORKDIR coredumper-1.2.1
RUN mv packages/deb debian
RUN chmod -R u+w .
COPY libcoredumper.patch /home/cxlbadm/dev/
RUN patch -p0 < ../libcoredumper.patch

RUN dpkg-buildpackage -us -uc

USER root
RUN dpkg -i ../libcoredumper*.deb
USER cxlbadm


WORKDIR /home/cxlbadm/dev
RUN git clone https://github.com/RangeNetworks/liba53.git
WORKDIR /home/cxlbadm/dev/liba53
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN dpkg-buildpackage -us -uc

USER root
RUN sudo dpkg -i ../liba53_0.1_amd64.deb
USER cxlbadm



WORKDIR /home/cxlbadm/dev
COPY CommonLibs-Logger.patch /home/cxlbadm/dev/
RUN git clone https://github.com/RangeNetworks/subscriberRegistry.git
WORKDIR subscriberRegistry
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN patch -p0 < /home/cxlbadm/dev/CommonLibs-Logger.patch
RUN dpkg-buildpackage -us -uc

USER root
RUN dpkg -i ../sipauthserve_5.0_amd64.deb 
USER cxlbadm




WORKDIR /home/cxlbadm/dev
RUN git clone https://github.com/RangeNetworks/smqueue.git
WORKDIR smqueue
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN patch -p0 < /home/cxlbadm/dev/CommonLibs-Logger.patch
RUN dpkg-buildpackage -us -uc

USER root
RUN dpkg -i ../smqueue_5.0_amd64.deb
USER cxlbadm




WORKDIR /home/cxlbadm/dev
RUN git clone https://github.com/RangeNetworks/system-config
WORKDIR system-config
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN dpkg-buildpackage -us -uc

USER root
RUN echo Y | dpkg -i --force-overwrite ../range-configs_5.1-master_all.deb
USER cxlbadm





WORKDIR /home/cxlbadm/
RUN wget http://ftp.us.debian.org/debian/pool/main/l/linphone/libortp9_3.6.1-3_amd64.deb
RUN wget http://ftp.us.debian.org/debian/pool/main/l/linphone/libortp-dev_3.6.1-3_amd64.deb

USER root
RUN dpkg -i libortp9_3.6.1-3_amd64.deb
RUN dpkg -i libortp-dev_3.6.1-3_amd64.deb
USER cxlbadm





WORKDIR /home/cxlbadm/dev
RUN git clone https://github.com/RangeNetworks/openbts
WORKDIR openbts
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN patch -p0 < /home/cxlbadm/dev/CommonLibs-Logger.patch
COPY openbts.patch /home/cxlbadm/dev/
RUN patch -p0 < /home/cxlbadm/dev/openbts.patch
RUN dpkg-buildpackage -us -uc

USER root
RUN dpkg -i ../openbts_5.0_amd64.deb
USER cxlbadm




WORKDIR /home/cxlbadm/dev
RUN git clone https://github.com/RangeNetworks/asterisk-config
WORKDIR asterisk-config
RUN git checkout master
RUN git submodule update --init --recursive --remote
RUN dpkg-buildpackage -us -uc

USER root
RUN echo Y | dpkg -i --force-overwrite ../range-asterisk-config_5.0_all.deb

WORKDIR /home/cxlbadm/dev
RUN dpkg --force-confnew -i libcoredumper1_1.2.1-1_amd64.deb libcoredumper-dev_1.2.1-1_amd64.deb liba53_0.1_amd64.deb smqueue_5.0_amd64.deb sipauthserve_5.0_amd64.deb openbts_5.0_amd64.deb  range-configs_5.1-master_all.deb  range-asterisk-config_5.0_all.deb
USER cxlbadm


WORKDIR /home/cxlbadm/
RUN git clone --recursive https://github.com/nadiia-kotelnikova/openbts_systemd_scripts.git




USER root

RUN cp -r /home/cxlbadm/openbts_systemd_scripts/systemd/. /etc/systemd/system/
RUN sed -i "s/^Description=sipauthserve$/Description=sipauthserve\nRequires=asterisk.service\nAfter=asterisk.service/" /etc/systemd/system/sipauthserve.service
RUN sed -i "s/^Description=smqueue$/Description=smqueue\nRequires=sipauthserve.service\nAfter=sipauthserve.service/" /etc/systemd/system/smqueue.service
RUN sed -i "s/^Description=OpenBTS$/Description=OpenBTS\nRequires=smqueue.service\nAfter=smqueue.service/" /etc/systemd/system/openbts.service
# comment the following line if you don't want openbts to start automatically when container runs

RUN systemctl enable openbts




WORKDIR /OpenBTS

CMD [ "/sbin/init" ]


