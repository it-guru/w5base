Summary: PDF::Reuse AppCom perl Modules at /apps
Name: apps-perlmod-PDF-Reuse-RH56
Version: 0.35
Release: 1
License: GPL
Group: Applications/Web
Source0: http://search.cpan.org/CPAN/authors/id/L/LA/LARSLUND/PDF-Reuse-0.35.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Holger Förster <holger.foerster@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0


%description
Perl Module PDF::Reuse installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm


%prep
rm -rf $RPM_BUILD_DIR/PDF-Reuse-0.35
zcat $RPM_SOURCE_DIR/PDF-Reuse-0.35.tar.gz | tar -xvf -


%build
cd $RPM_BUILD_DIR/PDF-Reuse-0.35
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/PDF-Reuse-0.35
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/PDF/Reuse.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/PDF/Reuse/Util.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/AcroFormsEtc.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/analysera.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/autosplit.ix
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/behandlaNames.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/byggForm.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/calcMatrix.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/checkContentStream.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/checkResources.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/createCharProcs.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/crossrefObj.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/defInit.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/defLadda.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/descend.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/errLog.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/extractName.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/extractObject.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/fillTheForm.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/findBarFont.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/findDir.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/getImage.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/getKnown.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/getObject.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/getPage.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/inkludera.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/kolla.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/mergeLinks.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/ordnaBookmarks.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prBar.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prBookmark.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prCid.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prCompress.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prDoc.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prDocDir.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prDocForm.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prExtract.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prField.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prGetLogBuffer.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prGraphState.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prId.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prIdType.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prImage.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prInit.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prInitVars.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prJpeg.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prJs.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prLink.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prLog.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prLogDir.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prMbox.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prSinglePage.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prTouchUp.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prVers.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/prep.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/quickxform.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/sidAnalys.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/skrivJS.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/skrivKedja.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/translate.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/unZipPrepare.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/xRefs.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/xform.al
/apps/perlmod/lib/perl5/site_perl/5.8.8/auto/PDF/Reuse/xrefSection.al
/apps/perlmod/share/man/man*/*
