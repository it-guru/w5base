Summary: File::Temp AppCom perl Modules at /apps
Name: apps-perlmod-File-Temp-RH56
Version: 0.18
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/T/TJ/TJENNESS/File-Temp-0.18.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module File::Temp installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/File-Temp-0.18
zcat $RPM_SOURCE_DIR/File-Temp-0.18.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/File-Temp-0.18
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/File-Temp-0.18
pwd
make pure_site_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/File-Temp-0.18
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/File/*.pm
/apps/perlmod/share/man/man*/*
