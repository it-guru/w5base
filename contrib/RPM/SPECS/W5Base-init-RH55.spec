Summary: W5Base basic initialisation
Name: W5Base-init-RH55
Version: 1.0
Release: 20
License: GPL
Group: Applications/Web
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Provides: /bin/sh


%description
This is a base initialisation, which creates all
neassesary directories.

In detail, this package handels:
- fix rights and ownership of /apps/etc/w5base
- fix rights and ownership of /apps/etc/default
- create a default init config file at /apps/etc/default/init
- create neassary directories for W5Base System


%prep

%build
install -d $RPM_BUILD_ROOT

%install

%files


%post

install -d  apps/pkg               -o w5base -g daemon -m 2755
install -d  apps/etc/w5base        -o w5base -g daemon -m 2750
install -d  apps/w5base/opt
install -d  apps/w5base/opt/w5base -o w5base -g daemon -m 2750

if [ ! -f etc/profile.local ]; then
   echo "# default profile.local " > etc/profile.local
   echo "# needs to be modified by w5usrmgr" >> etc/profile.local
fi
chown root:w5usrmgr etc/profile.local
chmod 775           etc/profile.local
if [ ! -h opt/w5base ]; then
   ln -s ../apps/w5base/opt/w5base opt/w5base
fi
if ! grep -q 'profile.local' etc/profile; then
   echo 'test -s /etc/profile.local && . /etc/profile.local' >>etc/profile
fi






