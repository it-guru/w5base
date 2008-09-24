VERSION=0.6.0
PACKAGE=strhash


CC=gcc
L=./auto-link.sh
C=./auto-compile.sh
W=./auto-compilew.sh
PACKAGE_VERSION=$(PACKAGE)-$(VERSION)
PREMAKE_DEFS=-DPACKAGE_VERSION=\"$(PACKAGE)-$(VERSION)\" \
 -DPACKAGE=\"$(PACKAGE)\" -DVERSION=\"$(VERSION)\" -DPACKAGE_CLASS=\"$(CLASS)\"

TARGETS=$(EXTRA_TARGETS) $(PREMAKE_TARGETS)
CLEANFILES=$(EXTRA_CLEANFILES) $(PREMAKE_CLEANFILES)
MAINTAINER_CLEANFILES=$(EXTRA_MAINTAINER_CLEANFILES) $(PREMAKE_MAINTAINER_CLEANFILES)
PREMAKE_DIST=$(PACKAGE_VERSION).tar.gz


#
#
#


#!G:libstrhash.pod:libstrhash.3:libstrhash.html:the strhash library
#!G:integration.pod:libstrhash-integration.3:integration.html:how to integrate strhash into your projects

PREMAKE_TARGETS = libstrhash-integration.3 libstrhash.3
 
PREMAKE_CLEANFILES = fsync.o fsync.lib gettimeofday.lib \
auto-have_futimes.h inet_aton.o inet_aton.lib socket.lib socklen_t.h \
socklen_t.stamp ssize_t.h ssize_t.stamp utimes.o utimes.lib vfork.o \
vfork.lib auto-have_ftruncate.h libstrhash-integration.3.t \
libstrhash.3.t integration.html.t libstrhash.html.t pod2html-itemcache \
pod2html-dircache pod2htmi.x~~ pod2htmd.x~~ auto-typesize.h \
auto-typesize.stamp *.stamp
 
PREMAKE_MAINTAINER_CLEANFILES = libstrhash-integration.3 libstrhash.3 \
integration.html libstrhash.html
 

libbyte_a_SOURCES=str_len.c byte_copy.c fmt_ulong.c byte_cr.c \
byte_chr.c scan_ulong.c 
libbyte_a_OBJECTS=$(libbyte_a_SOURCES:.c=.o)
 
libstrhash_a_SOURCES=strhash_crea.c strhash_dest.c strhash_ente.c \
strhash_del.c strhash_look.c strhash_get.c strhash_walk.c \
strhash_chng.c strhash_hash.c strhash_save.c strhash_load.c 
libstrhash_a_OBJECTS=$(libstrhash_a_SOURCES:.c=.o)
 
libunix_a_SOURCES=buffer_2.c buffer_put.c error.c error_str.c getln.c \
stralloc_catb.c stralloc_plus.c gen_alloc_lus.c gen_alloc_ady.c \
alloc.c alloc_re.c buffer_get.c buffer.c open_read.c open_trunc.c \
stralloc_eady.c stralloc_free.c 
libunix_a_OBJECTS=$(libunix_a_SOURCES:.c=.o)
 
libuomisc_a_SOURCES=bailout.c 
libuomisc_a_OBJECTS=$(libuomisc_a_SOURCES:.c=.o)
 
PREMAKE_EXTRA_SYSTYPE = auto-systype.lfs auto-have_utimes.h
 
all:  auto-systype $(TARGETS) $(EXTRA_TARGETS)
 
auto-alias.h:have_alias.sh auto-compile.sh auto-link.sh
	sh have_alias.sh >$@.t && mv $@.t $@
auto-typesize.h: auto-typesize.stamp
auto-typesize.stamp: typesize.sh auto-compile.sh auto-link.sh
	sh typesize.sh >typesize.t
	@if cmp typesize.t auto-typesize.h 2>/dev/null >/dev/null ; then : ; else mv typesize.t auto-typesize.h ; fi
	rm -f typesize.t
	touch $@
libbyte.a: $(libbyte_a_OBJECTS) auto-makelib.sh
	./auto-makelib.sh $@ $(libbyte_a_OBJECTS)
libstrhash.a: $(libstrhash_a_OBJECTS) \
auto-makelib.sh
	./auto-makelib.sh $@ $(libstrhash_a_OBJECTS)
libunix.a: $(libunix_a_OBJECTS) auto-makelib.sh
	./auto-makelib.sh $@ $(libunix_a_OBJECTS)
libuomisc.a: $(libuomisc_a_OBJECTS) auto-makelib.sh
	./auto-makelib.sh $@ $(libuomisc_a_OBJECTS)
libstrhash-integration.3: integration.pod
	pod2man --section 3 --center strhash --release 0.6.0 integration.pod \
>libstrhash-integration.3.t && \
	mv libstrhash-integration.3.t libstrhash-integration.3
libstrhash.3: libstrhash.pod
	pod2man --section 3 --center strhash --release 0.6.0 libstrhash.pod \
>libstrhash.3.t && \
	mv libstrhash.3.t libstrhash.3
