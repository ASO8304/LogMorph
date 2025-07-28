<h1 style="font-family: Vazirmatn, sans-serif; color: #2c3e50;">📊 سیستم پردازش لاگ LogMorph با Logstash و FastAPI</h1>

<p style="font-family: Vazirmatn, sans-serif; font-size: 16px;">
این پروژه، یک سیستم سریع و سبک برای دریافت لاگ‌ها از طریق <strong>UDP</strong>، پردازش با <strong>Logstash</strong> و ذخیره در <strong>PostgreSQL</strong> از طریق <strong>FastAPI</strong> است.
</p>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🔧 پیش‌نیازها</h2>
<ul style="font-family: Vazirmatn, sans-serif;">
  <li>Ubuntu 20.04 یا جدیدتر</li>
  <li>Python 3.10+</li>
  <li>PostgreSQL</li>
  <li>curl / wget</li>
</ul>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">📦 نصب و راه‌اندازی</h2>

<h3 style="font-family: Vazirmatn, sans-serif;">۱. نصب PostgreSQL و ایجاد دیتابیس</h3>
<pre><code>sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
</code></pre>

<h4>ایجاد کاربر و دیتابیس:</h4>
<pre><code>sudo -i -u postgres
psql
CREATE USER aso WITH ENCRYPTED PASSWORD 'aso';
CREATE DATABASE logdb OWNER aso;
GRANT ALL PRIVILEGES ON DATABASE logdb TO aso;
\q
exit
</code></pre>

<hr>

<h3>۲. نصب Logstash به‌صورت دستی (نسخه 9.0.4)</h3>

<p>برای کنترل بیشتر و عملکرد پایدار، Logstash از فایل فشرده رسمی نصب می‌شود:</p>
<pre><code>
wget https://artifacts.elastic.co/downloads/logstash/logstash-9.0.4-linux-x86_64.tar.gz
sudo tar -xzf logstash-9.0.4-linux-x86_64.tar.gz -C /opt
sudo ln -sfn /opt/logstash-9.0.4 /opt/logstash
</code></pre>

<h4>افزودن پیکربندی Logstash:</h4>
<pre><code>sudo mkdir -p /opt/logstash/config/conf.d
sudo cp logstash/logstash.conf /opt/logstash/config/conf.d/logstash.conf
</code></pre>

<h4>افزودن سرویس systemd برای Logstash:</h4>
<pre><code>sudo nano /etc/systemd/system/logstash.service</code></pre>

<p>محتوا:</p>
<pre><code>[Unit]
Description=LogMorph Logstash Service
After=network.target

[Service]
ExecStart=/opt/logstash/bin/logstash -f /opt/logstash/config/conf.d/logstash.conf
Restart=always
User=YOUR_USER
Group=YOUR_USER
WorkingDirectory=/opt/logstash
StandardOutput=journal
StandardError=journal
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
</code></pre>

<p>سپس:</p>
<pre><code>
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl restart logstash
</code></pre>

<hr>

<h3>۳. راه‌اندازی FastAPI و محیط مجازی</h3>
<pre><code>
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
</code></pre>

<h4>ساخت فایل <code>.env</code></h4>
<pre><code>DATABASE_URL=postgresql://aso:aso@localhost:5432/logdb</code></pre>

<h4>اجرای FastAPI</h4>
<pre><code>uvicorn app:app --host 0.0.0.0 --port 10000 --reload</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🚀 ارسال لاگ آزمایشی</h2>

<h3>۱. ساخت فایل لاگ نمونه</h3>
<p>فایلی به نام <code>mylogs.txt</code> بسازید و لاگ‌های دلخواه را در آن قرار دهید.</p>

<h3>۲. اجرای اسکریپت ارسال لاگ</h3>
<pre><code>
cp tools/send_logs.sh .
chmod +x send_logs.sh
./send_logs.sh
</code></pre>

<p>این اسکریپت لاگ‌ها را با فاصله 0.1 ثانیه از طریق UDP به Logstash ارسال می‌کند.</p>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🧾 مشاهده لاگ‌ها در دیتابیس</h2>

<pre><code>psql -U aso -d logdb -c "SELECT * FROM logs ORDER BY id DESC LIMIT 10;"</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🔍 بررسی لاگ‌ها و سرویس‌ها</h2>

<h4>لاگ‌های Logstash:</h4>
<pre><code>journalctl -u logstash -f</code></pre>

<h4>لاگ‌های FastAPI (زمان اجرا):</h4>
<pre><code>uvicorn app:app --reload --host 0.0.0.0 --port 10000</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">📌 نکات تکمیلی</h2>
<ul style="font-family: Vazirmatn, sans-serif;">
  <li>اطمینان حاصل کنید FastAPI قبل از Logstash اجرا شده باشد.</li>
  <li>پورت UDP در Logstash را می‌توانید در فایل <code>logstash.conf</code> تغییر دهید.</li>
  <li>آدرس مقصد HTTP در خروجی Logstash باید با آدرس سرور FastAPI هماهنگ باشد.</li>
  <li>از محیط مجازی پایتون استفاده کنید تا از تداخل پکیج‌ها جلوگیری شود.</li>
  <li>برای امنیت بیشتر، از کلید API در ورودی FastAPI استفاده کنید.</li>
</ul>
