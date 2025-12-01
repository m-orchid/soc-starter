#!/bin/bash
# ============================================================
# اسکریپت نصب خودکار Wazuh All-in-One + دسکتاپ Xfce + XRDP
# نسخه: 4.8.2 (به‌روز در دسامبر 2025)
# سازنده: برای پروژه دانشگاهی SOC
# ============================================================

set -euo pipefail   # اگر هر دستوری خطا بده اسکریپت متوقف بشه

# رنگ‌ها برای خروجی زیبا
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_file="$HOME/Downloads/wazuh-install-log-$(date +%Y%m%d-%H%M).txt"
exec 1> >(tee -a "$log_file")
exec 2> >(tee -a "$log_file" >&2)

echo -e "${GREEN}[+] شروع نصب کامل Wazuh All-in-One + دسکتاپ — $(date)${NC}\n"

# ۱. آپدیت سیستم
echo -e "${YELLOW}[1/7] آپدیت و ارتقاء سیستم...${NC}"
sudo apt update && sudo apt upgrade -y

# ۲. نصب پیش‌نیازها
echo -e "${YELLOW}[2/7] نصب پیش‌نیازها...${NC}"
sudo apt install -y curl apt-transport-https unzip lsb-release gnupg2 net-tools

# ۳. اضافه کردن مخزن Wazuh
echo -e "${YELLOW}[3/7] اضافه کردن مخزن Wazuh...${NC}"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update

# ۴. دانلود و اجرای اسکریپت نصب رسمی Wazuh All-in-One
echo -e "${YELLOW}[4/7] دانلود و اجرای اسکریپت نصب Wazuh All-in-One...${NC}"
cd /tmp
curl -sO https://packages.wazuh.com/4.8/wazuh-install.sh
sudo bash ./wazuh-install.sh -a

# ۵. ذخیره یوزرنیم و پسورد داشبورد در پوشه Downloads
echo -e "${YELLOW}[5/7] ذخیره اعتبارنامه داشبورد...${NC}"
mkdir -p "$HOME/Downloads"
if [ -f "/root/wazuh-passwords.txt" ]; then
    sudo cp /root/wazuh-passwords.txt "$HOME/Downloads/WAZUH-CREDENTIALS-$(date +%Y%m%d-%H%M).txt"
    sudo chmod 600 "$HOME/Downloads"/WAZUH-CREDENTIALS-*.txt
    echo -e "${GREEN}✔ اعتبارنامه با موفقیت در Downloads ذخیره شد:${NC}"
    cat "$HOME/Downloads"/WAZUH-CREDENTIALS-*.txt
else
    echo -e "${RED}✘ فایل پسورد تولید نشد! (ممکن است نصب ناقص باشد)${NC}"
fi

# ۶. تست سرویس‌ها و پورت‌ها
echo -e "${YELLOW}[6/7] تست سرویس‌ها و پورت‌ها...${NC}"
sleep 10

echo -e "\n=== وضعیت سرویس‌ها ==="
for service in wazuh-manager wazuh-indexer wazuh-dashboard; do
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}✔ $service → فعال${NC}"
    else
        echo -e "${RED}✘ $service → غیرفعال یا خطا${NC}"
    fi
done

echo -e "\n=== پورت‌های در حال گوش دادن ==="
for port in 55000 9200 5601; do
    if netstat -tulnp | grep -q ":$port "; then
        echo -e "${GREEN}✔ پورت $port → باز${NC}"
    else
        echo -e "${RED}✘ پورت $port → بسته یا در حال گوش نیست${NC}"
    fi
done

# ۷. نصب دسکتاپ Xfce + XRDP (اختیاری اما خیلی کاربردی برای پروژه)
echo -e "${YELLOW}[7/7] نصب محیط دسکتاپ Xfce + XRDP (برای اتصال گرافیکی از ویندوز)...${NC}"
sudo apt install -y xfce4 xfce4-goodies xrdp
sudo adduser xrdp ssl-cert
echo "xfce4-session" > ~/.xsession
sudo systemctl enable xrdp
sudo systemctl restart xrdp
sudo ufw allow 3389/tcp 2>/dev/null || true

echo -e "${GREEN}
══════════════════════════════════════════════
        WAZUH با موفقیت نصب شد!
══════════════════════════════════════════════
داشبورد: https://$(hostname -I | awk '{print $1}'):5601
یوزر: admin
پسورد در پوشه Downloads ذخیره شد

از ویندوز با Remote Desktop (mstsc) به این IP وصل شوید
و از دسکتاپ گرافیکی لذت ببرید :)
══════════════════════════════════════════════${NC}"