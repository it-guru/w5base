Summary: Params::Validate AppCom perl Modules at /apps
Name: apps-perlmod-Params-Validate-RH55-64Bit
Version: 0.94
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/Params-Validate-0.94.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Params::Validate installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/Params-Validate-0.94
zcat $RPM_SOURCE_DIR/Params-Validate-0.94.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Params-Validate-0.94
%{__perl} Build.PL
./Build

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Params-Validate-0.94
pwd
./Build pure_install install_base=$RPM_BUILD_ROOT/apps/perlmod
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/site_perl
mv $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/x86_64-linux-thread-multi $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/site_perl/5.8.8/
mkdir -p $RPM_BUILD_ROOT/apps/perlmod/share
mv $RPM_BUILD_ROOT/apps/perlmod/man $RPM_BUILD_ROOT/apps/perlmod/share


%check || :
cd $RPM_BUILD_DIR/Params-Validate-0.94
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/Attribute/Params/Validate.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Params/*.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/Params/Validate/Validate.so
/apps/perlmod/share/man/man*/*
