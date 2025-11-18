#!/bin/bash
echo "$(date '+%Y-%m-%d %H:%M:%S,%3N') INFO pre config /bin/init.sh"

if [ -f /etc/profile.local ]; then
   chown root:root /etc/profile.local
   chmod +x /etc/profile.local
   ln -sf /etc/profile.local /etc/profile.d/profile.local.sh
   . /etc/profile.local
fi
if [ -z "$W5BRANCH" ]; then
   W5BRANCH="prod"
fi
if ! getent group w5base > /dev/null 2>&1; then
   groupadd -g 2000 w5base
fi
if ! getent group w5adm > /dev/null 2>&1; then
   groupadd -g 2002 w5adm
fi
if ! getent passwd w5base > /dev/null 2>&1; then
   useradd -m -u 2000 -g 2000 -G w5base w5base
fi
if ! getent passwd w5adm > /dev/null 2>&1; then
   useradd -m -u 2002 -g 2002 -G w5base,w5adm w5adm
fi

chown w5base:w5adm /opt/w5*
chmod 2575 /opt/w5*

su w5adm -c "git config --global --add safe.directory /opt/w5base"
su w5base -c "git config --global --add safe.directory /opt/w5base"

if [ ! -d /opt/w5base/.git ]; then
   if [ -d '/opt/w5base/lost+found' ]; then
      rm -Rf '/opt/w5base/lost+found' 2>/dev/null
   fi
   su w5adm -c "cd /opt && umask 002 && \
                git clone https://github.com/it-guru/w5base w5base"
fi




if [ ! -d /etc/container ]; then  # if container is not started with
   mkdir /etc/container          # tmpfs option /etc/w5base/container
fi

cat << EOF > /etc/container/maindb.conf
EventJobBaseUrl="https://$W5BASESITENAME/$W5BASECONFIGNAME/"

DATAOBJCONNECT[w5base] ="dbi:mysql:$W5DBNAME:host=$W5DBHOST;port=$W5DBPORT"
DATAOBJUSER[w5base]    ="$W5DBUSER"
DATAOBJPASS[w5base]    ="$W5DBPASS"
EOF

cat << EOF > /etc/container/httpd.site.conf
ServerName $W5BASESITENAME
Alias /$W5BASECONFIGNAME/auth/     /opt/w5base/bin/
Alias /$W5BASECONFIGNAME/public/   /opt/w5base/bin/
Alias /$W5BASECONFIGNAME/static/   /opt/w5base/static/
Alias /$W5BASECONFIGNAME/index/    /var/www/html/

ErrorDocument 401 /w5base/public/base/menu/LoginFail

DirectoryIndex index.html

RewriteRule ^/favicon.ico$ /$W5BASECONFIGNAME/public/base/load/icon_w5base.ico
RewriteRule ^/($W5BASECONFIGNAME)/(public|auth)/([^/]+)/([^/]+)/(.+)$ /\$1/\$2/fastapp.sh?MOD=\$3::\$4&FUNC=\$5 [QSA,PT]

RewriteEngine on

# enable data compress
AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript

<Directory /var/www/html>
        Options +Indexes -FollowSymLinks +MultiViews
        AllowOverride None
        Require all granted
</Directory>


<Location /$W5BASECONFIGNAME/public>
         Options -Indexes -FollowSymLinks +ExecCGI -Includes
         SetHandler fcgid-script
         Require all granted
</Location>

<Location /$W5BASECONFIGNAME/static>
         Options -Indexes -FollowSymLinks +ExecCGI -Includes
         Require all granted
</Location>

#
# The authentification if mod_auth_ae is used (BasicAuth)
#
<Location /$W5BASECONFIGNAME/auth>
        Options -Indexes -FollowSymLinks +ExecCGI -Includes
        SetHandler fcgid-script

        AuthType Basic
        AuthName "Login: emea1/a??????? or ciam/mueller.hans@telekom.de"
        aeAccountToLower on

        ### T-SSO (WebSSO and OpenID hook) Begin ######
        aeSSOUser           TelekomTSSO
        aeSSOPass           YSBkZjY0NWE4c2c0ZGFkcwo
        aeSSODomain         ciam/
        aeSSOHeaderUserAttr ssotcid
        aeSSOBasicAuthUser  sso SSO ciam CIAM ad AD ads ADS oid OpenID GoogleOID  EntraIdOID YahooOID
        AuthBasicProvider acache
        <Limit GET PUT POST>
                require valid-user
        </Limit>
</Location>

EOF

DATAOBJCONNECT[w5base] ="dbi:mysql:$W5DBNAME:host=$W5DBHOST;port=$W5DBPORT"
DATAOBJUSER[w5base]    ="$W5DBUSER"
DATAOBJPASS[w5base]    ="$W5DBPASS"
EOF

install -d -m 2770 -o w5base -g w5adm /etc/container/var/opt/w5base/state
install -d -m 2770 -o w5base -g w5adm /etc/container/var/w5base
install -d -m 2770 -o w5base -g w5adm /etc/container/var/run/w5base
install -d -m 2770 -o nobody -g w5base /etc/container/var/spool/w5base-mail
install -d -m 2770 -o w5base -g w5base /var/log/httpd
install -d -m 2777 -o w5base -g w5base /var/log/httpd/mod_fcgid
install -d -m 2770 -o w5base -g w5base /var/log/w5base

# ensure stale pid is removed
rm -f /etc/container/var/opt/w5base/state/W5Server.w5server.pid 2>/dev/null


CURW5BRANCH=$(su w5adm -c "cd /opt/w5base && git rev-parse --abbrev-ref HEAD")
echo "$(date '+%Y-%m-%d %H:%M:%S,%3N') INFO /opt/w5base is '$CURW5BRANCH'"

if [ "$W5BRANCH" != "$CURW5BRANCH" ]; then
   su w5adm -c "cd /opt/w5base && git checkout $W5BRANCH"
   # ensure repo is fresh
   #su w5adm -c "cd /opt/w5base && git fetch && git reset --hard origin/$W5BRANCH"
fi

# ensure aliases.db is fresh
/usr/bin/newaliases

/opt/w5base/sbin/W5Event -s TableVersionCheck # ensure DB is up to date


/usr/bin/supervisord -n -u root -c   /etc/supervisord.conf
