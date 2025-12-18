For domain: **cfehost.net**

NS1 (Primary): **195.26.248.226**

NS2 (Secondary): **212.90.121.36**

You are building a small, fully isolated hosting environment to replace a cPanel reseller account.

Your platform will provide:

- Custom nameservers (`ns1/ns2.cfehost.net`)
- Apache + NGINX + PHP-FPM web servers
- HestiaCP hosting with per-user isolation
- Mail (optional)
- Webmail via SnappyMail
- Sieve filters (ManageSieve)
- Redis object caching
- Local ClamAV scans + ModSecurity
- Multi-PHP support
- DNS Master/Slave cluster (Hestia → Hestia)

Your main business domain **cfesystems.com** stays separate on Cloudflare.

The hosting infrastructure lives entirely under **cfehost.net**.

---

# 1. **Servers & Roles**

## **Server A — PRIMARY Hosting Server**

- Provider: Contabo (US region)
- IP: **195.26.248.226**
- Role:
    - HestiaCP full install
    - DNS **master**
    - Web hosting (Apache + NGINX + FPM)
    - Optional mail server
    - Redis
    - ClamAV antivirus
    - ModSecurity WAF

### Nameserver:

```
ns1.cfehost.net → 195.26.248.226
```

---

## **Server B — SECONDARY DNS Server**

- Provider: Contabo (EU region)
- IP: **212.90.121.36**
- Role:
    - Hestia minimal install
    - **DNS slave only**
    - No web, no mail, no databases

### Nameserver:

```
ns2.cfehost.net → 212.90.121.36
```

Latency does not matter because secondary DNS is only used for redundancy.

---

---

# 2. **Registrar Setup (cfehost.net)**

Log into your registrar. Add these:

## 2.1. **Glue (“Host”) records**

```
ns1.cfehost.net → 195.26.248.226
ns2.cfehost.net → 212.90.121.36
```

## 2.2. **Set Nameservers for cfehost.net**

```
ns1.cfehost.net
ns2.cfehost.net

```

This enables your domain to act as a hosting provider NS set.

---

# 3. **Provisioning Both Servers**

Run on both:

```bash
apt update && apt upgrade -y
apt install -y software-properties-common curl wget git htop unzip

```

Set hostname (Server A):

```bash
hostnamectl set-hostname host1.cfehost.net

```

(Server B):

```bash
hostnamectl set-hostname ns2.cfehost.net

```

Set timezone (both):

```bash
timedatectl set-timezone America/Chicago
```

# 4. SSH Hardening

See starter script: [ssh-hardening.sh](ssh-hardening.sh)

# 5. Firewall

The recommended approach for a hosting server:
✔ Use Hestia’s built-in firewall (iptables)
❌ Do NOT use UFW - Disable it
✔ Use Fail2Ban (Hestia integrates it automatically)
This gives you:
Correct port configurations per hosting role
No conflicting iptables layers
Matches Hestia documentation
Lower maintenance complexity
Better compatibility with DNS clustering, mail, FTP, etc.

# 6. MASTER Server Install - Server A (Primary Hosting)

## Custom - MASTER SERVER INSTALL

``` bash
#defaults include install with phpfpm, bind, mariadb, dovecot, clamav, spamassassin, iptabls, fail2ban, api
bash hst-install.sh \
  --apache yes \
  --phpfpm yes \
  --multiphp yes \
  --named yes \
  --vsftpd no \
  --exim yes \
  --dovecot yes \
  --clamav yes \
  --spamassassin yes \
  --iptables yes \
  --fail2ban yes \
  --quota no \
  --resourcelimit no \
  --webterminal no \
  --sieve yes
```

##Reboot
```bash
reboot
```

## TEST SSH ACCESS - MAY NOT WORK AFTER REBOOT
Logging back in may require using password.  See full details here:

## Access panel:
Initially self-signed certificate is ok

# 7. SLAVE DNS Server **Install - Server B (DNS Slave Only)**

## Run:

```bash
bash hst-install.sh \
  --nginx no \
  --apache no \
  --phpfpm no \
  --multiphp no \
  --named yes \
  --mysql no \
  --vsftpd no \
  --exim no \
  --dovecot no \
  --clamav no \
  --spamassassin no \
  --iptables yes \
  --fail2ban yes \
  --quota no

```

## Reboot

**TEST SSH ACCESS - MAY NOT WORK AFTER REBOOT**

Logging back in may require using password.  See full details here:

