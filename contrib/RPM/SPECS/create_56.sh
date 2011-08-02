#!/bin/bash


ls *RH55*spec | while read SPEC
do
	SPEC_56=$( echo $SPEC | sed "s/RH55/RH56/g" )
	if [[ ! -f $SPEC_56 ]]
	then
		cp $SPEC $SPEC_56
		sed "s/RH55/RH56/g" -i $SPEC_56
		sed "s/RedHat 5\.5 AppCom Linux/RedHat 5\.6 AppCom Linux/g" -i $SPEC_56
	fi
done

LIST="apps-perlmod-Module-Build
apps-perlmod-ExtUtils-CBuilder
apps-perlmod-version
apps-perlmod-SOAP-Lite
apps-perlmod-Object-MultiType
apps-perlmod-IPC-Smart
apps-perlmod-XML-Smart
W5Base-apache
W5Base-apache
W5Base-init
apps-perlmod-Attribute-Handlers
apps-perlmod-Class-Load
apps-perlmod-Class-Singleton
apps-perlmod-Crypt-DES
apps-perlmod-Crypt-RC4
apps-perlmod-DTP
apps-perlmod-Data-HexDump
apps-perlmod-DateTime-Locale
apps-perlmod-DateTime
apps-perlmod-DateTime-Set
apps-perlmod-DateTime-TimeZone
apps-perlmod-Digest-Perl-MD5
apps-perlmod-Env-C
apps-perlmod-File-Temp
apps-perlmod-GD
apps-perlmod-IO-Multiplex
apps-perlmod-IO-stringy
apps-perlmod-JSON
apps-perlmod-List-MoreUtils
apps-perlmod-MIME-Base64
apps-perlmod-MIME-tools
apps-perlmod-MailTools
apps-perlmod-Net-Server
apps-perlmod-Net-UCP
apps-perlmod-NetAddr-IP
apps-perlmod-OLE-Storage_Lite
apps-perlmod-Params-Validate
apps-perlmod-Parse-RecDescent
apps-perlmod-RPC-Smart
apps-perlmod-SC-API
apps-perlmod-Set-Infinite
apps-perlmod-Spreadsheet-ParseExcel
apps-perlmod-Spreadsheet-WriteExcel
apps-perlmod-Sub-Uplevel
apps-perlmod-Task-Weaken
apps-perlmod-Test-Exception
apps-perlmod-Test-Pod
apps-perlmod-Test-Simple
apps-perlmod-TimeDate
apps-perlmod-Unicode-Map8
apps-perlmod-Unicode-String
apps-perlmod-constant"
# apps-perlmod-DBD-Oracle
LIST="apps-perlmod-Spreadsheet-ParseExcel"

for MOD in $LIST
do
	echo $MOD
        if [ ! -f ../RPMS/x86_64/$MOD-RH56-*.rpm ];then
	   rpmbuild -ba ${MOD}-RH56*.spec
        fi
	if [ $? -ne 0 ]; then
           exit 1
        fi
done
