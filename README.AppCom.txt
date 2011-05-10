Installations-Empfehlung für AppCom Umgebungen (RedHat 5)

Als root müssen folgende Aktionen vorbereitet werden:
=====================================================

# Als AG-Admin Group wird "w5usrmgr" angenommen!
# Als Application User wird "w5base" angenommen!

# Einrichtung der Service-Kennungen
useradd -m w5base -g daemon -G daemon

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
install -d /apps/w5base/opt/w5base -o w5base -g daemon -m 2770

# Basis Einrichtung der init.d Prozeduren
install -d /cAppCom/init.d/`uname -n` -o root -g w5usrmgr -m 2775
touch /cAppCom/init.d/`uname -n`.sh
chgrp w5usrmgr /cAppCom/init.d/`uname -n`.sh





