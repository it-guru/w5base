MOD=base/grp base/user base/workflow AL_TCom/workflow/businesreq base/MyW5Base/wfmyjobs AL_TCom/workflow/change itil/appl AL_TCom/custcontract base/filemgmt 

HOST=localhost
CONFIG=w5base2
all:
	@(rm -Rf net; exit 0)
	@( for m in $(MOD); do  \
        URL="http://$(HOST)/$(CONFIG)/public/base/interface/WSDL/$${m}"; \
	echo "loading $${URL}"; \
	java -Dhttp.proxyHost=localhost -Dhttp.proxyPort=11833 org.apache.axis.wsdl.WSDL2Java  \
		$${URL}; \
	 done )
	find net | wc -l

compile:
	javac *.java
	find net -name \*.class
