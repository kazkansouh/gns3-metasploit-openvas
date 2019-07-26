# Copyright (C) 2019 Karim Kanso. All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

FROM debian:buster

## Approx 1GB
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -qq -y install openvas psmisc curl openssh-client net-tools && \
        rm -rf /var/lib/apt/lists/*

## Performs full sync to community feeds (at least 1.5GB I think)
RUN openvasmd --create-user metasploit --password metasploit && \
        greenbone-nvt-sync && \
        greenbone-scapdata-sync && \
        greenbone-certdata-sync && \
        echo "DAEMON_ARGS=/etc/redis/redis-openvas.conf" >> /etc/default/redis-server && \
        mkdir -p /var/run/redis-openvas && \
        chown redis:redis /var/run/redis-openvas

RUN     service openvas-manager start && \
        service redis-server start && \
        service openvas-scanner start && \
        openvasmd --rebuild && \
        service openvas-scanner stop && \
        service redis-server stop && \
        service openvas-manager stop && \
        sed -i -E 's/^(GSA_ADDRESS=).*/\10.0.0.0/' /etc/default/greenbone-security-assistant && \
        sed -i -E 's/"(--listen=\$GSA_ADDRESS)"/"$DAEMONOPTS \1"/' /etc/init.d/greenbone-security-assistant && \
        echo 'DAEMONOPTS=$(for ip in $(hostname -I) $(hostname -s) ; do echo -n "--allow-header-host $ip " ; done)' >> /etc/default/greenbone-security-assistant

## Approx 0.5GB
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -qq -y install postgresql less ruby-bundler thin vim && \
        curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
        chmod 755 msfinstall && \
        ./msfinstall && \
        rm msfinstall && \
        rm -rf /var/lib/apt/lists/* && \
        service postgresql start && \
        ( \
          echo "CREATE USER metasploit PASSWORD 'metasploit';" ; \
          echo "CREATE DATABASE metasploit OWNER metasploit;") | \
        su postgres -c psql && \
        service postgresql stop && \
        ( \
          echo "development: &pgsql" ; \
          echo "  adapter: postgresql" ; \
          echo "  database: metasploit" ; \
          echo "  username: metasploit" ; \
          echo "  password: metasploit" ; \
          echo "  host: localhost" ; \
          echo "  port: 5432" ; \
          echo "  pool: 200" ; \
          echo "  timeout: 5" ; \
          echo "production: &production" ; \
          echo "  <<: *pgsql") \
        > /opt/metasploit-framework/embedded/framework/config/database.yml

# for gsa
EXPOSE 80/tcp
EXPOSE 9392/tcp

# Entrypoint starts up services
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]

VOLUME ["/var/lib/redis", "/var/lib/postgresql"]
