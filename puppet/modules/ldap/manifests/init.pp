#
# Initialize an LDAP database
#

class ldap(
  $configdn = 'cn=config'
 ){

  # package

  # service
  
}

class ldap::schema(
  $name,
  $convert = false
 ) {

 }
  
class ldap::database(
  $configdn = 'cn=config',
  $basedn = 'dc=example,dc=com',
  $rootdn = 'cn=Manager',
  $rootpw = 'UNSET'
){

  $real_rootdn = "${rootdn},${basedn}"
  notify {"rootdn = ${real_rootdn}": }

  # set basedn
  notify {"ldapdb = ${::ldapdb}":}

  # set rootdn

  dbvalue {"olcSuffix: dc=example,dc=com":
    dn => "olcDataBase=${::lapdb},cn=config"
  }

  dbvalue {"olcRootDN: cn=Manager,dc=example,dc=com":
    dn => "olcDataBase=${::lapdb},cn=config"
  }

  dbvalue {"olcRootPW: {SSHA}xvlUQEdtQvMpYzHTBbPZHxihme50BVTc":
    dn => "olcDataBase=${::lapdb},cn=config"
  }

}

define dbvalue(
  $dn
) {
  notify {"setting db value ${name} on ${dn}":}

  $parts = split($name, ": ")
  $key = $parts[0]
  $value = $parts[1]

  exec {"set ${name} on ${dn}":
    command => "/usr/bin/cat <<EOF | /usr/bin/sudo /usr/bin/ldapmodify -Q -Y EXTERNAL -H ldapi:///
dn: olcDatabase=${::ldapdb},cn=config
changetype: modify
replace: $key
$name
EOF
",
    unless => "/usr/bin/sudo /usr/bin/ldapsearch -Q -Y EXTERNAL -H ldapi:/// -LLL -b cn=config olcDatabase=${::ldapdb} olcSuffix | grep $key | cut -d' ' -f2 | grep -q -e '^${value}\$'
"
  }
}
