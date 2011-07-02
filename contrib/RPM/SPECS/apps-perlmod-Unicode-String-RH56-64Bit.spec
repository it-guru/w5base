Summary: Unicode::String AppCom perl Modules at /apps
Name: apps-perlmod-Unicode-String-RH56-64Bit
Version: 2.09
Release: 1
License: GPL
Group: Applications/Web
URL:     http://search.cpan.org/~gaas/Unicode-String-2.09/
Source0: http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/Unicode-String-2.09.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Unicode::String installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/Unicode-String-2.09
zcat $RPM_SOURCE_DIR/Unicode-String-2.09.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Unicode-String-2.09
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Unicode-String-2.09
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/Unicode-String-2.09
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/Unicode/String/String.so
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/Unicode/*.pm
/apps/perlmod/share/man/man*/*


