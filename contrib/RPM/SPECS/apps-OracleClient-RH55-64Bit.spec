Summary: Nativer Oracle Client (AppCom Plug-Style)
Name: apps-OracleClient-RH55-64Bit
Version: 11.2.0.1.2
Release: 1
License: GPL
Group: Applications/Databases
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
Autoreq: 0
Provides: /bin/sh
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)




%description
Generic Oracle Client based on AppCom Plug Directory.
Build only posible on AppCom RH Systems!


%prep


%build

%install
mkdir -p $RPM_BUILD_ROOT/apps/AppCom/plugs/oracle/client-11/oracle-client_11.2.0.1.2_RHEL5_64
cd /
echo "Copying from plugs/oracle/client-11/oracle-client_11.2.0.1.2_RHEL5_64 ..."
(cp -fr apps/AppCom/plugs/oracle/client-11/oracle-client_11.2.0.1.2_RHEL5_64/* \
   $RPM_BUILD_ROOT/apps/AppCom/plugs/oracle/client-11/oracle-client_11.2.0.1.2_RHEL5_64 2>/dev/null ; true)



%files
%defattr(-,root,root,-)
/apps/AppCom/plugs/oracle/client-11/oracle-client_11.2.0.1.2_RHEL5_64

%post

