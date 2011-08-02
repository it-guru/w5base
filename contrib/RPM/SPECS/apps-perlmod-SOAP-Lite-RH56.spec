Summary: SOAP::Lite AppCom perl Modules at /apps
Name: apps-perlmod-SOAP-Lite-RH56
Version: 0.710.08
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/M/MK/MKUTTER/SOAP-Lite-0.710.08.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module SOAP::Lite installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/SOAP-Lite-0.710.08
zcat $RPM_SOURCE_DIR/SOAP-Lite-0.710.08.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/SOAP-Lite-0.710.08
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/SOAP-Lite-0.710.08
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/SOAP-Lite-0.710.08
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/bin/SOAPsh.pl
/apps/perlmod/bin/XMLRPCsh.pl
/apps/perlmod/bin/stubmaker.pl
/apps/perlmod/lib/perl5/site_perl/5.8.8/SOAP/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/XMLRPC/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/XML/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/Apache/SOAP.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Apache/XMLRPC/Lite.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/IO/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/UDDI/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/OldDocs/*
/apps/perlmod/share/man/man*/*
