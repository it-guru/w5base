Summary: W5Base start stop and config of apache web server
Name: W5Base-apache-RH56-64Bit
Version: 1.0
Release: 15
License: GPL
Group: Applications/Web
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Source0: apache-mod_ae-0.22.tgz
Source1: httpd-devel-2.2.3-nativ.tgz
Source2: apr-devel-1.2.7-nativ.tgz
Source3: apr-util-devel-1.2.7-nativ.tgz
Source3: mkcert.tgz
Source4: wiwauth.tgz
Provides: /bin/sh
BuildPreReq: wget, unzip, tar


%description
Basic Apache2 Enviroment for running a W5Base Application
In detail, this package handels:

- create of a sample directory structure for apache at /apps/pkg/_default
- install mod_auth_ae shared object
- install acache and debug client acacheclient (link at /apps/bin)
- create a default conf /etc/acache.conf
- create a default apps/etc/aetools.conf and ensure rights/ownership
- install some default auth-handlers for mod_auth_ae at /apps/apache/auth
- install wiw.pl auth handler at /apps/apache/auth
- install a self signed cert handling script at /apps/etc/ssl
- install snakeoil certifiactes at /apps/etc/ssl


%prep
# this download is to keep the SRPM small!
test -f $RPM_SOURCE_DIR/samba-3.0.37.tar.gz || \
   wget -O $RPM_SOURCE_DIR/samba-3.0.37.tar.gz \
        http://ftp.samba.org/pub/samba/samba-3.0.37.tar.gz
rm -rf $RPM_BUILD_DIR/samba-3.0.37.tar.gz
rm -rf $RPM_BUILD_DIR/apache-mod_ae-0.15
rm -rf $RPM_BUILD_DIR/httpd-devel-2.2.3
rm -rf $RPM_BUILD_DIR/apr-devel-1.2.7
rm -rf $RPM_BUILD_DIR/apr-util-devel-1.2.7
zcat $RPM_SOURCE_DIR/samba-3.0.37.tar.gz | tar -xvf -
zcat $RPM_SOURCE_DIR/apache-mod_ae-0.22.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/httpd-devel-2.2.3-nativ.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/apr-devel-1.2.7-nativ.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/apr-util-devel-1.2.7-nativ.tgz | tar -xvf -


%build
cd $RPM_BUILD_DIR/apache-mod_ae-0.22/src
make clean
make
cd $RPM_BUILD_DIR/apache-mod_ae-0.22/apache2
libtool --mode=compile --tag=disable-static gcc -prefer-pic -DLINUX=2 -D_GNU_SOURCE -D_LARGEFILE64_SOURCE -D_REENTRANT -I/usr/include/apr-1.0  -I/usr/include/openssl  -I/usr/include/xmltok -pthread     -I../../apr-devel-1.2.7/include/apr-1 -I../../apr-util-devel-1.2.7/include/apr-1 -I../../httpd-devel-2.2.3/include/httpd  -I../include  -c -o ae_module.lo ae_module.c
libtool --silent --mode=link --tag=disable-static gcc -o ae_module.la  -L../lib -lacache -rpath /apps/apache/lib -module -avoid-version    ae_module.lo
cd $RPM_BUILD_DIR/samba-3.0.37/source
./configure --prefix=/opt/samba \
            --with-libsmbclient \
            -without-ads \
            -without-syslog \
            -without-smbmount \
            -without-krb5
make
cp -a $RPM_BUILD_DIR/apache-mod_ae-0.22/contrib/authscripts/samba-3.0.37/examples/smb3passchk $RPM_BUILD_DIR/samba-3.0.37/examples
cd $RPM_BUILD_DIR/samba-3.0.37/examples/smb3passchk
make

%install
rm -rf $RPM_BUILD_ROOT/*
cd $RPM_BUILD_DIR/apache-mod_ae-0.22/bin
install -d $RPM_BUILD_ROOT/apps/apache/sbin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/apps/apache/bin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/apps/apache/lib -o root -g root -m 755
install -m 755 client $RPM_BUILD_ROOT/apps/apache/bin/acacheclient
install -m 755 acache $RPM_BUILD_ROOT/apps/apache/sbin/acache
cd $RPM_BUILD_DIR/apache-mod_ae-0.22/apache2
libtool --mode=install cp ae_module.la $RPM_BUILD_ROOT/apps/apache/lib/
libtool --finish /apps/apache/lib
install -d $RPM_BUILD_ROOT/etc -m 755
echo 'HELPERS      = /apps/etc/aetools.conf' > $RPM_BUILD_ROOT/etc/acache.conf
echo 'MAXCACHETIME = 60'                    >> $RPM_BUILD_ROOT/etc/acache.conf
cd $RPM_BUILD_DIR/apache-mod_ae-0.22
install -d $RPM_BUILD_ROOT/apps/apache/auth
install contrib/authscripts/dummy.sh $RPM_BUILD_ROOT/apps/apache/auth -m 750
install contrib/authscripts/httpforward.sh $RPM_BUILD_ROOT/apps/apache/auth -m 750
install $RPM_BUILD_DIR/samba-3.0.37/examples/smb3passchk/smb3passchk $RPM_BUILD_ROOT/apps/apache/auth -m 755
install -d $RPM_BUILD_ROOT/apps/etc/ssl -g daemon -o w5base -m 2750
cd $RPM_BUILD_ROOT/apps/etc/ssl
zcat $RPM_SOURCE_DIR/mkcert.tgz | tar -xvf -
cd $RPM_BUILD_ROOT
zcat $RPM_SOURCE_DIR/wiwauth.tgz | tar -xvf -



%files
%defattr(-,root,root,-)
/apps/apache/bin/acacheclient
/apps/apache/sbin/acache
/apps/apache/lib/ae_module.so
/apps/etc/ssl/*
/apps/apache/lib/ae_module.la
/apps/apache/auth/httpforward.sh
/apps/apache/auth/wiw.pl
/apps/apache/auth/smb3passchk

%config(noreplace) /etc/acache.conf
%config(noreplace) /apps/apache/auth/dummy.sh

%post
pwd
if grep -q 'w5base:' etc/group; then
   install -d apps/pkg/_default     -g root -o root -m 2775
   install -d apps/pkg/_default/etc -o w5base -g w5base -m 2775
   install -d apps/pkg/_default/var -g root -o root -m 2775
   install -d apps/pkg/_default/var/lib -g root -o root -m 2775
   install -d apps/pkg/_default/var/run -g root -o root -m 2775
   install -d apps/pkg/_default/var/log -g root -o root -m 2775
   install -d apps/pkg/_default/etc/httpd -g daemon -o w5base -m 2750
fi
if [ -d apps/bin/acacheclient ]; then
   ln -sf ../apache/bin/acacheclient apps/bin/acacheclient
fi
if [ ! -f apps/etc/aetools.conf ]; then
   touch apps/etc/aetools.conf
fi
chown w5base:daemon apps/etc/aetools.conf
chmod 660 apps/etc/aetools.conf
chown w5base:daemon apps/etc/ssl 
chmod 2750 apps/etc/ssl 
chgrp daemon apps/etc/ssl/snakeoil-*
chmod g+r apps/etc/ssl/snakeoil-*

