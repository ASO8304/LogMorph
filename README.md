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

<h3 style="font-family: Vazirmatn, sans-serif;">۱. نصب PostgreSQL و تنظیمات اولیه</h3>

<p style="font-family: Vazirmatn, sans-serif;">
ابتدا سیستم را به‌روز کنید و PostgreSQL را نصب کنید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
sudo apt update
sudo apt install postgresql postgresql-contrib
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
برای فعال‌سازی سرویس PostgreSQL در هنگام روشن شدن سیستم و اجرای آن، دستورات زیر را اجرا کنید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
sudo systemctl enable postgresql
sudo systemctl start postgresql
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
برای مدیریت دیتابیس، وارد کاربر postgres شوید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
sudo -i -u postgres
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
حالا وارد محیط psql شوید تا دیتابیس و کاربر بسازید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
psql
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
در محیط psql، دستورات زیر را برای ساخت کاربر و دیتابیس وارد کنید (مقادیر <code>&lt;username&gt;</code> و <code>&lt;password&gt;</code> را با مقادیر دلخواه خود جایگزین کنید):
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
CREATE USER &lt;username&gt; WITH ENCRYPTED PASSWORD '&lt;password&gt;';
CREATE DATABASE logdb OWNER &lt;username&gt;;
GRANT ALL PRIVILEGES ON DATABASE logdb TO &lt;username&gt;;
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
برای خروج از محیط psql دستور زیر را بزنید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
\q
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
و سپس برای خروج از کاربر postgres به کاربر عادی خود بازگردید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
exit
</pre>

<h4 style="font-family: Vazirmatn, sans-serif;">اجازه اتصال از راه دور (اختیاری)</h4>

<p style="font-family: Vazirmatn, sans-serif;">
برای فعال‌کردن اتصال از راه دور، فایل پیکربندی <code>postgresql.conf</code> را ویرایش کنید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
sudo vim /etc/postgresql/*/main/postgresql.conf
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
خط <code>listen_addresses</code> را پیدا کرده و مقدار آن را به <code>'*'</code> تغییر دهید یا از حالت کامنت خارج کنید:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
listen_addresses = '*'
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
سپس فایل <code>pg_hba.conf</code> را ویرایش کرده و خط زیر را به انتهای فایل اضافه کنید تا اتصال از هر IP با رمز عبور مجاز شود:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
host    all             all             0.0.0.0/0               md5
</pre>

<p style="font-family: Vazirmatn, sans-serif;">
در نهایت PostgreSQL را ریستارت کنید تا تنظیمات اعمال شوند:
</p>
<pre style="font-family: 'Courier New', monospace; background-color: #f6f8fa; padding: 15px; border-radius: 8px; overflow-x: auto;">
sudo systemctl restart postgresql
</pre>

<h3>۲. نصب Logstash</h3>
<pre><code>sudo apt install logstash</code></pre>

<h3>۳. ساخت دایرکتوری پروژه و ایجاد محیط مجازی Python (venv)</h3>
<pre><code>mkdir logmorph
cd logmorph
python3 -m venv <venv_name>
source <venv_name>/bin/activate
</code></pre>

<h3>۴. نصب کتابخانه‌های Python مورد نیاز در محیط مجازی</h3>
<pre><code>pip install --upgrade pip
pip install fastapi uvicorn[standard] sqlalchemy psycopg2 requests
</code></pre>

<h3>۵. کپی فایل <code>app.py</code> از دایرکتوری پروژه</h3>
<p>اگر مخزن پروژه را کلون کرده‌اید، کافی است فایل <code>app.py</code> را به پوشه جاری کپی کنید:</p>
<pre><code>cp ../logmorph/app.py .</code></pre>
<p>توجه کنید مسیر <code>../logmorph/app.py</code> باید با مسیر واقعی فایل شما هماهنگ باشد.</p>

<h3>۶. اجرای FastAPI</h3>
<p><strong>توجه:</strong> <br> قبل از اجرای Logstash، حتما باید سرویس FastAPI را اجرا کنید تا لاگ‌ها به مقصد برسند.</p>
<pre><code>source venv/bin/activate
uvicorn app:app --host 0.0.0.0 --port 10000
</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🧾 پیکربندی Logstash</h2>

<h3>۱. کپی فایل کانفیگ از دایرکتوری پروژه</h3>

<p style="font-family: Vazirmatn, sans-serif;">
فایل کانفیگ <code>logmorph.conf</code> داخل پوشه پروژه قرار دارد. برای استفاده، آن را به مسیر اصلی Logstash کپی کنید:
</p>

<pre><code>sudo cp ../logmorph/logmorph.conf /etc/logstash/conf.d/</code></pre>
<p>توجه کنید مسیر <code>../logmorph/logmorph.conf</code> باید با مسیر واقعی فایل شما هماهنگ باشد.</p>

<h3>۲. اجرای Logstash</h3>
<pre><code>sudo systemctl restart logstash
sudo systemctl enable logstash
</code></pre>

<p><strong>توجه:</strong> حتما قبل از اجرای Logstash، FastAPI را با uvicorn اجرا کرده باشید.</p>

<h2 style="font-family: Vazirmatn, sans-serif;">🚀 تست سیستم با فایل لاگ</h2>

<h3>۱. ساخت فایل <code>mylogs.txt</code> با نمونه لاگ‌ها</h3>

<h3>۲. کپی اسکریپت <code>simulate_logs.sh</code> از دایرکتوری پروژه و اجرای آن</h3>

<p>اگر مخزن پروژه را کلون کرده‌اید، کافی است فایل <code>simulate_logs.sh</code> را به پوشه جاری کپی کنید و مجوز اجرا بدهید:</p>

<pre><code>cp ../logmorph/simulate_logs.sh .
chmod +x simulate_logs.sh
./simulate_logs.sh
</code></pre>

<p>توجه کنید مسیر <code>../logmorph/simulate_logs.sh</code> باید با مسیر واقعی فایل شما هماهنگ باشد.</p>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">📦 مشاهده لاگ‌ها در دیتابیس</h2>

<p>برای مشاهده لاگ‌های ذخیره‌شده در دیتابیس، دستور زیر را اجرا کنید:</p>

<pre><code>psql -U &lt;username&gt; -d logdb -c "SELECT * FROM logs ORDER BY id DESC LIMIT 10;"</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🔍 بررسی لاگ‌های سرویس‌ها</h2>


<h4>بررسی لاگ Logstash:</h4>
<pre><code>journalctl -u logstash -f</code></pre>

<hr>

<h2 style="font-family: Vazirmatn, sans-serif;">🧠 نکات تکمیلی</h2>
<ul style="font-family: Vazirmatn, sans-serif;">
  <li>در صورت نیاز به تغییر پورت UDP در Logstash، مقدار <code>port => 5140</code> را ویرایش کنید.</li>
  <li>آدرس FastAPI در بخش خروجی Logstash باید با آدرس سرور شما هماهنگ باشد.</li>
  <li>در صورت نیاز به احراز هویت، می‌توانید هدر یا توکن نیز به خروجی Logstash اضافه کنید.</li>
  <li>مطمئن شوید <code>uvicorn</code> قبل از اجرای Logstash در حال اجرا است، در غیر این صورت لاگ‌ها به FastAPI نمی‌رسند.</li>
</ul>

<hr>
