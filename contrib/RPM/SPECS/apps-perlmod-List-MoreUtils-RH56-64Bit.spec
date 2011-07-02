Summary: List::MoreUtils AppCom perl Modules at /apps
Name: apps-perlmod-List-MoreUtils-RH56-64Bit
Version: 0.30
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/List-MoreUtils-0.30.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module List::MoreUtils installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/List-MoreUtils-0.30
zcat $RPM_SOURCE_DIR/List-MoreUtils-0.30.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/List-MoreUtils-0.30
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/List-MoreUtils-0.30
pwd
make pure_site_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/List-MoreUtils-0.30
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/List/MoreUtils/MoreUtils.so
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/List/MoreUtils.pm
/apps/perlmod/share/man/man*/*
