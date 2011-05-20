Summary: JSON AppCom perl Modules at /apps
Name: apps-perlmod-JSON-RH55
Version: 2.51
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/M/MA/MAKAMAKA/JSON-2.51.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module JSON installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/JSON-2.51
zcat $RPM_SOURCE_DIR/JSON-2.51.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/JSON-2.51
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/JSON-2.51
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/JSON-2.51
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/JSON.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/JSON/backportPP.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/JSON/backportPP/Boolean.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/JSON/backportPP/Compat5005.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/JSON/backportPP/Compat5006.pm
/apps/perlmod/share/man/man3/JSON.3pm
/apps/perlmod/share/man/man3/JSON::backportPP.3pm
/apps/perlmod/share/man/man3/JSON::backportPP::Boolean.3pm
/apps/perlmod/share/man/man3/JSON::backportPP::Compat5005.3pm
/apps/perlmod/share/man/man3/JSON::backportPP::Compat5006.3pm
