Summary: W5Base start stop and config of apache web server
Name: W5Base-apache-RH55-64Bit
Version: 1.0
Release: 1
License: GPL
Group: Applications/Web
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Source0: apache-mod_ae-0.15.tgz
Source1: httpd-devel-2.2.3-nativ.tgz
Source2: apr-devel-1.2.7-nativ.tgz
Source3: apr-util-devel-1.2.7-nativ.tgz
Provides: /bin/sh


%description
Basic Apache2 Enviroment for running a W5Base Application

%prep
rm -rf $RPM_BUILD_DIR/apache-mod_ae-0.15
rm -rf $RPM_BUILD_DIR/httpd-devel-2.2.3
rm -rf $RPM_BUILD_DIR/apr-devel-1.2.7
rm -rf $RPM_BUILD_DIR/apr-util-devel-1.2.7
zcat $RPM_SOURCE_DIR/apache-mod_ae-0.15.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/httpd-devel-2.2.3-nativ.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/apr-devel-1.2.7-nativ.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/apr-util-devel-1.2.7-nativ.tgz | tar -xvf -


%build
cd $RPM_BUILD_DIR/apache-mod_ae-0.15/src
make
cd $RPM_BUILD_DIR/apache-mod_ae-0.15/apache2
libtool --mode=compile --tag=disable-static gcc -prefer-pic -DLINUX=2 -D_GNU_SOURCE -D_LARGEFILE64_SOURCE -D_REENTRANT -I/usr/include/apr-1.0  -I/usr/include/openssl  -I/usr/include/xmltok -pthread     -I../../apr-devel-1.2.7/include/apr-1 -I../../apr-util-devel-1.2.7/include/apr-1 -I../../httpd-devel-2.2.3/include/httpd  -I../include  -c -o ae_module.lo ae_module.c

%install
cd $RPM_BUILD_DIR/apache-mod_ae-0.15/bin
install -d $RPM_BUILD_ROOT/apps/apache/sbin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/apps/apache/bin -o root -g root -m 755
install -d $RPM_BUILD_ROOT/apps/apache/lib -o root -g root -m 755
install -m 755 client $RPM_BUILD_ROOT/apps/apache/bin/acacheclient
install -m 755 acache $RPM_BUILD_ROOT/apps/apache/sbin/acache
install $RPM_BUILD_DIR/apache-mod_ae-0.15/apache2/ae_module.lo $RPM_BUILD_ROOT/apps/apache/lib/ae_module.lo
install -d $RPM_BUILD_ROOT/etc -m 755
echo 'HELPERS      = /apps/etc/aetools.conf' > $RPM_BUILD_ROOT/etc/acache.conf
echo 'MAXCACHETIME = 60'                    >> $RPM_BUILD_ROOT/etc/acache.conf

%files
%defattr(-,root,root,-)
/apps/apache/bin/acacheclient
/apps/apache/sbin/acache
/apps/apache/lib/ae_module.lo

%config
/etc/acache.conf

%post
pwd
if grep -q 'w5usrmgr:' etc/group; then
   install -d apps/pkg/_default     -g root -o root -m 2775
   install -d apps/pkg/_default/etc -g root -o root -m 2775
   install -d apps/pkg/_default/var -g root -o root -m 2775
   install -d apps/pkg/_default/var/lib -g root -o root -m 2775
   install -d apps/pkg/_default/var/run -g root -o root -m 2775
   install -d apps/pkg/_default/var/log -g root -o root -m 2775
   install -d apps/pkg/_default/etc/httpd -g daemon -o w5base -m 2750
fi

