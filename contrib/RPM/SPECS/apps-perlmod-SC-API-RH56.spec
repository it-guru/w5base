Summary: ServiceCenter::API AppCom perl Modules at /apps
Name: apps-perlmod-SC-API-RH56
Version: 0.0.6
Release: 1
License: GPL
Group: Applications/Web
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl ServiceCenter::API installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/sc-perl-api
svn export https://sc-perl-api.svn.sourceforge.net/svnroot/sc-perl-api sc-perl-api

%build
cd $RPM_BUILD_DIR/sc-perl-api/ServiceCenter-API
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/sc-perl-api/ServiceCenter-API
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/SC/API.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/SC/Customer/TSystems.pm
/apps/perlmod/share/man/man3/SC::API.3pm
