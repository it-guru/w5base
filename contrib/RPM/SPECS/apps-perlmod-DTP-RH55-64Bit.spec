Summary: DTP AppCom perl Modules at /apps
Name: apps-perlmod-DTP-RH55-64Bit
Version: 0.0.1
Release: 3
License: GPL
Group: Applications/Web
Source:  perl-dtp-0.0.1.tgz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module DTP installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/perl-dtp-0.0.1
zcat $RPM_SOURCE_DIR/perl-dtp-0.0.1.tgz | tar -xvf -
rm -rf $RPM_BUILD_DIR/PDFlib-Lite-7.0.4
zcat $RPM_BUILD_DIR/perl-dtp-0.0.1/dependence/PDFlib-Lite-7.0.4.tar.gz | \
     tar -xvf -

%build
cd $RPM_BUILD_DIR/PDFlib-Lite-7.0.4
./configure --without-py --without-tcl --without-ruby --without-java --bindir=$RPM_BUILD_ROOT/apps/bin --libdir=$RPM_BUILD_ROOT/apps/lib
sed -i "s#^PERLLIBDIR.*=.*\$#PERLLIBDIR=$RPM_BUILD_ROOT/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi#g" config/mkcommon.inc
make
cd $RPM_BUILD_DIR/perl-dtp-0.0.1
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi -m 0755
cd $RPM_BUILD_DIR/PDFlib-Lite-7.0.4
make install
cd $RPM_BUILD_DIR/perl-dtp-0.0.1
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'


%check || :
cd $RPM_BUILD_DIR/perl-dtp-0.0.1
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/bin/pdfimage
/apps/bin/pdflib-config
/apps/bin/text2pdf
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.a
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.la
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.so
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.so.0
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/pdflib_pl.so.0.0.0
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/Entity.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/Entity/LineChart.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/GD.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/colors/rgb.txt
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/arial.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/arialbd.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/arialbi.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/ariali.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/cour.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/courbd.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/courbi.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/fonts/couri.ttf
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/jpg.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/pdf.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/DTP/png.pm
/apps/perlmod/share/man/man3/DTP.3pm
/apps/perlmod/share/man/man3/DTP::Entity.3pm
/apps/perlmod/share/man/man3/DTP::Entity::LineChart.3pm
