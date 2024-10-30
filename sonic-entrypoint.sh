#!/bin/bash -e

# Generate configuration

# NOTE: 'PLATFORM' and 'HWSKU' environment variables are set
# in the Dockerfile so that they persist for the life of the container

ln -sf /usr/share/sonic/device/$PLATFORM /usr/share/sonic/platform
ln -sf /usr/share/sonic/device/$PLATFORM/$HWSKU /usr/share/sonic/hwsku

SWITCH_TYPE=switch

pushd /usr/share/sonic/hwsku

# filter available front panel ports in lanemap.ini
[ -f lanemap.ini.orig ] || cp lanemap.ini lanemap.ini.orig
for p in $(ip link show | grep -oE "eth[0-9]+" | grep -v eth0); do
    grep ^$p: lanemap.ini.orig
done > lanemap.ini

# filter available sonic front panel ports in port_config.ini
[ -f port_config.ini.orig ] || cp port_config.ini port_config.ini.orig
grep ^# port_config.ini.orig > port_config.ini
for lanes in $(awk -F ':' '{print $2}' lanemap.ini); do
    grep -E "\s$lanes\s" port_config.ini.orig
done >> port_config.ini

popd

[ -d /etc/sonic ] || mkdir -p /etc/sonic

# Note: libswsscommon requires a dabase_config file in /var/run/redis/sonic-db/
# Prepare this file before any dependent application, such as sonic-cfggen
mkdir -p /var/run/redis/sonic-db
cp /etc/default/sonic-db/database_config.json /var/run/redis/sonic-db/
# Remove unneeded chassisdb configuration
update_chassisdb_config --delete --json /var/run/redis/sonic-db/database_config.json

SYSTEM_MAC_ADDRESS=$(ip link show eth0 | grep ether | awk '{print $2}')
sonic-cfggen -t /usr/share/sonic/templates/init_cfg.json.j2 -a "{\"system_mac\": \"$SYSTEM_MAC_ADDRESS\", \"switch_type\": \"$SWITCH_TYPE\"}" > /etc/sonic/init_cfg.json

sonic-cfggen -p /usr/share/sonic/hwsku/port_config.ini -k $HWSKU --print-data > /tmp/ports.json
sonic-cfggen -j /tmp/ports.json --preset l1 -y /etc/sonic/custom_setup.yaml > /etc/sonic/config_db.json

sonic-cfggen -t /usr/share/sonic/templates/copp_cfg.j2 > /etc/sonic/copp_cfg.json

mkdir -p /etc/swss/config.d/

rm -f /var/run/rsyslogd.pid

supervisorctl start rsyslogd

supervisorctl start redis-server

/usr/bin/configdb-load.sh

supervisorctl start syncd

supervisorctl start portsyncd

supervisorctl start orchagent

supervisorctl start coppmgrd

supervisorctl start neighsyncd

supervisorctl start fdbsyncd

supervisorctl start fpmsyncd

supervisorctl start vrfmgrd

supervisorctl start portmgrd

supervisorctl start intfmgrd

supervisorctl start vlanmgrd

supervisorctl start zebra

supervisorctl start staticd

supervisorctl start bgpd

supervisorctl start nbrmgrd

supervisorctl start vxlanmgrd

# Start arp_update when VLAN exists
VLAN=`sonic-cfggen -d -v 'VLAN.keys() | join(" ") if VLAN'`
if [ "$VLAN" != "" ]; then
    supervisorctl start arp_update
fi

vtysh --boot
