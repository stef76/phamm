#!/usr/bin/perl -T -w
#
# Connect to LDAP Server and extract a list of
# postgrey whitelist mail recipients
#
# Phamm - http://www.phamm.org - <team@phamm.org>
# Copyright (C) 2009 Alessandro De Zorzi
#
# This file is part of Phamm.
#  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Example LDIF
# bypassGreyListing: TRUE

use Data::Dumper;
use Net::LDAP;

# File dove sono scritti uno per riga i destinatari e domini
open(FILE_OUTPUT,'>/tmp/whitelist_recipients') or die "Can't open file";

print FILE_OUTPUT "# postgrey whitelist for mail recipients\n";
print FILE_OUTPUT "# --------------------------------------\n";
print FILE_OUTPUT "# Generated by read_recipients_whitelists_ldap.pl\n";
print FILE_OUTPUT "postmaster@\n";
print FILE_OUTPUT "abuse@\n";

$ldap = Net::LDAP->new ( "127.0.0.1" ) or die "$@";

$mesg = $ldap->bind( 'cn=admin,dc=example,dc=tld',
                     password => 'secret');

$mesg = $ldap->search(base   => "o=hosting,dc=example,dc=tld",
                      filter => "(&(bypassGreyListing=TRUE)(objectClass=VirtualDomain))",
                      attrs=> ['vd']
                     );

$mesg->code && die $mesg->error;

foreach $entry ($mesg->entries)
{
    $domain = $entry->get_value("vd");
    push(@whitelist, $domain);
}

$mesg = $ldap->search(base   => "o=hosting,dc=example,dc=tld",
                      filter => "(&(bypassGreyListing=TRUE)(|(objectClass=VirtualMailAlias)(objectClass=VirtualMailAccount)))",
                      attrs=> ['mail']
                     );

$mesg->code && die $mesg->error;

foreach $entry ($mesg->entries)
{
    $mail = $entry->get_value("mail");
    push(@whitelist, $mail);
}

# Scrive uno per riga i risultati sul file di output
foreach $entry(@whitelist)
{
    print FILE_OUTPUT $entry."\n";
}

close(FILE_OUTPUT);

exit;
