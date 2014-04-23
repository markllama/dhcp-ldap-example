#
# Configure a DHCP server
#

package {dhcp:
  ensure => present
}

service {dhcpd:
  require => Package[dhcp] 

}

package {rsyslog:
  ensure => present
}

service {rsyslog:
  enable => true,
  require => Package[rsyslog]
}

file {'/var/log/dhcpd.log':
  ensure => present
}


file {'/etc/rsyslog.d/10-dhcpd.conf':
  ensure => present,
  content => 'if $programname == "dhcpd" then /var/log/dhcpd.log
',
  require => [Package[rsyslog], File['/var/log/dhcpd.log']]
}

file {'/etc/dhcp/dhcpd.conf':
  content => '# LDAP backed DHCP config
ldap-server "127.0.0.1" ;
ldap-port 389 ;
ldap-base-dn "dc=example,dc=com" ;
ldap-dhcp-server-cn "dhcp-host" ;
ldap-method dynamic ;
ldap-debug-file "/var/log/dhcp-ldap-startup.log" ;
ldap-username "cn=Manager,dc=example,dc=com" ;
ldap-password "changeme" ;
',
  ensure => present
}

file {'/var/log/dhcp-ldap-startup.log':
  ensure => present
}

#
# Convert DHCP schema to LDIF
#
file { '/etc/openldap/schema/dhcp.schema':
  ensure => present,
  require => Package['dhcp']
}

# slapcat can convert configurations to LDIF format and print them
# Load the DHCP schema and write it in LDIF format
# then clean up
exec { 'Convert DHCP schema to LDIF':
  
  command => "/usr/bin/echo 'include /etc/openldap/schema/dhcp.schema' > /tmp/slapd.conf-dhcp ; \
mkdir -p /tmp/ldif_output ; \
slapcat -f /tmp/slapd.conf-dhcp -F /tmp/ldif_output -n0 -H ldap:///cn={0}dhcp,cn=schema,cn=config -l /etc/openldap/schema/dhcp.ldif ; \
sed -i -e '/CRC32/d ; s/{0}dhcp/dhcp/ ; /structuralObjectClass/,\$d' /etc/openldap/schema/dhcp.ldif; \
rm -rf /tmp/ldif_output ; \
rm /tmp/slapd.conf-dhcp ;
  ",
  creates => '/etc/openldap/schema/dhcp.ldif',
  require => File['/etc/openldap/schema/dhcp.schema']
}

file {'/etc/openldap/schema/dhcp.ldif':
  require => Exec['Convert DHCP schema to LDIF']
}

#
# Load DHCP schema
#
exec {'Load DHCP LDAP Schema':
  command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/dhcp.ldif',
  unless => "/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b 'cn=schema,cn=config' dn | grep -q dhcp,cn=schema",
  require => File['/etc/openldap/schema/dhcp.ldif']
}
