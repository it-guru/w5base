FROM oraclelinux:9

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG http_proxy
ARG https_proxy

ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}

COPY certs/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
COPY certs/apache-selfsigned.crt /etc/pki/tls/certs/apache-selfsigned.crt
COPY certs/apache-selfsigned.key /etc/pki/tls/private/apache-selfsigned.key

RUN update-ca-trust extract

RUN dnf config-manager --enable ol9_appstream
COPY repos/ /etc/yum.repos.d/

RUN dnf makecache


RUN dnf -y install \
      supervisor httpd busybox postfix net-tools \
      httpd httpd-devel httpd-tools \
      mod_fcgid mod_ssl mod_auth_openidc mod_auth_ae \
      curl jq wget git netcat \
      expect libaio patch s-nail \
      perl openssl-devel gd gd-devel \
      unixODBC unixODBC-devel \
      MariaDB-shared MariaDB-client MariaDB-devel \
      python3  python3-devel  \
      perl-libwww-perl \
      perl-JSON \
      perl-FCGI \
      perl-Env-C \
      perl-Time-HiRes \
      perl-IO-stringy \
      perl-Data-Printer \
      perl-Unicode-UTF8 \
      perl-Unicode-MapUTF8 \
      perl-Apache-DBI \
      perl-DBD-ODBC \
      perl-App-cpanminus \
      perl-Archive-Zip \
      perl-CGI \
      perl-Class-ISA \
      perl-Crypt-OpenSSL-RSA \
      perl-Unicode-String \
      perl-Data-HexDump \
      perl-DBD-MySQL \
      perl-DBD-Pg \
      perl-DBI \
      perl-Digest-MD5 \
      perl-ExtUtils-CBuilder \
      perl-ExtUtils-Install \
      perl-ExtUtils-MakeMaker \
      perl-ExtUtils-Manifest \
      perl-ExtUtils-ParseXS \
      perl-FCGI \
      perl-IO-Multiplex \
      perl-IO-Socket-INET6 \
      perl-LDAP \
      perl-libxml-perl \
      perl-LWP-Protocol-https \
      perl-MailTools \
      perl-Net-Server \
      perl-NetAddr-IP \
      perl-IPC-SysV \
      perl-Socket6 \
      perl-Sys-Syslog \
      perl-Time-HiRes \
      perl-XML-Parser \
      perl-XML-Simple \
      perl-UUID-Tiny \
      perl-HTML-Format \
      perl-HTML-Tree \
      perl-HTML-TreeBuilder-LibXML \
      perl-HTML-TreeBuilder-XPath \
      perl-Moose \
      perl-Crypt-DES \
      perl-Crypt-OpenSSL-X509 \
      perl-GD \
      perl-MIME-tools \
      perl-Proc-ProcessTable \
      perl-Set-Infinite \
      perl-Text-CSV_XS \
      perl-Crypt-OpenSSL-Random \
      perl-Crypt-OpenSSL-RSA \
      perl-Crypt-OpenSSL-Bignum \
      perl-DateTime \
      perl-DateTime-Set \
      perl-DateTime-Format-Strptime \
      perl-DateTime-Locale \
      perl-DateTime-Format-ISO8601 \
      perl-Data-Dumper \
      perl-Date-Calc \
      perl-DTP \
      perl-Class-ISA \
      perl-RPC-Smart \
      perl-HTML-TagFilter \
      perl-HTTP-Daemon \
      perl-LWP-Protocol-connect \
      perl-Net-SFTP-Foreign \
      perl-Object-MultiType \
      perl-PDF-Reuse \
      perl-SOAP-Lite \
      perl-Spreadsheet-ParseExcel \
      perl-Spreadsheet-WriteExcel \
      perl-XML-Smart \
      perl-URL-Encode \
      perl-MooseX-ClassAttribute \
      perl-JSON-MaybeXS \
      perl-URI-Template \
      perl-Paws \
      perl-Net-Amazon-Signature-V4 \
      perl-DBD-Oracle 


COPY apache.conf.d/ /etc/httpd/conf.d/
COPY supervisord.d/ /etc/supervisord.d/
COPY bin/ /bin/
COPY etc/ /etc/
COPY acache/ /etc/acache/
COPY w5base/ /etc/w5base/

# Dummy-Verzeichnisse und Datei nur zur Klarstellung
RUN mkdir -p /etc/w5base \
    && mkdir -p /etc/oracle \
    && mkdir -p /opt/w5base \
    && mkdir -p /opt/w5darwin \
    && mkdir -p /var/log/httpd \
    && mkdir -p /var/log/w5base \
    && touch /etc/odbc.ini

CMD ["/bin/init.sh"]

