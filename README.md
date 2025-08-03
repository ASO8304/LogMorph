<!DOCTYPE html>
<html lang="en">
<body style="font-family: Arial, sans-serif; color: #2c3e50; line-height: 1.6;">

<h1>📊 LogMorph Log Processing System with Logstash and FastAPI</h1>

<p>This project is a fast and lightweight system for receiving logs via <strong>UDP</strong>, processing with <strong>Logstash</strong>, and storing them in <strong>PostgreSQL</strong> using <strong>FastAPI</strong>.</p>

<hr>

<h2>🔧 Requirements</h2>
<ul>
  <li>Ubuntu 20.04+</li>
  <li><strong>Python 3.10+</strong> with <code>venv</code> module</li>
  <li><strong>pip</strong></li>
  <li><strong>PostgreSQL 12+</strong></li>
  <li><strong>socat</strong> (for sending test logs via UDP)</li>
</ul>

<p>The installation script will automatically install any missing tools, but it's recommended to update your system beforehand.</p>

<hr>

<h2>📦 Installation and Setup</h2>

<h3>1. Install PostgreSQL and Create Database</h3>
<pre><code>sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
</code></pre>

<h4>Create a user and database:</h4>
<pre><code>sudo -i -u postgres
psql
CREATE USER aso WITH ENCRYPTED PASSWORD 'aso';
CREATE DATABASE logdb OWNER aso;
GRANT ALL PRIVILEGES ON DATABASE logdb TO aso;
\q
exit
</code></pre>

<hr>

<h4>Enable Remote Access to PostgreSQL</h4>

<p><strong>⚠️ Important:</strong> You should restrict access to only the IPs that need it. Avoid using <code>'*'</code> or <code>0.0.0.0/0</code> unless absolutely necessary.</p>

<h5>1. Edit <code>postgresql.conf</code> to listen on specific IPs:</h5>
<pre><code>sudo nano /etc/postgresql/*/main/postgresql.conf</code></pre>
<p>Change:</p>
<pre><code>listen_addresses = 'localhost'</code></pre>
<p>To (examples):</p>
<ul>
  <li><code>listen_addresses = 'localhost,192.168.1.100'</code> (only allow local + 192.168.1.100)</li>
  <li><code>listen_addresses = '*'</code> (allow all — not recommended)</li>
</ul>

<h5>2. Edit <code>pg_hba.conf</code> to limit who can connect:</h5>
<pre><code>sudo nano /etc/postgresql/*/main/pg_hba.conf</code></pre>

<p>Example — allow only a specific IP (e.g. 192.168.1.100):</p>
<pre><code>host    all             all             192.168.1.100/32         md5</code></pre>

<p>Example — allow a subnet (e.g. 192.168.1.0/24):</p>
<pre><code>host    all             all             192.168.1.0/24           md5</code></pre>

<p><strong>❌ Avoid this unless you really need it:</strong></p>
<pre><code>host    all             all             0.0.0.0/0               md5</code></pre>

<h5>3. Restart PostgreSQL:</h5>
<pre><code>sudo systemctl restart postgresql</code></pre>

<hr>

<h3>2. Install and Configure Logstash</h3>

<p><strong>✅ Recommended: Run the setup script:</strong></p>
<pre><code>bash scripts/setup_logstash.sh</code></pre>

<p>This script performs the following tasks automatically:</p>
<ul>
  <li>Downloads and extracts Logstash version 9.0.4</li>
  <li>Creates a symbolic link at <code>/opt/logstash</code></li>
  <li>Copies the <code>logstash.conf</code> file to <code>/opt/logstash/config/conf.d/</code></li>
  <li>Creates and installs a <code>systemd</code> service for Logstash</li>
  <li>Reloads and enables the Logstash service to start at boot</li>
  <li>Starts the Logstash service</li>
</ul>

