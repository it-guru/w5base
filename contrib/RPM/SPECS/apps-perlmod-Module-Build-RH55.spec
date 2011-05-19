Summary: Module::Build AppCom perl Modules at /apps
Name: apps-perlmod-Module-Build-RH55
Version: 1.001
Release: 2
License: GPL
Group: Applications/Web
URL:     http://search.cpan.org/CPAN/authors/id/K/KW/KWILLIAMS
Source0: http://search.cpan.org/CPAN/authors/id/K/KW/KWILLIAMS/Module-Build-0.30.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Module::Build installed at /perlmod
This installation can be used in AppCom enviroments with rpm -r /apps

%prep
rm -rf $RPM_BUILD_DIR/Module-Build-0.30
zcat $RPM_SOURCE_DIR/Module-Build-0.30.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Module-Build-0.30
%{__perl} Makefile.PL PREFIX=/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Module-Build-0.30
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT/apps
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'


%check || :
cd $RPM_BUILD_DIR/Module-Build-0.30
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/bin/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/Module/Build.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Module/Build/*
/apps/perlmod/share/man/man*/*

