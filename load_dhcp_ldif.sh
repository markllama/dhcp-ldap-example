#!/bin/sh
sudo systemctl restart rsyslog
sudo cp dhcpd.conf /etc/dhcp

CMD="ldapadd -x -w changeme -D cn=Manager,dc=example,dc=com"

$CMD -f LDIF/dhcp-host.ldif
$CMD -f LDIF/dhcp-service.ldif
$CMD -f LDIF/dhcp-subnet-10.0.2.0.ldif
$CMD -f LDIF/dhcp-host-testhost.ldif

sudo systemctl start dhcpd
sudo systemctl enable dhcpd
