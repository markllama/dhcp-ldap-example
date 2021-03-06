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

  dbobject {"dc=example,dc=com":
    objectclasses => ['dcObject', 'organization'],
    attributes => {
      'dc' => 'example',
      'o' => 'Example Company',
      'description' => 'a company that is just stuff'
    }
  }
}

define ldap::dbvalue(
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


# echo <<EOF | sudo ldapadd -Q -Y EXTERNAL -H ldapi:///
# dn: dc=example,dc=com
# objectClass: dcObject
# objectClass: organization
# cn: example
# o: Example Company Inc.
# description: An example company
#
#
# dbobject {"dc=example:dc=com":
#   objectClasses => ['dcObject', 'organization'],
#   attributes => {
#     'cn' => 'example',
#     'o' => 'Example Company Inc.',
#     'description' => 'An Example Company'
#   }
#}




define ldap::dbobject(
  $access = {},
  $objectclasses = [],
  $attributes = {}
){

  $template = "dn: <%= @name %>
<%= @objectclasses.map {|c| \"objectClass: #{c}\" }.join(\"\n\") %>
<%= @attributes.map {|k,v| \"#{k}: #{v}\" }.join(\"\n\") %>
"

  $contents = inline_template($template)

  exec {"add object ${name}":
    command => "/usr/bin/echo \"${contents}\" | /usr/bin/sudo /usr/bin/ldapadd -x -w ${access['password']} -D ${access['user']} -H ldap://${access['server']}",
    unless => "/usr/bin/sudo /usr/bin/ldapsearch -w ${access['password']} -D ${access['user']} -LLL -H ldap:// ${access['server']} -b ${name} dn > /dev/null"
  }
}


define ldap::dbvalues(
  $attributes = {}
){

  $template = "dn: <%= @name %>
changetype: modify
<%= @attributes.map {|k,v| \"replace: #{k}\n#{k}: #{v}\n\" }.join(\"-\n\") %>
"

  $contents = inline_template($template)

  exec {"set object attributes on ${name}":
    command => "/usr/bin/echo \"${contents}\" | /usr/bin/sudo /usr/bin/ldapmodify -Q -Y EXTERNAL -H ldapi:///"
  }
}
