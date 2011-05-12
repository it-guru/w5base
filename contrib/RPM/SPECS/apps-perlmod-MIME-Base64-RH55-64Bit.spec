Summary: MIME::Base64 AppCom perl Modules at /apps
Name: apps-perlmod-MIME-Base64-RH55-64Bit
Version: 3.13
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/MIME-Base64-3.13.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module MIME::Base64 installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/MIME-Base64-3.13
zcat $RPM_SOURCE_DIR/MIME-Base64-3.13.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/MIME-Base64-3.13
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/MIME-Base64-3.13
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/MIME-Base64-3.13
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib64/perl5/5.8.8/x86_64-linux-thread-multi/MIME/Base64.pm
/apps/perlmod/lib64/perl5/5.8.8/x86_64-linux-thread-multi/MIME/QuotedPrint.pm
/apps/perlmod/lib64/perl5/5.8.8/x86_64-linux-thread-multi/auto/MIME/Base64/Base64.so
/apps/perlmod/share/man/man*/*
