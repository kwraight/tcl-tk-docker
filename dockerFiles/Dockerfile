# base image
# FROM centos:centos7
FROM --platform=linux/amd64 alpine:3.14

### run as root
USER root

### open port
EXPOSE 8015

### set-up packages
# update
RUN true \ 
    && apk update \
    && apk upgrade
# display packages
RUN true \ 
    && apk add gcompat libc6-compat ttf-linux-libertine fontconfig libxft libx11 x11vnc xclock xsetroot
# useful stuff
    RUN true \
    && apk add nano wget tcl tk

###  Centos stuff to fix broken package repository links
# COPY yum_update.sh /tmp/yum_update.sh
# RUN true \ 
#     && source /tmp/yum_update.sh
# ### set-up packages
# RUN true \ 
#     sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
#     sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
#     sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
#     sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
#     sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
#     yum clean all
# RUN true \ 
#     && yum update -y \
#     && yum install nano wget -y \
#     && yum install tcl tk -y 

### make dir and get file
RUN true \ 
    && mkdir cloudtk \
    && wget -P cloudtk https://cloudtk.tcl-lang.org/Downloads/CloudTk.kit \
    && wget -P cloudtk https://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-rhel5-x86_64?name=36b5cb68899cfcb79417a29f9c6d8176ebae0d24
### change working dir
WORKDIR /cloudtk
RUN true \ 
    && mv tclkit-8.6.3-rhel5-x86_64?name=36b5cb68899cfcb79417a29f9c6d8176ebae0d24 tclkit \
    && chmod +x tclkit

RUN true \ 
    && ln -s /usr/bin/x11vnc /usr/bin/Xvnc
# # # run as not root
# RUN adduser appuser
# USER appuser

# match exposed port
CMD ["./tclkit","CloudTk.kit","-port","8015"]
