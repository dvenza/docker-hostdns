==============
Docker HostDNS
==============

Update BIND nameserver zone with Docker hosts via DNS Updates.

Usage
=====

*Docker HostDNS* can be run by ``docker-hostdns`` wrapper script or directly with ``python -m docker_hostdns``.

.. sourcecode::

   usage: docker-hostdns [-h] [--zone ZONE] [--dns-server DNS_SERVER]
                         [--dns-key-secret DNS_KEY_SECRET]
                         [--dns-key-name DNS_KEY_NAME] [--name NAME]
                         [--network NETWORK] [--daemonize PIDFILE] [--verbose]
                         [--syslog] [--clear-on-exit]
   
   Update BIND nameserver zone with Docker hosts via DNS Updates.
   
   optional arguments:
     -h, --help            show this help message and exit
     --zone ZONE           dns zone to update, defaults to "docker"
     --dns-server DNS_SERVER
                           address of DNS server which will be updated, defaults
                           to 127.0.0.1
     --dns-key-secret DNS_KEY_SECRET
                           DNS Server key secret for use when updating zone, use
                           '-' to read from stdin
     --dns-key-name DNS_KEY_NAME
                           DNS Server key name for use when updating zone
     --name NAME           name to differentiate between multiple instances
                           inside same dns zone, defaults to current hostname
     --network NETWORK     network to fetch container names from, defaults to
                           docker default bridge, can be used multiple times
     --daemonize PIDFILE, -d PIDFILE
                           daemonize after start and store PID at given path
     --verbose, -v         give more output - option is additive, and can be used
                           up to 3 times
     --syslog              enable logging to syslog
     --clear-on-exit       clear zone on exit


The ``--daemonize`` options is only available when you have installed ``python-daemon3`` package.

Example ``named.conf`` zone configuration with key auth:

.. sourcecode::

   include "/etc/bind/docker.key";
   
   zone "docker" in {
       type master;
       file "/var/bind/dyn/docker.zone";
       allow-update {
         key "docker-key";
       };
   };

``docker.key`` can be generated by:

.. sourcecode:: sh

   rndc-confgen -a -c docker.key -k docker-key

And then:

.. sourcecode:: sh

   echo 'my base64 key secret' | docker-hostdns --dns-key-name docker-key --dns-key-secret -

Host names
==========

Host name is created by using container name and slugifying & trimming it. So ``/example2::docker`` will result with ``example2-docker``.
In case of name duplication a "-<number>" will be appended, resulting with eg. ``example2-docker-1``

Following dns records are created for each container, given ``example`` hostname and ``docker`` zone:

- IPv4: ``example.docker``
- IPv4: ``*.example.docker``
- IPv6: ``example.docker``
- IPv6: ``*.example.docker``
- TXT: ``_container_<name>.docker`` with container name as value and instance name as ``<name>`` 

TXT record is used for keeping track of added hosts so when app is stopped or resumed it keeps its state. 

Custom host names
*****************

You can set custom host name by using container label ``pl.glorpen.hostname``, its content will be used as container name.

Docker Image
============

Docker image is available at ``glorpen/hostdns``.
For help try ``docker run --rm -it glorpen/hostdns:latest --help``.

Remember to mount ``/run/docker.sock`` inside container.

Securing DNS secret key
***********************

To secure secret key (the ``dns-key-secret`` option) you can:

- passing its contents to env var ``DNS_KEY_SECRET``
- setting env var ``DNS_KEY_SECRET_FILE`` to path of file with secret as its content

Option ``--dns-key-secret -`` will be then automatically prepended and secret key piped to docker-hostdns process.

Working with docker-compose
===========================

When using *docker-compose* for development you can create custom docker network and use it as
domain names source.

To do this, create docker network with ``docker network create example-dns`` and then run *Docker HostDNS* with ``--network example-dns`` argument. 

Next, with example ``docker-compose.yml``:

.. sourcecode:: yaml

   version: '2.2'
   services:
     app:
       image: example
       labels:
         pl.glorpen.hostname: example
       networks:
         default: ~
         dns: ~
   
   networks:
     dns:
       external: true
       name: example-dns

you can start container that would be accessible by host as ``example.docker`` domain.
