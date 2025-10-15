#!/bin/bash
##########################################################################
# W5MailSpool.sh ist the 1st line mailprocessor, for all mail            #
# incomming mails to the w5base system.                                  #
# It is desinged to work in /etc/aliases f.e.                            #
# postmaster: "|/opt/w5base/sbin/W5MailSpool.sh /var/spool/w5base-mail"  #
#                                                                        #
# The 1st parameter is the spool directory, which should have normaly    #
# created by ...                                                         #
#                                                                        #
# install -d -o nobody -g w5base -m 2770 /var/spool/w5base-mail          #
#                                                                        #
# ... if postfix (or your smtp mail agent) runs commands as user nobody  #
# and your w5base W5Server runs with group "w5base".                     #
#                                                                        #
##########################################################################

SPOOLDIR="/var/spool/w5mail"
if [ ! -z "$1" -a -d "$1" ]; then
   SPOOLDIR="$1"
fi
mkdir -p "$SPOOLDIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S_%N")
EMLFILE="$SPOOLDIR/mail_$TIMESTAMP.eml"
TMPFILE="$SPOOLDIR/mail_$TIMESTAMP.tmp"
cat > "$TMPFILE"  && mv "$TMPFILE" "$EMLFILE"
chmod 660 "$EMLFILE"


