-- noinspection SqlDialectInspectionForFile

-- noinspection SqlNoDataSourceInspectionForFile

-- CREATE DATABASE db;
-- DROP DATABASE db;

CREATE TABLE users (
                       name VARCHAR(100),
                       email VARCHAR(100),
                       username VARCHAR(100),
                       password_id INT
);

CREATE TABLE passwords (
                           password_id INT AUTO_INCREMENT PRIMARY KEY,
                           password VARCHAR(100),
                           salt VARCHAR(100)
);

INSERT INTO passwords (password, salt) VALUES ('adminpass', 'salt');

SET @admin_password_id = LAST_INSERT_ID();

INSERT INTO users (name, email, username, password_id) VALUES ('Admin', 'admin@example.com', 'admin', @admin_password_id);

-- UPDATE passwords SET password = 'adminpass123' WHERE password_id = 1;
-- SELECT * FROM passwords;
-- SELECT * FROM users;