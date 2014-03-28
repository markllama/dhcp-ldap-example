
node default {
  group { "puppet": ensure => "present" }

  package { "openldap-servers" : ensure => "present" }
  package { "openldap-clients" : ensure => "present" }
  package { "migrationtools" : ensure => "present" }
  package { 'dhcp': ensure => "present" }

  package { 'rsyslog': ensure => "present" } 

  file {'/etc/rsyslog.d/slapd.conf':
    ensure => present,
    content => 'if $programname == "slapd" then /var/log/slapd.log',
    require => Package['rsyslog']
  }

  file {'/var/log/slapd.log':
    ensure => present,
    content => '',
    require => Package['rsyslog']
  }

  service {'rsyslog':
    enable => true,
    ensure => running,
    require => File['/etc/rsyslog.d/slapd.conf',
                    '/var/log/slapd.log']
  }

}
