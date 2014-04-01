#
#
#

group { "puppet": ensure => "present" }

package { "openldap-servers" : ensure => "present" }
package { "openldap-clients" : ensure => "present" }
#  package { "migrationtools" : ensure => "present" }
package { 'dhcp': ensure => "present" }

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
# Load Cosine schema
#
exec {'Load Cosine LDAP Schema':
  command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif',
  unless => '/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" dn | grep -q cosine,cn=schema',  
  require => Package['openldap-servers']
}


#
# Load DHCP schema
#
exec {'Load DHCP LDAP Schema':
  command => '/usr/bin/sudo /usr/bin/ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/dhcp.ldif',
  unless => "/usr/bin/sudo /usr/bin/ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b 'cn=schema,cn=config' dn | grep -q dhcp,cn=schema",
  require => File['/etc/openldap/schema/dhcp.ldif']
}

#
# Set database base DN, root user, password
#
$openldap_basedn = "dc=example,dc=com"
$openldap_rootdn = "cn=Manager,$basedn"

# changeme
$openldap_rootpw = "{SSHA}B7aqK/ut35c/X9I7SJH8FwEUrQQmQO0d"

#
# Create top object for the base DN (organization/domain?)
#

ldap::dbobject {'dc=example,dc=com':
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