[Hestia Install SSH Firewall Changes to Use Keys and Whitelist](https://www.notion.so/Hestia-Install-SSH-Firewall-Changes-to-Use-Keys-and-Whitelist-2bd627673757804e9b95ee2aad63360e?pvs=21)

## Access panel:

```
https://212.90.121.36:8083
```

---

# 8. **DNS Cluster Configuration**

DNS clusters and DNSSEC | Hestia Control Panel

## Master -> Slave DNS cluster with the Hestia API
INFO
It doesn't work if you try to sync via local network! See Issue Make sure to use the public ip addresses
### Preparing your Slave server(s):
1. Whitelist your master server IP in Configure Server -> Security -> Allowed IP addresses for API
Screenshot
2. Enable API access for admins (or all users).
3.  Create an API key under the admin user with at least the sync-dns-cluster permission. This is found in user settings / Access keys.
Click on profile for admin account
Click Access Keys button
screenshots
4. Create a new DNS sync user as follows:
NOTE: Don’t try to create user “admin” as it won’t work - it is already reserved by system,
Has email address (something generic)
Has the role dns-cluster
Screenshot - no dns cluster - had DNS Sync User
You may want to set 'Do not allow user to log in to Control Panel' if they are not a regular user
If you have more than one slave, the slave user must be unique
5. Edit /usr/local/hestia/conf/hestia.conf, change DNS_CLUSTER_SYSTEM='hestia' to DNS_CLUSTER_SYSTEM='hestia-zone'.
6. Edit /etc/bind/named.conf.options, do the following changes, then restart bind9 with systemctl restart bind9:

```bash
# Change this lineallow-recursion { 127.0.0.1; ::1; };# To thisallow-recursion { 127.0.0.1; ::1; your.master.ip.address; };# Add this lineallow-notify{ your.master.ip.address; };
```

### Preparing your Master server:
On the Master server, open /usr/local/hestia/conf/hestia.conf, change DNS_CLUSTER_SYSTEM='hestia' to DNS_CLUSTER_SYSTEM='hestia-zone'.
Edit /etc/bind/named.conf.options, do the following changes, then restart bind9 with systemctl restart bind9.

```bash 
# Change this lineallow-transfer { "none"; };# To thisallow-transfer { your.slave.ip.address; };# Or this, if adding multiple slavesallow-transfer { first.slave.ip.address; second.slave.ip.address; };# Add this line, if adding multiple slavesalso-notify { second.slave.ip.address; };
```

Run the following command to enable each Slave DNS server, and wait a short while for it to complete zone transfers:

```bash
v-add-remote-dns-host <your slave host name> <port number> '<accesskey>:<secretkey>' '' 'api' '<your chosen slave user name>'
```

If you still want to use admin and password authentication (not recommended):

v-add-remote-dns-host slave.yourhost.com 8083 'admin' 'strongpassword' 'api' 'user-name'

Check it worked by listing the DNS zones on the Slave for the dns-user with the CLI command v-list-dns-domains dns-user or by connecting to the web interface as dns-user and reviewing the DNS zones.

DNSSEC

### Original Instructions
8.1. Generate API keys
On Server B (DNS slave):
Hestia → Settings → API → Create key
On Server A (DNS master):
Generate API key as well
8.2. Configure DNS cluster
On Server A (master):
Server → DNS Cluster → Add DNS server
Hostname/IP: 212.90.121.36
Type: HestiaCP
Username: admin
Password: API key from Server B
Role: Slave
Enable sync
On Server B (slave):
No further config needed unless you want bidirectional sync (not required).
Test by creating a test domain on Server A.
Zone should appear on Server B automatically.

# 9. Configure cfehost.net in Hestia

## Add domain to admin user on Server A:

```bash
cfehost.net
```

## Add DNS records:

```bash
ns1   A   195.26.248.226
ns2   A   212.90.121.36
panel A   195.26.248.226
mail  A   195.26.248.226
webmail A 195.26.248.226
```

## Enable Let's Encrypt for:

```bash
cfehost.net
panel.cfehost.net
```

## Use panel.cfehost.net as your login URL.

# 10. Mail (Optional)

If you use local mail:
MX: mail.cfehost.net
Add SPF, DKIM, DMARC in DNS via Hestia
Install SnappyMail under a webmail.cfehost.net domain
Enable ManageSieve via Dovecot.

# 11. Performance Optimization

## Redis:

```bash
apt install redis-server
```


## Ensure:

```bash
bind 127.0.0.1
protected-mode yes
```


## Restart:

```bash
systemctl restart redis-server
```


## Use “Redis Object Cache” plugin for WordPress.

```bash
Restart:
systemctl restart redis-server
```



## Use “Redis Object Cache” plugin for WordPress.

## OPcache (PHP):

Edit /etc/php/*/fpm/php.ini:

```bash
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=100000
opcache.revalidate_freq=60
```

## Restart PHP-FPM.

```bash
systemctl restart php-fpm
```

## ModSecurity:

```bash
apt install libapache2-mod-security2
```

## Enable through Hestia templates.

# 12. Security Enhancements

## Fail2Ban:

Make sure jails are active for:

```bash
ssh
hestia
nginx-auth
dovecot/exim (if using mail)
```

## ClamAV:

Daily scan script:

```bash
/usr/local/sbin/clamav-web-scan.sh
```

Cron entry:

```bash
30 2 * * * /usr/local/sbin/clamav-web-scan.sh >/dev/null 2>&1
```


AppArmor:

```bash
Verify active:
aa-status
```

Cron entry:

```bash
30 2 * * * /usr/local/sbin/clamav-web-scan.sh >/dev/null 2>&1
```


## AppArmor:

Verify active:

```bash
aa-status
```

# 13. Backups

## Enable Hestia backups on Server A.
Then use rclone for off-server backups:

```bash
apt install rclone
rclone config
```

## Set cron:

```bash
0 4 * * * rclone sync /backup remote:cfesystems-hestia >/dev/null 2>&1
```

# 14. Client Workflow

## Create new Hestia user per client

Add domain

## DNS:

If client uses your nameservers:
ns1.cfehost.net
ns2.cfehost.net

If they use GoDaddy/Cloudflare:
Provide A record to 195.26.248.226

## Install WordPress

Enable Redis + full-page caching
SnappyMail for email if needed

# 🎉 YOU NOW HAVE:
A fully isolated hosting provider setup:
✓ Separate hosting brand domain (cfehost.net)
✓ ns1 + ns2 on different continents
✓ Contabo price advantage
✓ Hestia DNS clustering
✓ Full web hosting stack
✓ Redis, OPcache, ModSecurity, ClamAV
✓ SnappyMail, ManageSieve
✓ cPanel-like multi-user hosting