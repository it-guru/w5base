Der DNS Resolver wird über das eBusiness System abgewickelt.
Es handelt sich um ein PHP Programm, das auf dem Server ebs14@ebwebp05-new
über den OKS Server abgelegt ist.

Inst mit ...
rsync -r . ebwebp05-new:/ag/www/ebs14/projekt_restdns/htdocs

Zugang dann über die URL:
https://ebs14.telekom.de/dns/resolv.php?q=performance.telekom.de

