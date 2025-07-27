<h1 style="font-family: Vazirmatn, sans-serif; color: #2c3e50;">📊 سیستم پردازش لاگ با Logstash و FastAPI</h1>

<p style="font-family: Vazirmatn, sans-serif; font-size: 16px;">
این پروژه یک سیستم سبک و سریع برای دریافت لاگ‌ها از طریق UDP، پردازش آنها با <strong>Logstash</strong> و ذخیره در دیتابیس <strong>PostgreSQL</strong> از طریق <strong>FastAPI</strong> است.
</p>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🔧 پیش‌نیازها</h2>
<ul style="font-family: Vazirmatn, sans-serif;">
  <li>Python 3.10+</li>
  <li>PostgreSQL</li>
  <li>Logstash</li>
  <li>socat (برای تست ارسال لاگ)</li>
</ul>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">📦 نصب و راه‌اندازی</h2>

<h3>۱. نصب PostgreSQL</h3>
<pre><code>sudo apt update
sudo apt install postgresql postgresql-contrib
sudo -u postgres psql
</code></pre>
<pre><code>CREATE DATABASE logdb;
CREATE USER &lt;username&gt; WITH PASSWORD &lt;username&gt;;
GRANT ALL PRIVILEGES ON DATABASE logdb TO &lt;username&gt;;
\q
</code></pre>

<h3>۲. نصب Logstash</h3>
<pre><code>sudo apt install logstash</code></pre>

<h3>۳. نصب FastAPI و پکیج‌های مورد نیاز</h3>
<pre><code>pip install fastapi uvicorn[standard] sqlalchemy psycopg2</code></pre>

<h3>۴. ساخت فایل <code>app.py</code></h3>
<p>در دایرکتوری پروژه، فایلی به نام <code>app.py</code> بسازید و کد FastAPI را در آن قرار دهید. (کدی که لاگ‌ها را در دیتابیس ذخیره می‌کند)</p>

<h3>۵. اجرای FastAPI</h3>
<pre><code>uvicorn app:app --host 0.0.0.0 --port 10000</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🧾 پیکربندی Logstash</h2>

<h3>۱. کپی فایل کانفیگ از دایرکتوری پروژه</h3>

<p style="font-family: Vazirmatn, sans-serif;">
پس از کلون کردن مخزن پروژه، فایلی به نام <code>logmorph.conf</code> در پوشه پروژه موجود است. با دستور زیر، آن را به مسیر مناسب در Logstash کپی کنید:
</p>

<pre><code>
sudo cp logmorph.conf /etc/logstash/conf.d/
</code></pre>


<h3>۲. اجرای Logstash</h3>
<pre><code>
sudo systemctl restart logstash
sudo systemctl enable logstash
</code></pre>

<h2 style="font-family: Vazirmatn, sans-serif;">🚀 تست سیستم با فایل لاگ</h2>

<h3>۱. ساخت فایل <code>mylogs.txt</code></h3>

<pre><code>
in_mac=aa:bb:cc:dd:ee:ff out_mac=ff:ee:dd:cc:bb:aa dir=in len=60 proto=6 src_ip=192.168.1.10 dst_ip=8.8.8.8 src_port=12345 dst_port=53 description=DNS_request
in_mac=aa:bb:cc:dd:ee:11 out_mac=ff:ee:dd:cc:bb:22 dir=out len=74 proto=17 src_ip=10.0.0.1 dst_ip=192.168.1.100 src_port=5678 dst_port=443 description=TLS
</code></pre>

<h3>۲. ساخت اسکریپت <code>simulate_logs.sh</code></h3>
<pre><code>
#!/bin/bash

LOG_FILE="mylogs.txt"
HOST="localhost"
PORT=5140

if [ ! -f "$LOG_FILE" ]; then
  echo "Log file not found: $LOG_FILE"
  exit 1
fi

echo "📤 Starting log simulation to $HOST:$PORT..."

while IFS= read -r line; do
  socat - UDP4-DATAGRAM:$HOST:$PORT <<< "$line" > /dev/null 2>&1
  echo "$line"
  sleep 0.1
done &lt; "$LOG_FILE"

echo "✅ Finished sending all logs."
</code></pre>

<h3>۳. اجرای تست</h3>

<pre><code>
chmod +x simulate_logs.sh
./simulate_logs.sh
</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">📦 مشاهده لاگ‌ها در دیتابیس</h2>

<p>برای مشاهده لاگ‌های وارد شده:</p>

<pre><code>
psql -U &lt;username&gt; -d logdb -c "SELECT * FROM logs ORDER BY id DESC LIMIT 10;"
</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🔍 بررسی لاگ‌های سرویس‌ها</h2>

<h4>بررسی لاگ FastAPI:</h4>
<pre><code>uvicorn app:app --host 0.0.0.0 --port 10000</code></pre>

<h4>بررسی لاگ Logstash:</h4>
<pre><code>journalctl -u logstash -f</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🧠 نکات تکمیلی</h2>
<ul style="font-family: Vazirmatn, sans-serif;">
  <li>در صورت نیاز به تغییر پورت UDP در Logstash، مقدار <code>port => 5140</code> را ویرایش کنید.</li>
  <li>آدرس FastAPI در بخش خروجی Logstash باید با آدرس سرور شما هماهنگ باشد.</li>
  <li>در صورت نیاز به احراز هویت، می‌توانید هدر یا توکن نیز به خروجی Logstash اضافه کنید.</li>
</ul>

<hr>

