#!/bin/bash

set -e

. db-creds.txt

echo "${JOEY_KEY}" >> ~/.ssh/authorized_keys

case $1 in
	staging) PG_PW=${PW_STAGING} ;;
	prod)    PG_PW=${PW_PROD} ;;
	*) echo Usage: $0 "[ staging | prod ]" ; exit 1 ;;
esac

sudo apt update
sudo apt install -y postgresql-9.5

# configure pg_hba.conf
(
	printf "host all all 10.240.0.0/16 md5\n"
	printf "host all all 0.0.0.0/0 md5\n"
) | sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf

# configure postgresql.conf
echo "effective_cache_size = 24GB" | \
	sudo tee -a /etc/postgresql/9.5/main/postgresql.conf
sudo sed -i \
	-e '/^shared_buffers = /s/=.*/= 8192MB/' \
	/etc/postgresql/9.5/main/postgresql.conf

# set the postgres password
echo "alter user postgres with encrypted password '${PG_PW}';" | \
	sudo -u postgres psql

export PGPASSWORD=${PG_PW}

# now that a password has been set, require the postgres password locally
sudo sed -i \
	-e "/^.listen_addresses/s/.*/listen_addresses = '*'/" \
	/etc/postgresql/9.5/main/postgresql.conf

sudo sed -i \
	-e '/^local.*postgres/s/peer/md5/' \
	/etc/postgresql/9.5/main/pg_hba.conf

sudo systemctl restart postgresql

# Fetch the data
wget ${DATA_URL}
_db_file=$(basename ${DATA_URL})

echo "CREATE DATABASE ${DB_NAME};" | psql -U postgres

bunzip2 -c ${_db_file} | psql -U postgres --dbname ${DB_NAME}

echo """
    DROP TABLE IF EXISTS students;
    CREATE TABLE students(
        name TEXT,
        gpa FLOAT CHECK (gpa >= 0.0 and gpa <= 4.0),
        age INTEGER,
        dept TEXT,
        gender CHAR,
        studentid INT PRIMARY KEY
        );
    INSERT INTO students VALUES
    ('Sergey Brin', 2.8, 40, 'CS', 'M',0),
    ('Danah Boyd', 3.9, 35, 'CS', 'F',1),
    ('Bill Gates', 1.0, 60, 'CS', 'M',2),
    ('Hillary Mason', 4.0, 35, 'DATASCI', 'F',3),
    ('Mike Olson', 3.7, 50, 'CS', 'M',4),
    ('Mark Zuckerberg', 4.0, 30, 'CS', 'M',5),
    ('Cheryl Sandberg', 4.0, 47, 'BUSINESS', 'F',6),
    ('Susan Wojcicki', 4.0, 46, 'BUSINESS', 'F',7),
    ('Marissa Meyer', 4.0, 45, 'BUSINESS', 'F',8);
""" | psql -U postgres --dbname ${DB_NAME}

echo """
REVOKE CREATE ON SCHEMA public FROM public;
CREATE ROLE student WITH LOGIN PASSWORD '${PW_STUDENT}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO student;
""" | psql -U postgres --dbname ${DB_NAME}
