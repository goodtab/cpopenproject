---
sidebar_navigation:
  title: System requirements
  priority: 1000
---

# System requirements

__Note__: The configurations described below are what we use and test against.
This means that other configurations might also work but we do not
provide any official support for them.

## Server

The server hardware requirements should be roughly the same for both the packaged installation and docker (both all-in-one container and compose).

### Minimum Hardware Requirements

* __CPU:__ Quad Core CPU (>= 2ghz)
* __Memory:__ 4096 MB
* __Free disk space:__ 20 GB

This is for a single server running OpenProject for up to 200 total users. Depending on your number of concurrent users,  these requirements might vary drastically.

## Scaling Requirements

Generally speaking you will need more CPUs (the faster the better) and more RAM with an increasing number of users.
Technically this only really depends on the number of concurrent users. No matter if you have 1000 or only 100 total users, if there only ever 20 users working at the same time, the CPU & RAM required will be the same.
Still, the total number of users is a good general indicator of how much resources you will need.

It's not enough to simply have more resources available, however. You will have to make use of them too.
By default OpenProject has 4 so called web workers and 1 background worker. Web workers are handling the HTTP requests while backend workers are doing offloaded tasks such as sending emails or performing resource-intensive tasks of unknown duration, e.g. copying or deleting resources.
If there are more users you will need more web workers and eventually also more background workers.

