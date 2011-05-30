Installations-Empfehlung für AppCom Umgebungen (RedHat 5)

Generell ist zu empfehlen, dass die Standard LANG Umgebung für ALLE
User auf en_GB.iso885915 eingestellt wird. Dies gilt auch (und 
insbesondere) für den root!


Als root müssen folgende Aktionen vorbereitet werden:
=====================================================

# Als AG-Admin Group wird "w5usrmgr" angenommen!
# Als Application User wird "w5base" angenommen!

# Einrichtung der Service-Kennungen
groupadd w5base
useradd -m w5base -g w5base -G w5base,daemon
groupadd apache
useradd -m apache -g apache -G w5base,daemon

# Erstellung der /etc/profile.local
touch /etc/profile.local
chgrp w5usrmgr /etc/profile.local   
chmod 775 /etc/profile.local

# Einbindung der /etc/profile.local
rm /etc/profile
cp /.etc/profile /etc/profile
echo 'test -s /etc/profile.local && . /etc/profile.local' >> /etc/profile

# Oracle-Umgebung vorbereiten
mkdir /etc/oracle
chgrp w5usrmgr /etc/oracle         
chmod 2775 /etc/oracle

# Basis Einrichtung von /apps
install -d /apps/pkg -o root -g w5usrmgr -m 2775
install -d /apps/rpm -o root -g root -m 755
install -d /apps/bin -o root -g root -m 755
install -d /apps/etc -o root -g w5usrmgr -m 2775
install -d /apps/tmp -o root -g root -m 4777
install -d /apps/w5base/opt/w5base -o w5base -g daemon -m 2770

# Entfernen der default motd und link nach /apps/etc/motd
rm /etc/motd
cp /etc/ssh/sshd_banner /apps/etc/motd
ln -sf /apps/etc/motd /etc/motd

# Entfernen der sshd Banner Option
sed 's/^Banner/#Banner/g' -i /etc/ssh/sshd_config
/etc/init.d/sshd restart

# Basis Einrichtung der init.d Prozeduren
install -d /cAppCom/init.d/`uname -n` -o root -g w5usrmgr -m 2775
touch /cAppCom/init.d/`uname -n`.sh
chgrp w5usrmgr /cAppCom/init.d/`uname -n`.sh

# Sicherstellen das folgende sudo Einträge (ALL=AppCom Systeme) 
# vorhanden sind:
%w5usrmgr       ALL=NOPASSWD:/bin/cat *
%w5usrmgr       ALL=NOPASSWD:/bin/ls *
%w5usrmgr       ALL=NOPASSWD:/usr/bin/test *
%w5usrmgr       ALL=NOPASSWD:/usr/bin/tail *
%w5usrmgr       ALL=NOPASSWD:/bin/rpm --dbpath /apps/rpm *
%w5usrmgr       ALL=NOPASSWD:/cAppCom/init.d/*.sh *
%w5usrmgr       ALL=(mysql)  NOPASSWD:ALL
%w5usrmgr       ALL=(w5base) NOPASSWD:ALL
%w5base         ALL=NOPASSWD:/etc/init.d/w5base *
%w5base         ALL=NOPASSWD:/etc/init.d/apache2 *
%w5base         ALL=NOPASSWD:/etc/init.d/httpd *
%w5base         ALL=NOPASSWD:/etc/init.d/acache *
%w5base         ALL=NOPASSWD:/usr/bin/killall -9 apache2
%w5base         ALL=NOPASSWD:/usr/bin/killall -HUP apache2
%w5base         ALL=NOPASSWD:/usr/bin/killall -USR1 apache2
%w5base         ALL=NOPASSWD:/usr/bin/killall -9 httpd
%w5base         ALL=NOPASSWD:/usr/bin/killall -HUP httpd
%w5base         ALL=NOPASSWD:/usr/bin/killall -USR1 httpd

------

Nach diesen Einrichtungen kann nun mit "normalen" Userrechten die 
komplette Anwendung eingerichtet, aktualisiert, betreut und betrieben
werden.

Step 1: Anmelden als Application-User (d.h. als w5base oder falls es sich
um eine Entwicklungsumgebung handelt, eben als User, der die Entwicklung
durchführen soll)

# init der rpm Datenbank
sudo rpm --dbpath /apps/rpm --initdb

# Checkout der Applikation
cd /apps/w5base/opt
svn co https://w5base.svn.sourceforge.net/svnroot/w5base/HEAD w5base

# Ab diesem Zeitpunkt stehen unter /apps/w5base/opt/w5base/contrib/RPM/SPECS
# die notwendigen *.spec Dateien zur Verfügung, die als zusätzliche 
# Binaries mittels "sudo rpm --dbpath /apps/rpm ..." auf dem System 
# eingespielt werden müssen.






