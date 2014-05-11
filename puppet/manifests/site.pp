#
#
#

group { "puppet": ensure => "present" }

package { "openldap-servers" : ensure => "present" }
package { "openldap-clients" : ensure => "present" }
# package { "migrationtools" : ensure => "present" }
# package { 'dhcp': ensure => "present" }

#
# Prepare for separate logging for LDAP service
#
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

#
# Initialize and start the LDAP service
#
file { "/var/lib/ldap/DB_CONFIG":
  source => "/usr/share/openldap-servers/DB_CONFIG.example",
  require => Package['openldap-servers']
}

service {'slapd':
  ensure => running,
  enable => true,
  require => [Package['openldap-servers'], File['/var/lib/ldap/DB_CONFIG']]
}



#
# Load Cosine schema
#
exec {'Load Core LDAP Schema':
 command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif',
  unless => '/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" dn | grep -q core,cn=schema',  
  require => Service['slapd']
}

exec {'Load Cosine LDAP Schema':
 command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif',
  unless => '/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" dn | grep -q cosine,cn=schema',  
  require => Service['slapd']
}

#exec {'Load NIS LDAP Schema':
# command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif',
#  unless => '/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" dn | grep -q nis,cn=schema',  
#  require => Package['openldap-servers']
#}

exec {'Load Inet Org Person LDAP Schema':
 command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif',
  unless => '/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" dn | grep -q inetorgperson,cn=schema',  
  require => Service['slapd']
}



#
# Set database base DN, root user, password
#
$openldap_basedn = "dc=example,dc=com"
$openldap_rootdn = "cn=Manager,$openldap_basedn"

# changeme
$openldap_rootpw = "{SSHA}B7aqK/ut35c/X9I7SJH8FwEUrQQmQO0d"

ldap::dbvalues {'olcDatabase={2}hdb,cn=config':
  attributes => {
    'olcSuffix' => $openldap_basedn,
    'olcRootDN' => $openldap_rootdn,
    'olcRootPW' => $openldap_rootpw
  }
}

#
# Create top object for the base DN (organization/domain?)
#
ldap::dbobject {'dc=example,dc=com':
  access => {
    'server' => '127.0.0.1',
    'user' => $openldap_rootdn,
    'password' => 'changeme'
  },   
  objectclasses => ['dcObject', 'organization'],
  attributes => {
    'dc' => 'example',
    'o' => 'Example Company Inc.',
    'description' => 'an example company'
  }
}



#
# Create the first DHCP server object
#

#
# Create the DHCP service object
#   set default values

#
# Create a test host entry
#
import 'dhcp.pp'