integration.html: integration.pod
	pod2html --htmlroot=. --podpath=. --outfile integration.html.t \
--noindex --title "" integration.pod >integration.html.t && mv \
integration.html.t integration.html
libstrhash.html: libstrhash.pod
	pod2html --htmlroot=. --podpath=. --outfile libstrhash.html.t \
--noindex --title "" libstrhash.pod >libstrhash.html.t && mv \
libstrhash.html.t libstrhash.html
html: integration.html libstrhash.html $(EXTRA_HTML)

 
alloc.o: alloc.c alloc.h error.h auto-compilew.sh
	$W  -c alloc.c
alloc_re.o: alloc_re.c alloc.h byte.h auto-compilew.sh
	$W  -c alloc_re.c
bailout.o: bailout.c error.h buffer.h bailout.h fmt.h auto-compilew.sh
	$W  -c bailout.c
buffer.o: buffer.c buffer.h auto-compile.sh
	$C  -c buffer.c
buffer_2.o: buffer_2.c readwrite.h buffer.h auto-compile.sh
	$C  -c buffer_2.c
buffer_get.o: buffer_get.c buffer.h byte.h error.h auto-compile.sh
	$C  -c buffer_get.c
buffer_put.o: buffer_put.c buffer.h str.h byte.h error.h auto-compile.sh
	$C  -c buffer_put.c
byte_chr.o: byte_chr.c byte.h auto-compilew.sh
	$W  -c byte_chr.c
byte_copy.o: byte_copy.c byte.h auto-compilew.sh
	$W  -c byte_copy.c
byte_cr.o: byte_cr.c byte.h auto-compilew.sh
	$W  -c byte_cr.c
error.o: error.c error.h auto-compilew.sh
	$W  -c error.c
error_str.o: error_str.c error.h auto-compilew.sh
	$W  -c error_str.c
fmt_ulong.o: fmt_ulong.c gen_fmt.h fmt.h auto-compilew.sh
	$W  -c fmt_ulong.c
gen_alloc_ady.o: gen_alloc_ady.c alloc.h gen_alloci.h auto-compilew.sh
	$W  -c gen_alloc_ady.c
gen_alloc_lus.o: gen_alloc_lus.c gen_alloci.h auto-compilew.sh
	$W  -c gen_alloc_lus.c
getln.o: getln.c byte.h getln.h buffer.h stralloc.h gen_alloc.h auto-compilew.sh
	$W  -c getln.c
open_read.o: open_read.c open.h auto-compilew.sh
	$W  -c open_read.c
open_trunc.o: open_trunc.c open.h auto-compilew.sh
	$W  -c open_trunc.c
scan_ulong.o: scan_ulong.c gen_scan.h scan.h case.h auto-compilew.sh
	$W  -c scan_ulong.c
str_len.o: str_len.c str.h auto-compilew.sh
	$W  -c str_len.c
stralloc_catb.o: stralloc_catb.c stralloc.h gen_alloc.h byte.h auto-compilew.sh
	$W  -c stralloc_catb.c
stralloc_eady.o: stralloc_eady.c stralloc.h gen_alloc.h gen_alloci.h auto-compilew.sh
	$W  -c stralloc_eady.c
stralloc_free.o: stralloc_free.c stralloc.h gen_alloc.h alloc.h auto-compilew.sh
	$W  -c stralloc_free.c
stralloc_plus.o: stralloc_plus.c stralloc.h gen_alloc.h gen_alloci.h auto-compilew.sh
	$W  -c stralloc_plus.c
strhash_chng.o: strhash_chng.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_chng.c
strhash_crea.o: strhash_crea.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_crea.c
strhash_del.o: strhash_del.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_del.c
strhash_dest.o: strhash_dest.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_dest.c
strhash_ente.o: strhash_ente.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_ente.c
strhash_get.o: strhash_get.c strhashi.h uint32.h typesize.h \
 auto-typesize.h auto-compilew.sh
	$W  -c strhash_get.c
strhash_hash.o: strhash_hash.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_hash.c
strhash_load.o: strhash_load.c strhash_io.h strhash.h uint32.h \
 typesize.h auto-typesize.h buffer.h error.h stralloc.h gen_alloc.h \
 getln.h scan.h auto-compilew.sh
	$W  -c strhash_load.c
strhash_look.o: strhash_look.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_look.c
strhash_save.o: strhash_save.c strhash_io.h strhash.h uint32.h \
 typesize.h auto-typesize.h buffer.h fmt.h error.h auto-compilew.sh
	$W  -c strhash_save.c
strhash_walk.o: strhash_walk.c strhashi.h uint32.h typesize.h \
 auto-typesize.h strhash.h auto-compilew.sh
	$W  -c strhash_walk.c
auto-have_utimes.h: have_func.sh auto-compile.sh auto-link.sh
	sh have_func.sh utimes "#include <sys/time.h>" "utimes(0,0)" "" "" >$@.t && mv $@.t $@
utimes.lib: replace.sh auto-compile.sh auto-link.sh auto-have_utimes.h
	sh replace.sh utimes utimes "" -lsocket >$@.t && mv $@.t $@

