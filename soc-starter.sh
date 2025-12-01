#!/bin/bash
# ============================================================
# اسکریپت نصب خودکار Wazuh All-in-One + دسکتاپ Xfce + XRDP
# نسخه: 4.8.2 (به‌روز شده: دسامبر 2025)
# نویسنده: سینا | پروژه دانشگاهی SOC
# ============================================================

set -euo pipefail

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# فایل لاگ
log_file="$HOME/Downloads/wazuh-install-log-$(date +%Y%m%d-%H%M).txt"
exec 1> >(tee -a "$log_file")
exec 2> >(tee -a "$log_file" >&2)

echo -e "${GREEN}[+] شروع نصب Wazuh All-in-One + Xfce + XRDP — $(date)${NC}\n"

# ۱. آپدیت سیستم
echo -e "${YELLOW}[1/9] آپدیت و ارتقاء سیستم...${NC}"
sudo apt update && sudo apt upgrade -y

# ۲. نصب پیش‌نیازها
echo -e "${YELLOW}[2/9] نصب ابزارهای پایه...${NC}"
sudo apt install -y curl apt-transport-https unzip lsb-release gnupg2 net-tools software-properties-common ufw git

# ۳. اضافه کردن مخزن Wazuh
echo -e "${YELLOW}[3/9] اضافه کردن مخزن رسمی Wazuh...${NC}"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor | sudo tee /usr/share/keyrings/wazuh.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update

# ۴. دانلود و اجرای اسکریپت نصب رسمی Wazuh
echo -e "${YELLOW}[4/9] دانلود و اجرای اسکریپت نصب Wazuh...${NC}"
cd /tmp
curl -sO https://packages.wazuh.com/4.8/wazuh-install.sh
sudo bash ./wazuh-install.sh -a

# ۵. ذخیره امن پسورد داشبورد
echo -e "${YELLOW}[5/9] ذخیره اعتبارنامه داشبورد...${NC}"
mkdir -p "$HOME/Downloads"
if [ -f "/root/wazuh-passwords.txt" ]; then
    dest="$HOME/Downloads/WAZUH-CREDENTIALS-$(date +%Y%m%d-%H%M).txt"
    sudo cp /root/wazuh-passwords.txt "$dest"
    sudo chmod 600 "$dest"
    echo -e "${GREEN}✔ اعتبارنامه ذخیره شد در: $dest${NC}"
    cat "$dest"
else
    echo -e "${RED}✘ فایل پسورد یافت نشد! احتمالاً نصب ناقص بوده است.${NC}"
fi

# ۶. تست سرویس‌ها
echo -e "${YELLOW}[6/9] بررسی وضعیت سرویس‌ها...${NC}"
services=(wazuh-manager wazuh-indexer wazuh-dashboard)
for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "${GREEN}✔ $svc → فعال است${NC}"
    else
        echo -e "${RED}✘ $svc → غیرفعال یا با خطا مواجه شده${NC}"
    fi
done

# ۷. بررسی پورت‌ها
echo -e "${YELLOW}[7/9] بررسی پورت‌های کلیدی...${NC}"
ports=(55000 9200 5601)
for port in "${ports[@]}"; do
    if ss -tuln | grep -q ":$port "; then
        echo -e "${GREEN}✔ پورت $port → باز است${NC}"
    else
        echo -e "${RED}✘ پورت $port → بسته یا غیرفعال است${NC}"
    fi
done

# ۸. نصب محیط دسکتاپ Xfce + XRDP
echo -e "${YELLOW}[8/9] نصب Xfce و XRDP برای اتصال گرافیکی از ویندوز...${NC}"
sudo apt install -y xfce4 xfce4-goodies xrdp
sudo adduser xrdp ssl-cert
echo "xfce4-session" > ~/.xsession
sudo systemctl enable xrdp
sudo systemctl restart xrdp
sudo ufw allow 3389/tcp
sudo ufw allow 5601/tcp
sudo ufw allow 55000/tcp
sudo ufw allow 9200/tcp
sudo ufw --force enable

# ۹. نمایش اطلاعات نهایی
IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}
══════════════════════════════════════════════
        ✅ نصب WAZUH با موفقیت انجام شد!
══════════════════════════════════════════════
📍 داشبورد: https://$IP:5601
👤 یوزرنیم: admin
🔐 پسورد: در پوشه Downloads ذخیره شده است
🖥 اتصال گرافیکی: Remote Desktop به $IP (پورت 3389)
📄 لاگ نصب: $log_file
══════════════════════════════════════════════${NC}"
