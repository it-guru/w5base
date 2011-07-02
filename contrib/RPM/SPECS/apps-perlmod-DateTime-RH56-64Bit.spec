Summary: DateTime AppCom perl Modules at /apps
Name: apps-perlmod-DateTime-RH56-64Bit
Version: 0.53
Release: 1
License: GPL
Group: Applications/Web
URL:     http://search.cpan.org/~drolsky/DateTime-0.53/
Source0: http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/DateTime-0.53.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module DateTime installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/DateTime-0.53
zcat $RPM_SOURCE_DIR/DateTime-0.53.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/DateTime-0.53
%{__perl} Build.PL 

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/DateTime-0.53
./Build pure_install install_base=$RPM_BUILD_ROOT/apps/perlmod
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
mkdir -p $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/site_perl
mv $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/x86_64-linux-thread-multi $RPM_BUILD_ROOT/apps/perlmod/lib/perl5/site_perl/5.8.8/
mkdir -p $RPM_BUILD_ROOT/apps/perlmod/share
mv $RPM_BUILD_ROOT/apps/perlmod/man $RPM_BUILD_ROOT/apps/perlmod/share
chmod -R u+w $RPM_BUILD_ROOT/*



%check || :
cd $RPM_BUILD_DIR/DateTime-0.53
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/DateTime.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DateTime/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/DateTimePP*
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/DateTime/DateTime.so
/apps/perlmod/share/man/man*/*

