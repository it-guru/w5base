MOD=base/user base/grp itil/appl itil/system AL_TCom/appl
MOD=base/grp base/user base/workflow AL_TCom/workflow/businesreq base/MyW5Base/wfmyjobs
all:
	@(rm -Rf net; exit 0)
	@( for m in $(MOD); do  \
        URL="http://localhost/w5base2/public/base/interface/WSDL/$${m}"; \
	echo "loading $${URL}"; \
	java org.apache.axis.wsdl.WSDL2Java \
		$${URL}; \
	 done )
	find net | wc -l

compile:
	javac *.java
	find net -name \*.class
