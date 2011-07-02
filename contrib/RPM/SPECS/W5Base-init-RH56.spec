Summary: W5Base start stop procedures for W5Server only
Name: W5Base-init-RH56
Version: 1.0
Release: 13
License: GPL
Group: Applications/Web
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Source0: AppComStartup-1.0.tgz
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Provides: /bin/sh


%description
In this package are only the start/stop procedures
for the W5Server. The W5Server self will be deployed
via svn.

In detail, this package handels:
- fix rights and ownership of /apps/etc/w5base
- fix rights and ownership of /apps/etc/default
- create a default init config file at /apps/etc/default/init
- fix rights and ownership of /apps/etc/default/init
- create /cAppCom/init.d/W5BaseDefaultStartup_Sample.sh
- create neassary directories for W5Base System


%prep
rm -rf $RPM_BUILD_DIR/AppComStartup-1.0
zcat $RPM_SOURCE_DIR/AppComStartup-1.0.tgz | tar -xvf -

%build
install -d $RPM_BUILD_ROOT

%install
cd $RPM_BUILD_DIR/AppComStartup-1.0 && tar -cf - * | (cd $RPM_BUILD_ROOT && tar -xvf -)

%files
/cAppCom/init.d/W5BaseDefaultStartup_Sample.sh

%config(noreplace) /apps/etc/default/init

%post

chown w5base:daemon apps/etc/w5base 2>/dev/null
chmod g+srx apps/etc/w5base 2>/dev/null
chgrp w5base apps/etc/default 2>/dev/null
chmod g+srw apps/etc/default 2>/dev/null
chgrp w5base apps/etc/default/init 2>/dev/null
chmod g+rw apps/etc/default/init 2>/dev/null

#
# W5Base directories
#
install -d apps/pkg/_default/var/opt/w5base/state -o w5base -g daemon -m 700

cat <<EOF

   *************************************************************************
   INFO:  After Installation of this package, you have to rename/copy the 
          sample file /cAppCom/init.d/W5BaseDefaultStartup_Sample.sh to
          /cAppCom/init.d/HOSTNAME.sh and create the needed links at
          /cAppCom/init.d/HOSTNAME !
          At /cAppCom/etc/default/init you have to configure your individual
          module list for start or stop.
   *************************************************************************

EOF



