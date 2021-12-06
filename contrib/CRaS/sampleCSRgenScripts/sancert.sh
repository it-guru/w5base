#!/bin/bash
export OPENSSL_CONF=$(mktemp)
cat << EOF > $OPENSSL_CONF
[ req ]
prompt = no
default_bits		= 3072
distinguished_name	= req_distinguished_name
attributes		= req_attributes
utf8			= yes
string_mask             = utf8only


# The extensions to add to a certificate request - see [ v3_req ]
req_extensions		= v3_req

[ req_distinguished_name ]
# Describe the Subject (ie the origanisation).
# The first 6 below could be shortened to: C ST L O OU CN
# The short names are what are shown when the certificate is displayed.
# Eg the details below would be shown as:
#    Subject: C=UK, ST=Hertfordshire, L=My Town, O=Some Organisation, OU=Some Department, CN=www.example.com/emailAddress=bofh@example.com

# Leave as long names as it helps documentation

countryName_default=		DE
stateOrProvinceName_default=	Nordrhein-Westfalen
localityName_default=		Bonn
organizationName_default=	Deutsche Telekom IT GmbH
organizationalUnitName_default=	DH DTIT
commonName_default=		*.fassbrause.telekom.de
emailAddress_default=		xxo@telekom.de
countryName=		DE
stateOrProvinceName=	Nordrhein-Westfalen
localityName=		Bonn
organizationName=	Deutsche Telekom IT GmbH
organizationalUnitName=	DH DTIT
commonName=		*.fassbrause.telekom.de
emailAddress=		xxo@telekom.de

[ req_attributes ]
# None. Could put Challenge Passwords, don't want them, leave empty

[ v3_req ]

# X509v3 extensions to add to a certificate request
# See x509v3_config

# What the key can/cannot be used for:
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth,serverAuth

# The subjectAltName is where you give the names of extra web sites.
# You may have more than one of these, so put in the section [ alt_names ]
# If you do not have any extra names, comment the next line out.
subjectAltName = @alt_names

# List of all the other DNS names that the certificate should work for.
# alt_names is a name of my own invention
[ alt_names ]
DNS.1 = devel.ocean.de
DNS.2 = ipv6.ocean.de
DNS.3 = ipv4.ocean.de
DNS.4 = test.ocean.de
DNS.5 = party.ocean.de


















#[CERT]
#C = DE
#L = Bamberg
#ST = Bavaria
#O = Deutsche Telekom IT GmbH
#OU = Org Unit Name
#CN = world.in.baunach.central.de
#emailAddress = it@guru.de
EOF
openssl req -newkey rsa:3072 -keyout sanserverPrivate.key \
            -nodes -out sanServerCSR.pem
rm -f $OPENSSL_CONF 2>/dev/null
