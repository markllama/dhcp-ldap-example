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