rts check: rts-clean  rts-resolve 
rts-clean:
	rm -f rts-failures 
rts-resolve: 
	@if test -f rts-failures ; then echo The following tests failed: ; \
cat rts-failures ; exit 1; fi 
.PRECIOUS: Makefile
remake: clean
	rm -f auto-compile.sh auto-link.sh auto-compilew.sh auto-makelib.sh
packageinfo: 
	@echo version="$(VERSION)"
	@echo package="$(PACKAGE)"
	@echo class="$(CLASS)"

auto-compile.sh auto-compilew.sh auto-makelib.sh auto-link.sh \
auto-systype.lfs: guess-compiler.sh auto-compiler-config
auto-compiler-config: auto-compiler-config.stamp
auto-config: force
	@( for i in conf-cc conf-ld conf-ldflags conf-cflags conf-cflagsw \
	  conf-ar conf-ranlib conf-libs auto-compile.sh auto-compilew.sh \
	  auto-link.sh auto-makelib.sh ; do \
	  echo $$i ; if test -f $$i ; then cat $$i ; fi ;  \
	done ) >$@.t 
	@mv $@.t $@
auto-compiler-config.stamp: auto-config
	@if cmp auto-config $@ ; then : ; else \
	  echo configuration has changed ; \
	  DEFS='$(DEFS)' INCLUDES='$(INCLUDES)' \
	  PREMAKE_DEFS='$(PREMAKE_DEFS)' \
	  sh guess-compiler.sh ; \
	  rm auto-config ; \
	  make auto-config && mv auto-config $@ ; \
	fi 

maintainer-clean: distclean
	rm -f Makefile $(MAINTAINER_CLEANFILES)
distclean: clean
	rm -f $(DISTCLEANFILES) auto-dummy # to avoid "no arguments" error
clean spotless: mostlyclean
	rm -f $(TARGETS) auto-*
	rm -rf deps
mostlyclean:
	rm -f *.o *.a $(CLEANFILES)

NEWS-check:
	@if sed 1q NEWS | grep -e "$(VERSION)" > /dev/null; then :; else \
		echo "NEWS not updated; not releasing" 1>&2; \
		exit 1;                                   \
	fi
	@if grep -e "$(VERSION)" ChangeLog > /dev/null; then :; else \
		echo "ChangeLog not updated; not releasing" 1>&2; \
		exit 1;                                   \
	fi
dist:
	rm -f $(PREMAKE_DIST)
	package
bk-dist: NEWS-check
	bk tag `echo "Release-$(VERSION)" | sed 's/\./-/g'`
	$(MAKE) dist
gpg-dist: dist
	gpg -b --armor $(PREMAKE_DIST)
force:	

auto-systype: auto-typesize.h $(EXTRA_SYSTYPE) $(PREMAKE_EXTRA_SYSTYPE)
	rm -f $@.t
	@echo  >>$@.t
	@echo "PACKAGE: $(PACKAGE) $(VERSION)" >>$@.t
	@echo "REALNAME: $(REALNAME)" >>$@.t
	@echo "uname-a:" `uname -a` >>$@.t
	@echo "uname-s:" `uname -s` >>$@.t
	@echo "uname-r:" `uname -r` >>$@.t
	@echo "uname-v:" `uname -v` >>$@.t
	@echo "uname-m:" `uname -m` >>$@.t
	@echo "linux-ld.so:" `ls /lib/ld-*.so` >>$@.t
	@echo "linux-libc.so:" `ls /lib/libc-*.so` >>$@.t
	cat auto-typesize.h >>$@.t
	if test "x$(PREMAKE_EXTRA_SYSTYPE)$(EXTRA_SYSTYPE)" = x ; then true ; else \
	  for i in $(PREMAKE_EXTRA_SYSTYPE) $(EXTRA_SYSTYPE) dummy ; do \
	    if test "x$$i" = "xdummy" ; then true ; else \
	      grep systype-info $$i 2>/dev/null >> $@.t || exit 0; \
	    fi; \
	  done \
	fi
	mv $@.t $@

strhash.c: $(STRHASH_FILES) strhash.h strhashi.h
	( \
	 echo '#include "strhash.h"' ;  \
	 cat strhashi.h ; \
	 cat strhash_*.c | grep -v '#include.*strhash' \
	) >$@.t
	mv $@.t $@


# this only works for one person on this world.
htmlinstall: $(HTMLINSTALLFILES)
	scp $(HTMLINSTALLFILES) serak.ohse.de:uwe_html/$(PACKAGE)/

check: auto-compilew.sh libbyte.a libunix.a libstrhash.a libuomisc.a
	sh ./docheck
#
install.html: install.html.in
	sed -e "s/@PACKAGE@/$(PACKAGE)/g" \
	-e "s/@VERSION@/$(VERSION)/g" \
	-e "s/@PACKAGE_VERSION@/$(PACKAGE_VERSION)/g" <$@.in >$@.t \
	&& mv $@.t $@
INSTALL: install.html
	lynx -dump install.html >INSTALL.t && mv INSTALL.t $@

