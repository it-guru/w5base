Summary: nrpe AppCom at /apps
Name: apps-nrpe-RH56
Version: 2.12
Release: 1
License: GPL
Group: Applications/Web
Source0: nrpe-2.12.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Holger Förster <holger.foerster@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Autoreq: 0

%description
nrpe installed at /apps/nrpe
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/nrpe-2.12
zcat $RPM_SOURCE_DIR/nrpe-2.12.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/nrpe-2.12
./configure --prefix=/apps/nrpe
#sed "s#\$(DESTDIR)#${RPM_BUILD_ROOT}/#g" -i Makefile
# redirect the path
sed "s#\$(DESTDIR)#${RPM_BUILD_ROOT}#g" -i src/Makefile

# remove chown options
sed "s#NAGIOS_INSTALL_OPTS=-o nagios -g nagios#NAGIOS_INSTALL_OPTS=#g" -i src/Makefile
sed "s#NRPE_INSTALL_OPTS=-o nagios -g nagios#NRPE_INSTALL_OPTS=#g" -i src/Makefile

make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/nrpe-2.12
pwd



make install
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*

%check || :
cd $RPM_BUILD_DIR/nrpe-2.12
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/nrpe/*

%post
chown -R nagios:nagios /apps/nrpe
chmod -R 775 /apps/nrpe
