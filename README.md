# Metasploit and OpenVAS

Docker image based off Debian Buster with [Metasploit][metasploit] and
[OpenVAS][openvas] installed and configured. The image is compatible
with GNS3 (i.e. it marks database storage locations as volumes for
data persistence).

The image is intended only as a study aid to be used in a lab
environment and thus has had some of the settings for GSA (Greenbone
Security Assistant) weakened. In addition, all accounts are set to
`metasploit`/`metasploit`.

## Usage

First build image:

```bash
git checkout https://github.com/kazkansouh/gns3-metasploit.git
docker build -t metasploit gns3-metasploit
```

The building will take a long time as it include the sync from the
Greenbone community feed. The image will be approx 3GB, thus for this
reason it has not been uploaded to DockerHub.

Then run image:

```bash
docker run -t -i \
  -v /host/path1:/var/lib/redis \
  -v /host/path2:/var/lib/postgresql \
  metasploit
```

Mounting volumes is optional, however it allows for persistent
data. Redis is used by OpenVAS and PostgreSQL is used by Metasploit.

When image starts, it should implicitly start OpenVAS (which can be
accessed by firing web browser to port 80 of container) and PostgreSQL.

To access Metasploit, issue `msfconsole` from the terminal. It should
automatically connect to the PostgreSQL database.

### Updates

If needed, its possible to update the OpenVAS feeds. Execute the
following:

```bash
greenbone-nvt-sync
greenbone-scapdata-sync
openvasmd --rebuild
```

### Other bits

While the image was fine for use in a lab, it would be best to split
out the image into 3 images. I.e. one for [PostgreSQL][postgres], one
for [Metasploit][metasploit-docker] and one for OpenVAS (and possibly
one for [Redis][redis]). At time of writing only OpenVAS does not have
an officially maintained docker image.

Copyright 2019, Karim Kanso. All rights reserved. Released under GPLv3.


[metasploit]: https://www.metasploit.com/ "Metasploit The world’s most used penetration testing framework"
[openvas]: https://www.openvas.org/ "Open Vulnerability Assessment Scanner"
[postgres]: https://hub.docker.com/_/postgres "DockerHub.com: postgres"
[metasploit-docker]: https://hub.docker.com/r/metasploitframework/metasploit-framework "DockerHub.com: metasploit-framework"
[redis]: https://hub.docker.com/_/redis "DockerHub.com: redis"
