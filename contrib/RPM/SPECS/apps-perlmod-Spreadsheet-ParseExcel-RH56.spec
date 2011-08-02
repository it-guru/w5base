Summary: Spreadsheet::ParseExcel AppCom perl Modules at /apps
Name: apps-perlmod-Spreadsheet-ParseExcel-RH56
Version: 0.32
Release: 1
License: GPL
Group: Applications/Web
Source0: libspreadsheet-parseexcel-perl_0.3200.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Spreadsheet::ParseExcel installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/Spreadsheet-ParseExcel-0.32
zcat $RPM_SOURCE_DIR/libspreadsheet-parseexcel-perl_0.3200.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Spreadsheet-ParseExcel-0.32
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Spreadsheet-ParseExcel-0.32
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/Spreadsheet-ParseExcel-0.32
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/Dump.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/FmtDefault.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/FmtJapan.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/FmtJapan2.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/FmtUnicode.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/SaveParser.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/Spreadsheet/ParseExcel/Utility.pm
/apps/perlmod/share/man/man*/*
