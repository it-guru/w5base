all: package/compile
	./package/compile
install: package/install
	./package/install
check: package/check compile/Makefile
	./package/check
compile/Makefile: all
oldinstall: all check
	if test "x$(DEST)" = x ; then echo 'you must set $$DEST: make DEST=/usr/local oldinstall'. ; exit 1 ; fi
	for i in command/* ; do install -c "$$i" $(DEST)/bin/ || exit 1 ; done
	for i in doc/* ; do \
	  case "$$i" in \
	  *.[0-9]) x=`echo "$$i" | sed 's/.*\.//'` ; \
	           install -c $$i $(DEST)/man/man$$x || exit 1 ;; \
	  *) mkdir $(DEST)/doc 2>/dev/null ; \
	     mkdir $(DEST)/doc/strhash-0.6.0 2>/dev/null ; \
	     install -c $$i $(DEST)/doc/strhash-0.6.0/ || exit 1 ;; \
	  esac ; \
	done
