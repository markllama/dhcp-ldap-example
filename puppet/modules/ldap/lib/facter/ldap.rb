#
# Custom facts for openldap on RPM based systems
# 
require 'facter'

ldap_cmd = 'ldapsearch -Q -Y EXTERNAL -LLL -H ldapi:/// -b cn=config'

Facter.add("ldapdb") do
  setcode do
    ldapdb = nil
    input = Facter::Util::Resolution.exec("#{ldap_cmd} olcDatabase=* dn").split("\n\n")

    input.each do |line|
      (dummy, dn) = line.split
      m = dn.match(/^olcDatabase=(.*),cn=config$/)

      ldapdb = m[1] if m and m[1].end_with? "hdb"
    end
    ldapdb
  end
end

Facter.add("basedn") do
  ldapdb = Facter.value('ldapdb')
  basedn = nil
  setcode do
    input = Facter::Util::Resolution.exec("#{ldap_cmd} olcDatabase=#{ldapdb} olcSuffix").split("\n")
    input.each do |line|
      (key, value) = line.split
      basedn = value if key.start_with? "olcSuffix:"
    end
    basedn
  end
end


Facter.add("rootdn") do
  ldapdb = Facter.value('ldapdb')
  rootdn = nil
  setcode do
    input = Facter::Util::Resolution.exec("#{ldap_cmd} olcDatabase=#{ldapdb} olcRootDN").split("\n")
    input.each do |line|
      (key, value) = line.split
      rootdn = value if key.start_with? "olcRootDN"
    end
    rootdn
  end
end

Facter.add("rootpw") do
  ldapdb = Facter.value('ldapdb')
  rootpw = nil
  setcode do
    input = Facter::Util::Resolution.exec("#{ldap_cmd} olcDatabase=#{ldapdb} olcRootPW").split("\n")
    input.each do |line|
      (key, value) = line.split
      rootpw = value if key.start_with? "olcRootPW"
    end
    rootpw
  end
end
