Summary: MailTools AppCom perl Modules at /apps
Name: apps-perlmod-MailTools-RH56
Version: 0.02
Release: 1
License: GPL
Group: Applications/Web
URL:     http://search.cpan.org/~markov/MailTools-2.07/
Source0: http://search.cpan.org/CPAN/authors/id/M/MA/MARKOV/MailTools-2.07.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Mail::* installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/MailTools-2.07
zcat $RPM_SOURCE_DIR/MailTools-2.07.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/MailTools-2.07
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/MailTools-2.07
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.pod' -a -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/MailTools-2.07
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/Mail/*.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Mail/Field/*.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Mail/Mailer/*.pm
/apps/perlmod/share/man/man*/*

