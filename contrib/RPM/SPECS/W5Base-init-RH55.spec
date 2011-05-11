Summary: W5Base start stop procedures for W5Server only
Name: W5Base-init-RH55
Version: 1.0
Release: 1
License: GPL
Group: Applications/Web
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Source0: AppComStartup-1.0.tgz
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0

%description
In this package are only the start/stop procedures
for the W5Server. The W5Server self will be deployed
via svn.

%prep
rm -rf $RPM_BUILD_DIR/AppComStartup-1.0
zcat $RPM_SOURCE_DIR/AppComStartup-1.0.tgz | tar -xvf -

%build
true

%install
cd $RPM_BUILD_DIR/AppComStartup-1.0 && tar -cf - * | (cd $RPM_BUILD_ROOT && tar -xvf -)

%files
/cAppCom/init.d/W5BaseDefaultStartup_Sample.sh

%config
/apps/etc/default/init




