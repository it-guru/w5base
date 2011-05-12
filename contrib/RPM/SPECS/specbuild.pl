#!/bin/env perl
use LWP::Simple;
use strict;

my $label=shift(@ARGV);
my $url=shift(@ARGV);

my $file=$url;
$file=~s/^.*\///;

my $dir=$file;
$dir=~s/(\.tgz|\.tar.gz)$//;

my $version=$dir;
$version=~s/^.*-//;

my $name=$dir;
$name=~s/-\d.*$//;

my $module=$name;
$module=~s/-/::/g;

my $dist="RH55";

my $spec="apps-perlmod-${name}-${dist}.spec";

printf("Label    : %s\n",$label);
printf("Download : %s\n",$url);
printf("File     : %s\n",$file);
printf("Directory: %s\n",$dir);
printf("Version  : %s\n",$version);
printf("Name     : %s\n",$name);
printf("Module   : %s\n",$module);
printf("Distri   : %s\n",$dist);
printf("SPEC     : %s\n",$spec);

if (! -f $spec){
   printf("< Press Enter if OK >\n");
   my $key=<STDIN>;
   printf STDERR ("INFO:  download $file\n");
   getstore($url, "../SOURCES/$file");
   printf STDERR ("INFO:  wirte spec $spec\n");
   open(F,">$spec");
}
else{
   printf STDERR ("ERROR: spec $spec alread exists\n");
   exit(1);
}



printf F ("%s",<<EOF);
Summary: ${label} AppCom perl Modules at /apps
Name: apps-perlmod-${name}-${dist}
Version: ${version}
Release: 1
License: GPL
Group: Applications/Web
Source0: ${url}
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler\@t-systems.com>
BuildRoot: \%{_tmppath}/\%{name}-\%{version}-\%{release}-root-\%(\%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

\%description
Perl Module ${label} installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

\%prep
rm -rf \$RPM_BUILD_DIR/${dir}
zcat \$RPM_SOURCE_DIR/${file} | tar -xvf -

\%build
cd \$RPM_BUILD_DIR/${dir}
\%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

\%install
rm -rf \$RPM_BUILD_ROOT
cd \$RPM_BUILD_DIR/${dir}
pwd
make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT
find \$RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find \$RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find \$RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w \$RPM_BUILD_ROOT/*


\%check || :
cd \$RPM_BUILD_DIR/${dir}
#make test

\%clean
rm -rf \$RPM_BUILD_ROOT

\%files
\%defattr(-,root,root,-)
/apps/perlmod/bin/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/Data/*.pm
/apps/perlmod/lib64/perl5/site_perl/5.8.8/Data/*.pm
/apps/perlmod/share/man/man*/*
EOF

close(F);
