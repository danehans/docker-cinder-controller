docker-cinder-controller
========================

Docker Image for OpenStack Cinder Controller Services

Overview
--------

Run OpenStack Cinder Controller Services in a Docker container.


Caveats
-------

The container does **NOT** include cinder-volume. The container only includes Cinder API and Scheduler services.

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed. Reference the [Getting images from outside Docker registries](https://access.redhat.com/articles/881893#images) section of the the guide to pull your base rhel7 image from Red Hat's private registry. This is required to build the rhel7-systemd base image used by the cinder-controller container.

Make sure your Docker host has been configured with the required [OSP 5 channels and repositories](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Installation_and_Configuration_Guide/chap-Prerequisites.html#sect-Software_Repository_Configuration)

After following the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893) guide, verify your Docker Registry is running:
```
# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/usr/lib/systemd/system/docker-registry.service; enabled)
   Active: active (running) since Mon 2014-05-05 13:42:56 EDT; 601ms ago
 Main PID: 21031 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─21031 /usr/bin/python /usr/bin/gunicorn --access-logfile - --debug ...
            ...
```
Now that you have the rhel7 base image, follow the instructions in the [docker-rhel7-systemd project](https://github.com/danehans/docker-rhel7-systemd/blob/master/README.md) to build your rhel7-systemd image.

The container does not setup Keystone endpoints for Cinder. This is a task the Keystone service is responsible for.

Although the container does initialize the database used by Cinder, it does not create the database, permissions, etc.. These are responsibilities of the database service.

Installation
------------

From your Docker Registry, set the environment variables used to automate the image building process

Required. Name of the Github repo. Change danehans to your Github repo name if you forked this project. Otherwise set REPO_NAME to danehans.
```
export REPO_NAME=danehans
```
Required. The branch from the REPO_NAME repo. Unless you are using a different branch, set the REPO_BRANCH to master.
```
export REPO_BRANCH=master
```
Optional. Name of the Docker base image in your Docker Registry. This should be the image that includes systemd. Defaults to rhel7-systemd.
```
export BASE_IMAGE=ouruser/rhel7-systemd
```
Optional. Name to use for the cinder-controller Docker image. Defaults to cinder-controller.
```
export IMAGE_NAME=ouruser/cinder-controller
```
Required. IP address/hostname of the Database server.
```
export DB_HOST=10.10.10.200
```
Optional. Password used to connect to the cinder-controller database on the DB_HOST server. Defaults to changeme.
```
export DB_PASSWORD=changeme
```
Required. IP address/hostname of the RabbitMQ server.
```
export RABBIT_HOST=10.10.10.200
```
Optional. Username/Password to connect to the RabbitMQ server. Defaults to guest/guest
```
export RABBIT_USER=guest
export RABBIT_PASSWORD=guest
```
Required. IP address/hostname of Keystone.
```
export KEYSTONE_HOST=10.10.10.100
```
Optional. TCP Port used by the Keystone Admin API. Defaults to 35357.
```
export KEYSTONE_ADMIN_HOST_PORT=35357
```
Optional. TCP Port used by the Keystone Public API. Defaults to 5000
```
export KEYSTONE_PUBLIC_HOST_PORT=5001
```
Optional. The name and password of the service tenant within the Keystone service catalog. Defaults to service/changeme
```
export SERVICE_TENANT=services
export SERVICE_PASSWORD=changeme
```
Optional. Credentials used in the cinder-controller RC files. Defaults to changeme.
```
export ADMIN_USER_PASSWORD=changeme
export DEMO_USER_PASSWORD=changeme
```
Required. IP address/hostname of the Glance API endpoint. Defaults to 127.0.0.1
```
export GLANCE_API_HOST=127.0.0.1
```
Additional environment variables can be set as needed. You can reference the [build script](https://github.com/danehans/docker-cinder-controller/blob/master/data/scripts/build) to review all the available environment variables options and their default settings.

Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/cinder-controller.html) for more details on the .conf configuration parameters.

Run the build script.
```
bash <(curl \-fsS https://raw.githubusercontent.com/$REPO_NAME/docker-cinder-controller/$REPO_BRANCH/data/scripts/build)
```
```
The image should now appear in your image list:
```
# docker images
REPOSITORY          TAG       IMAGE ID            CREATED             VIRTUAL SIZE
cinder-controller   latest    d280a0d8e4c5        14 minutes ago      765.9 MB

```
Now you can run a cinder-controller container from the newly created image. You can use the run script or run the container manually.

First, set your environment variables:
```
export IMAGE_NAME=ouruser/cinder-controller
export CINDER_CONTROLLER_HOSTNAME=cinder-controller.example.com
export DNS_SEARCH=example.com
```
**Option 1-** Use the run script:
```
# . $HOME/docker-cinder-controller/data/scripts/run
```
**Option 2-** Manually:

Run the cinder-controller container. The example below uses the -h flag to configure the hostame as cinder-controller within the container, exposes TCP port 8776 on the Docker host, names the container cinder-controller, uses -d to run the container as a daemon.
```
docker run --privileged -d -h cinder-controller -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 8776:8776 --name="cinder-controller" ouruser/cinder-controller
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your cinder-controller container is running:
```
# docker ps
CONTAINER ID  IMAGE                      COMMAND          CREATED             STATUS              PORTS                    NAMES
96173898fa16  cinder-controller:latest   /usr/sbin/init   About an hour ago   Up 51 minutes       0.0.0.0:8776->8776/tcp   cinder-controller
```
Access the shell of your container:
```
# docker inspect --format='{{.State.Pid}}' cinder-controller
```
The command above will provide a process ID of the Cinder container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing the installed RPMs, Cinder services, the cinder-controller.conf file, etc..

Deploy a Cinder Volume
----------------------

Since the container does not include the cinder-volume service, you will need an existing cinder-volume host or use the [official OpenStack documentation](http://docs.openstack.org/icehouse/install-guide/install/yum/content/cinder-controller-verify.html) to deploy a cinder-volume host.

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
