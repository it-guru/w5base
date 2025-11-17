create database w5db;
CREATE USER 'w5app'@'172.%' IDENTIFIED BY 'w5app';
GRANT ALL PRIVILEGES ON w5db.* TO 'w5app'@'172.%';
FLUSH PRIVILEGES;