<p>After running the script, Logstash will start automatically and begin listening for logs according to the configuration file located at <code>/opt/logstash/config/conf.d/logstash.conf</code>. You can edit this file to adjust inputs, filters, or outputs as needed.</p>

<h4>📡 Monitor Logstash Status and Logs</h4>
<p>To view real-time Logstash logs:</p>
<pre><code>journalctl -u logstash.service -f</code></pre>

<p>To check the status of the Logstash service:</p>
<pre><code>systemctl status logstash.service</code></pre>

<h3>3. Set Up FastAPI</h3>

<p><strong>✅ Recommended: Run the setup script:</strong></p>
<pre><code>bash scripts/setup_fastapi.sh</code></pre>

<p>This script automatically performs the following actions:</p>
<ul>
  <li>Creates a dedicated system user named <code>fastapi</code> to run the service securely</li>
  <li>Creates a Python virtual environment</li>
  <li>Installs all required Python dependencies via <code>requirements.txt</code></li>
  <li>Creates a <code>systemd</code> service to run FastAPI using <code>uvicorn</code></li>
  <li>Registers and enables the FastAPI service to start on boot</li>
  <li>Starts the FastAPI application on port <code>10000</code></li>
</ul>

<h4>🌐 Configure the database connection</h4>
<p>Before running the FastAPI service, make sure to create a <code>.env</code> file in the project root with your database URL:</p>
<pre><code>DATABASE_URL=postgresql://&lt;username&gt;:&lt;password&gt;@&lt;postgres_ip&gt;:&lt;postgres_port&gt;/&lt;database_name&gt;</code></pre>
<p>Example:</p>
<pre><code>DATABASE_URL=postgresql://aso:aso@localhost:5432/logdb</code></pre>

<h4>📡 Monitor FastAPI Logs</h4>
<p>To view FastAPI logs in real-time:</p>
<pre><code>journalctl -u fastapi.service -f</code></pre>

<p>To check the status of the FastAPI service:</p>
<pre><code>systemctl status fastapi.service</code></pre>

<hr>

<h2>🚀 Send Test Logs</h2>

<h3>1. Create a Sample Log File</h3>
<p>Create a file named <code>mylogs.txt</code> in the project root and populate it with sample log lines (each line represents a log entry).</p>

<h3>2. Run the Log Simulation Script</h3>
<pre><code>
bash scripts/log_simulator.sh
</code></pre>

<p>This script does the following:</p>
<ul>
  <li>Verifies the existence of <code>mylogs.txt</code></li>
  <li>Automatically installs <code>socat</code> if it is not already installed</li>
  <li>Sends each line from <code>mylogs.txt</code> to Logstash via UDP (default: <code>localhost:5140</code>)</li>
  <li>Delays each line by 0.01 seconds (simulates ~100 logs/second)</li>
</ul>

<p>You can modify the target <strong>HOST</strong>, <strong>PORT</strong>, or log file path inside the script if needed.</p>

<hr>

<h2>🧾 View Logs in Database</h2>
<pre><code>psql -U aso -d logdb -c "SELECT * FROM logs ORDER BY id DESC LIMIT 10;"</code></pre>

<hr>

<h2>🔍 Check Logs and Services</h2>

<h4>View Logstash logs:</h4>
<pre><code>journalctl -u logstash -f</code></pre>

<h4>Manually run FastAPI with logging:</h4>
<pre><code>uvicorn app:app --reload --host 0.0.0.0 --port 10000</code></pre>

<hr>

<h2>📌 Additional Notes</h2>
<ul>
  <li>Ensure FastAPI is running before Logstash.</li>
  <li>You can change the UDP port in <code>logstash.conf</code>.</li>
  <li>FastAPI address in Logstash config must match the actual destination.</li>
  <li>Use Python virtual environments to prevent package conflicts.</li>
  <li>Consider using an API key for FastAPI for security.</li>
  <li>Ensure PostgreSQL remote access settings are properly configured.</li>
</ul>

</body>
</html>
