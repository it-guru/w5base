Summary: GD AppCom perl Modules at /apps
Name: apps-perlmod-GD-RH55-64Bit
Version: 2.46
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/L/LD/LDS/GD-2.46.tar.gz
Source1: gd-devel-2.0.33.tgz
Source2: libXpm-devel-3.5.5.tgz
Source3: libjpeg-devel-6b.tgz
Source4: libpng-devel-1.2.10.tgz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module GD installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/GD-2.46
zcat $RPM_SOURCE_DIR/GD-2.46.tar.gz | tar -xvf -
# Die fehlden devel Packete auf der AppCom Umgebung einfach mit
# "alien -t" in TGZ archive umwandeln. Dann lassen diese sich einfach
# als zusätzliche sourcen in die dieses rpm einbinden.
# Sollte also für eine System das devel Packet nicht installierbar sein,
# so ist der korrekte Weg:
# a) download des Packets
# b) umwandel mit "alien -t" in ein tgz
# c) das tgz in der Liste der sources aufführen
# d) cd $RPM_BUILD_DIR/devel und das tgz entpacken
# e) u.U. libs aus der "normalen" Umgebung in die temp
#    devel Umgebung kopieren
# f) die Umgebungsvariabeln C_INCLUDE_PATH und LIBRARY_PATH
#    auf die temporäre devel Umgebung setzten.
rm -rf $RPM_BUILD_DIR/devel 
mkdir $RPM_BUILD_DIR/devel
cd $RPM_BUILD_DIR/devel
zcat $RPM_SOURCE_DIR/libXpm-devel-3.5.5.tgz | tar -xvf - 
zcat $RPM_SOURCE_DIR/gd-devel-2.0.33.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/libjpeg-devel-6b.tgz | tar -xvf -
zcat $RPM_SOURCE_DIR/libpng-devel-1.2.10.tgz | tar -xvf -
cd $RPM_BUILD_DIR/devel/usr/lib64
cp /usr/lib64/libgd.so* .
cp /usr/lib64/libXpm.so* .
cp /usr/lib64/libjpeg.so* .
cp /usr/lib64/libpng*.so* .


%build
cd $RPM_BUILD_DIR/GD-2.46
export PATH=$RPM_BUILD_DIR/devel/usr/bin:$PATH
export C_INCLUDE_PATH=$RPM_BUILD_DIR/devel/usr/include
export LIBRARY_PATH=/usr/lib64:$RPM_BUILD_DIR/devel/usr/lib64
#export LD_LIBRARY_PATH=$LIBRARY_PATH
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/GD-2.46
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/GD-2.46
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/bin/bdf2gdfont.pl
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD/Group.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD/Image.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD/Polygon.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD/Polyline.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/GD/Simple.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/GD/GD.so
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/GD/autosplit.ix
/apps/perlmod/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/qd.pl
/apps/perlmod/share/man/man*/*
