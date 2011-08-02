Summary: Auth module for apache web server
Name: httpd-mod_auth_ae-64Bit
Version: 1.0
Release: 1
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
Install mod_auth_ae into the standard redhed apache directory structure
In detail, this package handels:

- install mod_auth_ae shared object
- install acache and debug client acacheclient 
- create a default conf etc/acache.conf
- create a default etc/aetools.conf and ensure rights/ownership
- install some default auth-handlers for mod_auth_ae at usr/share/lib/acache
- install wiw.pl auth handler at usr/share/lib/acache


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
install -d $RPM_BUILD_ROOT/usr/sbin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/usr/bin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/usr/share/lib/acache -o root -g root -m 755
install -m 755 client $RPM_BUILD_ROOT/usr/bin/acacheclient
install -m 755 acache $RPM_BUILD_ROOT/usr/sbin/acache
cd $RPM_BUILD_DIR/apache-mod_ae-0.22/apache2
libtool --mode=install cp ae_module.la $RPM_BUILD_ROOT/usr/lib64/httpd/modules/
libtool --finish /usr/lib64/httpd/modules/
install -d $RPM_BUILD_ROOT/etc -m 755
echo 'HELPERS      = /etc/aetools.conf' > $RPM_BUILD_ROOT/etc/acache.conf
echo 'MAXCACHETIME = 60'               >> $RPM_BUILD_ROOT/etc/acache.conf
cd $RPM_BUILD_DIR/apache-mod_ae-0.22
install -d $RPM_BUILD_ROOT/apps/apache/auth
install contrib/authscripts/dummy.sh $RPM_BUILD_ROOT/apps/apache/auth -m 750
install contrib/authscripts/httpforward.sh $RPM_BUILD_ROOT/apps/apache/auth -m 750
install $RPM_BUILD_DIR/samba-3.0.37/examples/smb3passchk/smb3passchk $RPM_BUILD_ROOT/usr/share/lib/acache -m 755
cd $RPM_BUILD_ROOT
zcat $RPM_SOURCE_DIR/wiwauth.tgz | tar -xvf -



%files
%defattr(-,root,root,-)
/usr/bin/acacheclient
/usr/sbin/acache
/usr/lib64/httpd/modules/ae_module.so
/usr/lib64/httpd/modules/ae_module.la
/usr/share/lib/acache/httpforward.sh
/usr/share/lib/acache/wiw.pl
/usr/share/lib/acache/smb3passchk

%config(noreplace) /etc/acache.conf
%config(noreplace) /usr/share/lib/acache/dummy.sh

%post
pwd
if [ ! -f etc/aetools.conf ]; then
   touch etc/aetools.conf
fi
chown w5base:daemon etc/aetools.conf
chmod 660 etc/aetools.conf

