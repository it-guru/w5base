MOD=base/user base/grp itil/appl itil/system AL_TCom/appl
MOD=base/grp base/user base/workflow AL_TCom/workflow/businesreq
all:
	@(rm -Rf net; exit 0)
	@( for m in $(MOD); do  echo "loading $${m}"; \
	java org.apache.axis.wsdl.WSDL2Java \
		http://localhost/w5base2/public/base/interface/WSDL/$${m}; \
	 done )
	find net

compile:
	javac *.java
	find net -name \*.class
