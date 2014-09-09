docker-cinder
=============

Docker Image for OpenStack Cinder

Overview
--------

Run OpenStack Cinder in a Docker container.


Caveats
-------

The container does **NOT** include cinder-volume. The container only includes Cinder API and Scheduler services.

The systemd_rhel7 base image used by the Cinder container is a private image.
Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893)
to create your base rhel7 image. Then enable systemd within the rhel7 base image.
Use [Running SystemD within a Docker Container](http://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/) to enable SystemD.

The container does not setup Keystone endpoints for Cinder. This is a task the Keystone service is responsible for.

Although the container does initialize the database used by Cinder, it does not create the database, permissions, etc.. These are responsibilities of the database service.

The container does not include any OpenStack clients. After the Cinder container is running, issue Cinder commands from a host running the python-cinderclient.

Installation
------------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed.

### From Github

Clone the Github repo and change to the project directory:
```
yum install -y git
git clone https://github.com/danehans/docker-cinder.git
cd docker-cinder
```
Edit the cinder.conf file according to your deployment needs then build the Cinder image. Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/ch_cinder.html) for details. Next, build your Docker Cinder image.
```
docker build -t cinder .
```
The image should now appear in your image list:
```
# docker images
REPOSITORY    TAG       IMAGE ID            CREATED             VIRTUAL SIZE
cinder        latest    d280a0d8e4c5        14 minutes ago      765.9 MB

```
Run the Cinder container. The example below uses the -h flag to configure the hostame as cinder within the container, exposes TCP port 8776 on the Docker host, names the container cinder, uses -d to run the container as a daemon.
```
docker run --privileged -d -h cinder -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 8776:8776 --name="cinder" cinder
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your Cinder container is running:
```
# docker ps
CONTAINER ID  IMAGE         COMMAND          CREATED             STATUS              PORTS                    NAMES
96173898fa16  cinder:latest   /usr/sbin/init   About an hour ago   Up 51 minutes       0.0.0.0:8776->8776/tcp   cinder
```
Access the shell from your container:
```
# docker inspect --format='{{.State.Pid}}' cinder
```
The command above will provide a process ID of the Cinder container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing the installed RPMs, Cinder services, the cinder.conf file, etc..

Deploy a Cinder Volume
----------------------

Since the container does not include the cinder-volume service, you will need an existing cinder-volume host or use the [official OpenStack documentation](http://docs.openstack.org/icehouse/install-guide/install/yum/content/cinder-verify.html) to deploy a cinder-volume host.

After the cinder-volume host is deployed, use these steps [here](http://docwiki.cisco.com/wiki/OpenStack_Havana_Release:_High-Availability_Manual_Deployment_Guide#Create_and_Attach_a_Cinder_Volume) to continue validating Cinder functionality.

Troubleshooting
---------------

Can you connect to the OpenStack API endpints from your Docker host and container? Verify connectivity with tools such as ping and curl.

IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
iptables -L
```
To change iptables rules:
```
vi /etc/sysconfig/iptables
systemctl restart iptables.service
```