The database will need resources as well, and this, too, will increase with the number of users.
There may come a point where you will have to make configuration changes to the database and/or use an external database, but for most cases the default database setup should be enough. You will ideally want to have the database on a performant storage such as SSDs. [There are also other excellent resources](https://wiki.postgresql.org/wiki/Performance_Optimization) for tuning PostgreSQL database performance.

Using a rough estimate we can give the following recommendations based on the number of total active users.

| Total active users | CPU cores | RAM in GB | web workers | background workers | disk space in GB |
| ------------------ | --------- | --------- | ----------- | ------------------ | ---------------- |
| <=200              | 4         | 4         | 2           | 1                  | 20               |
| 500                | 8         | 8         | 4           | 2                  | 40               |
| 1500               | 16        | 16        | 8          | 4                  | 80               |

Mind, even just for 5 users we do recommend 2 web workers as each page may require
multiple requests to be made simultaneously. Having just one will work, but pages may take longer to finish loading.

These numbers are a guideline only and your mileage may vary.
It's best to monitor your server and its resource usage. You can always allocate more resources if needed.

### **Scaling horizontally**

At some point simply increasing the resources of one single server may not be enough anymore.

OpenProject needs to scale in three different dimensions:

- Sizing of CPU & RAM, Storage, and Availability (e.g., available number of connections) in the PostgreSQL database
- Number of web application workers and their multithreading parameters for request queues and parallel request execution
- Number of background workers and their multithreading parameters for sending out emails, creating exports, or performing bulk operations (copying work packages, projects, etc.)

In the _packaged installation_ you can have multiple servers running OpenProject. They will need to share an external database, memcached and file storage (e.g. via NFS), however.

> [!NOTE]
>
> We recommend to run OpenProject in a [Kubernetes deployment using our Helm charts](../installation/helm-chart), or in smaller environments, [docker compose](../installation/docker-compose) or [docker Swarm](../installation/docker/#docker-swarm). Kubernetes and Docker swarm are fully horizontally scalable

[For more information on applying scaling options depending on your installation method, please see this document](../operation/scaling/).


### Scaling parameters

Extrapolating the general system requirements for different sets of users, you will roughly need these scaling parameters. These information correlate with our SaaS infrastructure, so we assume current or last-generation CPUs and architecture. Assume higher values accordingly for older generations.

- **Database**: 2 CPU / 8 GiB RAM per ~500 Users
- **CPU**: 4-6 CPU per ~500 users
- **RAM**: 6-8 GiB per ~500 users
- **Web Workers**: +4 per ~500 users
- **Background Workers**: +1-2 multithreaded workers per ~500 users, depending on workload
- **Disk Space**: +20-50 GiB per ~500 users, depending on workload and attachment storage

These values are **guidelines** and should be adjusted based on actual monitoring of resource usage. Scaling should prioritize **CPU and RAM, prioritize scaling Web Workers** first, followed by **Background Workers and Disk Space** as needed.

## Example Configurations

### **Small Instance (≤ 200 users, low concurrent activity)**

- **Database**: 2 CPU / 4 GiB RAM

- **CPU**: 2 CPU

- **RAM**: 4 GB

- **Web Workers**:  2 Workers, each with 4 threads

- **Background Workers**: 1 multithreaded worker with 4GiB RAM (more RAM possibly required for larger exports)

- **Disk Space**: 20 GB + additional disk space in case of internal attachment storage

### **Medium Instance (~500 users, moderate concurrent activity)**

- **Database**: 2-4 CPU / 8 GiB RAM
- **CPU**: 4 CPU
- **RAM**: 8 GB
-  **Web Workers**: 4 Workers, each with 4-8 threads
  •
- **Background Workers**: 2 multithreaded workers with 4-6 GiB RAM
- **Disk Space**: 50 GB + additional disk space in case of internal attachment storage

### **Large Instance (~1500 users, medium to high concurrent activity)**

- **Database**: 4-8 CPU / 16 GiB RAM
- **CPU**: 8 CPU
- **RAM**: 16-24 GB
- **Web Workers**: 6-8 Workers, each with 8-32 threads
- **Background Workers**: 4-8 multithreaded workers with 4-6GiB RAM, depending on workload
- **Disk Space**: 100 GB + additional disk space in case of internal attachment storage

### **Enterprise-scale multitenancy instance (~80K - 100K users, high concurrent activity)**

- **Database**: Cluster of two 8 vCPU / 32 GiB RAM (e.g., AWS db.m7g.xlarge, Gravitron 3)
- **Worker instances**: 2-4 instances of the following
  - **CPU**: 8 CPU (e.g., AWS r7a.xlarge instances)
  - **RAM**: 32GB

- **Web Workers**: 8 - 12 Workers, each with 8-32 threads and 6GiB available RAM
- **Background Workers**: 8 multithreaded workers with 4-6GiB RAM, depending on workload
- **Disk Space**: 250 GB + additional disk space in case of internal attachment storage



### Additional Scaling Recommendations

**Monitor Resource Usage**

You can [use our health checks to monitor the background job queue](../operation/monitoring/#health-checks). If the `worker_backed_up` check fails you may want to scale up the number of background workers.

For everything else a general monitoring solution for your servers is recommended.
Be it cloud-platform solutions like CloudWatch (AWS), or your own setup using open-source tools
such as Prometheus and Grafana.

Adjust CPU, RAM, and disk space as needed.

**Database Scaling**

Consider external PostgreSQL with performance tuning.

**Load Balancing**

For high-availability setups, distribute traffic across multiple servers and availability regions.



## Host Operating system

The [package-based installation](../installation/packaged) requires one of the following Linux distributions:

| Distribution (__64 bits only__) |
| ------------------------------- |
| Ubuntu 22.04 Jammy              |
| Ubuntu 20.04 Focal              |
| Debian 12 Bookworm              |
| Debian 11 Bullseye              |
| CentOS/RHEL 9.x                 |
| Suse Linux Enterprise Server 15 |

The [docker-based installation](../installation/docker) requires a system with Docker installed. Please see the [official Docker page](https://docs.docker.com/install/) for the list of supported systems.

**Please note**, that we only provide packages for the __AMD64__ (x86) architecture. We do provide *docker containers* for both __ARM64__ and __AMD64__.

### Overview of dependencies

Both the package and docker based installations will install and setup the following dependencies that are required by OpenProject to run:

* __Runtime:__ [Ruby](https://www.ruby-lang.org/en/) Version = 3.3.x
* __Webserver:__ [Apache](https://httpd.apache.org/)
  or [nginx](https://nginx.org/en/docs/)
* __Application server:__ [Puma](https://puma.io/)
* __Database__: [PostgreSQL](https://www.postgresql.org/) Version >= 13

Starting in OpenProject 12.0, PostgreSQL 13.0 will be a minimum requirement.
PostgreSQL versions 9.6. and up will continue to work, but may result in incompatibilities and degraded performance in the future. We have a [migration guide on how to upgrade to PostgreSQL 13](../../installation-and-operations/misc/migration-to-postgresql13/).

## Client

OpenProject supports the latest versions of the major browsers.

* [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/products/) (at least ESR version 102)
* [Microsoft Edge](https://www.microsoft.com/de-de/windows/microsoft-edge) (only MS Edge version based on Chromium is supported)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/)
* [Apple Safari](https://www.apple.com/safari/)

## Frequently asked questions (FAQ)

### Can I run OpenProject on Windows?

At the moment this is not officially supported, although the docker image might work. Check above regarding the system requirements.
