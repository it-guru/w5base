Summary: Net::UCP AppCom perl Modules at /apps
Name: apps-perlmod-Net-UCP-RH55
Version: 0.41
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/N/NE/NEMUX/Net-UCP-0.41.tgz
Source1: http://search.cpan.org/CPAN/authors/id/N/NE/NEMUX/Net-UCP-Common-0.05.tar.gz
Source2: http://search.cpan.org/CPAN/authors/id/N/NE/NEMUX/Net-UCP-IntTimeout-0.05.tar.gz
Source3: http://search.cpan.org/CPAN/authors/id/N/NE/NEMUX/Net-UCP-TransactionManager-0.02.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Net::UCP installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/Net-UCP-0.41
zcat $RPM_SOURCE_DIR/Net-UCP-0.41.tgz | tar -xvf -
rm -rf $RPM_BUILD_DIR/Net-UCP-Common-0.05
zcat $RPM_SOURCE_DIR/Net-UCP-Common-0.05.tar.gz | tar -xvf -
rm -rf $RPM_BUILD_DIR/Net-UCP-IntTimeout-0.05
zcat $RPM_SOURCE_DIR/Net-UCP-IntTimeout-0.05.tar.gz | tar -xvf -
rm -rf $RPM_BUILD_DIR/Net-UCP-TransactionManager-0.02
zcat $RPM_SOURCE_DIR/Net-UCP-TransactionManager-0.02.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Net-UCP-Common-0.05
%{__perl} Makefile.PL --skipdeps PREFIX=/apps/perlmod
make
cd $RPM_BUILD_DIR/Net-UCP-IntTimeout-0.05
%{__perl} Makefile.PL --skipdeps PREFIX=/apps/perlmod
make
cd $RPM_BUILD_DIR/Net-UCP-TransactionManager-0.02
%{__perl} Makefile.PL --skipdeps PREFIX=/apps/perlmod
make
cd $RPM_BUILD_DIR/Net-UCP-0.41
%{__perl} Makefile.PL --skipdeps PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Net-UCP-Common-0.05
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Net-UCP-IntTimeout-0.05
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Net-UCP-TransactionManager-0.02
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Net-UCP-0.41
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/Net-UCP-0.41
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/Net/UCP.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Net/UCP/*.pm
/apps/perlmod/share/man/man*/*
