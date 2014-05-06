#!/bin/sh

CMD="ldapadd -x -w changeme -D cn=Manager,dc=example,dc=com"

$CMD -f LDIF/dhcp-host.ldif
$CMD -f LDIF/dhcp-service.ldif
$CMD -f LDIF/dhcp-subnet-10.0.2.0.ldif
