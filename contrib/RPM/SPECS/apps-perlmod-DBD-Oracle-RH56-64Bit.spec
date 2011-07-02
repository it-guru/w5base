Summary: DBD::Oracle AppCom perl Modules at /apps
Name: apps-perlmod-DBD-Oracle-RH56-64Bit
Version: 1.28
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/P/PY/PYTHIAN/DBD-Oracle-1.28.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module DBD::Oracle installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/DBD-Oracle-1.28
zcat $RPM_SOURCE_DIR/DBD-Oracle-1.28.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/DBD-Oracle-1.28
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/DBD-Oracle-1.28
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/DBD-Oracle-1.28
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/bin/*
/apps/perlmod/share/man/man*/*
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/DBD/Oracle.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/DBD/Oracle/GetInfo.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/DBD/Oracle/Object.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/Oraperl.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBD/Oracle/Oracle.h
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBD/Oracle/Oracle.so
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBD/Oracle/dbdimp.h
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBD/Oracle/mk.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBD/Oracle/ocitrace.h
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/oraperl.ph

