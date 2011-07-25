Summary: W5Base start stop procedures for AppCom Enviroments
Name: W5Base-AppCom-RH55
Version: 1.0
Release: 2
License: GPL
Group: Applications/Web
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Source0: AppComStartup-1.1.tgz
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Provides: /bin/sh
Requires: W5Base-init-RH55


%description
In this package are only the start/stop procedures
for the W5Server. The W5Server self will be deployed
via svn.

In detail, this package handels:
- create a default init config file at /cAppCom/conf.d
- create /cAppCom/init.d/W5BaseDefaultStartup_Sample.sh


%prep
rm -rf $RPM_BUILD_DIR/AppComStartup-1.1
zcat $RPM_SOURCE_DIR/AppComStartup-1.1.tgz | tar -xvf -

%build
install -d $RPM_BUILD_ROOT

%install
cd $RPM_BUILD_DIR/AppComStartup-1.1 && tar -cf - * | (cd $RPM_BUILD_ROOT && tar -xvf -)

%files
/cAppCom/init.d/W5BaseDefaultStartup_Sample.sh

%config /cAppCom/conf.d/init.W5BaseDefaultStartup_Sample.cfg

%post

