Summary: FreeTDS Library based on unixodbc
Name: apps-lib-freetds-RH56-64Bit
Version: 0.82
Release: 1
License: GPL
Group: Applications/Web
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0
Source0: freetds-0.82.tgz
Provides: /bin/sh
BuildPreReq: wget, unzip, tar


%description
Library to access MSSQL via UnixODBC

%prep
rm -rf $RPM_BUILD_DIR/freetds-0.82
zcat $RPM_SOURCE_DIR/freetds-0.82.tgz | tar -xvf -


%build
cd $RPM_BUILD_DIR/freetds-0.82
./configure --prefix=/apps
make

%install
rm -rf $RPM_BUILD_ROOT/*
cd $RPM_BUILD_DIR/freetds-0.82
DESTDIR=$RPM_BUILD_ROOT make install
rm -rf $RPM_BUILD_ROOT/apps/include
rm -rf $RPM_BUILD_ROOT/apps/bin
rm -rf $RPM_BUILD_ROOT/apps/share
rm -rf $RPM_BUILD_ROOT/apps/man




%files
%defattr(-,root,root,-)
/apps/lib/*
/apps/etc/*



