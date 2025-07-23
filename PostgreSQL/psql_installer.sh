# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Ensure PostgreSQL runs on boot
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Switch to the PostgreSQL user
sudo -i -u postgres

# Open the PostgreSQL shell
psql

# Inside the psql shell, create your user and database:
### >>> CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
### >>> CREATE DATABASE mydb OWNER myuser;
### >>> GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;

# Exit back to your normal user
exit

# --- Allow Remote Connections ---
# Edit the PostgreSQL configuration file to allow remote connections
sudo vim /etc/postgresql/*/main/postgresql.conf

# Uncomment the following line to allow connections from any IP address
listen_addresses = '*'

# Edit pg_hba.conf
sudo vim /etc/postgresql/*/main/pg_hba.conf

# Add this line at the bottom:
host    all             all             0.0.0.0/0               md5

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# --- Install psycopg2 for Python for testing purpose ---
pip install psycopg2-binary

# test_postgres_connection.py: 
### import psycopg2
### from psycopg2 import OperationalError
### 
### def test_connection():
###     try:
###         conn = psycopg2.connect(
###             dbname="mydb",         # Replace with your DB name
###             user="myuser",         # Replace with your DB user
###             password="mypassword", # Replace with your password
###             host="your_server_ip", # Replace with your server's IP
###             port="5432"            # Default PostgreSQL port
###         )
###         print("✅ Connected to PostgreSQL server successfully.")
###         conn.close()
###     except OperationalError as e:
###         print("❌ Connection failed.")
###         print(f"Error: {e}")
### 
### if __name__ == "__main__":
###     test_connection()


# To connect to the database using psql
psql -d your_database_name -U your_db_user