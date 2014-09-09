# Cinder
# VERSION               0.0.1
# Tested on RHEL7 and OSP5 (i.e. Icehouse)

FROM      systemd_rhel7
MAINTAINER Daneyon Hansen "daneyonhansen@gmail.com"

WORKDIR /root

# Uses Cisco Internal Mirror. Follow the OSP 5 Repo documentation if you are using subscription manager.
RUN curl --url http://173.39.232.144/repo/redhat.repo --output /etc/yum.repos.d/redhat.repo
RUN yum -y update; yum clean all

# Required Utilities
RUN yum -y install openssl ntp

# Cinder
RUN yum -y install openstack-cinder
RUN mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.save
ADD cinder.conf /etc/cinder/cinder.conf
RUN chown -R cinder:cinder /var/log/cinder
RUN chown cinder:cinder /etc/cinder/cinder.conf
RUN systemctl enable openstack-cinder-api
RUN systemctl enable openstack-cinder-scheduler

# Initialize the Cinder MySQL DB
RUN cinder-manage db sync

# Expose Cinder TCP ports
EXPOSE 8776 

CMD ["/usr/sbin/init"]
