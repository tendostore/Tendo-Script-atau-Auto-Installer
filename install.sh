#!/bin/bash
# ==================================================
#   Auto Script Install X-ray & Zivpn + SSH WS
#   EDITION: PLATINUM CLEAN V.6.0 (ULTIMATE FINAL + BOT CLIENT)
#   Script BY: Tendo Store | WhatsApp: +6282224460678
#   Updated: Anti-Ghost Vless, Split Chat Telegram, SSH Multi-Thread, No Force Close, Auto-Restart Fix
# ==================================================

# --- WARNA & UI ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'; WHITE='\033[1;37m'

# --- ANTI INTERACTIVE GLOBALS ---
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# --- SET TIMEZONE DEFAULT: Asia/Jakarta ---
timedatectl set-timezone Asia/Jakarta 2>/dev/null || ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ══════════════════════════════════════════════════════
# CEK KOMPATIBILITAS OS — Debian 11/12, Ubuntu 20.04/22.04/24.04
# ══════════════════════════════════════════════════════
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VER="${VERSION_ID:-0}"
else
    OS_ID="unknown"
    OS_VER="0"
fi

OS_SUPPORTED=0
case "$OS_ID" in
    debian)
        case "$OS_VER" in
            11|12) OS_SUPPORTED=1 ;;
        esac
        ;;
    ubuntu)
        case "$OS_VER" in
            20.04|22.04|24.04) OS_SUPPORTED=1 ;;
        esac
        ;;
esac

if [[ "$OS_SUPPORTED" -eq 0 ]]; then
    echo -e "${RED}=================================================${NC}"
    echo -e "${RED} OS TIDAK RESMI DIDUKUNG: ${OS_ID} ${OS_VER}${NC}"
    echo -e "${YELLOW} Script ini dites & didukung penuh untuk:${NC}"
    echo -e "${WHITE}   - Debian 11 (Bullseye) / 12 (Bookworm)${NC}"
    echo -e "${WHITE}   - Ubuntu 20.04 / 22.04 / 24.04 (LTS)${NC}"
    echo -e "${RED}=================================================${NC}"
    read -p " Tetap lanjut dengan resiko sendiri? (y/n): " _os_confirm
    if [[ "$_os_confirm" != "y" && "$_os_confirm" != "Y" ]]; then
        echo -e "${RED}Instalasi dibatalkan.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[OK] OS terdeteksi: ${OS_ID} ${OS_VER} (didukung).${NC}"
fi

# --- SETUP DNS RESOLVER ---
echo -e "${YELLOW}Mengatur DNS Resolver...${NC}"
systemctl stop systemd-resolved 2>/dev/null
systemctl disable systemd-resolved 2>/dev/null
chattr -i /etc/resolv.conf 2>/dev/null
rm -f /etc/resolv.conf
touch /etc/resolv.conf
cat <<EOF > /etc/resolv.conf
nameserver 9.9.9.9
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 127.0.0.53
EOF
echo -e "${GREEN}[OK] DNS Resolver berhasil diatur.${NC}"

function print_msg() { 
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}> $1...${NC}"
}
function print_ok() { 
    echo -e "${GREEN}[OK] $1 Berhasil!${NC}"
}

# ══════════════════════════════════════════════════════
# DETEKSI REINSTALL — cek apakah VPS sudah terinstall
# ══════════════════════════════════════════════════════
INSTALL_MODE="full"   # full | update | reinstall

function do_backup() {
    local DATE=$(date +"%Y-%m-%d_%H-%M")
    local BAK="/root/backup_vps_${DATE}.zip"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW} Membuat backup data akun & konfigurasi...${NC}"
    apt-get install -y zip -qq >/dev/null 2>&1
    cd /
    zip -r "$BAK" \
        usr/local/etc/xray/ssh.txt \
        usr/local/etc/xray/vmess.txt \
        usr/local/etc/xray/vless.txt \
        usr/local/etc/xray/trojan.txt \
        usr/local/etc/xray/config.json \
        usr/local/etc/xray/outbound.json \
        usr/local/etc/xray/domain \
        etc/zivpn/zivpn.txt \
        etc/zivpn/config.json \
        etc/tendo_bot/ \
        2>/dev/null
    cd - >/dev/null 2>&1
    echo -e "${GREEN} [OK] Backup tersimpan di: ${WHITE}${BAK}${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e " Setelah install selesai, restore data dengan:"
    echo -e "  ${WHITE}cd / && unzip -o ${BAK}${NC}"
    echo -e "  ${WHITE}systemctl restart xray zivpn${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    sleep 5
}

if [[ -f /usr/bin/menu && -f /usr/local/etc/xray/config.json ]]; then
    clear
    _EXIST_DOMAIN=$(cat /usr/local/etc/xray/domain 2>/dev/null || echo '-')
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}${YELLOW}         VPS SUDAH TERINSTALL SEBELUMNYA              ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Domain : ${_EXIST_DOMAIN}$(printf '%*s' $((38 - ${#_EXIST_DOMAIN})) '')${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}[1]${NC} Update Script  ${CYAN}|${NC} Update menu & web panel saja    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}     Data akun ${GREEN}AMAN${NC}, tidak ada yang dihapus          ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}[2]${NC} Full Reinstall ${CYAN}|${NC} Hapus & install ulang semua    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}     Data akun di-${YELLOW}BACKUP${NC} dulu sebelum dihapus        ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${RED}[x]${NC} Batal                                            ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    read -p " Pilih [1/2/x] : " _REINSTALL_OPT
    case "$_REINSTALL_OPT" in
        1) INSTALL_MODE="update"
           echo -e "${GREEN} Mode: Update Script — data akun tidak akan diubah.${NC}"
           sleep 1 ;;
        2) INSTALL_MODE="reinstall"
           echo -e "${YELLOW} Mode: Full Reinstall — backup data dahulu...${NC}"
           do_backup ;;
        *) echo -e "${RED} Dibatalkan.${NC}"; exit 0 ;;
    esac
fi

# --- 1. PROMPT DOMAIN ---
if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "reinstall" ]]; then
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${PURPLE}      AUTO INSTALLER X-RAY, ZIVPN & SSH WS       ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${YELLOW}           Script by Tendo Store                 ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${YELLOW}              SETUP DOMAIN MANUAL                ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${RED}PENTING: Pastikan A Record domain sudah mengarah ke IP VPS!${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    read -p " Masukan Domain/Subdomain Anda: " user_dom
    if [[ -z "$user_dom" ]]; then
        echo -e "${RED}Domain tidak boleh kosong! Script berhenti.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Domain diatur ke: $user_dom${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${GREEN}Memulai proses instalasi...${NC}"
    sleep 2
    clear
else
    # Mode update: ambil domain dari file yang sudah ada
    user_dom=$(cat /usr/local/etc/xray/domain 2>/dev/null)
    echo -e "${CYAN} Mode Update — domain: ${WHITE}${user_dom}${NC}"
    sleep 1
fi

# --- 2. VARIABLES ---
XRAY_DIR="/usr/local/etc/xray"
CONFIG_FILE="/usr/local/etc/xray/config.json"
DATA_SSH="/usr/local/etc/xray/ssh.txt"
DATA_VMESS="/usr/local/etc/xray/vmess.txt"; DATA_VLESS="/usr/local/etc/xray/vless.txt"; DATA_TROJAN="/usr/local/etc/xray/trojan.txt"
DATA_ZIVPN="/etc/zivpn/zivpn.txt"

# --- 3. OPTIMIZATION ---
# Sections 3-9 hanya dijalankan pada mode full install / reinstall
if [[ "$INSTALL_MODE" != "update" ]]; then
print_msg "Optimasi Sistem & Swap"
(
    export DEBIAN_FRONTEND=noninteractive
    rm -f /var/lib/apt/lists/lock
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    swapoff -a; rm -f /swapfile
    dd if=/dev/zero of=/swapfile bs=1024 count=2097152
    chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
)
print_ok "Optimasi Sistem"

# --- 4. DEPENDENCIES ---
print_msg "Install Dependencies"
(
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    mkdir -p /etc/needrestart/conf.d
    echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/restart.conf
    echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/conf.d/restart.conf
    sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf 2>/dev/null

    apt-get update -y -q
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    apt-get install -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl socat jq openssl uuid-runtime net-tools vnstat wget gnupg1 bc iproute2 iptables iptables-persistent python3 python3-pip neofetch cron zip unzip stunnel4 bzip2 zlib1g-dev build-essential gcc make cmake fail2ban
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    # FIX: repo Ookla belum ada build untuk codename Ubuntu 24.04 "noble",
    # fallback pakai repo "jammy" (22.04) yang kompatibel secara paket.
    if [[ -f /etc/apt/sources.list.d/ookla_speedtest-cli.list ]] && grep -q "noble" /etc/apt/sources.list.d/ookla_speedtest-cli.list 2>/dev/null; then
        sed -i 's/noble/jammy/g' /etc/apt/sources.list.d/ookla_speedtest-cli.list
        apt-get update -y -q
    fi
    apt-get install -y -q speedtest || echo "GAGAL: install speedtest-cli, fitur speedtest di menu tidak akan berfungsi." >&2
    
    touch /root/.hushlogin; chmod -x /etc/update-motd.d/* 2>/dev/null
    mkdir -p /etc/neofetch
    cat > /etc/neofetch/tendo_ascii.txt << 'ASCIIEOF'
${c1}
##### ##### #...# ####. .###.
..#.. #.... ##..# #...# #...#
..#.. ###.. #.#.# #...# #...#
..#.. #.... #..## #...# #...#
..#.. ##### #...# ####. .###.

${c2}
.#### ##### .###. ####. #####
#.... ..#.. #...# #...# #....
.###. ..#.. #...# ####. ###..
....# ..#.. #...# #..#. #....
####. ..#.. .###. #...# #####
ASCIIEOF
    sed -i '/neofetch/d' /root/.bashrc
    sed -i '/Welcome To Tendo/d' /root/.bashrc
    sed -i '/clear/d' /root/.bashrc
    echo "clear" >> /root/.bashrc
    echo "neofetch --source /etc/neofetch/tendo_ascii.txt --ascii_colors 1 7" >> /root/.bashrc
    echo 'echo -e "Welcome To Tendo Store Auto Script! Type \e[1;32mmenu\e[0m to start."' >> /root/.bashrc
)
print_ok "Dependencies"

IP_VPS=$(curl -s ifconfig.me)
IFACE_NET=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# --- 5. DOMAIN SELECTION EXECUTION & SSL ---
print_msg "Setup Domain & SSL Cert"
(
    systemctl enable vnstat && systemctl restart vnstat; vnstat -u -i $IFACE_NET
    mkdir -p $XRAY_DIR /etc/zivpn /root/tendo /etc/tendo_bot /usr/local/etc/xray/quota; touch $DATA_SSH $DATA_VMESS $DATA_VLESS $DATA_TROJAN $DATA_ZIVPN
    # Log file status notifikasi
    touch /etc/tendo_bot/log_stat /etc/tendo_bot/bak_stat
    mkdir -p /var/log/xray; touch /var/log/xray/access.log /var/log/xray/error.log
    # Xray dijalankan sebagai root (lihat override.conf di step Xray Core),
    # jadi log file cukup dimiliki root.
    chown root:root /var/log/xray/access.log /var/log/xray/error.log 2>/dev/null
    chmod 644 /var/log/xray/access.log /var/log/xray/error.log

    curl -s ipinfo.io/json | jq -r '.city' > /root/tendo/city
    curl -s ipinfo.io/json | jq -r '.org' > /root/tendo/isp
    curl -s ipinfo.io/json | jq -r '.ip' > /root/tendo/ip

    DOMAIN_VAL="$user_dom"
    echo "$DOMAIN_VAL" > $XRAY_DIR/domain

    openssl req -x509 -newkey rsa:2048 -nodes -sha256 -keyout $XRAY_DIR/xray.key \
        -out $XRAY_DIR/xray.crt -days 3650 -subj "/CN=$DOMAIN_VAL"
    chmod 644 $XRAY_DIR/xray.key; chmod 644 $XRAY_DIR/xray.crt
)
print_ok "Domain & SSL"

# --- 6. SSH, DROPBEAR, UDPGW & WS PROXY ---
print_msg "Install SSH, Dropbear 2019, WS Proxy & UDPGW"
(
    export DEBIAN_FRONTEND=noninteractive
    
    # BANNER SSH PENDEK DAN PRESISI
    cat > /etc/issue.net << 'EOF'
<font color="#00FFFF">──────────────────────────────</font><br>
<font color="#00FF00"><b> AUTO SCRIPT TENDO STORE</b></font><br>
<font color="#00FFFF">──────────────────────────────</font><br>
<font color="#FFD700">Version :</font> <font color="#FFFFFF">v01.03.26</font><br>
<font color="#FFD700">Owner   :</font> <font color="#FFFFFF">Tendo Store</font><br>
<font color="#FFD700">Telegram:</font> <font color="#FFFFFF">@tendo_32</font><br>
<font color="#00FFFF">──────────────────────────────</font><br>
<font color="#FF0000"><b> No Spam, DDOS, Hacking!</b></font><br>
EOF

    # OpenSSH Config
    sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
    sed -i '/Port 22/a Port 444' /etc/ssh/sshd_config
    # Root TIDAK boleh login pakai password dari internet.
    # Akun jualan (customer) tetap pakai password seperti biasa lewat user biasa (bukan root).
    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    echo "MaxAuthTries 4" >> /etc/ssh/sshd_config
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    systemctl restart ssh || systemctl restart sshd

    # Fail2ban: cover sshd DAN dropbear (port 90), karena dropbear juga menerima
    # login password dari akun customer dan sebelumnya tidak dipantau sama sekali.
    cat > /etc/fail2ban/jail.local <<'F2BEOF'
[sshd]
enabled = true
port = 22,444
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 600
bantime = 3600

[dropbear]
enabled = true
port = 90
filter = dropbear
logpath = /var/log/auth.log
maxretry = 5
findtime = 600
bantime = 3600
F2BEOF
    systemctl enable fail2ban && systemctl restart fail2ban

    # Dropbear 2019 Build
    wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2019.78.tar.bz2
    if [[ ! -s dropbear-2019.78.tar.bz2 ]] || ! tar -tf dropbear-2019.78.tar.bz2; then
        echo "GAGAL: download dropbear-2019.78.tar.bz2 rusak/kosong, skip build dropbear." >&2
    else
        tar -xf dropbear-2019.78.tar.bz2
        if cd dropbear-2019.78; then
            ./configure
            make
            make install
            cd ..
        else
            echo "GAGAL: cd ke dropbear-2019.78 gagal, skip build." >&2
        fi
    fi
    rm -rf dropbear-2019.78*

    # Generate Dropbear Host Keys
    mkdir -p /etc/dropbear
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key

    # Dropbear Service with Banner
    cat > /etc/systemd/system/dropbear.service <<EOF
[Unit]
Description=Dropbear SSH Daemon
After=network.target

[Service]
ExecStart=/usr/local/sbin/dropbear -F -p 90 -W 65536 -b /etc/issue.net -w
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable dropbear && systemctl start dropbear

    # WS Python Proxy -> Dropbear 2019 (port 90), buffer 8192, TCP_NODELAY
    cat > /usr/local/bin/ws-proxy.py << 'EOF'
import socket, select, threading, time, collections

DROPBEAR_HOST = '127.0.0.1'
DROPBEAR_PORT = 90
BUF_SIZE = 8192
HANDSHAKE_TIMEOUT = 10
LOG_FILE = '/var/log/ws-proxy.log'

# Dropbear hanya melihat koneksi dari 127.0.0.1 (lewat proxy ini), jadi untuk
# limit-IP yang akurat kita simpan peta "port lokal saat connect ke dropbear"
# -> "IP asli client". Script xray-limit nanti mencocokkan port ini dengan
# `ss -tnp` (peer port pada koneksi ESTABLISHED ke 127.0.0.1:90) untuk tahu
# IP asli di balik setiap sesi dropbear per user.
IPMAP_FILE = '/var/run/ws-proxy-ipmap.log'
_ipmap = {}

# Rate-limit sederhana per IP asli. Dropbear cuma lihat 127.0.0.1 (semua
# koneksi lewat proxy ini), jadi brute-force protection HARUS dilakukan di
# sini, bukan lewat fail2ban yang baca log dropbear.
RATE_WINDOW = 60       # detik
RATE_MAX_CONN = 8      # maksimal koneksi baru per IP per window sebelum dianggap brute-force

_lock = threading.Lock()
_conn_history = collections.defaultdict(list)

def log(msg):
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(msg + "\n")
    except Exception:
        pass

def write_ipmap():
    """Tulis snapshot peta port->IP secara atomik (tmp file lalu rename)."""
    try:
        tmp = IPMAP_FILE + ".tmp"
        with open(tmp, 'w') as f:
            for port, ip in _ipmap.items():
                f.write("%s %s\n" % (port, ip))
        import os
        os.replace(tmp, IPMAP_FILE)
    except Exception:
        pass

def check_rate(ip):
    """True kalau IP masih wajar, False kalau kelewat sering connect (indikasi brute-force)."""
    now = time.time()
    with _lock:
        hist = _conn_history[ip]
        hist[:] = [t for t in hist if now - t < RATE_WINDOW]
        hist.append(now)
        return len(hist) <= RATE_MAX_CONN

def recv_headers(sock):
    """Baca sampai header HTTP lengkap (\\r\\n\\r\\n) atau timeout, tanpa nunggu 1 recv besar saja."""
    data = b""
    sock.settimeout(HANDSHAKE_TIMEOUT)
    while b"\r\n\r\n" not in data:
        chunk = sock.recv(BUF_SIZE)
        if not chunk:
            break
        data += chunk
        if len(data) > 65536:  # guard biar ga infinite-buffer kalau ada yg iseng
            break
    return data

def extract_real_ip(client_socket, peek_data):
    """Kalau Xray mengirim PROXY protocol v1 (xver=1, jalur fallback :443/:80),
    ambil IP asli dari situ. Kalau tidak ada (jalur langsung iptables REDIRECT
    atau stunnel), IP socket TCP memang sudah IP asli."""
    fallback_ip = "unknown"
    try:
        fallback_ip = client_socket.getpeername()[0]
    except Exception:
        pass
    if peek_data.startswith(b"PROXY "):
        try:
            line, rest = peek_data.split(b"\r\n", 1)
            parts = line.decode(errors="ignore").split()
            real_ip = parts[2] if len(parts) >= 3 else fallback_ip
            return real_ip, rest
        except Exception:
            return fallback_ip, peek_data
    return fallback_ip, peek_data

def handle_client(client_socket):
    remote_socket = None
    try:
        client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        request = recv_headers(client_socket)
        real_ip, request = extract_real_ip(client_socket, request)

        if not check_rate(real_ip):
            log("ws-proxy: repeated connections from %s - possible brute force" % real_ip)
            return

        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        remote_socket.settimeout(HANDSHAKE_TIMEOUT)
        remote_socket.connect((DROPBEAR_HOST, DROPBEAR_PORT))


        # Catat port lokal koneksi ke dropbear ini supaya bisa dipetakan balik ke IP asli
        local_port = remote_socket.getsockname()[1]
        with _lock:
            _ipmap[local_port] = real_ip
            write_ipmap()

        if b"HTTP/" in request:
            client_socket.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            parts = request.split(b"\r\n\r\n", 1)
            if len(parts) == 2 and len(parts[1]) > 0:
                remote_socket.sendall(parts[1])
        elif request:
            remote_socket.sendall(request)
        else:
            return

        # Lepas timeout setelah handshake selesai, biar sesi SSH panjang ga ke-cut
        client_socket.settimeout(None)
        remote_socket.settimeout(None)

        sockets = [client_socket, remote_socket]
        while True:
            r, _, _ = select.select(sockets, [], [])
            if not r:
                break
            if client_socket in r:
                data = client_socket.recv(BUF_SIZE)
                if not data: break
                remote_socket.sendall(data)
            if remote_socket in r:
                data = remote_socket.recv(BUF_SIZE)
                if not data: break
                client_socket.sendall(data)
    except Exception:
        pass
    finally:
        if remote_socket:
            try:
                local_port = remote_socket.getsockname()[1]
                with _lock:
                    _ipmap.pop(local_port, None)
                    write_ipmap()
            except Exception:
                pass
            try: remote_socket.close()
            except: pass
        try: client_socket.close()
        except: pass

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 10015))
server.listen(100)
while True:
    try:
        client, addr = server.accept()
        t = threading.Thread(target=handle_client, args=(client,))
        t.daemon = True
        t.start()
    except Exception:
        pass
EOF
    # Log file untuk ws-proxy + logrotate biar ga membengkak
    touch /var/log/ws-proxy.log
    cat > /etc/logrotate.d/ws-proxy <<'EOF'
/var/log/ws-proxy.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
    # Filter fail2ban khusus untuk log rate-limit ws-proxy (IP asli, bukan 127.0.0.1)
    cat > /etc/fail2ban/filter.d/wsproxy.conf <<'EOF'
[Definition]
failregex = ^ws-proxy: repeated connections from <HOST> - possible brute force$
ignoreregex =
EOF
    cat >> /etc/fail2ban/jail.local <<'F2BEOF'

[wsproxy]
enabled = true
port = 8080,2082,2083,8880,8443,10015
filter = wsproxy
logpath = /var/log/ws-proxy.log
maxretry = 2
findtime = 120
bantime = 3600
F2BEOF
    systemctl restart fail2ban
    cat > /etc/systemd/system/ws-proxy.service <<EOF
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable ws-proxy && systemctl start ws-proxy

    # Stunnel for 8443
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4.pid
cert = /usr/local/etc/xray/xray.crt
key = /usr/local/etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear_tls]
accept = 8443
connect = 127.0.0.1:10015
EOF
    systemctl restart stunnel4

    # UDPGW (Badvpn)
    wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/prem/main/badvpn-udpgw64"
    if [[ ! -s /usr/bin/badvpn-udpgw ]]; then
        echo "GAGAL: download badvpn-udpgw kosong/rusak, service badvpn tidak akan start dengan benar." >&2
    fi
    chmod +x /usr/bin/badvpn-udpgw
    for port in 7100 7200 7300; do
    cat > /etc/systemd/system/badvpn-${port}.service <<EOF
[Unit]
Description=BadVPN UDPGW Port ${port}
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:${port} --max-clients 500
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable badvpn-${port} && systemctl start badvpn-${port}
    done

    # IPTables redirect for WS
    iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-ports 10015
    iptables -t nat -A PREROUTING -p tcp -m multiport --dports 2082,2083,8880 -j REDIRECT --to-ports 10015
    netfilter-persistent save
)
print_ok "SSH, Dropbear & UDPGW"

# --- 7. XRAY CONFIG ---
print_msg "Install Xray Core & Config"
(
    export DEBIAN_FRONTEND=noninteractive
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    UUID_SYS=$(uuidgen)

    # FIX PERMANEN (bug: "xray off setelah instalasi"):
    # 1) Installer resmi XTLS menjalankan xray.service sebagai User=nobody
    #    DAN menimpa ownership /var/log/xray ke nobody:nogroup.
    #    Solusinya: paksa xray jalan sebagai root DAN matikan sandboxing.
    # 2) Sebagian unit file xray.service memakai directive sandboxing systemd
    #    yang bisa memblokir tulis ke /var/log/xray & /usr/local/etc/xray.
    mkdir -p /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray
User=root
Group=root
ProtectSystem=false
ProtectHome=false
ReadWritePaths=-/var/log/xray -/usr/local/etc/xray
EOF
    systemctl daemon-reload
    chown -R root:root /var/log/xray
    chmod 644 /var/log/xray/access.log /var/log/xray/error.log 2>/dev/null

cat > $CONFIG_FILE <<EOF
{
  "log": { "access": "/var/log/xray/access.log", "error": "/var/log/xray/error.log", "loglevel": "info" },
  "api": { "tag": "api_out", "services": [ "StatsService" ] },
  "stats": {},
  "policy": { "levels": { "0": { "statsUserUplink": true, "statsUserDownlink": true } }, "system": { "statsInboundUplink": true, "statsInboundDownlink": true } },
  "inbounds": [
    { "listen": "127.0.0.1", "port": 10085, "protocol": "dokodemo-door", "settings": { "address": "127.0.0.1" }, "tag": "api_in" },
    { "tag": "inbound-443", "port": 443, "protocol": "vless", "settings": { "clients": [ { "id": "$UUID_SYS", "flow": "xtls-rprx-vision", "level": 0, "email": "system" } ], "decryption": "none", "fallbacks": [ 
        { "path": "/vmess", "dest": 10001, "xver": 1 }, { "path": "/vless", "dest": 10002, "xver": 1 }, { "path": "/trojan", "dest": 10003, "xver": 1 },
        { "path": "/vmess-upg", "dest": 10004, "xver": 1 }, { "path": "/vless-upg", "dest": 10005, "xver": 1 }, { "path": "/trojan-upg", "dest": 10006, "xver": 1 },
        { "alpn": "h2", "path": "/vmess-grpc", "dest": 10007, "xver": 1 }, { "alpn": "h2", "path": "/vless-grpc", "dest": 10008, "xver": 1 }, { "alpn": "h2", "path": "/trojan-grpc", "dest": 10009, "xver": 1 },
        { "dest": 10015, "xver": 1 }
    ] }, "streamSettings": { "network": "tcp", "security": "tls", "tlsSettings": { "alpn": ["h2", "http/1.1"], "certificates": [ { "certificateFile": "/usr/local/etc/xray/xray.crt", "keyFile": "/usr/local/etc/xray/xray.key" } ] } } },
    { "tag": "inbound-80", "port": 80, "protocol": "vless", "settings": { "clients": [], "decryption": "none", "fallbacks": [ 
        { "path": "/vmess", "dest": 10001, "xver": 1 }, { "path": "/vless", "dest": 10002, "xver": 1 }, { "path": "/trojan", "dest": 10003, "xver": 1 },
        { "path": "/vmess-upg", "dest": 10004, "xver": 1 }, { "path": "/vless-upg", "dest": 10005, "xver": 1 }, { "path": "/trojan-upg", "dest": 10006, "xver": 1 },
        { "dest": 10015, "xver": 1 }
    ] }, "streamSettings": { "network": "tcp", "security": "none" } },
    { "tag": "vmess_ws", "port": 10001, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "acceptProxyProtocol": true, "path": "/vmess" } } },
    { "tag": "vless_ws", "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [], "decryption": "none" }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "acceptProxyProtocol": true, "path": "/vless" } } },
    { "tag": "trojan_ws", "port": 10003, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "acceptProxyProtocol": true, "path": "/trojan" } } },
    { "tag": "vmess_upg", "port": 10004, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [] }, "streamSettings": { "network": "httpupgrade", "security": "none", "httpupgradeSettings": { "acceptProxyProtocol": true, "path": "/vmess-upg" } } },
    { "tag": "vless_upg", "port": 10005, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [], "decryption": "none" }, "streamSettings": { "network": "httpupgrade", "security": "none", "httpupgradeSettings": { "acceptProxyProtocol": true, "path": "/vless-upg" } } },
    { "tag": "trojan_upg", "port": 10006, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [] }, "streamSettings": { "network": "httpupgrade", "security": "none", "httpupgradeSettings": { "acceptProxyProtocol": true, "path": "/trojan-upg" } } },
    { "tag": "vmess_grpc", "port": 10007, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [] }, "streamSettings": { "network": "grpc", "security": "none", "grpcSettings": { "acceptProxyProtocol": true, "serviceName": "vmess-grpc" } } },
    { "tag": "vless_grpc", "port": 10008, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [], "decryption": "none" }, "streamSettings": { "network": "grpc", "security": "none", "grpcSettings": { "acceptProxyProtocol": true, "serviceName": "vless-grpc" } } },
    { "tag": "trojan_grpc", "port": 10009, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [] }, "streamSettings": { "network": "grpc", "security": "none", "grpcSettings": { "acceptProxyProtocol": true, "serviceName": "trojan-grpc" } } }
  ]
}
EOF

# File terpisah khusus outbound & routing (dibaca via -confdir, digabung otomatis oleh Xray)
cat > /usr/local/etc/xray/outbound.json <<'EOF'
{
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": { "domainStrategy": "IPIfNonMatch", "rules": [ { "inboundTag": ["api_in"], "outboundTag": "api_out", "type": "field" }, { "type": "field", "outboundTag": "blocked", "protocol": [ "bittorrent" ] } ] }
}
EOF
)
print_ok "Xray Configured"

# --- 8. ZIVPN ---
print_msg "Install ZIVPN"
(
    wget -O /usr/local/bin/zivpn "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    if [[ ! -s /usr/local/bin/zivpn ]]; then
        echo "GAGAL: download zivpn binary kosong/rusak, service zivpn tidak akan start." >&2
    fi
    chmod +x /usr/local/bin/zivpn
    echo '{"listen":":5667","cert":"/usr/local/etc/xray/xray.crt","key":"/usr/local/etc/xray/xray.key","obfs":"zivpn","auth":{"mode":"passwords","config":[]}}' > /etc/zivpn/config.json
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZIVPN
After=network.target
[Service]
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable zivpn && systemctl restart zivpn xray
    iptables -t nat -A PREROUTING -i $IFACE_NET -p udp --dport 6000:19999 -j DNAT --to-destination :5667
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5667
    netfilter-persistent save
)
print_ok "ZIVPN Installed"

# --- 9. AUTO-KILL, QUOTA & NOTIFIKASI SCRIPTS ---
print_msg "Setting up Cron & Notifikasi Scripts"
(
mkdir -p /usr/local/etc/xray/quota

# Script Expiry Auto-Kill
cat > /usr/local/bin/xray-exp <<'EOF'
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Cegah race condition: xray-exp, xray-limit, xray-quota semua jalan tiap
# menit lewat cron dan sama-sama menulis config.json. Tanpa lock ini,
# perubahan salah satu bisa tertimpa/hilang oleh yang lain.
[ "$XRAY_CFG_LOCKED" != "1" ] && exec env XRAY_CFG_LOCKED=1 flock /var/lock/xray-config.lock "$0" "$@"
CONFIG="/usr/local/etc/xray/config.json"
NOW=$(date +%s)
for proto in vmess vless trojan; do
    FILE="/usr/local/etc/xray/${proto}.txt"
    if [[ -f "$FILE" ]]; then
        while IFS="|" read -r user id exp limit status quota; do
            user=$(echo "$user" | tr -d '[:space:]')
            [[ -z "$user" ]] && continue
            EXP_S=$(date -d "$exp" +%s 2>/dev/null)
            if [[ -n "$EXP_S" && "$NOW" -ge "$EXP_S" ]]; then
_tf1=$(mktemp) &&                 jq --arg u "$user" '(.inbounds[] | select(.protocol == "'$proto'")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf1" && mv "$_tf1" $CONFIG; chmod 644 $CONFIG
                sed -i "/^$user|/d" $FILE
                rm -f "/usr/local/etc/xray/quota/$user"
                systemctl restart xray
            fi
        done < "$FILE"
    fi
done

# SSH Expiry
S_FILE="/usr/local/etc/xray/ssh.txt"
if [[ -f "$S_FILE" ]]; then
    while IFS="|" read -r user pass exp limit status; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" ]] && continue
        EXP_S=$(date -d "$exp" +%s 2>/dev/null)
        if [[ -n "$EXP_S" && "$NOW" -ge "$EXP_S" ]]; then
            userdel -f "$user" 2>/dev/null
            sed -i "/^$user|/d" "$S_FILE"
        fi
    done < "$S_FILE"
fi

# ZIVPN Expiry
Z_FILE="/etc/zivpn/zivpn.txt"
Z_CONF="/etc/zivpn/config.json"
if [[ -f "$Z_FILE" ]]; then
    while IFS="|" read -r f1 f2 f3; do
        if [[ -z "$f3" ]]; then u="unknown"; p="$f1"; exp="$f2"; else u="$f1"; p="$f2"; exp="$f3"; fi
        EXP_S=$(date -d "$exp" +%s 2>/dev/null)
        if [[ -n "$EXP_S" && "$NOW" -ge "$EXP_S" ]]; then
            _tfz=$(mktemp) && jq --arg pwd "$p" 'del(.auth.config[] | select(. == $pwd))' $Z_CONF > "$_tfz" && mv "$_tfz" $Z_CONF
            if [[ "$u" == "unknown" ]]; then sed -i "/^$p|/d" $Z_FILE; else sed -i "/^$u|/d" $Z_FILE; fi
            systemctl restart zivpn
        fi
    done < "$Z_FILE"
fi
EOF
chmod +x /usr/local/bin/xray-exp

# Script Limit IP (Toleransi 30 Detik + Anti-Ghost IP Xray + Deteksi IP Asli SSH via WS-Tunnel)
cat > /usr/local/bin/xray-limit <<'EOF'
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
[ "$XRAY_CFG_LOCKED" != "1" ] && exec env XRAY_CFG_LOCKED=1 flock /var/lock/xray-config.lock "$0" "$@"
CONFIG="/usr/local/etc/xray/config.json"
LOG_FILE="/var/log/xray/access.log"
TOKEN=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
CHATID=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
NOW=$(date +%s)

IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
DOM_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
ISP_VPS=$(cat /root/tendo/isp 2>/dev/null)

# --- GRACE-PERIOD / DEBOUNCE ---
# Script ini jalan tiap 1 menit lewat cron. Supaya reconnect cepat (mode
# pesawat, pindah WiFi<->data, dsb) yang bikin IP lama & IP baru sempat
# ke-scan bersamaan tidak langsung dianggap pelanggaran, kita baru lock
# kalau over-limit terdeteksi $REQUIRED_STREAK kali BERTURUT-TURUT
# (default 2x scan ~1-2 menit). Kalau di scan berikutnya sudah normal lagi,
# streak-nya direset ke 0 (dianggap reconnect biasa, bukan multi-device).
STREAK_DIR="/usr/local/etc/xray/streak"
mkdir -p "$STREAK_DIR"
REQUIRED_STREAK=2

[[ ! -f "$LOG_FILE" ]] && exit 0

# --- FIX: STATE IP AKTIF PERSISTEN ANTAR-RUN ---
# Xray cuma nulis baris "accepted ... email:" SEKALI saat koneksi baru
# dibuat, bukan berulang selama sesi itu hidup. Kalau cuma nge-scan window
# singkat (mis. 30 detik) tiap cron 1 menit, device yang sudah connect >30
# detik lalu (dan diam, tidak reconnect) akan hilang dari hasil scan walau
# sesinya masih aktif -> active_ips jadi under-count -> limit IP tidak
# pernah kena walau ada 2+ device/jaringan yang benar-benar nyala bareng.
# Makanya sekarang tiap IP yang pernah terlihat disimpan ke STATE_FILE
# dengan waktu terakhir terlihat, dan baru dianggap "sudah tidak aktif"
# kalau memang tidak ada baris log baru dari IP itu selama ACTIVE_WINDOW detik.
STATE_FILE="/tmp/xray_ip_state.log"
ACTIVE_WINDOW=90   # detik toleransi "masih dianggap aktif" sejak terakhir terlihat di log
SCAN_SECONDS=180   # scan log 3 menit terakhir supaya sesi yang lebih lama tetap ke-capture

STRS=$(for i in $(seq 0 $SCAN_SECONDS); do date -d "$i seconds ago" +"%Y/%m/%d %H:%M:%S"; done | paste -sd '|' -)
# FIX Ghost IP: Menghapus 127.0.0.1 dan user kosong "email: system"
tail -n 5000 "$LOG_FILE" | grep -E "^($STRS)" | grep "accepted" | grep "email: " | grep -v "email: system" | grep -v "127.0.0.1" | grep -v "::1" | awk '{
    ts = $1" "$2;
    for(i=1;i<=NF;i++) {
        if($i=="accepted") { ip=$(i-1); sub(/:.*/,"",ip); }
        if($i=="email:") { email=$(i+1); gsub(/[^a-zA-Z0-9_-]/, "", email); }
    }
    # FIX AKURASI: pakai IP penuh (bukan subnet /24) supaya 1 IP terdeteksi = 1 device asli
    if(ip!="" && email!="" && email!="system") {
        print ts"|"ip"|"email;
    }
}' > /tmp/xray_seen.log

touch "$STATE_FILE"
{
    # entri lama yang masih dalam ACTIVE_WINDOW detik
    awk -v now="$NOW" -v win="$ACTIVE_WINDOW" -F'|' '(now-$3)<=win{print}' "$STATE_FILE"
    # entri baru dari hasil scan barusan (konversi timestamp log jadi epoch)
    while IFS='|' read -r ts ip email; do
        epoch=$(date -d "$ts" +%s 2>/dev/null)
        [[ -n "$epoch" ]] && echo "${email}|${ip}|${epoch}"
    done < /tmp/xray_seen.log
} | awk -F'|' '{key=$1"|"$2; if(!($key in seen)||$3>seen[key]){seen[key]=$3; line[key]=$0}} END{for(k in line) print line[k]}' > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

awk -F'|' '{print $2, $1}' "$STATE_FILE" | sort -u > /tmp/xray_active.log

for proto in vmess vless trojan; do
    FILE="/usr/local/etc/xray/${proto}.txt"
    [[ ! -f "$FILE" ]] && continue
    while IFS="|" read -r user id exp limit status quota; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" ]] && continue
        
        if [[ "$status" == LOCKED_IP_* ]]; then
            lock_time=${status#LOCKED_IP_}
            if [[ $((NOW - lock_time)) -ge 600 ]]; then
                if [[ "$proto" == "trojan" ]]; then
_tf2=$(mktemp) &&                     jq --arg p "$id" --arg u "$user" '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password":$p,"email":$u,"level":0}]' $CONFIG > "$_tf2" && mv "$_tf2" $CONFIG; chmod 644 $CONFIG
                else
_tf3=$(mktemp) &&                     jq --arg id "$id" --arg u "$user" '(.inbounds[] | select(.protocol == "'$proto'")).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf3" && mv "$_tf3" $CONFIG; chmod 644 $CONFIG
                fi
                sed -i "s/^$user|.*/$user|$id|$exp|$limit|ACTIVE|$quota/g" "$FILE"
                systemctl restart xray
                if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
                    MSG="<b>[OK] AKUN DI-UNLOCK OTOMATIS (${proto^^})</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"User       : <code>$user</code>"$'\n'"[UNLOCK] Status: Active (Hukuman 10 menit selesai)"
                    /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
                fi
            fi
            continue
        elif [[ "$status" == "LOCKED" ]]; then
            continue
        fi
        
        [[ -z "$limit" || "$limit" == "0" ]] && continue
        
        active_ips=$(grep -w "$user" /tmp/xray_active.log | awk '{print $1}' | sort -u | wc -l)
        streak_file="$STREAK_DIR/${proto}_${user}"
        if [[ "$active_ips" -gt "$limit" ]]; then
            streak=$(cat "$streak_file" 2>/dev/null); streak=$((10#${streak:-0} + 1))
            echo "$streak" > "$streak_file"
            if [[ "$streak" -ge "$REQUIRED_STREAK" ]]; then
_tf4=$(mktemp) &&                 jq --arg u "$user" '(.inbounds[] | select(.protocol == "'$proto'")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf4" && mv "$_tf4" $CONFIG; chmod 644 $CONFIG
                sed -i "s/^$user|.*/$user|$id|$exp|$limit|LOCKED_IP_${NOW}|$quota/g" "$FILE"
                systemctl restart xray
                rm -f "$streak_file"
                if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
                    MSG="<b>[WARN] MULTI-LOGIN TERDETEKSI (${proto^^})</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"User       : <code>$user</code>"$'\n'"Limit IP   : $limit"$'\n'"[ALERT] Login Count: $active_ips"$'\n'"[BLOCK] Status: Terkunci 10 Menit"
                    /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
                fi
            fi
        else
            rm -f "$streak_file"
        fi
    done < "$FILE"
done

# SSH Limit IP Lock (deteksi IP asli, termasuk yang lewat WS-Tunnel/Dropbear)
S_FILE="/usr/local/etc/xray/ssh.txt"
WS_MAP="/var/run/ws-proxy-ipmap.log"
if [[ -f "$S_FILE" ]]; then
    # FIX AKURASI TOTAL: pendekatan lama mencocokkan PID dropbear ke user
    # pakai `ps -u "$user"` (proses yang UID-nya sudah jadi user itu). Ini
    # cuma valid KALAU dropbear benar-benar setuid ke user tsb untuk semua
    # jenis channel -- termasuk sesi port-forward-only tanpa shell (`-N`),
    # yang justru paling umum dipakai app tunneling (HTTP Injector, dst).
    # Kalau proses itu ternyata tetap jalan sebagai root selama channel-nya
    # cuma direct-tcpip (bukan shell/exec), `ps -u "$user"` TIDAK PERNAH
    # menemukan proses itu -> tunnel_ips selalu kosong -> limit IP gak
    # pernah kena walau ada banyak device beda IP connect lewat WS-tunnel.
    #
    # Sekarang PID dipetakan ke user langsung dari LOG AUTENTIKASI dropbear
    # sendiri (/var/log/auth.log): setiap login sukses dicatat sebagai
    # "dropbear[PID]: Password/Pubkey auth succeeded for 'user' from
    # 127.0.0.1:PORT" -- PORT di situ persis sama dengan port yang dicatat
    # ws-proxy.py di WS_MAP. Jadi cocokkan (user -> pid -> port -> IP asli)
    # lewat PID (bukan UID), dan validasi sesi masih aktif dengan mengecek
    # apakah PID itu masih hidup (`kill -0`) -- ini akurat terlepas dari
    # apakah dropbear drop privilege atau tidak untuk sesi tsb.
    declare -A PID_USER=()
    declare -A PID_PORT=()
    AUTH_LOG="/var/log/auth.log"
    if [[ -f "$AUTH_LOG" ]]; then
        while IFS= read -r line; do
            pid=$(grep -oP 'dropbear\[\K[0-9]+' <<< "$line")
            au=$(grep -oP "for '\K[^']+" <<< "$line")
            port=$(grep -oP ':\K[0-9]+$' <<< "$line")
            [[ -n "$pid" && -n "$au" && -n "$port" ]] && { PID_USER["$pid"]="$au"; PID_PORT["$pid"]="$port"; }
        done < <(tail -n 20000 "$AUTH_LOG" 2>/dev/null | grep -E "dropbear\[[0-9]+\]: (Password|Pubkey) auth succeeded")
    fi

    while IFS="|" read -r user pass exp limit status; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" ]] && continue
        if [[ "$status" == LOCKED_IP_* ]]; then
            lock_time=${status#LOCKED_IP_}
            if [[ $((NOW - lock_time)) -ge 600 ]]; then
                usermod -U "$user" 2>/dev/null
                sed -i "s/^$user|.*/$user|$pass|$exp|$limit|ACTIVE/g" "$S_FILE"
                if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
                    MSG="<b>[OK] AKUN DI-UNLOCK OTOMATIS (SSH)</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"User       : <code>$user</code>"$'\n'"[UNLOCK] Status: Active (Hukuman 10 menit selesai)"
                    /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
                fi
            fi
            continue
        elif [[ "$status" == "LOCKED" ]]; then
            continue
        fi
        
        [[ -z "$limit" || "$limit" == "0" ]] && continue

        # FIX AKURASI: hitung IP SUMBER UNIK asli (bukan jumlah sesi/koneksi).
        # 1) SSH langsung (port 22/444, openssh) -> IP asli terlihat langsung di `who`.
        direct_ips=$(who | awk -v u="$user" '$1==u {print $NF}' | tr -d '()' | grep -E '^[0-9a-fA-F.:]+$')

        # 2) SSH lewat WS-Tunnel/Dropbear -> dropbear cuma lihat 127.0.0.1, jadi
        #    IP aslinya diambil dari WS_MAP (ditulis ws-proxy.py), dipetakan
        #    lewat PID dari auth.log (bukan lewat kepemilikan proses/UID).
        tunnel_ips=""
        if [[ -f "$WS_MAP" ]]; then
            for pid in "${!PID_USER[@]}"; do
                [[ "${PID_USER[$pid]}" == "$user" ]] || continue
                kill -0 "$pid" 2>/dev/null || continue
                port="${PID_PORT[$pid]}"
                ip=$(awk -v p="$port" '$1==p{print $2}' "$WS_MAP" | tail -n1)
                [[ -n "$ip" ]] && tunnel_ips+="$ip"$'\n'
            done
        fi

        # 1 device yang buka banyak koneksi (aplikasi multi-thread) tetap dihitung
        # 1 IP; 2 device beda IP (walau share 1 akun) akan terdeteksi sebagai 2.
        active_ips=$(printf "%s\n%s\n" "$direct_ips" "$tunnel_ips" | grep -v '^$' | sort -u | wc -l)
        streak_file="$STREAK_DIR/ssh_${user}"
        if [[ "$active_ips" -gt "$limit" ]]; then
            streak=$(cat "$streak_file" 2>/dev/null); streak=$((10#${streak:-0} + 1))
            echo "$streak" > "$streak_file"
            if [[ "$streak" -ge "$REQUIRED_STREAK" ]]; then
                # Kunci akun agar tidak bisa login baru
                usermod -L "$user" 2>/dev/null

                # Putus SEMUA sesi aktif user (SSH langsung maupun WS-tunnel):
                # 1) Putus sesi OpenSSH langsung (port 22/444)
                killall -u "$user" 2>/dev/null

                # 2) Putus sesi WS-Tunnel/Dropbear:
                #    Kill semua PID dropbear yang teridentifikasi milik user ini.
                #    Dropbear akan menutup koneksi ke ws-proxy, sehingga
                #    ws-proxy juga akan menutup sisi client (HTTP Custom app).
                for pid in "${!PID_USER[@]}"; do
                    [[ "${PID_USER[$pid]}" == "$user" ]] || continue
                    kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null
                done

                sed -i "s/^$user|.*/$user|$pass|$exp|$limit|LOCKED_IP_${NOW}/g" "$S_FILE"
                rm -f "$streak_file"
                if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
                    MSG="<b>[WARN] MULTI-LOGIN TERDETEKSI (SSH)</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"User       : <code>$user</code>"$'\n'"Limit IP   : $limit"$'\n'"[ALERT] IP Aktif: $active_ips"$'\n'"[BLOCK] Status: Terkunci 10 Menit (Semua sesi diputus)"
                    /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
                fi
            fi
        else
            rm -f "$streak_file"
        fi
    done < "$S_FILE"
fi
EOF
chmod +x /usr/local/bin/xray-limit

# Script Quota 
cat > /usr/local/bin/xray-quota <<'EOF'
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
[ "$XRAY_CFG_LOCKED" != "1" ] && exec env XRAY_CFG_LOCKED=1 flock /var/lock/xray-config.lock "$0" "$@"
CONFIG="/usr/local/etc/xray/config.json"
TOKEN=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
CHATID=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')

IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
DOM_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
ISP_VPS=$(cat /root/tendo/isp 2>/dev/null)

STATS=$(/usr/local/bin/xray api statsquery -server=127.0.0.1:10085 2>/dev/null)
for proto in vmess vless trojan; do
    FILE="/usr/local/etc/xray/${proto}.txt"
    [[ ! -f "$FILE" ]] && continue
    while IFS="|" read -r user id exp limit status quota; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" || -z "$quota" || "$quota" == "0" || "$status" == "LOCKED" || "$status" == LOCKED_IP_* ]] && continue
        
        down=$(echo "$STATS" | jq -r ".stat[]? | select(.name == \"user>>>${user}>>>traffic>>>downlink\") | .value" 2>/dev/null)
        up=$(echo "$STATS" | jq -r ".stat[]? | select(.name == \"user>>>${user}>>>traffic>>>uplink\") | .value" 2>/dev/null)
        [[ -z "$down" || "$down" == "null" ]] && down=0
        [[ -z "$up" || "$up" == "null" ]] && up=0
        current_api=$((down + up))
        
        QUOTA_FILE="/usr/local/etc/xray/quota/${user}"
        if [[ -f "$QUOTA_FILE" ]]; then
            read total_acc last_api < "$QUOTA_FILE"
        else
            total_acc=0
            last_api=0
        fi
        
        if (( current_api < last_api )); then
            total_acc=$((total_acc + current_api))
        else
            diff=$((current_api - last_api))
            total_acc=$((total_acc + diff))
        fi
        last_api=$current_api
        echo "$total_acc $last_api" > "$QUOTA_FILE"
        
        quota_bytes=$(awk "BEGIN {printf \"%.0f\", $quota * 1073741824}")
        if (( total_acc >= quota_bytes )); then
_tf5=$(mktemp) &&             jq --arg u "$user" '(.inbounds[] | select(.protocol == "'$proto'")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf5" && mv "$_tf5" $CONFIG; chmod 644 $CONFIG
            sed -i "/^$user|/d" "$FILE"
            rm -f "$QUOTA_FILE"
            systemctl restart xray
            if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
                MSG="<b>[BLOCK] KUOTA HABIS (AKUN DIHAPUS - ${proto^^})</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"User       : <code>$user</code>"$'\n'"[INFO] Batas Kuota: ${quota} GB"$'\n'"[BLOCK] Status: Akun Otomatis Dihapus"
                /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
            fi
        fi
    done < "$FILE"
done
EOF
chmod +x /usr/local/bin/xray-quota

# Script Telegram Login Notif (Split per-protocol, Anti-Ghosting)
cat > /usr/local/bin/bot-login-notif <<'EOF'
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
TOKEN=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
CHATID=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
[[ -z "$TOKEN" || -z "$CHATID" ]] && exit 0
LOG_FILE="/var/log/xray/access.log"

IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
DOM_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
ISP_VPS=$(cat /root/tendo/isp 2>/dev/null)

STRS=$(for i in {0..30}; do date -d "$i seconds ago" +"%Y/%m/%d %H:%M:%S"; done | paste -sd '|' -)
tail -n 5000 "$LOG_FILE" | grep -E "^($STRS)" | grep "accepted" | grep "email: " | grep -v "email: system" | grep -v "127.0.0.1" | grep -v "::1" | awk '{
    for(i=1;i<=NF;i++) {
        if($i=="accepted") { ip=$(i-1); sub(/:.*/,"",ip); }
        if($i=="email:") { email=$(i+1); gsub(/[^a-zA-Z0-9_-]/, "", email); }
    }
    if(ip!="" && email!="" && email!="system") {
        print ip, email;
    }
}' | sort -u > /tmp/bot_active.log

STATS=$(/usr/local/bin/xray api statsquery -server=127.0.0.1:10085 2>/dev/null)

for proto in vmess vless trojan; do
    FILE="/usr/local/etc/xray/${proto}.txt"
    [[ ! -f "$FILE" ]] && continue
    
    PROTO_MSG=""
    FOUND=0
    while IFS="|" read -r user id exp limit status quota; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" ]] && continue
        
        active_ips=$(grep -w "$user" /tmp/bot_active.log | wc -l)
        if [[ "$active_ips" -gt 0 ]]; then
            down=$(echo "$STATS" | jq -r ".stat[]? | select(.name == \"user>>>${user}>>>traffic>>>downlink\") | .value" 2>/dev/null)
            up=$(echo "$STATS" | jq -r ".stat[]? | select(.name == \"user>>>${user}>>>traffic>>>uplink\") | .value" 2>/dev/null)
            [[ -z "$down" || "$down" == "null" ]] && down=0
            [[ -z "$up" || "$up" == "null" ]] && up=0
            current_api=$((down + up))

            QUOTA_FILE="/usr/local/etc/xray/quota/${user}"
            if [[ -f "$QUOTA_FILE" ]]; then
                read total_acc last_api < "$QUOTA_FILE"
                [[ -z "$total_acc" ]] && total_acc=0
                [[ -z "$last_api" ]] && last_api=0
                if (( current_api >= last_api )); then
                    real_usage=$(( total_acc + (current_api - last_api) ))
                else
                    real_usage=$(( total_acc + current_api ))
                fi
            else
                real_usage=$current_api
            fi

            if (( real_usage < 1048576 )); then
                usage_fmt=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $real_usage/1024}")" KB"
            elif (( real_usage < 1073741824 )); then
                usage_fmt=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $real_usage/1048576}")" MB"
            else
                usage_fmt=$(LC_ALL=C awk "BEGIN {printf \"%.2f\", $real_usage/1073741824}")" GB"
            fi

            PROTO_MSG+="User       : <code>$user</code> | Login: $active_ips IP | Usage: ${usage_fmt}"$'\n'
            FOUND=1
        fi
    done < "$FILE"
    
    if [[ "$FOUND" -eq 1 ]]; then
        MSG="<b>[INFO] LAPORKAN PENGGUNA AKTIF (${proto^^})</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"${PROTO_MSG}"
        /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
    fi
done

# Check SSH Active Absolute Tracker
S_FILE="/usr/local/etc/xray/ssh.txt"
if [[ -f "$S_FILE" ]]; then
    PROTO_MSG=""
    FOUND=0
    while IFS="|" read -r user pass exp limit status; do
        user=$(echo "$user" | tr -d '[:space:]')
        [[ -z "$user" ]] && continue
        
        active_ips=$(who | awk -v u="$user" '$1==u {print $NF}' | tr -d '()' | grep -E '^[0-9a-fA-F.:]+$' | sort -u | wc -l)
        if [[ "$active_ips" -gt 0 ]]; then
            PROTO_MSG+="User       : <code>$user</code> | Login: $active_ips IP Aktif"$'\n'
            FOUND=1
        fi
    done < "$S_FILE"
    
    if [[ "$FOUND" -eq 1 ]]; then
        MSG="<b>[INFO] LAPORKAN PENGGUNA AKTIF (SSH)</b>"$'\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"${PROTO_MSG}"
        /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d "chat_id=${CHATID}" --data-urlencode "text=${MSG}" -d "parse_mode=HTML" > /dev/null
    fi
fi
EOF
chmod +x /usr/local/bin/bot-login-notif

# Script Telegram Backup Notif
cat > /usr/local/bin/bot-backup <<'EOF'
#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if ! command -v zip &> /dev/null; then apt-get install -y zip; fi
TOKEN=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
CHATID=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
[[ -z "$TOKEN" || -z "$CHATID" ]] && exit 0
DATE=$(date +"%Y-%m-%d_%H-%M")

IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
DOM_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
ISP_VPS=$(cat /root/tendo/isp 2>/dev/null)

ZIP_FILE="/tmp/Backup_${DATE}.zip"
cd /
zip -r $ZIP_FILE usr/local/etc/xray/ etc/zivpn/ etc/tendo_bot/ etc/issue.net
cd -
[[ ! -f "$ZIP_FILE" ]] && exit 0

/usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendDocument" \
    -F "chat_id=${CHATID}" \
    -F "document=@${ZIP_FILE}" \
    -F "caption=[PKG] AUTOBACKUP VPS"$'\n\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"Date       : ${DATE}"$'\n'"[OK] Backup Successfully generated." > /dev/null
rm -f $ZIP_FILE
EOF
chmod +x /usr/local/bin/bot-backup

(crontab -l 2>/dev/null | grep -v "xray-exp"; echo "* * * * * /usr/local/bin/xray-exp") | crontab -
(crontab -l 2>/dev/null | grep -v "xray-limit"; echo "* * * * * /usr/local/bin/xray-limit") | crontab -
(crontab -l 2>/dev/null | grep -v "xray-quota"; echo "* * * * * /usr/local/bin/xray-quota") | crontab -
)
print_ok "Sistem Auto & Cron Jobs"
fi  # end of [[ INSTALL_MODE != update ]] guard

# --- 10. WEB PANEL ADMIN ---
print_msg "Instalasi Web Panel Admin"
(
pip3 install flask --break-system-packages -q 2>/dev/null \
  || pip3 install flask -q 2>/dev/null \
  || apt-get install -y -q python3-flask 2>/dev/null
python3 -c "import flask" 2>/dev/null || {
    echo "[WARN] Gagal install Flask otomatis, mencoba metode terakhir..."
    apt-get update -q 2>/dev/null
    apt-get install -y -q python3-flask 2>/dev/null
    pip3 install flask --break-system-packages --force-reinstall -q 2>/dev/null
}

cat > /usr/local/bin/xpanel.py << 'XPANELEOF'
#!/usr/bin/env python3
"""xpanel - Web Admin Panel VPS Manager"""
import os, sys, json, hashlib, secrets, subprocess, time, re, fcntl, shlex, unicodedata
from datetime import datetime
from functools import wraps

try:
    from flask import (Flask, render_template_string, request,
                       redirect, url_for, session, flash, jsonify)
except ImportError:
    sys.exit("[ERROR] Flask tidak ditemukan. Install: pip3 install flask")

# ── Path Data ────────────────────────────────────────────────────────
PANEL_CONF  = '/etc/tendo_bot/panel.conf'
DATA_SSH    = '/usr/local/etc/xray/ssh.txt'
DATA_VMESS  = '/usr/local/etc/xray/vmess.txt'
DATA_VLESS  = '/usr/local/etc/xray/vless.txt'
DATA_TROJAN = '/usr/local/etc/xray/trojan.txt'
DATA_ZIVPN  = '/etc/zivpn/zivpn.txt'
XRAY_CFG    = '/usr/local/etc/xray/config.json'
DOMAIN_FILE = '/usr/local/etc/xray/domain'
QUOTA_DIR   = '/usr/local/etc/xray/quota'
BOT_TOKEN   = '/etc/tendo_bot/bot_token'
BOT_CHATID  = '/etc/tendo_bot/chat_id'
LOG_STAT    = '/etc/tendo_bot/log_stat'
BAK_STAT    = '/etc/tendo_bot/bak_stat'
IP_FILE     = '/root/tendo/ip'
ISP_FILE    = '/root/tendo/isp'
CITY_FILE   = '/root/tendo/city'
LOCK_FILE   = '/var/lock/xray-config.lock'

# ── Load Konfigurasi Panel ───────────────────────────────────────────
def load_conf():
    try:
        with open(PANEL_CONF) as f:
            p = f.read().strip().split(':')
            if len(p) >= 5:
                return {'user': p[0], 'salt': p[1], 'hash': p[2],
                        'port': int(p[3]), 'secret': p[4]}
    except:
        pass
    return None

conf = load_conf()
if not conf:
    sys.exit("[ERROR] Panel belum dikonfigurasi.\nJalankan: menu -> Web Panel -> Setup Panel")

app = Flask(__name__)
app.secret_key = conf['secret']
PORT = conf['port']
SESSION_HOURS = 8

# ── Auth Helpers ─────────────────────────────────────────────────────
_attempts = {}

def hash_pw(pw, salt):
    return hashlib.sha256((salt + pw).encode()).hexdigest()

def clean_id(raw, maxlen=32):
    """Lowercase + hanya sisakan a-z 0-9 . _ - (buang emoji/spasi/simbol/unicode)."""
    if not raw:
        return ''
    raw = unicodedata.normalize('NFKC', raw).strip().lower()
    raw = re.sub(r'[^a-z0-9._-]', '', raw)
    return raw[:maxlen]

def id_exists_in_files(u, *files):
    """Cek keberadaan username di file data tanpa lewat shell (aman dari karakter aneh)."""
    for fp in files:
        try:
            with open(fp) as f:
                for line in f:
                    if line.split('|', 1)[0].strip().lower() == u:
                        return True
        except FileNotFoundError:
            continue
    return False

def linux_user_exists(u):
    if not u:
        return False
    out, _ = run(f"id {shlex.quote(u)} > /dev/null 2>&1 && echo EXISTS || echo OK")
    return 'EXISTS' in out

def rate_ok(ip):
    now = time.time()
    if ip in _attempts:
        cnt, t0 = _attempts[ip]
        if now - t0 > 600:
            del _attempts[ip]; return True
        return cnt < 5
    return True

def rec_attempt(ip):
    now = time.time()
    c, t = _attempts.get(ip, (0, now))
    _attempts[ip] = (c + 1, t if c else now)

def clear_attempt(ip):
    _attempts.pop(ip, None)

def login_required(f):
    @wraps(f)
    def d(*a, **kw):
        if 'user' not in session:
            return redirect('/login')
        if time.time() - session.get('ts', 0) > SESSION_HOURS * 3600:
            session.clear()
            flash('Sesi telah berakhir. Silakan login kembali.', 'warning')
            return redirect('/login')
        session['ts'] = time.time()
        return f(*a, **kw)
    return d

# ── Data Helpers ─────────────────────────────────────────────────────
def rd(path):
    try:
        with open(path) as f: return f.read().strip()
    except: return ''

def rlines(path):
    try:
        with open(path) as f:
            return [l.strip() for l in f if l.strip()]
    except: return []

def wlines(path, lines):
    with open(path, 'w') as f:
        f.write('\n'.join(lines) + ('\n' if lines else ''))

def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip(), r.returncode
    except: return '', 1

def xray_lock(fn):
    """Jalankan operasi xray config dengan file lock."""
    lock = open(LOCK_FILE, 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fn()
    finally:
        fcntl.flock(lock, fcntl.LOCK_UN)
        lock.close()

def exp_info(exp_str):
    try:
        exp = datetime.strptime(exp_str[:10], '%Y-%m-%d')
        days = (exp - datetime.now()).days
        if days < 0: return 'expired', f'Expired ({abs(days)}h lalu)'
        if days == 0: return 'warning', 'Hari ini'
        if days <= 3: return 'warning', f'{days} hari lagi'
        return 'ok', f'{days} hari lagi'
    except: return 'ok', exp_str

def read_ssh():
    out = []
    for l in rlines(DATA_SSH):
        p = l.split('|')
        if len(p) >= 5:
            st, sttxt = exp_info(p[2])
            locked = 'LOCKED' in p[4]
            out.append({'user':p[0],'pass':p[1],'exp':p[2],'limit':p[3],
                        'status':p[4],'exp_st':st,'exp_txt':sttxt,'locked':locked})
    return out

def read_xray(proto):
    fp = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    out = []
    for l in rlines(fp):
        p = l.split('|')
        if len(p) >= 6:
            st, sttxt = exp_info(p[2])
            locked = 'LOCKED' in p[4]
            qf = os.path.join(QUOTA_DIR, p[0])
            usage = '0.00'
            try:
                with open(qf) as f:
                    v = f.read().strip().split()
                    if v: usage = '{:.2f}'.format(float(v[0]) / (1024**3))
            except: pass
            out.append({'user':p[0],'id':p[1],'exp':p[2],'limit':p[3],
                        'status':p[4],'quota':p[5],'usage':usage,
                        'exp_st':st,'exp_txt':sttxt,'locked':locked})
    return out

def read_zivpn():
    out = []
    for l in rlines(DATA_ZIVPN):
        p = l.split('|')
        if len(p) == 2:
            st, sttxt = exp_info(p[1])
            out.append({'user':'-','pass':p[0],'exp':p[1],'exp_st':st,'exp_txt':sttxt})
        elif len(p) >= 3:
            st, sttxt = exp_info(p[2])
            out.append({'user':p[0],'pass':p[1],'exp':p[2],'exp_st':st,'exp_txt':sttxt})
    return out

def send_telegram(msg_html):
    """Send a formatted account-detail message to Telegram, same style as the CLI's send_tele()."""
    tok = rd(BOT_TOKEN); chat = rd(BOT_CHATID)
    if not tok or not chat: return
    full = "<b>[OK] NEW ACCOUNT CREATED</b>\n\n" + msg_html
    try:
        import urllib.request, urllib.parse
        data = urllib.parse.urlencode({'chat_id': chat, 'text': full, 'parse_mode': 'HTML'}).encode()
        req = urllib.request.Request(f'https://api.telegram.org/bot{tok}/sendMessage', data=data)
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        pass

def detail_ssh(u, p, exp, lim, html=False):
    domain = rd(DOMAIN_FILE); isp = rd(ISP_FILE); city = rd(CITY_FILE)
    payload = f"GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]"
    if html:
        u2, p2, d2, pl2 = f'<code>{u}</code>', f'<code>{p}</code>', f'<code>{domain}</code>', f'<code>{payload}</code>'
        line = '<b>------------------------------------</b>'
    else:
        u2, p2, d2, pl2 = u, p, domain, payload
        line = '------------------------------------'
    title = '<b>ACCOUNT SSH / WS</b>' if html else 'ACCOUNT SSH / WS'
    return (f"{line}\n          {title}\n{line}\n"
            f"Username       : {u2}\nPassword       : {p2}\nCITY           : {city}\nISP            : {isp}\nDomain         : {d2}\n"
            f"Port TLS       : 443, 8443\nPort none TLS  : 80, 8080\nPort any       : 2082, 2083, 8880\n"
            f"Port OpenSSH   : 22, 444\nPort Dropbear  : 90\nPort UDPGW     : 7100-7600\n"
            f"Limit IP       : {lim} IP\nPayload WS     : {pl2}\nExpired On     : {exp}\n{line}\n")

def build_xray_links(proto, u, uid, domain):
    import base64
    if proto == 'vmess':
        def enc(port, net, path, tls, sni):
            obj = {"v":"2","ps":u,"add":domain,"port":str(port),"id":uid,"aid":"0","scy":"auto",
                   "net":net,"type":"none","host":domain,"path":path,"tls":tls,"sni":sni}
            return base64.b64encode(json.dumps(obj).encode()).decode()
        ws_tls   = "vmess://" + enc(443,"ws","/vmess","tls",domain)
        ws_ntls  = "vmess://" + enc(80,"ws","/vmess","","")
        grpc_tls = "vmess://" + enc(443,"grpc","/vmess-grpc","tls",domain)
        upg_tls  = "vmess://" + enc(443,"httpupgrade","/vmess-upg","tls",domain)
        upg_ntls = "vmess://" + enc(80,"httpupgrade","/vmess-upg","","")
    elif proto == 'vless':
        ws_tls   = f"vless://{uid}@{domain}:443?path=%2Fvless&security=tls&encryption=none&host={domain}&type=ws&sni={domain}#{u}"
        ws_ntls  = f"vless://{uid}@{domain}:80?path=%2Fvless&security=none&encryption=none&host={domain}&type=ws#{u}"
        grpc_tls = f"vless://{uid}@{domain}:443?security=tls&encryption=none&host={domain}&type=grpc&serviceName=vless-grpc&sni={domain}#{u}"
        upg_tls  = f"vless://{uid}@{domain}:443?path=%2Fvless-upg&security=tls&encryption=none&host={domain}&type=httpupgrade&sni={domain}#{u}"
        upg_ntls = f"vless://{uid}@{domain}:80?path=%2Fvless-upg&security=none&encryption=none&host={domain}&type=httpupgrade#{u}"
    else:  # trojan
        ws_tls   = f"trojan://{uid}@{domain}:443?path=%2Ftrojan&security=tls&host={domain}&type=ws&sni={domain}#{u}"
        ws_ntls  = f"trojan://{uid}@{domain}:80?path=%2Ftrojan&security=none&host={domain}&type=ws#{u}"
        grpc_tls = f"trojan://{uid}@{domain}:443?security=tls&host={domain}&type=grpc&serviceName=trojan-grpc&sni={domain}#{u}"
        upg_tls  = f"trojan://{uid}@{domain}:443?path=%2Ftrojan-upg&security=tls&host={domain}&type=httpupgrade&sni={domain}#{u}"
        upg_ntls = ''
    return ws_tls, ws_ntls, grpc_tls, upg_tls, upg_ntls

def detail_xray(proto, u, uid, exp, lim, quota, usage, html=False):
    domain = rd(DOMAIN_FILE); isp = rd(ISP_FILE); city = rd(CITY_FILE)
    ws_tls, ws_ntls, grpc_tls, upg_tls, upg_ntls = build_xray_links(proto, u, uid, domain)
    str_quota = 'Unlimited' if quota == '0' else f'{quota} GB'
    P = proto.upper()
    if html:
        u2, id2, d2 = f'<code>{u}</code>', f'<code>{uid}</code>', f'<code>{domain}</code>'
        b = lambda s: f'<b>{s}</b>'; line = '<b>------------------------------------</b>'
        wrap = lambda s: f'<code>{s}</code>'
    else:
        u2, id2, d2 = u, uid, domain
        b = lambda s: s; line = '------------------------------------'
        wrap = lambda s: s
    idlabel = 'Password' if proto == 'trojan' else 'Password / ID'
    extra = ''
    if proto == 'vmess': extra = 'alterId        : 0\nSecurity       : auto\n'
    elif proto == 'vless': extra = 'Encryption     : none\n'
    out = (f"{line}\n               {b(P)}\n{line}\n"
           f"Username       : {u2}\n{idlabel}  : {id2}\nCITY           : {city}\nISP            : {isp}\nDomain         : {d2}\n"
           f"Port TLS       : 443\nPort none TLS  : 80\n{extra}"
           f"network        : ws, grpc, upgrade\npath ws        : /{proto}\nserviceName    : {proto}-grpc\npath upgrade   : /{proto}-upg\n"
           f"Limit IP       : {lim} IP\nQuota Bandwidth: {str_quota}\nUsage Bandwidth: {usage} GB\nExpired On     : {exp}\n")
    out += f"{line}\n           {b(P + ' WS TLS')}\n{line}\n{wrap(ws_tls)}\n{line}\n"
    if ws_ntls:
        out += f"          {b(P + ' WS NO TLS')}\n{line}\n{wrap(ws_ntls)}\n{line}\n"
    out += f"             {b(P + ' GRPC')}\n{line}\n{wrap(grpc_tls)}\n{line}\n"
    out += f"         {b(P + ' Upgrade TLS')}\n{line}\n{wrap(upg_tls)}\n{line}\n"
    if upg_ntls:
        out += f"        {b(P + ' Upgrade NO TLS')}\n{line}\n{wrap(upg_ntls)}\n{line}\n"
    return out

def detail_zivpn(p, exp, html=False):
    domain = rd(DOMAIN_FILE); isp = rd(ISP_FILE); city = rd(CITY_FILE); ip = rd(IP_FILE)
    if html:
        p2, d2, ip2 = f'<code>{p}</code>', f'<code>{domain}</code>', f'<code>{ip}</code>'
        line = '<b>-----------------------------------------</b>'
        title = '<b>ACCOUNT ZIVPN UDP</b>'
    else:
        p2, d2, ip2 = p, domain, ip
        line = '-----------------------------------------'
        title = 'ACCOUNT ZIVPN UDP'
    return (f"{line}\n  {title}\n{line}\n"
            f"Password   : {p2}\nCITY       : {city}\nISP        : {isp}\nIP ISP     : {ip2}\nDomain     : {d2}\nExpired On : {exp}\n{line}\n")

def detail_modal(mid, title, text):
    esc = text.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
    return f"""<div class="modal" id="{mid}">
  <div class="modal-box" style="max-width:520px">
    <span class="modal-close" onclick="closeModal('{mid}')">x</span>
    <h3>{title}</h3>
    <textarea id="{mid}_ta" readonly style="width:100%;min-height:280px;background:var(--bg);border:1px solid var(--border);border-radius:6px;color:#c9d1d9;font-size:12px;font-family:monospace;padding:10px;white-space:pre;resize:vertical">{esc}</textarea>
    <button class="btn btn-primary" style="margin-top:10px" onclick="copyText(document.getElementById('{mid}_ta').value)">Salin Semua</button>
  </div>
</div>"""

ACC_ICON_DETAIL = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v4l2.5 2.5"/></svg>'
ACC_ICON_RENEW  = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.2-8.56"/><path d="M21 3v6h-6"/></svg>'
ACC_ICON_LOCK   = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>'
ACC_ICON_UNLOCK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 7.9-2.5"/></svg>'
ACC_ICON_DELETE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/></svg>'

EXP_COLOR = {'expired':'var(--red)','warning':'var(--amber)','ok':'var(--green)'}

def acc_initials(name):
    parts = [p for p in re.split(r'[ ._-]+', name) if p]
    if not parts: return '??'
    if len(parts) == 1: return (parts[0][:2] or '??').upper()
    return (parts[0][0] + parts[1][0]).upper()

def acc_meta(label, value, color=''):
    style = f' style="color:{color}"' if color else ''
    return f'<div><div class="k">{label}</div><div class="v"{style}>{value}</div></div>'

def acc_act_detail(mid):
    return f'<button type="button" class="acc-act" onclick="openModal(\'{mid}\')">{ACC_ICON_DETAIL}<span>Detail</span></button>'

def acc_act_renew(mid):
    return f'<button type="button" class="acc-act" onclick="openModal(\'{mid}\')">{ACC_ICON_RENEW}<span>Renew</span></button>'

def acc_act_lock(action_url, hidden_name, hidden_val, locked):
    if locked:
        return (f'<form method="post" action="{action_url}" style="display:contents">'
                f'<input type="hidden" name="{hidden_name}" value="{hidden_val}">'
                f'<button type="submit" class="acc-act unlock">{ACC_ICON_UNLOCK}<span>Buka</span></button></form>')
    return (f'<form method="post" action="{action_url}" style="display:contents">'
            f'<input type="hidden" name="{hidden_name}" value="{hidden_val}">'
            f'<button type="submit" class="acc-act lock">{ACC_ICON_LOCK}<span>Kunci</span></button></form>')

def acc_act_delete(action_url, hidden_name, hidden_val, confirm_msg):
    return (f'<form method="post" action="{action_url}" style="display:contents" onsubmit="return confirm(\'{confirm_msg}\')">'
            f'<input type="hidden" name="{hidden_name}" value="{hidden_val}">'
            f'<button type="submit" class="acc-act danger">{ACC_ICON_DELETE}<span>Hapus</span></button></form>')

def acc_card(name, sub, cred_label, cred_value, meta_items, actions_html):
    cred_html = ''
    if cred_value:
        cred_html = f'<div class="acc-cred"><span title="{cred_value}">{cred_label}: {cred_value}</span><button type="button" onclick="copyText(\'{cred_value}\')">Salin</button></div>'
    meta_html = ''.join(meta_items)
    return f"""<div class="acc-item">
  <div class="acc-item-head" onclick="this.parentElement.classList.toggle('open')">
    <div class="acc-avatar">{acc_initials(name)}</div>
    <div class="acc-main"><div class="acc-name">{name}</div><div class="acc-sub">{sub}</div></div>
    <svg class="acc-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><polyline points="6 9 12 15 18 9"/></svg>
  </div>
  <div class="acc-detail"><div class="acc-detail-inner">
    <div class="acc-divider"></div>
    {cred_html}
    <div class="acc-meta">{meta_html}</div>
    <div class="acc-actions">{actions_html}</div>
  </div></div>
</div>"""

def human_bytes(n):
    try: n = float(n)
    except: return '0 B'
    for unit in ['B','KB','MB','GB','TB']:
        if abs(n) < 1024 or unit == 'TB':
            return f"{n:.2f} {unit}" if unit != 'B' else f"{int(n)} B"
        n /= 1024
    return f"{n:.2f} TB"

def human_bps(bits_per_sec):
    try: n = float(bits_per_sec)
    except: return '0 bps'
    for unit in ['bps','Kbps','Mbps','Gbps']:
        if abs(n) < 1000 or unit == 'Gbps':
            return f"{n:.1f} {unit}"
        n /= 1000
    return f"{n:.1f} Gbps"

_iface_cache = {'val': None, 't': 0}
def get_default_iface():
    if _iface_cache['val'] and time.time() - _iface_cache['t'] < 60:
        return _iface_cache['val']
    out, _ = run("ip -4 route ls | grep default | grep -Po '(?<=dev )(\\S+)' | head -1")
    iface = out.strip() or 'eth0'
    _iface_cache['val'] = iface; _iface_cache['t'] = time.time()
    return iface

def read_net_bytes(iface):
    try:
        with open('/proc/net/dev') as f:
            for line in f:
                if ':' not in line: continue
                name, data = line.split(':', 1)
                if name.strip() == iface:
                    p = data.split()
                    return int(p[0]), int(p[8])  # rx bytes, tx bytes
    except Exception:
        pass
    return 0, 0

def get_live_rate(iface, sample=0.5):
    """Blocking short sample of the live transfer rate (bits/sec), same pattern as get_cpu_usage()."""
    try:
        rx1, tx1 = read_net_bytes(iface)
        time.sleep(sample)
        rx2, tx2 = read_net_bytes(iface)
        rx_bps = max(0, rx2 - rx1) / sample * 8
        tx_bps = max(0, tx2 - tx1) / sample * 8
        return rx_bps, tx_bps
    except Exception:
        return 0, 0

def vnstat_series(mode, iface, limit):
    """mode: 'f' (5 minutes), 'd' (days), 'm' (months). Values from vnstat are in KiB."""
    out, code = run(f"vnstat --json {mode} {limit} -i {iface}")
    if code != 0 or not out: return []
    try:
        data = json.loads(out)
        ifaces = data.get('interfaces', [])
        if not ifaces: return []
        key = {'f':'fiveminute','h':'hour','d':'day','m':'month','y':'year'}[mode]
        entries = ifaces[0].get('traffic', {}).get(key, [])
        out_list = []
        for e in entries:
            rx = e.get('rx', 0) * 1024
            tx = e.get('tx', 0) * 1024
            d = e.get('date', {})
            t = e.get('time', {})
            if 'day' in d and 'hour' in t:
                label = f"{d.get('day'):02d}/{d.get('month'):02d} {t.get('hour'):02d}:{t.get('minute'):02d}"
            elif 'day' in d:
                label = f"{d.get('day'):02d}/{d.get('month'):02d}/{d.get('year')}"
            elif 'month' in d:
                bulan_id = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des']
                label = f"{bulan_id[d.get('month',0)]} {d.get('year')}"
            else:
                label = '-'
            out_list.append({'label': label, 'rx': rx, 'tx': tx, 'total': rx + tx})
        return out_list[-limit:]
    except Exception:
        return []

def bandwidth_rows_html(series):
    if not series:
        return '<tr><td colspan="4" style="text-align:center;color:#6e7681;padding:20px">Data belum tersedia (vnstat masih mengumpulkan data)</td></tr>'
    maxv = max((e['total'] for e in series), default=1) or 1
    rows = ''
    for e in reversed(series):
        pct = int(e['total'] / maxv * 100)
        rows += f"""<tr>
<td data-th="Waktu">{e['label']}</td>
<td data-th="Download">{human_bytes(e['rx'])}</td>
<td data-th="Upload">{human_bytes(e['tx'])}</td>
<td data-th="Total" style="min-width:140px">
  <div style="display:flex;align-items:center;gap:8px">
    <div class="card-bar" style="flex:1;margin:0"><div class="card-bar-fill" style="width:{pct}%"></div></div>
    <span style="font-size:12px;white-space:nowrap">{human_bytes(e['total'])}</span>
  </div>
</td></tr>"""
    return rows

def get_cpu_usage():
    ncpu = os.cpu_count() or 1
    sample = 0.4
    # 1) cgroup v2 — accurate on modern LXC/Docker/systemd-nspawn containers
    try:
        cpu_stat = '/sys/fs/cgroup/cpu.stat'
        if os.path.exists(cpu_stat):
            def _usec():
                with open(cpu_stat) as f:
                    for line in f:
                        if line.startswith('usage_usec'):
                            return int(line.split()[1])
                return None
            u1 = _usec()
            if u1 is not None:
                time.sleep(sample)
                u2 = _usec()
                pct = ((u2 - u1) / 1_000_000.0) / (sample * ncpu) * 100
                if pct > 0.01:
                    return str(round(min(pct, 100), 1))
    except Exception:
        pass
    # 2) cgroup v1 — older Docker/LXC containers
    try:
        acct = '/sys/fs/cgroup/cpuacct/cpuacct.usage'
        if os.path.exists(acct):
            def _ns():
                with open(acct) as f: return int(f.read().strip())
            n1 = _ns()
            time.sleep(sample)
            n2 = _ns()
            pct = ((n2 - n1) / 1_000_000_000.0) / (sample * ncpu) * 100
            if pct > 0.01:
                return str(round(min(pct, 100), 1))
    except Exception:
        pass
    # 3) /proc/stat — works on KVM/dedicated/most regular VPS
    try:
        def _read():
            with open('/proc/stat') as f:
                parts = f.readline().split()
            vals = list(map(int, parts[1:8]))
            idle = vals[3] + vals[4]
            total = sum(vals)
            return idle, total
        idle1, total1 = _read()
        time.sleep(sample)
        idle2, total2 = _read()
        dt = total2 - total1
        di = idle2 - idle1
        if dt > 0:
            pct = (1 - di / dt) * 100
            if pct > 0.01:
                return str(round(pct, 1))
    except Exception:
        pass
    # 4) Last resort — load average relative to core count. On some
    #    older container hosts (legacy OpenVZ) /proc/stat and cgroup
    #    files reflect the host, not the container, and always read as
    #    idle. Load average is usually still container-specific there.
    try:
        load1 = os.getloadavg()[0]
        pct = min(load1 / ncpu * 100, 100)
        return str(round(pct, 1))
    except Exception:
        return '0'

def sys_info():
    domain  = rd(DOMAIN_FILE)
    ip      = rd(IP_FILE)
    isp     = rd(ISP_FILE)
    city    = rd(CITY_FILE)
    uptime, _= run("uptime -p | sed 's/up //'")
    cpu      = get_cpu_usage()
    ram_u, _ = run("free -m | awk 'NR==2{print $3}'")
    ram_t, _ = run("free -m | awk 'NR==2{print $2}'")
    disk, _  = run("df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\")\"}'")
    return {
        'domain':domain,'ip':ip,'isp':isp,'city':city,'uptime':uptime,
        'cpu':cpu or '0','ram_u':ram_u or '0','ram_t':ram_t or '1',
        'disk':disk or '-',
        'n_ssh':len(rlines(DATA_SSH)),'n_vmess':len(rlines(DATA_VMESS)),
        'n_vless':len(rlines(DATA_VLESS)),'n_trojan':len(rlines(DATA_TROJAN)),
        'n_zivpn':len(rlines(DATA_ZIVPN)),
    }

# ── HTML Template ────────────────────────────────────────────────────
BASE = r"""<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{{ title }} | VPS Panel</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{--bg:#0d1117;--surface:#161b22;--surface-2:#1c2128;--border:#30363d;--text:#e6edf3;--text-dim:#8b949e;--text-mute:#6e7681;--accent:#58a6ff;--green:#3fb950;--red:#f85149;--amber:#d29922;--purple:#a371f7}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Inter',-apple-system,'Segoe UI',sans-serif;background:var(--bg);color:#c9d1d9;min-height:100vh;display:flex;font-size:14px}
a{color:var(--accent);text-decoration:none}
::selection{background:#1f6feb55}
/* Sidebar */
.sidebar{width:240px;background:var(--surface);border-right:1px solid var(--border);display:flex;flex-direction:column;flex-shrink:0;position:fixed;height:100vh;overflow-y:auto;z-index:50;transition:transform .25s ease}
.sidebar-brand{padding:22px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:10px}
.brand-mark{width:34px;height:34px;border-radius:8px;background:linear-gradient(135deg,#1f6feb,#388bfd);display:flex;align-items:center;justify-content:center;flex-shrink:0}
.brand-mark svg{width:18px;height:18px;stroke:#fff}
.sidebar-brand h2{font-size:15px;color:var(--text);font-weight:700;letter-spacing:.2px}
.sidebar-brand small{color:var(--text-mute);font-size:11px;display:block;margin-top:1px}
.sidebar nav{padding:12px 10px}
.nav-section{font-size:10.5px;text-transform:uppercase;letter-spacing:.8px;color:var(--text-mute);padding:14px 10px 6px}
.sidebar nav a{display:flex;align-items:center;gap:11px;padding:9px 12px;color:var(--text-dim);font-size:13.5px;border-radius:6px;margin-bottom:2px;transition:.15s;font-weight:500}
.sidebar nav a svg{width:17px;height:17px;stroke:currentColor;flex-shrink:0}
.sidebar nav a:hover{color:var(--text);background:var(--surface-2)}
.sidebar nav a.active{color:#fff;background:#1f6feb;box-shadow:0 1px 2px rgba(0,0,0,.3)}
.sidebar-footer{margin-top:auto;padding:14px;border-top:1px solid var(--border)}
.user-card{display:flex;align-items:center;gap:10px;padding:8px;border-radius:8px}
.avatar{width:32px;height:32px;border-radius:50%;background:#21262d;border:1px solid var(--border);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;color:var(--accent);flex-shrink:0}
.user-info{flex:1;min-width:0}
.user-info .name{font-size:13px;color:var(--text);font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-info .role{font-size:11px;color:var(--text-mute)}
.logout-btn{width:30px;height:30px;border-radius:6px;display:flex;align-items:center;justify-content:center;color:var(--text-mute);border:1px solid transparent}
.logout-btn:hover{background:#3a1a1a;color:var(--red);border-color:#5a2323}
.logout-btn svg{width:15px;height:15px;stroke:currentColor}
/* Topbar */
.topbar{display:flex;align-items:center;justify-content:space-between;padding:0 0 18px}
.topbar-left{display:flex;align-items:center;gap:12px}
.menu-toggle{display:none;width:34px;height:34px;border-radius:6px;background:var(--surface);border:1px solid var(--border);align-items:center;justify-content:center;color:var(--text-dim);cursor:pointer}
.menu-toggle svg{width:17px;height:17px;stroke:currentColor}
.status-pill{display:inline-flex;align-items:center;gap:6px;padding:5px 10px;background:var(--surface);border:1px solid var(--border);border-radius:20px;font-size:12px;color:var(--text-dim)}
.status-pill .dot{width:7px;height:7px;border-radius:50%;background:var(--green);box-shadow:0 0 0 2px #3fb95022;animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
.clock{font-size:12px;color:var(--text-mute)}
.sidebar-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:40}
/* Main */
.main{margin-left:240px;flex:1;padding:22px 28px;min-height:100vh}
h1{font-size:19px;font-weight:700;color:var(--text);margin-bottom:20px;letter-spacing:.1px}
/* Cards */
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:14px;margin-bottom:22px}
.card{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;transition:.15s}
.card:hover{border-color:#3d4552}
.card-num{font-size:26px;font-weight:700;color:var(--text)}
.card-label{font-size:12.5px;color:var(--text-mute);margin-top:4px;font-weight:500}
.card-bar{height:4px;background:var(--surface-2);border-radius:2px;margin-top:10px;overflow:hidden}
.card-bar-fill{height:4px;background:var(--accent);border-radius:2px}
/* Table */
.tbl-wrap{background:var(--surface);border:1px solid var(--border);border-radius:10px;overflow-x:auto;margin-bottom:20px}
table{width:100%;border-collapse:collapse;font-size:13px}
th{background:var(--surface-2);padding:11px 14px;text-align:left;color:var(--text-dim);font-weight:600;font-size:11.5px;text-transform:uppercase;letter-spacing:.5px}
td{padding:10px 14px;border-bottom:1px solid var(--surface-2);color:#c9d1d9}
tr:last-child td{border-bottom:none}
tr:hover td{background:var(--surface-2)}
/* Badges */
.badge{display:inline-flex;align-items:center;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:600}
.badge-ok{background:#1a3a1a;color:var(--green)}
.badge-warn{background:#3a2a00;color:var(--amber)}
.badge-err{background:#3a1a1a;color:var(--red)}
.badge-lock{background:#2a1a3a;color:var(--purple)}
.badge-info{background:#102a3a;color:var(--accent)}
/* Buttons */
.btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border-radius:6px;font-size:13px;font-weight:600;cursor:pointer;border:none;transition:.15s}
.btn-primary{background:#238636;color:#fff}.btn-primary:hover{background:#2ea043}
.btn-danger{background:#b62324;color:#fff}.btn-danger:hover{background:#da3633}
.btn-warn{background:#9e6a03;color:#fff}.btn-warn:hover{background:#bb8009}
.btn-info{background:#1158c7;color:#fff}.btn-info:hover{background:#388bfd}
.btn-sm{padding:5px 11px;font-size:12px}
.btn-secondary{background:var(--surface-2);color:#c9d1d9;border:1px solid var(--border)}.btn-secondary:hover{background:#30363d}
/* Form */
.form-group{margin-bottom:14px}
.form-group label{display:block;font-size:12.5px;color:var(--text-dim);margin-bottom:6px;font-weight:500}
.form-group input,.form-group select{width:100%;padding:9px 12px;background:var(--bg);border:1px solid var(--border);border-radius:6px;color:#c9d1d9;font-size:14px;outline:none;font-family:inherit}
.form-group input:focus,.form-group select:focus{border-color:var(--accent);box-shadow:0 0 0 3px #1f6feb26}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px}
/* Alert */
.alert{padding:11px 14px;border-radius:8px;font-size:13.5px;margin-bottom:16px}
.alert-success{background:#1a3a1a;border:1px solid #238636;color:var(--green)}
.alert-error{background:#3a1a1a;border:1px solid #da3633;color:var(--red)}
.alert-warning{background:#3a2a00;border:1px solid #d29922;color:var(--amber)}
/* Modal */
.modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.7);z-index:100;align-items:center;justify-content:center}
.modal.show{display:flex}
.modal-box{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:24px;width:100%;max-width:460px;max-height:90vh;overflow-y:auto}
.modal-box h3{font-size:15px;color:var(--text);margin-bottom:18px;padding-bottom:12px;border-bottom:1px solid var(--border);font-weight:600}
.modal-close{float:right;cursor:pointer;color:var(--text-mute);width:26px;height:26px;display:flex;align-items:center;justify-content:center;border-radius:6px;font-size:14px}
.modal-close:hover{background:var(--surface-2);color:var(--text)}
/* Sysinfo grid */
.sys-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:24px}
.sys-item{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px}
.sys-item .label{font-size:11.5px;color:var(--text-mute);text-transform:uppercase;letter-spacing:.5px;font-weight:600}
.sys-item .value{font-size:14.5px;color:#c9d1d9;margin-top:5px;font-weight:600}
/* Toolbar */
.toolbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;flex-wrap:wrap;gap:10px}
.toolbar-left{display:flex;align-items:center;gap:10px}
/* Tabs */
.tabs{display:flex;gap:6px;margin-bottom:18px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.tab-btn{background:none;border:none;color:var(--text-dim);padding:9px 16px;font-size:13.5px;font-weight:600;cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-1px}
.tab-btn:hover{color:var(--text)}
.tab-btn.active{color:var(--accent);border-bottom-color:var(--accent)}
/* Copy */
.copy-wrap{display:flex;align-items:center;gap:6px}
.copy-btn{background:none;border:none;color:var(--accent);cursor:pointer;font-size:12px}
/* Toast */
.toast{position:fixed;bottom:20px;right:20px;background:var(--surface);border:1px solid var(--border);border-left:3px solid var(--green);color:var(--text);padding:11px 16px;border-radius:8px;font-size:13px;box-shadow:0 8px 24px rgba(0,0,0,.4);z-index:200;opacity:0;transform:translateY(8px);transition:.25s;pointer-events:none}
.toast.show{opacity:1;transform:translateY(0)}
/* Responsive */
@media(max-width:900px){
  .sidebar{transform:translateX(-100%)}
  .sidebar.open{transform:translateX(0)}
  .sidebar-overlay.show{display:block}
  .main{margin-left:0}
  .menu-toggle{display:flex}
  .form-row{grid-template-columns:1fr}
  .sys-grid{grid-template-columns:1fr}
  .clock{display:none}
}
@media(max-width:700px){
  .tbl-wrap{overflow-x:visible}
  table,thead,tbody,th,td,tr{display:block}
  thead{display:none}
  table{width:100%}
  tr{border:1px solid var(--border);border-radius:10px;margin:10px;padding:2px 0;background:var(--surface)}
  tr:hover td{background:transparent}
  td{border-bottom:1px solid var(--surface-2);padding:9px 14px;display:flex;justify-content:space-between;align-items:center;gap:10px;text-align:right;word-break:break-word}
  td:last-child{border-bottom:none;flex-wrap:wrap;justify-content:flex-start;gap:6px}
  td[data-th]::before{content:attr(data-th);font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.4px;color:var(--text-mute);text-align:left;flex-shrink:0}
  td[data-th="UUID/Password"]{flex-direction:column;align-items:flex-start;max-width:none!important}
  td[data-th="UUID/Password"] code{max-width:100%!important;width:100%;display:block;white-space:normal;line-height:1.5;text-align:left}
  td[data-th="Aksi"]::before{width:100%;margin-bottom:2px}
  .modal-box{max-width:94vw;padding:18px}
  .cards{grid-template-columns:repeat(auto-fill,minmax(140px,1fr))}
}
.text-muted{color:var(--text-mute);font-size:12px}
code{background:var(--surface-2);padding:2px 6px;border-radius:4px;font-size:12px;color:#c9d1d9}
/* Account Accordion List */
.acc-head{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:14px;flex-wrap:wrap;gap:10px}
.acc-head h1{margin-bottom:2px}
.acc-count{font-size:11px;color:var(--text-mute);font-family:monospace}
.acc-list{margin-bottom:20px}
.acc-item{background:var(--surface);border:1px solid var(--border);border-radius:11px;margin-bottom:8px;overflow:hidden;transition:border-color .15s}
.acc-item:hover{border-color:#3d4552}
.acc-item-head{display:flex;align-items:center;gap:10px;padding:11px 12px;cursor:pointer}
.acc-avatar{width:32px;height:32px;border-radius:8px;flex-shrink:0;background:#58a6ff1a;border:1px solid #58a6ff40;display:flex;align-items:center;justify-content:center;font-family:monospace;font-size:12px;font-weight:700;color:var(--accent)}
.acc-main{flex:1;min-width:0}
.acc-main .acc-name{font-size:13.5px;font-weight:600;color:var(--text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.acc-main .acc-sub{font-size:10.5px;color:var(--text-mute);font-family:monospace;margin-top:1px}
.acc-chev{width:15px;height:15px;stroke:var(--text-mute);flex-shrink:0;transition:transform .18s}
.acc-item.open .acc-chev{transform:rotate(180deg)}
.acc-detail{max-height:0;overflow:hidden;transition:max-height .25s ease}
.acc-item.open .acc-detail{max-height:600px}
.acc-detail-inner{padding:0 12px 12px}
.acc-divider{height:1px;background:var(--border);margin:0 0 10px}
.acc-cred{background:var(--surface-2);border:1px solid var(--border);border-radius:7px;padding:7px 9px;font-family:monospace;font-size:10.5px;color:var(--text-dim);display:flex;justify-content:space-between;align-items:center;gap:6px;margin-bottom:9px;overflow:hidden}
.acc-cred span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.acc-cred button{background:none;border:none;color:var(--accent);font-size:10px;cursor:pointer;flex-shrink:0;font-weight:600;font-family:inherit}
.acc-meta{display:flex;gap:14px;margin-bottom:11px;flex-wrap:wrap}
.acc-meta div{font-size:10.5px}
.acc-meta .k{color:var(--text-mute);margin-bottom:2px;text-transform:uppercase;letter-spacing:.4px}
.acc-meta .v{color:var(--text-dim);font-family:monospace}
.acc-actions{display:flex;gap:4px;flex-wrap:wrap}
.acc-act{flex:1;min-width:56px;display:flex;flex-direction:column;align-items:center;gap:3px;padding:7px 2px;border-radius:7px;background:transparent;border:1px solid var(--border);cursor:pointer;color:inherit;font-family:inherit}
.acc-act:hover{background:var(--surface-2)}
.acc-act svg{width:13px;height:13px;stroke:var(--text-dim)}
.acc-act span{font-size:8.5px;color:var(--text-dim);font-weight:600}
.acc-act.danger{border-color:#f8514933;background:#f8514910}
.acc-act.danger svg{stroke:var(--red)}
.acc-act.danger span{color:var(--red)}
.acc-act.lock{border-color:#d2992233;background:#d2992210}
.acc-act.lock svg{stroke:var(--amber)}
.acc-act.lock span{color:var(--amber)}
.acc-act.unlock{border-color:#3fb95033;background:#3fb95010}
.acc-act.unlock svg{stroke:var(--green)}
.acc-act.unlock span{color:var(--green)}
.acc-empty{text-align:center;color:var(--text-mute);padding:30px 20px;font-size:13px;background:var(--surface);border:1px solid var(--border);border-radius:10px;margin-bottom:20px}
@media(max-width:700px){
  .acc-meta{gap:10px}
}
</style>
</head>
<body>
<div class="sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar()"></div>
<aside class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <div class="brand-mark"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l8 4v6c0 5-3.5 9-8 10-4.5-1-8-5-8-10V6l8-4z"/></svg></div>
    <div><h2>VPS Panel</h2><small>{{ si.domain or 'Belum diatur' }}</small></div>
  </div>
  <nav>
    <div class="nav-section">Utama</div>
    <a href="/dashboard" class="{{ 'active' if active=='dashboard' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg> Dashboard</a>
    <div class="nav-section">Layanan</div>
    <a href="/ssh" class="{{ 'active' if active=='ssh' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg> SSH Account</a>
    <a href="/xray/vmess" class="{{ 'active' if active=='vmess' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg> Vmess</a>
    <a href="/xray/vless" class="{{ 'active' if active=='vless' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg> Vless</a>
    <a href="/xray/trojan" class="{{ 'active' if active=='trojan' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> Trojan</a>
    <a href="/zivpn" class="{{ 'active' if active=='zivpn' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg> ZIVPN UDP</a>
    <a href="/bandwidth" class="{{ 'active' if active=='bandwidth' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/></svg> Bandwidth</a>
    <div class="nav-section">Sistem</div>
    <a href="/bot" class="{{ 'active' if active=='bot' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg> Bot Notifikasi</a>
    <a href="/system" class="{{ 'active' if active=='system' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg> System</a>
    <a href="/settings" class="{{ 'active' if active=='settings' }}"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg> Pengaturan</a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-card">
      <div class="avatar">{{ session.user[0]|upper if session.user else 'A' }}</div>
      <div class="user-info"><div class="name">{{ session.user }}</div><div class="role">Administrator</div></div>
      <a href="/logout" class="logout-btn" title="Keluar"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg></a>
    </div>
  </div>
</aside>
<main class="main">
<div class="topbar">
  <div class="topbar-left">
    <div class="menu-toggle" onclick="toggleSidebar()"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg></div>
    <div class="status-pill"><span class="dot"></span> Server Online</div>
  </div>
  <div class="clock" id="clock"></div>
</div>
{% with msgs = get_flashed_messages(with_categories=true) %}
  {% for cat, msg in msgs %}
  <div class="alert alert-{{ 'success' if cat=='success' else 'error' if cat=='danger' else 'warning' }}">{{ msg }}</div>
  {% endfor %}
{% endwith %}
{{ content|safe }}
</main>
<div class="toast" id="toast"></div>
<script>
function openModal(id){document.getElementById(id).classList.add('show')}
function closeModal(id){document.getElementById(id).classList.remove('show')}
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('show')}
function showToast(msg){var t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');clearTimeout(window._tt);window._tt=setTimeout(function(){t.classList.remove('show')},2000)}
function copyText(t){navigator.clipboard.writeText(t).then(()=>showToast('Berhasil disalin')).catch(()=>showToast('Gagal menyalin'))}
window.onclick=function(e){if(e.target.classList.contains('modal'))e.target.classList.remove('show')}
function updateClock(){var d=new Date();var el=document.getElementById('clock');if(el){el.textContent=d.toLocaleDateString('id-ID',{weekday:'short',day:'numeric',month:'short'})+' \u2022 '+d.toLocaleTimeString('id-ID',{hour:'2-digit',minute:'2-digit'})}}
updateClock();setInterval(updateClock,30000);
</script>
</body></html>"""

LOGIN_HTML = """<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Login | VPS Panel</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--text:#e6edf3;--text-dim:#8b949e;--text-mute:#6e7681;--accent:#58a6ff}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Inter',-apple-system,'Segoe UI',sans-serif;background:radial-gradient(circle at 20% 20%,#111823 0%,#0d1117 55%);color:#c9d1d9;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
.wrap{display:flex;width:100%;max-width:820px;background:var(--surface);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 24px 60px rgba(0,0,0,.45)}
.side{flex:1;background:linear-gradient(160deg,#0f1f3d,#0d1117 75%);padding:44px 36px;display:flex;flex-direction:column;justify-content:space-between;position:relative;overflow:hidden;border-right:1px solid var(--border)}
.side::after{content:'';position:absolute;width:260px;height:260px;background:radial-gradient(circle,#1f6feb33,transparent 70%);top:-80px;right:-80px}
.side-mark{width:46px;height:46px;border-radius:12px;background:linear-gradient(135deg,#1f6feb,#388bfd);display:flex;align-items:center;justify-content:center;box-shadow:0 8px 20px #1f6feb44}
.side-mark svg{width:24px;height:24px;stroke:#fff}
.side h1{font-size:21px;color:#fff;margin-top:20px;font-weight:700;letter-spacing:.2px}
.side p{font-size:13.5px;color:#8b949e;margin-top:8px;line-height:1.6;max-width:260px}
.side-feat{margin-top:30px;display:flex;flex-direction:column;gap:12px}
.side-feat div{display:flex;align-items:center;gap:10px;font-size:12.5px;color:#8b949e}
.side-feat svg{width:15px;height:15px;stroke:#3fb950;flex-shrink:0}
.side-foot{font-size:11.5px;color:#4d5560;position:relative;z-index:1}
.panel{flex:1;padding:44px 40px;display:flex;flex-direction:column;justify-content:center;min-width:0}
.panel h2{font-size:20px;color:var(--text);margin-bottom:6px;font-weight:700}
.panel p.sub{color:var(--text-mute);font-size:13px;margin-bottom:26px}
label{display:block;font-size:12.5px;color:var(--text-dim);margin-bottom:7px;font-weight:600}
.field{position:relative;margin-bottom:16px}
.field svg.icon{position:absolute;left:12px;top:50%;transform:translateY(-50%);width:16px;height:16px;stroke:var(--text-mute)}
input{width:100%;padding:11px 12px 11px 38px;background:var(--bg);border:1px solid var(--border);border-radius:8px;color:#c9d1d9;font-size:14px;outline:none;font-family:inherit;transition:.15s}
input:focus{border-color:var(--accent);box-shadow:0 0 0 3px #1f6feb26}
.toggle-eye{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--text-mute);cursor:pointer;display:flex;padding:4px}
.toggle-eye svg{width:16px;height:16px;stroke:currentColor}
button.submit{width:100%;padding:11px;background:#1f6feb;color:#fff;border:none;border-radius:8px;font-size:14.5px;font-weight:700;cursor:pointer;margin-top:6px;transition:.15s;display:flex;align-items:center;justify-content:center;gap:8px}
button.submit:hover{background:#388bfd}
button.submit svg{width:15px;height:15px;stroke:currentColor}
.alert{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;background:#3a1a1a;border:1px solid #da3633;color:#f85149;display:flex;align-items:center;gap:8px}
.alert svg{width:15px;height:15px;stroke:currentColor;flex-shrink:0}
.ver{text-align:center;margin-top:20px;font-size:11.5px;color:var(--text-mute);display:flex;align-items:center;justify-content:center;gap:6px}
.ver svg{width:12px;height:12px;stroke:currentColor}
@media(max-width:640px){.side{display:none}.wrap{max-width:400px}}
</style>
</head>
<body>
<div class="wrap">
  <div class="side">
    <div>
      <div class="side-mark"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l8 4v6c0 5-3.5 9-8 10-4.5-1-8-5-8-10V6l8-4z"/></svg></div>
      <h1>VPS Management Panel</h1>
      <p>Kelola akun SSH, layanan Xray, dan seluruh infrastruktur server dari satu dasbor terpusat.</p>
      <div class="side-feat">
        <div><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Akses terenkripsi &amp; sesi aman</div>
        <div><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Monitoring server real-time</div>
        <div><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Proteksi percobaan login berulang</div>
      </div>
    </div>
    <div class="side-foot">&copy; {{ year }} VPS Panel &mdash; Seluruh hak dilindungi.</div>
  </div>
  <div class="panel">
    <h2>Masuk ke Panel</h2>
    <p class="sub">Silakan masuk menggunakan akun administrator Anda.</p>
    {% for cat, msg in msgs %}
    <div class="alert"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> {{ msg }}</div>
    {% endfor %}
    <form method="post" autocomplete="off">
      <label>Username</label>
      <div class="field">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
        <input type="text" name="username" autocomplete="off" required>
      </div>
      <label>Password</label>
      <div class="field">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
        <input type="password" name="password" id="pw" required>
        <button type="button" class="toggle-eye" onclick="var p=document.getElementById('pw');p.type=p.type==='password'?'text':'password'"><svg viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg></button>
      </div>
      <button type="submit" class="submit">Masuk<svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></button>
    </form>
    <div class="ver"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> Port {{ port }} &mdash; Koneksi Lokal Aman</div>
  </div>
</div>
</body></html>"""

def render(title, active, content_html, **kw):
    si = sys_info()
    return render_template_string(
        BASE, title=title, active=active,
        content=content_html, si=si, **kw)

# ── Routes Login ─────────────────────────────────────────────────────
@app.route('/')
def index():
    return redirect('/dashboard' if 'user' in session else '/login')

@app.route('/login', methods=['GET','POST'])
def login():
    msgs = []
    if request.method == 'POST':
        ip = request.remote_addr
        if not rate_ok(ip):
            msgs.append(('danger', 'Terlalu banyak percobaan. Coba lagi dalam 10 menit.'))
        else:
            u = request.form.get('username','').strip()
            p = request.form.get('password','')
            c = load_conf()
            if c and u == c['user'] and hash_pw(p, c['salt']) == c['hash']:
                clear_attempt(ip)
                session['user'] = u
                session['ts']   = time.time()
                return redirect('/dashboard')
            rec_attempt(ip)
            msgs.append(('danger', 'Username atau password salah.'))
    return render_template_string(LOGIN_HTML, msgs=msgs, port=PORT, year=datetime.now().year)

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

# ── Dashboard ─────────────────────────────────────────────────────────
@app.route('/dashboard')
@login_required
def dashboard():
    si = sys_info()
    try:
        ram_pct = int(int(si['ram_u']) / int(si['ram_t']) * 100)
    except: ram_pct = 0
    html = f"""
<h1>Dashboard</h1>
<div class="cards">
  <div class="card"><div class="card-num">{si['n_ssh']}</div><div class="card-label">Akun SSH</div></div>
  <div class="card"><div class="card-num">{si['n_vmess']}</div><div class="card-label">Akun Vmess</div></div>
  <div class="card"><div class="card-num">{si['n_vless']}</div><div class="card-label">Akun Vless</div></div>
  <div class="card"><div class="card-num">{si['n_trojan']}</div><div class="card-label">Akun Trojan</div></div>
  <div class="card"><div class="card-num">{si['n_zivpn']}</div><div class="card-label">Akun ZIVPN</div></div>
  <div class="card"><div class="card-num">{si['cpu']}%</div><div class="card-label">CPU Usage<br><div class="card-bar"><div class="card-bar-fill" style="width:{si['cpu']}%"></div></div></div></div>
  <div class="card"><div class="card-num">{si['ram_u']}M</div><div class="card-label">RAM ({ram_pct}%)<br><div class="card-bar"><div class="card-bar-fill" style="width:{ram_pct}%"></div></div></div></div>
</div>
<div class="sys-grid">
  <div class="sys-item"><div class="label">IP VPS</div><div class="value">{si['ip'] or '-'}</div></div>
  <div class="sys-item"><div class="label">Domain</div><div class="value">{si['domain'] or '-'}</div></div>
  <div class="sys-item"><div class="label">ISP</div><div class="value">{si['isp'] or '-'}</div></div>
  <div class="sys-item"><div class="label">Kota</div><div class="value">{si['city'] or '-'}</div></div>
  <div class="sys-item"><div class="label">Uptime</div><div class="value">{si['uptime'] or '-'}</div></div>
  <div class="sys-item"><div class="label">Disk /</div><div class="value">{si['disk'] or '-'}</div></div>
</div>
<div class="toolbar" style="margin-top:4px"><h3 style="font-size:15px;color:#e6edf3">Bandwidth Live</h3>
  <a href="/bandwidth" class="btn btn-sm btn-secondary">Lihat Detail &amp; Riwayat &rarr;</a>
</div>
<div class="cards">
  <div class="card"><div class="card-num" id="dashLiveRx">0 bps</div><div class="card-label">Download (Live)</div></div>
  <div class="card"><div class="card-num" id="dashLiveTx">0 bps</div><div class="card-label">Upload (Live)</div></div>
</div>
<script>
function _dashPollLive(){{
  fetch('/api/net_live').then(function(r){{return r.json()}}).then(function(d){{
    var a=document.getElementById('dashLiveRx'), b=document.getElementById('dashLiveTx');
    if(a) a.textContent = d.rx_human;
    if(b) b.textContent = d.tx_human;
  }}).catch(function(){{}});
}}
_dashPollLive();
var _dashBwTimer = setInterval(_dashPollLive, 2000);
window.addEventListener('beforeunload', function(){{ clearInterval(_dashBwTimer); }});
</script>"""
    return render('Dashboard', 'dashboard', html)

# ── SSH ───────────────────────────────────────────────────────────────
@app.route('/ssh')
@login_required
def ssh_page():
    accs = read_ssh()
    cards = ''
    modals = ''
    for a in accs:
        det_id = f'detail_ssh_{a["user"]}'
        sub = f'Limit {a["limit"]} IP · ' + ('Terkunci' if a['locked'] else 'Aktif')
        meta = [
            acc_meta('EXPIRED', a['exp']),
            acc_meta('SISA', a['exp_txt'], EXP_COLOR.get(a['exp_st'], '')),
        ]
        actions = (
            acc_act_detail(det_id) +
            acc_act_renew(f'renew_{a["user"]}') +
            acc_act_lock('/ssh/unlock' if a['locked'] else '/ssh/lock', 'user', a['user'], a['locked']) +
            acc_act_delete('/ssh/delete', 'user', a['user'], f"Hapus akun {a['user']}?")
        )
        cards += acc_card(a['user'], sub, 'Password', a['pass'], meta, actions)
        modals += detail_modal(det_id, f"Detail Akun SSH: {a['user']}", detail_ssh(a['user'], a['pass'], a['exp'], a['limit']))
        modals += f"""<div class="modal" id="renew_{a['user']}">
    <div class="modal-box">
      <span class="modal-close" onclick="closeModal('renew_{a['user']}')">x</span>
      <h3>Renew SSH: {a['user']}</h3>
      <form method="post" action="/ssh/renew">
        <input type="hidden" name="user" value="{a['user']}">
        <div class="form-group"><label>Tambah Hari</label><input type="number" name="days" value="30" min="1" max="365"></div>
        <button class="btn btn-primary" type="submit">Renew</button>
      </form>
    </div>
  </div>"""
    html = f"""
<div class="acc-head">
  <div><h1>Manajemen SSH</h1><div class="acc-count">{len(accs)} akun aktif</div></div>
  <button class="btn btn-primary" onclick="openModal('m_ssh_create')">+ Buat Akun</button>
</div>
<div class="acc-list">{cards or '<div class="acc-empty">Belum ada akun SSH</div>'}</div>
{modals}
<div class="modal" id="m_ssh_create">
  <div class="modal-box">
    <span class="modal-close" onclick="closeModal('m_ssh_create')">x</span>
    <h3>Buat Akun SSH Baru</h3>
    <form method="post" action="/ssh/create">
      <div class="form-row">
        <div class="form-group"><label>Username</label><input type="text" name="user" required pattern="[a-z0-9._-]{{3,32}}" minlength="3" maxlength="32" title="Huruf kecil, angka, titik, garis bawah, strip" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
        <div class="form-group"><label>Password</label><input type="text" name="pass" required pattern="[a-z0-9._-]{{6,64}}" minlength="6" maxlength="64" title="Huruf kecil, angka, titik, garis bawah, strip" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>Durasi (hari)</label><input type="number" name="days" value="30" min="1"></div>
        <div class="form-group"><label>Limit IP (0=bebas)</label><input type="number" name="limit" value="1" min="0"></div>
      </div>
      <button class="btn btn-primary" type="submit">Buat Akun</button>
    </form>
  </div>
</div>"""
    return render('SSH Account', 'ssh', html)

@app.route('/ssh/create', methods=['POST'])
@login_required
def ssh_create():
    u = clean_id(request.form.get('user',''))
    p = clean_id(request.form.get('pass',''), maxlen=64)
    d = request.form.get('days','30').strip()
    lim = request.form.get('limit','1').strip()
    if not u or len(u) < 3:
        flash('Username tidak valid. Hanya huruf kecil, angka, titik, garis bawah, dan strip (min 3 karakter).', 'danger'); return redirect('/ssh')
    if not p or len(p) < 6:
        flash('Password tidak valid. Hanya huruf kecil, angka, titik, garis bawah, dan strip (min 6 karakter).', 'danger'); return redirect('/ssh')
    if id_exists_in_files(u, DATA_SSH, DATA_VMESS, DATA_VLESS, DATA_TROJAN) or linux_user_exists(u):
        flash(f'Username {u} sudah terdaftar.', 'danger'); return redirect('/ssh')
    exp = run(f"date -d '+{d} days' +'%Y-%m-%d'")[0]
    run("grep -q '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells")
    run(f"useradd -e {exp} -s /bin/false -M {shlex.quote(u)}")
    run(f"echo {shlex.quote(u + ':' + p)} | chpasswd")
    with open(DATA_SSH, 'a') as f: f.write(f'{u}|{p}|{exp}|{lim}|ACTIVE\n')
    send_telegram(detail_ssh(u, p, exp, lim, html=True))
    flash(f'Akun SSH {u} berhasil dibuat. Expired: {exp}', 'success')
    return redirect('/ssh')

@app.route('/ssh/delete', methods=['POST'])
@login_required
def ssh_delete():
    u = request.form.get('user','').strip()
    run(f"userdel -f {u} 2>/dev/null")
    lines = [l for l in rlines(DATA_SSH) if not l.startswith(f'{u}|')]
    wlines(DATA_SSH, lines)
    flash(f'Akun SSH {u} dihapus.', 'success')
    return redirect('/ssh')

@app.route('/ssh/renew', methods=['POST'])
@login_required
def ssh_renew():
    u = request.form.get('user','').strip()
    d = request.form.get('days','30').strip()
    lines = rlines(DATA_SSH)
    new_lines = []
    for l in lines:
        p = l.split('|')
        if p[0] == u:
            exp_old = p[2]
            new_exp = run(f"date -d '{exp_old} + {d} days' +'%Y-%m-%d'")[0]
            run(f"chage -E {new_exp} {u} 2>/dev/null")
            p[2] = new_exp; l = '|'.join(p)
        new_lines.append(l)
    wlines(DATA_SSH, new_lines)
    flash(f'Akun SSH {u} diperbarui.', 'success')
    return redirect('/ssh')

@app.route('/ssh/lock', methods=['POST'])
@login_required
def ssh_lock():
    u = request.form.get('user','').strip()
    run(f"usermod -L {u}")
    lines = rlines(DATA_SSH)
    new_lines = []
    now = int(time.time())
    for l in lines:
        p = l.split('|')
        if p[0] == u and len(p) >= 5: p[4] = f'LOCKED_IP_{now}'; l = '|'.join(p)
        new_lines.append(l)
    wlines(DATA_SSH, new_lines)
    flash(f'Akun SSH {u} dikunci.', 'success')
    return redirect('/ssh')

@app.route('/ssh/unlock', methods=['POST'])
@login_required
def ssh_unlock():
    u = request.form.get('user','').strip()
    run(f"usermod -U {u}")
    lines = rlines(DATA_SSH)
    new_lines = []
    for l in lines:
        p = l.split('|')
        if p[0] == u and len(p) >= 5: p[4] = 'ACTIVE'; l = '|'.join(p)
        new_lines.append(l)
    wlines(DATA_SSH, new_lines)
    flash(f'Akun SSH {u} dibuka kuncinya.', 'success')
    return redirect('/ssh')

# ── Xray (Vmess/Vless/Trojan) ─────────────────────────────────────────
@app.route('/xray/<proto>')
@login_required
def xray_page(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    accs = read_xray(proto)
    fp   = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    cred_label = 'Password' if proto == 'trojan' else 'UUID'
    cards = ''
    modals = ''
    for a in accs:
        det_id = f'detail_{proto}_{a["user"]}'
        q_display = f'{a["usage"]}/{a["quota"]}GB' if a['quota'] != '0' else 'Unlimited'
        sub = f'Limit {a["limit"]} IP · {q_display}'
        meta = [
            acc_meta('EXPIRED', a['exp']),
            acc_meta('SISA', a['exp_txt'], EXP_COLOR.get(a['exp_st'], '')),
        ]
        actions = (
            acc_act_detail(det_id) +
            acc_act_renew(f'renew_{proto}_{a["user"]}') +
            acc_act_lock(f'/xray/{proto}/unlock' if a['locked'] else f'/xray/{proto}/lock', 'user', a['user'], a['locked']) +
            acc_act_delete(f'/xray/{proto}/delete', 'user', a['user'], f"Hapus akun {a['user']}?")
        )
        cards += acc_card(a['user'], sub, cred_label, a['id'], meta, actions)
        modals += detail_modal(det_id, f"Detail Akun {proto.upper()}: {a['user']}", detail_xray(proto, a['user'], a['id'], a['exp'], a['limit'], a['quota'], a['usage']))
        modals += f"""<div class="modal" id="renew_{proto}_{a['user']}">
    <div class="modal-box">
      <span class="modal-close" onclick="closeModal('renew_{proto}_{a['user']}')">x</span>
      <h3>Renew {proto.upper()}: {a['user']}</h3>
      <form method="post" action="/xray/{proto}/renew">
        <input type="hidden" name="user" value="{a['user']}">
        <div class="form-group"><label>Tambah Hari</label><input type="number" name="days" value="30" min="1"></div>
        <button class="btn btn-primary" type="submit">Renew</button>
      </form>
    </div>
  </div>"""
    proto_label = proto.upper()
    html = f"""
<div class="acc-head">
  <div><h1>Manajemen {proto_label}</h1><div class="acc-count">{len(accs)} akun aktif</div></div>
  <button class="btn btn-primary" onclick="openModal('m_{proto}_create')">+ Buat Akun</button>
</div>
<div class="acc-list">{cards or f'<div class="acc-empty">Belum ada akun {proto_label}</div>'}</div>
{modals}
<div class="modal" id="m_{proto}_create">
  <div class="modal-box">
    <span class="modal-close" onclick="closeModal('m_{proto}_create')">x</span>
    <h3>Buat Akun {proto_label} Baru</h3>
    <form method="post" action="/xray/{proto}/create">
      <div class="form-group"><label>Username</label><input type="text" name="user" required pattern="[a-z0-9._-]{{3,32}}" minlength="3" maxlength="32" title="Huruf kecil, angka, titik, garis bawah, strip" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
      <div class="form-group"><label>{'Password' if proto=='trojan' else 'UUID (kosongkan = auto)'}</label><input type="text" name="uuid" placeholder="{'auto' if proto!='trojan' else 'isi password'}" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
      <div class="form-row">
        <div class="form-group"><label>Durasi (hari)</label><input type="number" name="days" value="30" min="1"></div>
        <div class="form-group"><label>Limit IP</label><input type="number" name="limit" value="1" min="0"></div>
      </div>
      <div class="form-group"><label>Quota (GB, 0=unlimited)</label><input type="number" name="quota" value="0" min="0"></div>
      <button class="btn btn-primary" type="submit">Buat Akun</button>
    </form>
  </div>
</div>"""
    return render(proto_label, proto, html)

@app.route('/xray/<proto>/create', methods=['POST'])
@login_required
def xray_create(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    fp  = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    u   = clean_id(request.form.get('user',''))
    raw_uid = request.form.get('uuid','').strip()
    uid = clean_id(raw_uid, maxlen=64) if proto == 'trojan' and raw_uid else (raw_uid or run('uuidgen')[0])
    d   = request.form.get('days','30').strip()
    lim = request.form.get('limit','1').strip()
    qta = request.form.get('quota','0').strip()
    if not u or len(u) < 3:
        flash('Username tidak valid. Hanya huruf kecil, angka, titik, garis bawah, dan strip (min 3 karakter).','danger'); return redirect(f'/xray/{proto}')
    if proto == 'trojan' and not uid:
        flash('Password tidak valid.','danger'); return redirect(f'/xray/{proto}')
    if id_exists_in_files(u, DATA_SSH, DATA_VMESS, DATA_VLESS, DATA_TROJAN) or linux_user_exists(u):
        flash(f'Username {u} sudah terdaftar.','danger'); return redirect(f'/xray/{proto}')
    exp = run(f"date -d '+{d} days' +'%Y-%m-%d'")[0]
    def do_create():
        cfg = json.load(open(XRAY_CFG))
        for ib in cfg.get('inbounds',[]):
            if ib.get('protocol') == proto:
                if proto == 'trojan':
                    ib['settings']['clients'].append({'password':uid,'email':u,'level':0})
                else:
                    ib['settings']['clients'].append({'id':uid,'email':u,'level':0})
        json.dump(cfg, open(XRAY_CFG,'w'), indent=2)
        os.chmod(XRAY_CFG, 0o644)
    try: xray_lock(do_create)
    except: flash('Gagal update config Xray.','danger'); return redirect(f'/xray/{proto}')
    with open(fp,'a') as f: f.write(f'{u}|{uid}|{exp}|{lim}|ACTIVE|{qta}\n')
    os.makedirs(QUOTA_DIR, exist_ok=True)
    open(os.path.join(QUOTA_DIR,u),'w').write('0 0')
    run('systemctl restart xray')
    send_telegram(detail_xray(proto, u, uid, exp, lim, qta, '0.00', html=True))
    flash(f'Akun {proto.upper()} {u} berhasil dibuat.','success')
    return redirect(f'/xray/{proto}')

@app.route('/xray/<proto>/delete', methods=['POST'])
@login_required
def xray_delete(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    fp = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    u  = request.form.get('user','').strip()
    def do_del():
        cfg = json.load(open(XRAY_CFG))
        for ib in cfg.get('inbounds',[]):
            if ib.get('protocol') == proto:
                ib['settings']['clients'] = [c for c in ib['settings']['clients']
                    if c.get('email') != u]
        json.dump(cfg, open(XRAY_CFG,'w'), indent=2)
        os.chmod(XRAY_CFG, 0o644)
    try: xray_lock(do_del)
    except: flash('Gagal update config Xray.','danger'); return redirect(f'/xray/{proto}')
    wlines(fp, [l for l in rlines(fp) if not l.startswith(f'{u}|')])
    run(f'rm -f {QUOTA_DIR}/{u}')
    run('systemctl restart xray')
    flash(f'Akun {proto.upper()} {u} dihapus.','success')
    return redirect(f'/xray/{proto}')

@app.route('/xray/<proto>/renew', methods=['POST'])
@login_required
def xray_renew(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    fp = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    u  = request.form.get('user','').strip()
    d  = request.form.get('days','30').strip()
    lines = rlines(fp); new_lines = []
    for l in lines:
        p = l.split('|')
        if p[0] == u:
            exp_old = p[2]
            p[2] = run(f"date -d '{exp_old} + {d} days' +'%Y-%m-%d'")[0]
            l = '|'.join(p)
        new_lines.append(l)
    wlines(fp, new_lines)
    flash(f'Akun {proto.upper()} {u} diperpanjang.','success')
    return redirect(f'/xray/{proto}')

@app.route('/xray/<proto>/lock', methods=['POST'])
@login_required
def xray_lock_user(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    fp = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    u  = request.form.get('user','').strip()
    def do_lock():
        cfg = json.load(open(XRAY_CFG))
        for ib in cfg.get('inbounds',[]):
            if ib.get('protocol') == proto:
                ib['settings']['clients'] = [c for c in ib['settings']['clients'] if c.get('email') != u]
        json.dump(cfg, open(XRAY_CFG,'w'), indent=2); os.chmod(XRAY_CFG, 0o644)
    try: xray_lock(do_lock)
    except: pass
    lines = rlines(fp); now = int(time.time()); new_lines = []
    for l in lines:
        p = l.split('|')
        if p[0] == u and len(p) >= 5: p[4] = f'LOCKED_IP_{now}'; l = '|'.join(p)
        new_lines.append(l)
    wlines(fp, new_lines)
    run('systemctl restart xray')
    flash(f'Akun {proto.upper()} {u} dikunci.','success')
    return redirect(f'/xray/{proto}')

@app.route('/xray/<proto>/unlock', methods=['POST'])
@login_required
def xray_unlock_user(proto):
    if proto not in ('vmess','vless','trojan'): return redirect('/dashboard')
    fp  = {'vmess':DATA_VMESS,'vless':DATA_VLESS,'trojan':DATA_TROJAN}[proto]
    u   = request.form.get('user','').strip()
    lines = rlines(fp); new_lines = []
    uid = ''
    for l in lines:
        p = l.split('|')
        if p[0] == u:
            uid = p[1] if len(p) > 1 else ''
            if len(p) >= 5: p[4] = 'ACTIVE'; l = '|'.join(p)
        new_lines.append(l)
    wlines(fp, new_lines)
    def do_unlock():
        cfg = json.load(open(XRAY_CFG))
        for ib in cfg.get('inbounds',[]):
            if ib.get('protocol') == proto:
                emails = [c.get('email') for c in ib['settings']['clients']]
                if u not in emails:
                    if proto == 'trojan':
                        ib['settings']['clients'].append({'password':uid,'email':u,'level':0})
                    else:
                        ib['settings']['clients'].append({'id':uid,'email':u,'level':0})
        json.dump(cfg, open(XRAY_CFG,'w'), indent=2); os.chmod(XRAY_CFG, 0o644)
    try: xray_lock(do_unlock)
    except: pass
    run('systemctl restart xray')
    flash(f'Akun {proto.upper()} {u} dibuka kuncinya.','success')
    return redirect(f'/xray/{proto}')

# ── ZIVPN ─────────────────────────────────────────────────────────────
@app.route('/zivpn')
@login_required
def zivpn_page():
    accs = read_zivpn()
    cards = ''
    modals = ''
    for i, a in enumerate(accs):
        det_id = f'detail_z_{i}'
        sub = f'#{i+1} · UDP'
        meta = [
            acc_meta('EXPIRED', a['exp']),
            acc_meta('SISA', a['exp_txt'], EXP_COLOR.get(a['exp_st'], '')),
        ]
        actions = (
            acc_act_detail(det_id) +
            acc_act_renew(f'renew_z_{i}') +
            acc_act_delete('/zivpn/delete', 'idx', i, "Hapus akun ini?")
        )
        cards += acc_card(a['user'], sub, 'Password', a['pass'], meta, actions)
        modals += detail_modal(det_id, f"Detail Akun ZIVPN: {a['user']}", detail_zivpn(a['pass'], a['exp']))
        modals += f"""<div class="modal" id="renew_z_{i}">
    <div class="modal-box">
      <span class="modal-close" onclick="closeModal('renew_z_{i}')">x</span>
      <h3>Renew ZIVPN: {a['user']}</h3>
      <form method="post" action="/zivpn/renew">
        <input type="hidden" name="idx" value="{i}">
        <div class="form-group"><label>Tambah Hari</label><input type="number" name="days" value="30" min="1"></div>
        <button class="btn btn-primary" type="submit">Renew</button>
      </form>
    </div>
  </div>"""
    html = f"""
<div class="acc-head">
  <div><h1>Manajemen ZIVPN UDP</h1><div class="acc-count">{len(accs)} akun aktif</div></div>
  <button class="btn btn-primary" onclick="openModal('m_z_create')">+ Buat Akun</button>
</div>
<div class="acc-list">{cards or '<div class="acc-empty">Belum ada akun ZIVPN</div>'}</div>
{modals}
<div class="modal" id="m_z_create">
  <div class="modal-box">
    <span class="modal-close" onclick="closeModal('m_z_create')">x</span>
    <h3>Buat Akun ZIVPN Baru</h3>
    <form method="post" action="/zivpn/create">
      <div class="form-row">
        <div class="form-group"><label>Username</label><input type="text" name="user" required pattern="[a-z0-9._-]{{3,32}}" minlength="3" maxlength="32" title="Huruf kecil, angka, titik, garis bawah, strip" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
        <div class="form-group"><label>Password</label><input type="text" name="pass" required pattern="[a-z0-9._-]{{6,64}}" minlength="6" maxlength="64" title="Huruf kecil, angka, titik, garis bawah, strip" oninput="this.value=this.value.toLowerCase().replace(/[^a-z0-9._-]/g,'')"></div>
      </div>
      <div class="form-group"><label>Durasi (hari)</label><input type="number" name="days" value="30" min="1"></div>
      <button class="btn btn-primary" type="submit">Buat Akun</button>
    </form>
  </div>
</div>"""
    return render('ZIVPN UDP', 'zivpn', html)

@app.route('/zivpn/create', methods=['POST'])
@login_required
def zivpn_create():
    u = clean_id(request.form.get('user',''))
    p = clean_id(request.form.get('pass',''), maxlen=64)
    d = request.form.get('days','30').strip()
    if not u or len(u) < 3 or not p or len(p) < 6:
        flash('Username/password tidak valid. Hanya huruf kecil, angka, titik, garis bawah, dan strip (username min 3, password min 6 karakter).','danger'); return redirect('/zivpn')
    exp = run(f"date -d '+{d} days' +'%Y-%m-%d'")[0]
    cfg = json.load(open('/etc/zivpn/config.json'))
    if p in cfg.get('auth',{}).get('config',[]): flash(f'Password sudah digunakan.','danger'); return redirect('/zivpn')
    cfg['auth']['config'].append(p)
    json.dump(cfg, open('/etc/zivpn/config.json','w'), indent=2)
    with open(DATA_ZIVPN,'a') as f: f.write(f'{u}|{p}|{exp}\n')
    run('systemctl restart zivpn')
    send_telegram(detail_zivpn(p, exp, html=True))
    flash(f'Akun ZIVPN {u} berhasil dibuat.','success')
    return redirect('/zivpn')

@app.route('/zivpn/delete', methods=['POST'])
@login_required
def zivpn_delete():
    idx = int(request.form.get('idx','-1'))
    lines = rlines(DATA_ZIVPN)
    if 0 <= idx < len(lines):
        p = lines[idx].split('|'); pw = p[1] if len(p) >= 3 else p[0]
        cfg = json.load(open('/etc/zivpn/config.json'))
        cfg['auth']['config'] = [x for x in cfg['auth']['config'] if x != pw]
        json.dump(cfg, open('/etc/zivpn/config.json','w'), indent=2)
        lines.pop(idx); wlines(DATA_ZIVPN, lines)
    run('systemctl restart zivpn')
    flash('Akun ZIVPN dihapus.','success')
    return redirect('/zivpn')

@app.route('/zivpn/renew', methods=['POST'])
@login_required
def zivpn_renew():
    idx  = int(request.form.get('idx','-1'))
    days = request.form.get('days','30').strip()
    lines = rlines(DATA_ZIVPN)
    if 0 <= idx < len(lines):
        p = lines[idx].split('|')
        exp_old = p[-1]
        new_exp = run(f"date -d '{exp_old} + {days} days' +'%Y-%m-%d'")[0]
        p[-1] = new_exp; lines[idx] = '|'.join(p)
        wlines(DATA_ZIVPN, lines)
    flash('Akun ZIVPN diperpanjang.','success')
    return redirect('/zivpn')

# ── Bot Notifikasi ────────────────────────────────────────────────────
@app.route('/bot')
@login_required
def bot_page():
    token = rd(BOT_TOKEN)
    chatid = rd(BOT_CHATID)
    log_st = rd(LOG_STAT) or 'OFF'
    bak_st = rd(BAK_STAT) or 'OFF'
    import re as re3
    _lm = re3.search(r'\(([^)]+)\)', log_st)
    log_val = _lm.group(1) if _lm else '10m'
    _bm = re3.search(r'\(([^)]+)\)', bak_st)
    bak_val = _bm.group(1) if _bm else '12h'
    html = f"""
<h1>Pengaturan Bot Notifikasi</h1>
<div class="sys-grid">
  <div class="sys-item"><div class="label">Status Notif Login</div>
    <div class="value"><span class="badge {'badge-ok' if 'ON' in log_st else 'badge-err'}">{log_st}</span></div></div>
  <div class="sys-item"><div class="label">Status Notif Backup</div>
    <div class="value"><span class="badge {'badge-ok' if 'ON' in bak_st else 'badge-err'}">{bak_st}</span></div></div>
</div>
<div class="tbl-wrap" style="padding:20px">
  <form method="post" action="/bot/save">
    <div class="form-group"><label>Bot Token API</label>
      <input type="text" name="token" value="{token}" placeholder="12345678:AABBcc..."></div>
    <div class="form-group"><label>Chat ID</label>
      <input type="text" name="chatid" value="{chatid}" placeholder="-100xxxxxxxxx"></div>
    <button class="btn btn-primary" type="submit">Simpan Token &amp; Chat ID</button>
  </form>
</div>
<div class="tbl-wrap" style="padding:20px;margin-top:16px">
  <h3 style="margin-bottom:16px;font-size:15px;color:#e6edf3">Jadwal Notifikasi Login Aktif</h3>
  <form method="post" action="/bot/notif">
    <input type="hidden" name="type" value="login">
    <div class="form-row">
      <div class="form-group"><label>Interval</label>
        <input type="text" name="dur" value="{log_val}" placeholder="contoh: 10m, 1h, 2h"></div>
      <div class="form-group" style="align-self:flex-end">
        <button class="btn btn-primary" type="submit" name="action" value="set">Set Jadwal Login</button>
        <button class="btn btn-danger" type="submit" name="action" value="off">Matikan</button>
      </div>
    </div>
  </form>
  <h3 style="margin:20px 0 16px;font-size:15px;color:#e6edf3">Jadwal Backup Otomatis</h3>
  <form method="post" action="/bot/notif">
    <input type="hidden" name="type" value="backup">
    <div class="form-row">
      <div class="form-group"><label>Interval</label>
        <input type="text" name="dur" value="{bak_val}" placeholder="contoh: 30m, 6h, 12h"></div>
      <div class="form-group" style="align-self:flex-end">
        <button class="btn btn-primary" type="submit" name="action" value="set">Set Jadwal Backup</button>
        <button class="btn btn-danger" type="submit" name="action" value="off">Matikan</button>
      </div>
    </div>
  </form>
</div>"""
    return render('Bot Notifikasi', 'bot', html)

@app.route('/bot/save', methods=['POST'])
@login_required
def bot_save():
    token  = request.form.get('token','').strip()
    chatid = request.form.get('chatid','').strip()
    if token:  open(BOT_TOKEN,'w').write(token)
    if chatid: open(BOT_CHATID,'w').write(chatid)
    flash('Token dan Chat ID berhasil disimpan.','success')
    return redirect('/bot')

@app.route('/bot/notif', methods=['POST'])
@login_required
def bot_notif():
    ntype  = request.form.get('type','login')
    action = request.form.get('action','set').strip()
    dur    = request.form.get('dur','').strip()
    script  = 'bot-login-notif' if ntype == 'login' else 'bot-backup'
    stat_f  = LOG_STAT if ntype == 'login' else BAK_STAT
    if action == 'off':
        open(stat_f,'w').write('OFF')
        run(f"crontab -l | grep -v '{script}' > /tmp/c.tmp; crontab /tmp/c.tmp")
        flash(f'Notifikasi {ntype} dimatikan.','success')
    else:
        import re as re2
        m = re2.match(r'^(\d+)(m|h)$', dur)
        if not m: flash('Format durasi tidak valid. Contoh: 10m, 1h, 6h','danger'); return redirect('/bot')
        n, unit = m.group(1), m.group(2)
        cron = f'*/{n} * * * *' if unit == 'm' else f'0 */{n} * * *'
        open(stat_f,'w').write(f'ON ({dur})')
        run(f"crontab -l | grep -v '{script}' > /tmp/c.tmp; echo '{cron} /usr/local/bin/{script}' >> /tmp/c.tmp; crontab /tmp/c.tmp")
        flash(f'Notifikasi {ntype} diset setiap {dur}.','success')
    return redirect('/bot')

# ── Bandwidth Monitoring ────────────────────────────────────────────
@app.route('/bandwidth')
@login_required
def bandwidth_page():
    iface = get_default_iface()
    five    = vnstat_series('f', iface, 12)   # last ~1 hour
    daily   = vnstat_series('d', iface, 30)   # last 30 days
    monthly = vnstat_series('m', iface, 12)   # last 12 months
    today_rx = today_tx = 0
    if daily:
        today_rx, today_tx = daily[-1]['rx'], daily[-1]['tx']
    month_rx = month_tx = 0
    if monthly:
        month_rx, month_tx = monthly[-1]['rx'], monthly[-1]['tx']
    html = f"""
<h1>Monitoring Bandwidth</h1>
<div class="toolbar"><div class="toolbar-left"><span class="text-muted">Interface: <code>{iface}</code></span></div></div>
<div class="tabs">
  <button class="tab-btn active" onclick="showTab('bw_live', this)">Live</button>
  <button class="tab-btn" onclick="showTab('bw_5m', this)">5 Menit</button>
  <button class="tab-btn" onclick="showTab('bw_day', this)">Harian</button>
  <button class="tab-btn" onclick="showTab('bw_month', this)">Bulanan</button>
</div>

<div class="tab-pane" id="bw_live">
  <div class="cards">
    <div class="card"><div class="card-num" id="liveRx">0 bps</div><div class="card-label">Download (Live)</div></div>
    <div class="card"><div class="card-num" id="liveTx">0 bps</div><div class="card-label">Upload (Live)</div></div>
    <div class="card"><div class="card-num">{human_bytes(today_rx + today_tx)}</div><div class="card-label">Total Hari Ini</div></div>
    <div class="card"><div class="card-num">{human_bytes(month_rx + month_tx)}</div><div class="card-label">Total Bulan Ini</div></div>
  </div>
  <div class="text-muted" style="margin-top:-8px;margin-bottom:16px">Kecepatan diperbarui otomatis setiap 2 detik.</div>
</div>

<div class="tab-pane" id="bw_5m" style="display:none">
  <div class="tbl-wrap"><table>
  <thead><tr><th>Waktu</th><th>Download</th><th>Upload</th><th>Total</th></tr></thead>
  <tbody>{bandwidth_rows_html(five)}</tbody>
  </table></div>
</div>

<div class="tab-pane" id="bw_day" style="display:none">
  <div class="tbl-wrap"><table>
  <thead><tr><th>Tanggal</th><th>Download</th><th>Upload</th><th>Total</th></tr></thead>
  <tbody>{bandwidth_rows_html(daily)}</tbody>
  </table></div>
</div>

<div class="tab-pane" id="bw_month" style="display:none">
  <div class="tbl-wrap"><table>
  <thead><tr><th>Bulan</th><th>Download</th><th>Upload</th><th>Total</th></tr></thead>
  <tbody>{bandwidth_rows_html(monthly)}</tbody>
  </table></div>
</div>
<script>
function showTab(id, btn){{
  document.querySelectorAll('.tab-pane').forEach(function(el){{el.style.display='none'}});
  document.getElementById(id).style.display='block';
  document.querySelectorAll('.tab-btn').forEach(function(el){{el.classList.remove('active')}});
  btn.classList.add('active');
}}
var _bwTimer = null;
function pollLive(){{
  fetch('/api/net_live').then(function(r){{return r.json()}}).then(function(d){{
    document.getElementById('liveRx').textContent = d.rx_human;
    document.getElementById('liveTx').textContent = d.tx_human;
  }}).catch(function(){{}});
}}
pollLive();
_bwTimer = setInterval(pollLive, 2000);
window.addEventListener('beforeunload', function(){{ if(_bwTimer) clearInterval(_bwTimer); }});
</script>"""
    return render('Bandwidth', 'bandwidth', html)

@app.route('/api/net_live')
@login_required
def api_net_live():
    iface = get_default_iface()
    rx_bps, tx_bps = get_live_rate(iface)
    return jsonify({
        'rx_bps': rx_bps, 'tx_bps': tx_bps,
        'rx_human': human_bps(rx_bps), 'tx_human': human_bps(tx_bps),
    })

# ── System ────────────────────────────────────────────────────────────
@app.route('/system')
@login_required
def system_page():
    log, _ = run("tail -n 40 /var/log/ws-proxy.log 2>/dev/null")
    log = log.replace('<','&lt;').replace('>','&gt;') if log else '(log kosong)'
    html = f"""
<h1>System</h1>
<div class="toolbar" style="margin-bottom:20px">
  <div style="display:flex;gap:10px;flex-wrap:wrap">
    <form method="post" action="/system/restart"><input type="hidden" name="svc" value="all">
      <button class="btn btn-warn">Restart Semua Service</button></form>
    <form method="post" action="/system/restart"><input type="hidden" name="svc" value="xray">
      <button class="btn btn-secondary">Restart Xray</button></form>
    <form method="post" action="/system/restart"><input type="hidden" name="svc" value="ws-proxy">
      <button class="btn btn-secondary">Restart WS-Proxy</button></form>
    <form method="post" action="/system/restart"><input type="hidden" name="svc" value="zivpn">
      <button class="btn btn-secondary">Restart ZIVPN</button></form>
    <form method="post" action="/system/clear_cache">
      <button class="btn btn-secondary">Bersihkan Cache RAM</button></form>
  </div>
</div>
<div class="tbl-wrap" style="padding:16px">
  <h3 style="font-size:14px;color:#8b949e;margin-bottom:12px">LOG WS-PROXY (40 baris terakhir)</h3>
  <pre style="font-size:12px;color:#c9d1d9;overflow-x:auto;white-space:pre-wrap">{log}</pre>
</div>"""
    return render('System', 'system', html)

@app.route('/system/restart', methods=['POST'])
@login_required
def system_restart():
    svc = request.form.get('svc','all')
    if svc == 'all':
        run('systemctl restart xray zivpn dropbear ws-proxy stunnel4 vnstat 2>/dev/null')
        flash('Semua service berhasil di-restart.','success')
    else:
        run(f'systemctl restart {svc}')
        flash(f'Service {svc} berhasil di-restart.','success')
    return redirect('/system')

@app.route('/system/clear_cache', methods=['POST'])
@login_required
def clear_cache():
    run('sync; echo 3 > /proc/sys/vm/drop_caches')
    flash('Cache RAM berhasil dibersihkan.','success')
    return redirect('/system')

# ── Pengaturan ────────────────────────────────────────────────────────
@app.route('/settings')
@login_required
def settings_page():
    c = load_conf()
    ip = rd(IP_FILE)
    # Baca domain panel jika sudah dikonfigurasi via CLI
    dom_lines = []
    try:
        with open('/etc/tendo_bot/panel_domain') as f:
            dom_lines = [l.strip() for l in f if l.strip()]
    except: pass
    panel_dom  = dom_lines[0] if len(dom_lines) > 0 else ''
    panel_prot = dom_lines[1] if len(dom_lines) > 1 else 'http'
    port_suffix= dom_lines[2] if len(dom_lines) > 2 else ''
    if panel_dom:
        url_main   = f'{panel_prot}://{panel_dom}{port_suffix}'
        url_backup = f'http://{ip}:{c["port"]}'
        if panel_prot == 'https' and port_suffix == '':
            ssl_badge = '<span class="badge badge-ok">HTTPS Aktif</span>'
        elif panel_prot == 'https':
            ssl_badge = f'<span class="badge badge-ok">HTTPS (port {port_suffix.strip(":")})</span>'
        else:
            ssl_badge = '<span class="badge badge-warn">HTTP</span>'
    else:
        url_main   = f'http://{ip}:{c["port"]}'
        url_backup = ''
        ssl_badge  = '<span class="badge badge-err">Domain belum diatur</span>'
    dom_row = f'<tr><td style="color:#6e7681">Domain</td><td><code>{panel_dom}</code> {ssl_badge}</td></tr>' if panel_dom else \
              f'<tr><td style="color:#6e7681">Domain</td><td>{ssl_badge} <span class="text-muted">Gunakan CLI: menu &gt; [6] Web Panel &gt; [2] Setup Domain</span></td></tr>'
    bak_row = f'<tr><td style="color:#6e7681">URL Cadangan</td><td><code>{url_backup}</code></td></tr>' if url_backup else ''
    html = f"""
<h1>Pengaturan Panel</h1>
<div class="tbl-wrap" style="padding:20px;max-width:460px">
  <h3 style="font-size:15px;color:#e6edf3;margin-bottom:16px">Ganti Password Admin</h3>
  <form method="post" action="/settings/password">
    <div class="form-group"><label>Password Lama</label><input type="password" name="old_pw" required></div>
    <div class="form-group"><label>Password Baru</label><input type="password" name="new_pw" required minlength="6"></div>
    <div class="form-group"><label>Konfirmasi Password Baru</label><input type="password" name="confirm_pw" required></div>
    <button class="btn btn-primary" type="submit">Simpan Password</button>
  </form>
</div>
<div class="tbl-wrap" style="padding:20px;max-width:560px;margin-top:16px">
  <h3 style="font-size:15px;color:#e6edf3;margin-bottom:12px">Informasi Panel</h3>
  <table>
  <tr><td style="color:#6e7681;width:140px">Username</td><td>{c['user']}</td></tr>
  <tr><td style="color:#6e7681">Port Internal</td><td>{c['port']}</td></tr>
  <tr><td style="color:#6e7681">Sesi Aktif</td><td>{SESSION_HOURS} jam</td></tr>
  <tr><td style="color:#6e7681">URL Utama</td><td><code>{url_main}</code></td></tr>
  {bak_row}
  {dom_row}
  </table>
</div>
<div class="tbl-wrap" style="padding:16px;max-width:560px;margin-top:16px">
  <p style="color:#8b949e;font-size:13px">
    Untuk mengubah domain akses, gunakan CLI di server:<br>
    <code>menu</code> &rarr; <code>[6] Web Panel</code> &rarr; <code>[2] Setup / Ganti Domain Akses</code>
  </p>
</div>"""
    return render('Pengaturan', 'settings', html)

@app.route('/settings/password', methods=['POST'])
@login_required
def settings_password():
    old = request.form.get('old_pw','')
    new = request.form.get('new_pw','')
    cnf = request.form.get('confirm_pw','')
    c = load_conf()
    if hash_pw(old, c['salt']) != c['hash']:
        flash('Password lama salah.','danger'); return redirect('/settings')
    if new != cnf:
        flash('Password baru tidak cocok.','danger'); return redirect('/settings')
    if len(new) < 6:
        flash('Password minimal 6 karakter.','danger'); return redirect('/settings')
    new_salt = secrets.token_hex(8)
    new_hash = hash_pw(new, new_salt)
    with open(PANEL_CONF,'w') as f:
        f.write(f"{c['user']}:{new_salt}:{new_hash}:{c['port']}:{c['secret']}")
    flash('Password berhasil diubah. Silakan login ulang.','success')
    session.clear()
    return redirect('/login')

# ── Run ───────────────────────────────────────────────────────────────
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=False)
XPANELEOF

chmod +x /usr/local/bin/xpanel.py

cat > /etc/systemd/system/xpanel.service << 'EOF'
[Unit]
Description=VPS Web Admin Panel
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/xpanel.py
Restart=always
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xpanel >/dev/null 2>&1

)
print_ok "Web Panel Admin"

# --- 11. MENU SCRIPT ---
print_msg "Finalisasi Menu"
(
cat > /usr/bin/menu <<'END_MENU'
#!/bin/bash
CYAN='\033[0;36m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'
CONFIG="/usr/local/etc/xray/config.json"
D_SSH="/usr/local/etc/xray/ssh.txt"
D_VMESS="/usr/local/etc/xray/vmess.txt"
D_VLESS="/usr/local/etc/xray/vless.txt"
D_TROJAN="/usr/local/etc/xray/trojan.txt"
D_ZIVPN="/etc/zivpn/zivpn.txt"

# ---------------------------------------------
# FUNGSI HELPER UI
# ---------------------------------------------
print_line() {
    local text="$1"
    local clean_text=$(echo -e "$text" | sed -r 's/\x1b\[[0-9;]*m//g' | sed -r 's/\x1b\[[0-9;]*K//g')
    local len=${#clean_text}
    local spaces=$(( 54 - len ))
    local pad=""
    if (( spaces > 0 )); then pad=$(printf '%*s' "$spaces" ""); fi
    echo -e "${CYAN}│${NC}${text}${pad}${CYAN}│${NC}"
}

print_line_open() {
    local text="$1"
    echo -e "${CYAN}│${NC}${text}"
}

print_center() {
    local text="$1"
    local clean_text=$(echo -e "$text" | sed -r 's/\x1b\[[0-9;]*m//g' | sed -r 's/\x1b\[[0-9;]*K//g')
    local len=${#clean_text}
    local spaces=$(( 54 - len ))
    local pad_l=$(( spaces / 2 ))
    local pad_r=$(( spaces - pad_l ))
    local str_l=$(printf '%*s' "$pad_l" "")
    local str_r=$(printf '%*s' "$pad_r" "")
    echo -e "${CYAN}│${NC}${str_l}${text}${str_r}${CYAN}│${NC}"
}

function check_exists() {
    local user=$1
    if grep -q "^$user|" $D_SSH $D_VMESS $D_VLESS $D_TROJAN $D_ZIVPN 2>/dev/null; then
        echo -e "${RED}Username '$user' sudah terdaftar! Silakan gunakan username lain.${NC}"
        sleep 2
        return 1
    fi
    if id "$user" &>/dev/null; then
        echo -e "${RED}Username '$user' sudah ada di sistem Linux! Silakan gunakan username lain.${NC}"
        sleep 2
        return 1
    fi
    return 0
}

function check_uuid() {
    local uuid=$1
    if grep -q "|$uuid|" $D_VMESS $D_VLESS $D_TROJAN 2>/dev/null; then
        echo -e "${RED}Password/UUID '$uuid' sudah digunakan! Silakan gunakan yang lain.${NC}"
        sleep 2
        return 1
    fi
    return 0
}

function send_tele() {
    local bot_tok=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
    local chat_id=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
    [[ -z "$bot_tok" || -z "$chat_id" ]] && return
    
    local msg=$(echo -e "$1")
    local full_msg="<b>[OK] NEW ACCOUNT CREATED</b>"$'\n\n'"$msg"
    
    curl -s -X POST "https://api.telegram.org/bot${bot_tok}/sendMessage" \
        -d "chat_id=${chat_id}" \
        --data-urlencode "text=${full_msg}" \
        -d "parse_mode=HTML" > /dev/null &
}

function show_account_ssh() {
    systemctl restart dropbear >/dev/null 2>&1 &
    clear
    local user=$1; local pass=$2; local domain=$3; local exp=$4; local limit=$5
    local isp=$(cat /root/tendo/isp); local city=$(cat /root/tendo/city)
    
    local MSG=""
    MSG+="------------------------------------\n          ACCOUNT SSH / WS\n------------------------------------\n"
    MSG+="Username       : ${user}\nPassword       : ${pass}\nCITY           : ${city}\nISP            : ${isp}\nDomain         : ${domain}\n"
    MSG+="Port TLS       : 443, 8443\nPort none TLS  : 80, 8080\nPort any       : 2082, 2083, 8880\n"
    MSG+="Port OpenSSH   : 22, 444\nPort Dropbear  : 90\nPort UDPGW     : 7100-7600\n"
    MSG+="Limit IP       : ${limit} IP\n"
    MSG+="Payload WS     : GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]\n"
    MSG+="Expired On     : ${exp}\n------------------------------------\n"

    local MSG_BOT=""
    MSG_BOT+="<b>------------------------------------</b>\n          <b>ACCOUNT SSH / WS</b>\n<b>------------------------------------</b>\n"
    MSG_BOT+="Username       : <code>${user}</code>\nPassword       : <code>${pass}</code>\nCITY           : ${city}\nISP            : ${isp}\nDomain         : <code>${domain}</code>\n"
    MSG_BOT+="Port TLS       : 443, 8443\nPort none TLS  : 80, 8080\nPort any       : 2082, 2083, 8880\n"
    MSG_BOT+="Port OpenSSH   : 22, 444\nPort Dropbear  : 90\nPort UDPGW     : 7100-7600\n"
    MSG_BOT+="Limit IP       : ${limit} IP\n"
    MSG_BOT+="Payload WS     : <code>GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]</code>\n"
    MSG_BOT+="Expired On     : ${exp}\n<b>------------------------------------</b>\n"

    echo -e "$MSG"
    send_tele "$MSG_BOT"
    echo ""
    read -n 1 -s -r -p "Tekan enter untuk kembali..."
}

function show_account_xray() {
    systemctl restart xray >/dev/null 2>&1 &
    clear
    local proto=$1; local user=$2; local domain=$3; local uuid=$4; local exp=$5; local limit=$6; local quota=$7; local usage=$8
    local link_ws_tls=$9; local link_ws_ntls=${10}; local link_grpc_tls=${11}; local link_upg_tls=${12}; local link_upg_ntls=${13}
    local isp=$(cat /root/tendo/isp); local city=$(cat /root/tendo/city)
    [[ "$quota" == "0" ]] && str_quota="Unlimited" || str_quota="${quota} GB"

    local MSG=""
    local MSG_BOT=""
    
    if [[ "$proto" == "VMESS" ]]; then
        MSG+="------------------------------------\n               VMESS\n------------------------------------\n"
        MSG+="Username       : ${user}\nPassword / ID  : ${uuid}\nCITY           : ${city}\nISP            : ${isp}\nDomain         : ${domain}\n"
        MSG+="Port TLS       : 443\nPort none TLS  : 80\nalterId        : 0\n"
        MSG+="Security       : auto\nnetwork        : ws, grpc, upgrade\npath ws        : /vmess\n"
        MSG+="serviceName    : vmess-grpc\npath upgrade   : /vmess-upg\nLimit IP       : ${limit} IP\n"
        MSG+="Quota Bandwidth: ${str_quota}\nUsage Bandwidth: ${usage} GB\nExpired On     : ${exp}\n"
        MSG+="------------------------------------\n           VMESS WS TLS\n------------------------------------\n${link_ws_tls}\n"
        MSG+="------------------------------------\n          VMESS WS NO TLS\n------------------------------------\n${link_ws_ntls}\n"
        MSG+="------------------------------------\n             VMESS GRPC\n------------------------------------\n${link_grpc_tls}\n"
        MSG+="------------------------------------\n         VMESS Upgrade TLS\n------------------------------------\n${link_upg_tls}\n"
        MSG+="------------------------------------\n        VMESS Upgrade NO TLS\n------------------------------------\n${link_upg_ntls}\n------------------------------------\n"
    elif [[ "$proto" == "VLESS" ]]; then
        MSG+="------------------------------------\n               VLESS\n------------------------------------\n"
        MSG+="Username       : ${user}\nPassword / ID  : ${uuid}\nCITY           : ${city}\nISP            : ${isp}\nDomain         : ${domain}\n"
        MSG+="Port TLS       : 443\nPort none TLS  : 80\nEncryption     : none\n"
        MSG+="Network        : ws, grpc, upgrade\nPath ws        : /vless\nserviceName    : vless-grpc\n"
        MSG+="Path upgrade   : /vless-upg\nLimit IP       : ${limit} IP\nQuota Bandwidth: ${str_quota}\n"
        MSG+="Usage Bandwidth: ${usage} GB\nExpired On     : ${exp}\n"
        MSG+="------------------------------------\n            VLESS WS TLS\n------------------------------------\n${link_ws_tls}\n"
        MSG+="------------------------------------\n          VLESS WS NO TLS\n------------------------------------\n${link_ws_ntls}\n"
        MSG+="------------------------------------\n             VLESS GRPC\n------------------------------------\n${link_grpc_tls}\n"
        MSG+="------------------------------------\n          VLESS Upgrade TLS\n------------------------------------\n${link_upg_tls}\n"
        MSG+="------------------------------------\n        VLESS Upgrade NO TLS\n------------------------------------\n${link_upg_ntls}\n------------------------------------\n"
    elif [[ "$proto" == "TROJAN" ]]; then
        MSG+="------------------------------------\n               TROJAN\n------------------------------------\n"
        MSG+="Username     : ${user}\nPassword     : ${uuid}\nCITY         : ${city}\nISP          : ${isp}\nDomain       : ${domain}\n"
        MSG+="Port         : 443\nNetwork      : ws, grpc, upgrade\n"
        MSG+="Path ws      : /trojan\nserviceName  : trojan-grpc\nPath upgrade : /trojan-upg\n"
        MSG+="Limit IP     : ${limit} IP\nQuota Limit  : ${str_quota}\nUsage Traffic: ${usage} GB\nExpired On   : ${exp}\n"
        MSG+="------------------------------------\n           TROJAN WS TLS\n------------------------------------\n${link_ws_tls}\n"
        MSG+="------------------------------------\n            TROJAN GRPC\n------------------------------------\n${link_grpc_tls}\n"
        MSG+="------------------------------------\n         TROJAN Upgrade TLS\n------------------------------------\n${link_upg_tls}\n"
        MSG+="----------\n--------------------------\n"
    fi

    MSG_BOT+="<b>------------------------------------</b>\n               <b>${proto}</b>\n<b>------------------------------------</b>\n"
    MSG_BOT+="Username       : <code>${user}</code>\nCITY           : ${city}\nISP            : ${isp}\nDomain         : <code>${domain}</code>\n"
    MSG_BOT+="Port TLS       : 443\nPort none TLS  : 80\n"
    if [[ "$proto" == "TROJAN" ]]; then MSG_BOT+="Password       : <code>${uuid}</code>\n"; else MSG_BOT+="Password / ID  : <code>${uuid}</code>\n"; fi
    if [[ "$proto" == "VMESS" ]]; then MSG_BOT+="alterId        : 0\nSecurity       : auto\n"; elif [[ "$proto" == "VLESS" ]]; then MSG_BOT+="Encryption     : none\n"; fi
    MSG_BOT+="network        : ws, grpc, upgrade\npath ws        : /${proto,,}\nserviceName    : ${proto,,}-grpc\npath upgrade   : /${proto,,}-upg\n"
    MSG_BOT+="Limit IP       : ${limit} IP\nQuota Bandwidth: ${str_quota}\nUsage Bandwidth: ${usage} GB\nExpired On     : ${exp}\n"
    MSG_BOT+="<b>------------------------------------</b>\n           <b>${proto} WS TLS</b>\n<b>------------------------------------</b>\n"
    MSG_BOT+="<code>${link_ws_tls}</code>\n<b>------------------------------------</b>\n"
    if [[ -n "$link_ws_ntls" ]]; then
        MSG_BOT+="          <b>${proto} WS NO TLS</b>\n<b>------------------------------------</b>\n<code>${link_ws_ntls}</code>\n<b>------------------------------------</b>\n"
    fi
    MSG_BOT+="             <b>${proto} GRPC</b>\n<b>------------------------------------</b>\n<code>${link_grpc_tls}</code>\n<b>------------------------------------</b>\n"
    MSG_BOT+="         <b>${proto} Upgrade TLS</b>\n<b>------------------------------------</b>\n<code>${link_upg_tls}</code>\n<b>------------------------------------</b>\n"
    if [[ -n "$link_upg_ntls" ]]; then
        MSG_BOT+="        <b>${proto} Upgrade NO TLS</b>\n<b>------------------------------------</b>\n<code>${link_upg_ntls}</code>\n<b>------------------------------------</b>\n"
    fi

    echo -e "$MSG"
    send_tele "$MSG_BOT"
    echo ""
    read -n 1 -s -r -p "Tekan enter untuk kembali..."
}

function show_account_zivpn() {
    systemctl restart zivpn >/dev/null 2>&1 &
    clear
    local user=$1; local pass=$2; local domain=$3; local exp=$4
    local isp=$(cat /root/tendo/isp); local city=$(cat /root/tendo/city); local ip=$(cat /root/tendo/ip)

    local MSG=""
    MSG+="-----------------------------------------\n  ACCOUNT ZIVPN UDP\n-----------------------------------------\n"
    MSG+="Password   : ${pass}\nCITY       : ${city}\nISP        : ${isp}\nIP ISP     : ${ip}\nDomain     : ${domain}\nExpired On : ${exp}\n-----------------------------------------\n"
    
    local MSG_BOT=""
    MSG_BOT+="<b>-----------------------------------------</b>\n  <b>ACCOUNT ZIVPN UDP</b>\n<b>-----------------------------------------</b>\n"
    MSG_BOT+="Password   : <code>${pass}</code>\nCITY       : ${city}\nISP        : ${isp}\nIP ISP     : <code>${ip}</code>\nDomain     : <code>${domain}</code>\nExpired On : ${exp}\n<b>-----------------------------------------</b>\n"

    echo -e "$MSG"
    send_tele "$MSG_BOT"
    echo ""
    read -n 1 -s -r -p "Tekan enter untuk kembali..."
}

function header_main() {
    clear; DOMAIN=$(cat /usr/local/etc/xray/domain); OS=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/PRETTY_NAME="//g' | sed 's/"//g')
    RAM=$(free -m | awk '/Mem:/ {print $2}'); SWAP=$(free -m | awk '/Swap:/ {print $2}'); IP=$(cat /root/tendo/ip)
    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    CITY=$(cat /root/tendo/city)
    ISP=$(cat /root/tendo/isp)
    UPTIME=$(uptime -p | sed 's/up //')
    
    MONTH_NAME=$(date +%B)
    DAY_NAME=$(date +%A)
    RX_DAY=$(vnstat -d -i $IFACE --oneline | awk -F';' '{print $4}' 2>/dev/null || echo "0 B")
    TX_DAY=$(vnstat -d -i $IFACE --oneline | awk -F';' '{print $5}' 2>/dev/null || echo "0 B")
    TOT_DAY=$(vnstat -d -i $IFACE --oneline | awk -F';' '{print $6}' 2>/dev/null || echo "0 B")
    RX_MON=$(vnstat -m -i $IFACE --oneline | awk -F';' '{print $9}' 2>/dev/null || echo "0 B")
    TX_MON=$(vnstat -m -i $IFACE --oneline | awk -F';' '{print $10}' 2>/dev/null || echo "0 B")
    TOT_MON=$(vnstat -m -i $IFACE --oneline | awk -F';' '{print $11}' 2>/dev/null || echo "0 B")
    
    R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes); T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes); sleep 0.4
    R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes); T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    TRAFFIC=$(echo "scale=2; (($R2 - $R1) + ($T2 - $T1)) * 8 / 409.6 / 1024" | bc)
    
    ACC_SSH=$(wc -l < "$D_SSH" 2>/dev/null || echo 0)
    ACC_VMESS=$(wc -l < "$D_VMESS" 2>/dev/null || echo 0)
    ACC_VLESS=$(wc -l < "$D_VLESS" 2>/dev/null || echo 0)
    ACC_TROJAN=$(wc -l < "$D_TROJAN" 2>/dev/null || echo 0)
    ACC_ZIVPN=$(wc -l < "$D_ZIVPN" 2>/dev/null || echo 0)

    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_center "${YELLOW}AUTO SCRIPT TENDO STORE ( AIO )${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_line_open "  OS      : ${WHITE}${OS}${NC}"
    print_line_open "  RAM     : ${WHITE}${RAM}MB${NC}"
    print_line_open "  SWAP    : ${WHITE}${SWAP}MB${NC}"
    print_line_open "  CITY    : ${WHITE}${CITY}${NC}"
    print_line_open "  ISP     : ${WHITE}${ISP}${NC}"
    print_line_open "  IP      : ${WHITE}${IP}${NC}"
    print_line_open "  DOMAIN  : ${YELLOW}${DOMAIN}${NC}"
    print_line_open "  UPTIME  : ${WHITE}${UPTIME}${NC}"
    print_line_open "  ----------------------------"
    print_line_open "  MONTH   : ${TOT_MON}    [${MONTH_NAME}]"
    print_line_open "  RX      : ${RX_MON}"
    print_line_open "  TX      : ${TX_MON}"
    print_line_open "  ----------------------------"
    print_line_open "  DAY     : ${TOT_DAY}    [${DAY_NAME}]"
    print_line_open "  RX      : ${RX_DAY}"
    print_line_open "  TX      : ${TX_DAY}"
    print_line_open "  TRAFFIC : ${TRAFFIC} Mbit/s"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    
    if systemctl is-active --quiet xray; then X_ST="${GREEN}ON${NC}"; else X_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet zivpn; then Z_ST="${GREEN}ON${NC}"; else Z_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet dropbear; then D_ST="${GREEN}ON${NC}"; else D_ST="${RED}OFF${NC}"; fi
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_line "  STATUS  : XRAY: ${X_ST} | SSH/WS: ${D_ST} | ZIVPN: ${Z_ST}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_center "${YELLOW}LIST USER${NC}"
    print_center "----------------------------"
    
    local acc_all=$((ACC_SSH + ACC_VMESS + ACC_VLESS + ACC_TROJAN + ACC_ZIVPN))
    
    local f_ssh=$(printf "%-2s" "$ACC_SSH")
    local f_vm=$(printf "%-2s" "$ACC_VMESS")
    local f_vl=$(printf "%-2s" "$ACC_VLESS")
    local f_tr=$(printf "%-2s" "$ACC_TROJAN")
    local f_zi=$(printf "%-2s" "$ACC_ZIVPN")
    local f_all=$(printf "%-2s" "$acc_all")
    
    local STR1="SSH/WS : ${WHITE}${f_ssh}${NC} USR   |   VMESS : ${WHITE}${f_vm}${NC} USR"
    local STR2="VLESS  : ${WHITE}${f_vl}${NC} USR   |   TROJAN: ${WHITE}${f_tr}${NC} USR"
    local STR3="ZIVPN  : ${WHITE}${f_zi}${NC} USR   |   ALL   : ${WHITE}${f_all}${NC} USR"
    
    print_center "$STR1"
    print_center "$STR2"
    print_center "$STR3"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    
    echo -e "        ${CYAN}┌──────────────────────────────────────┐${NC}"
    echo -e "                Version   :  ${WHITE}v01.03.26${NC}         "
    echo -e "                Owner     :  ${WHITE}Tendo Store${NC}       "
    echo -e "                Telegram  :  ${WHITE}@tendo_32${NC}         "
    echo -e "                Expiry In :  ${WHITE}Lifetime${NC}          "
    echo -e "        ${CYAN}└──────────────────────────────────────┘${NC}"
}

function header_sub() {
    clear; echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_center "${YELLOW}TENDO STORE - SUB MENU${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
}

# ---------------------------------------------
# MENU TELEGRAM BOT SETUP (Notifikasi & Backup)
# ---------------------------------------------
function menu_login_notif() {
    while true; do header_sub
        local st=$(cat /etc/tendo_bot/log_stat 2>/dev/null || echo "OFF")
        print_line " ----------------------------------------"
        print_line "        Status [${st}]"
        print_line "  [1]  OFF"
        print_line "  [2]  Set Time Notif (h) jam (m) menit"
        print_line "  [x]  Exit"
        print_line " ----------------------------------------"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Pilihan: " opt2
        case $opt2 in
            1) echo "OFF" > /etc/tendo_bot/log_stat; crontab -l | grep -v "bot-login-notif" > /tmp/c.tmp; crontab /tmp/c.tmp; echo -e "${GREEN}Turned OFF${NC}"; sleep 1;;
            2) read -p " Durasi (e.g., 10m, 1h): " dur; 
               if [[ "$dur" =~ ^[0-9]+m$ ]]; then n=${dur%m}; [[ "$n" -lt 1 || "$n" -gt 59 ]] && { echo "Menit harus 1-59"; sleep 1; continue; }; c="*/${n} * * * *";
               elif [[ "$dur" =~ ^[0-9]+h$ ]]; then n=${dur%h}; [[ "$n" -lt 1 || "$n" -gt 23 ]] && { echo "Jam harus 1-23"; sleep 1; continue; }; c="0 */${n} * * *";
               else echo "Invalid"; sleep 1; continue; fi
               echo "ON (${dur})" > /etc/tendo_bot/log_stat
               crontab -l | grep -v "bot-login-notif" > /tmp/c.tmp; echo "$c /usr/local/bin/bot-login-notif" >> /tmp/c.tmp; crontab /tmp/c.tmp
               echo -e "${GREEN}Cron set to $dur${NC}"; sleep 1;;
            x) return;;
        esac
    done
}

function menu_backup_notif() {
    while true; do header_sub
        local st=$(cat /etc/tendo_bot/bak_stat 2>/dev/null || echo "OFF")
        print_line " ----------------------------------------"
        print_line "        Status [${st}]"
        print_line "  [1]  OFF"
        print_line "  [2]  Set Time Backup (h) jam (m) menit"
        print_line "  [x]  Exit"
        print_line " ----------------------------------------"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Pilihan: " opt3
        case $opt3 in
            1) echo "OFF" > /etc/tendo_bot/bak_stat; crontab -l | grep -v "bot-backup" > /tmp/c.tmp; crontab /tmp/c.tmp; echo -e "${GREEN}Turned OFF${NC}"; sleep 1;;
            2) read -p " Durasi (e.g., 10m, 12h): " dur; 
               if [[ "$dur" =~ ^[0-9]+m$ ]]; then n=${dur%m}; [[ "$n" -lt 1 || "$n" -gt 59 ]] && { echo "Menit harus 1-59"; sleep 1; continue; }; c="*/${n} * * * *";
               elif [[ "$dur" =~ ^[0-9]+h$ ]]; then n=${dur%h}; [[ "$n" -lt 1 || "$n" -gt 23 ]] && { echo "Jam harus 1-23"; sleep 1; continue; }; c="0 */${n} * * *";
               else echo "Invalid"; sleep 1; continue; fi
               echo "ON (${dur})" > /etc/tendo_bot/bak_stat
               crontab -l | grep -v "bot-backup" > /tmp/c.tmp; echo "$c /usr/local/bin/bot-backup" >> /tmp/c.tmp; crontab /tmp/c.tmp
               echo -e "${GREEN}Cron set to $dur${NC}"; sleep 1;;
            x) return;;
        esac
    done
}

function bot_menu() {
    while true; do header_sub
        local st_log=$(cat /etc/tendo_bot/log_stat 2>/dev/null || echo "OFF")
        local st_bak=$(cat /etc/tendo_bot/bak_stat 2>/dev/null || echo "OFF")
        
        local cur_tok=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
        [[ -z "$cur_tok" ]] && cur_tok="Not setup" || cur_tok=$(echo "$cur_tok" | sed 's/.\{10\}$/**********/')
        local cur_id=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
        [[ -z "$cur_id" ]] && cur_id="Not setup"

        print_line " Bot Token :"
        print_line " ${GREEN}${cur_tok}${NC}"
        print_line " Chat ID   :"
        print_line " ${GREEN}${cur_id}${NC}"
        print_line " Notif Log : ${YELLOW}${st_log}${NC}"
        print_line " Notif Bak : ${YELLOW}${st_bak}${NC}"
        print_line " ----------------------------------------"
        print_line " [1] Change BOT API & CHATID"
        print_line " [2] Set notifikasi User login"
        print_line " [3] Set notifikasi backup"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Bot Token: " bt; read -p " Chat ID: " ci; echo "$bt" > /etc/tendo_bot/bot_token; echo "$ci" > /etc/tendo_bot/chat_id; echo -e "${GREEN}Saved Successfully!${NC}"; sleep 1;;
            2) menu_login_notif ;;
            3) menu_backup_notif ;;
            x) return;;
        esac
    done
}

# ---------------------------------------------
# MENU SSH & X-RAY MANAGER
# ---------------------------------------------
function ssh_menu() {
    while true; do header_sub
        print_line " [1] Create Account SSH"
        print_line " [2] Delete Account SSH"
        print_line " [3] Renew Account SSH"
        print_line " [4] Check Config User"
        print_line " [5] Trial Account SSH"
        print_line " [6] Lock Account SSH"
        print_line " [7] Unlock Account SSH"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Username : " u; [[ -z "$u" ]] && continue
               if ! check_exists "$u"; then continue; fi
               read -p " Password : " p; read -p " Expired (days): " ex; [[ -z "$ex" ]] && ex=30; read -p " Limit IP (0 for unlimited): " limit; [[ -z "$limit" ]] && limit=0
               exp_date=$(date -d "+$ex days" +"%Y-%m-%d")
               grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells; useradd -e $(date -d "$ex days" +"%Y-%m-%d") -s /bin/false -M $u; echo "$u:$p" | chpasswd; echo "$u|$p|$exp_date|$limit|ACTIVE" >> $D_SSH; DMN=$(cat /usr/local/etc/xray/domain); show_account_ssh "$u" "$p" "$DMN" "$exp_date" "$limit";;
            2) nl $D_SSH; read -p "No: " n; [[ -z "$n" ]] && continue; u=$(sed -n "${n}p" $D_SSH | cut -d'|' -f1); sed -i "${n}d" $D_SSH; userdel -f $u 2>/dev/null; echo -e "${GREEN}Account SSH Deleted!${NC}"; sleep 2;;
            3) nl $D_SSH; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_SSH); u=$(echo "$line" | cut -d'|' -f1); p=$(echo "$line" | cut -d'|' -f2); exp_old=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); read -p " Add Days: " add_days; exp_new=$(date -d "$exp_old + $add_days days" +"%Y-%m-%d"); sed -i "${n}s/.*/$u|$p|$exp_new|$limit|$stat/" $D_SSH; chage -E $(date -d "$exp_new" +"%Y-%m-%d") $u 2>/dev/null; echo -e "${GREEN}Account $u Renewed until $exp_new!${NC}"; sleep 2;;
            4) nl $D_SSH; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_SSH); u=$(echo "$line" | cut -d'|' -f1); p=$(echo "$line" | cut -d'|' -f2); exp_date=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); DMN=$(cat /usr/local/etc/xray/domain); show_account_ssh "$u" "$p" "$DMN" "$exp_date" "$limit";;
            5) u="trial-$(tr -dc a-z0-9 </dev/urandom | head -c 5)"; echo -e " Username (Trial): ${GREEN}$u${NC}"; p="$u"; read -p " Duration (e.g., 10m, 1h): " dur;
               if [[ "$dur" == *m ]]; then add_str="+${dur%m} minutes"; elif [[ "$dur" == *h ]]; then add_str="+${dur%h} hours"; else add_str="+1 hours"; fi
               exp_date=$(date -d "$add_str" +"%Y-%m-%d %H:%M:%S"); limit=1; grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells; useradd -e $(date -d "$add_str" +"%Y-%m-%d") -s /bin/false -M $u; echo "$u:$p" | chpasswd; echo "$u|$p|$exp_date|$limit|ACTIVE" >> $D_SSH; DMN=$(cat /usr/local/etc/xray/domain); show_account_ssh "$u" "$p" "$DMN" "$exp_date" "$limit";;
            6) nl $D_SSH; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_SSH); u=$(echo "$line" | cut -d'|' -f1); p=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5)
               if [[ "$stat" == "ACTIVE" ]]; then
                   usermod -L "$u" 2>/dev/null; killall -u "$u" 2>/dev/null
                   sed -i "${n}s/.*/$u|$p|$exp|$limit|LOCKED/" $D_SSH
                   echo -e "${GREEN}Account $u Locked Successfully!${NC}"; sleep 2
               else
                   echo -e "${RED}Account is already locked!${NC}"; sleep 2
               fi;;
            7) nl $D_SSH; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_SSH); u=$(echo "$line" | cut -d'|' -f1); p=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5)
               if [[ "$stat" != "ACTIVE" ]]; then
                   usermod -U "$u" 2>/dev/null
                   sed -i "${n}s/.*/$u|$p|$exp|$limit|ACTIVE/" $D_SSH
                   echo -e "${GREEN}Account $u Unlocked Successfully!${NC}"; sleep 2
               else
                   echo -e "${YELLOW}Account is already Active!${NC}"; sleep 2
               fi;;
            x) return;;
        esac
    done
}

function xray_manager_menu() {
    while true; do header_sub
        print_line " [1] VMESS ACCOUNT"
        print_line " [2] VLESS ACCOUNT"
        print_line " [3] TROJAN ACCOUNT"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) vmess_menu ;;
            2) vless_menu ;;
            3) trojan_menu ;;
            x) return ;;
        esac
    done
}

function auto_reboot_menu() {
    while true; do header_sub
        if [[ -f "/etc/cron.d/autoreboot" ]]; then
            local st=$(cat /etc/cron.d/autoreboot | awk '{print $2":"$1}')
            print_line "        Status [ON - $st]"
        else
            print_line "        Status [OFF]"
        fi
        print_line " ----------------------------------------"
        print_line "   1.)  Turn ON (Set Time)"
        print_line "   2.)  Turn OFF"
        print_line "   x.)  Exit"
        print_line " ----------------------------------------"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Pilihan: " opt
        case $opt in
            1) read -p " Set Jam (0-23): " hr
               read -p " Set Menit (0-59): " min
               echo "$min $hr * * * root reboot" > /etc/cron.d/autoreboot
               service cron restart
               echo -e "${GREEN}Auto Reboot set to $hr:$min!${NC}"
               sleep 2;;
            2) rm -f /etc/cron.d/autoreboot
               service cron restart
               echo -e "${GREEN}Auto Reboot dimatikan!${NC}"
               sleep 2;;
            x) return;;
        esac
    done
}

function rebuild_menu() {
    header_sub
    print_center "${RED}WARNING: REBUILD HAPUS DATA VPS!${NC}"
    print_center "Pastikan anda sudah melakukan Backup Data."
    print_line " ----------------------------------------"
    print_line " [1] Ubuntu 24.04"
    print_line " [2] Ubuntu 22.04"
    print_line " [3] Ubuntu 20.04"
    print_line " [4] Debian 12"
    print_line " [5] Debian 11"
    print_line " [x] Cancel"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    read -p " Pilih OS untuk Rebuild: " opt
    case $opt in
        1) os="ubuntu 24.04" ;;
        2) os="ubuntu 22.04" ;;
        3) os="ubuntu 20.04" ;;
        4) os="debian 12" ;;
        5) os="debian 11" ;;
        x) return ;;
        *) echo "Invalid"; sleep 1; return ;;
    esac
    
    read -p "Apakah anda yakin ingin Rebuild ke $os? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo -e "${YELLOW}Memulai proses Rebuild ke $os... Koneksi akan terputus.${NC}"
        cd /root
        curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
        bash reinstall.sh $os
        reboot
    else
        echo -e "${GREEN}Rebuild dibatalkan.${NC}"
        sleep 2
    fi
}

function check_services() {
    header_sub
    if systemctl is-active --quiet xray; then X_ST="${GREEN}ON${NC}"; else X_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet zivpn; then Z_ST="${GREEN}ON${NC}"; else Z_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet dropbear; then D_ST="${GREEN}ON${NC}"; else D_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet ws-proxy; then W_ST="${GREEN}ON${NC}"; else W_ST="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet vnstat; then V_ST="${GREEN}ON${NC}"; else V_ST="${RED}OFF${NC}"; fi
    if iptables -L >/dev/null 2>&1; then I_ST="${GREEN}ON${NC}"; else I_ST="${RED}OFF${NC}"; fi
    
    print_line " Xray Core       : ${X_ST}"
    print_line " Dropbear SSH    : ${D_ST}"
    print_line " WS SSH Proxy    : ${W_ST}"
    print_line " ZIVPN UDP       : ${Z_ST}"
    print_line " Vnstat Mon      : ${V_ST}"
    print_line " IPtables        : ${I_ST}"
    
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    read -p "Enter..."
}

function warp_install() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${PURPLE}         INSTALL WARP CLOUDFLARE (WIREPROXY)     ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${YELLOW}Mengunduh script menu Warp (fscarmen)...${NC}"
    cd /root || cd ~
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
    if [[ ! -f menu.sh ]]; then
        echo -e "${RED}Gagal mengunduh menu.sh! Cek koneksi internet VPS.${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    echo -e "${YELLOW}Menjalankan instalasi otomatis:${NC}"
    echo -e "  ${WHITE}> Language      : 1 (English)${NC}"
    echo -e "  ${WHITE}> Menu Option   : 12 (Install wireproxy)${NC}"
    echo -e "  ${WHITE}> Socks5 Port   : 40000${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    printf '1\n12\n40000\n' | bash menu.sh
    RC=$?
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    if [[ $RC -eq 0 ]]; then
        echo -e "${GREEN}[OK] Proses instalasi Warp Cloudflare (wireproxy) selesai.${NC}"
        echo -e "${WHITE}Socks5 Proxy aktif di port: 40000${NC}"
    else
        echo -e "${RED}[WARN] Script selesai dengan exit code $RC — cek output di atas untuk error.${NC}"
    fi

    # --- Replace geosite.dat Xray dengan versi custom Tendo Store ---
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Mengganti geosite.dat Xray dengan versi custom (tendostore)...${NC}"
    GEOSITE_URL="https://raw.githubusercontent.com/tendostore/Geosite-Warp-Claudflare/main/geosite.dat"
    GEOSITE_DIR="/usr/local/share/xray"
    mkdir -p "$GEOSITE_DIR"
    if [[ -f "$GEOSITE_DIR/geosite.dat" ]]; then
        cp -f "$GEOSITE_DIR/geosite.dat" "$GEOSITE_DIR/geosite.dat.bak"
    fi
    if wget -N -O "$GEOSITE_DIR/geosite.dat.tmp" "$GEOSITE_URL" && [[ -s "$GEOSITE_DIR/geosite.dat.tmp" ]]; then
        mv -f "$GEOSITE_DIR/geosite.dat.tmp" "$GEOSITE_DIR/geosite.dat"
        systemctl restart xray 2>/dev/null
        echo -e "${GREEN}[OK] geosite.dat berhasil diganti & Xray sudah di-restart.${NC}"
    else
        rm -f "$GEOSITE_DIR/geosite.dat.tmp"
        echo -e "${RED}[GAGAL] Download geosite.dat custom gagal, geosite.dat lama (jika ada) tetap dipakai.${NC}"
    fi

    # --- Replace outbound & routing Xray agar traffic tertentu lewat WARP ---
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Mengganti outbound & routing Xray (route via WARP)...${NC}"
    XRAY_CONFDIR="/usr/local/etc/xray"
    mkdir -p "$XRAY_CONFDIR"
    if [[ -f "$XRAY_CONFDIR/outbound.json" ]]; then
        cp -f "$XRAY_CONFDIR/outbound.json" "$XRAY_CONFDIR/outbound.json.bak"
        # Simpan juga versi "sebelum WARP" (cuma sekali, dipakai oleh warp_disable)
        [[ ! -f "$XRAY_CONFDIR/outbound.json.no_warp" ]] && cp -f "$XRAY_CONFDIR/outbound.json" "$XRAY_CONFDIR/outbound.json.no_warp"
    fi
    cat > "$XRAY_CONFDIR/outbound.json" <<'EOF'
{
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    },
    {
      "tag": "WARP",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 40000
          }
        ]
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "ForceIPv4"
      },
      "proxySettings": {
        "tag": "WARP"
      },
      "tag": "routing"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "inboundTag": [
          "api_in"
        ],
        "outboundTag": "api_out",
        "type": "field"
      },
      {
        "type": "field",
        "port": "443",
        "network": "udp",
        "outboundTag": "blocked"
      },
      {
        "domain": [
          "geosite:rule-playstore",
          "geosite:youtube",
          "geosite:twitter"
        ],
        "outboundTag": "routing",
        "network": "tcp,udp",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  }
}
EOF
    if xray -test -confdir "$XRAY_CONFDIR" >/tmp/xray_test.log 2>&1; then
        systemctl restart xray 2>/dev/null
        echo -e "${GREEN}[OK] outbound.json diganti & Xray sudah di-restart (Playstore/YouTube/Twitter via WARP).${NC}"
    else
        echo -e "${RED}[GAGAL] Konfigurasi baru tidak valid, rollback ke outbound.json sebelumnya.${NC}"
        cat /tmp/xray_test.log
        if [[ -f "$XRAY_CONFDIR/outbound.json.bak" ]]; then
            mv -f "$XRAY_CONFDIR/outbound.json.bak" "$XRAY_CONFDIR/outbound.json"
        fi
        systemctl restart xray 2>/dev/null
    fi

    read -p "Tekan Enter untuk kembali..."
}

function warp_disable() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${PURPLE}         NONAKTIFKAN WARP CLOUDFLARE            ${NC}"
    echo -e "${CYAN}=================================================${NC}"

    # --- 1. Stop & disable service Wireproxy ---
    echo -e "${YELLOW}Mencari service Wireproxy...${NC}"
    WP_SERVICE=$(systemctl list-units --all --type=service --plain --no-legend 2>/dev/null | awk '{print $1}' | grep -i wireproxy | head -n1)
    if [[ -n "$WP_SERVICE" ]]; then
        systemctl stop "$WP_SERVICE" 2>/dev/null
        systemctl disable "$WP_SERVICE" 2>/dev/null
        echo -e "${GREEN}[OK] Service ${WP_SERVICE} sudah dihentikan & di-disable.${NC}"
    else
        echo -e "${YELLOW}[INFO] Service wireproxy tidak ditemukan (mungkin sudah nonaktif / belum pernah diinstall).${NC}"
    fi

    # --- 2. Kembalikan outbound.json ke kondisi sebelum WARP ---
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Mengembalikan outbound & routing Xray (tanpa WARP)...${NC}"
    XRAY_CONFDIR="/usr/local/etc/xray"
    if [[ -f "$XRAY_CONFDIR/outbound.json.no_warp" ]]; then
        cp -f "$XRAY_CONFDIR/outbound.json.no_warp" "$XRAY_CONFDIR/outbound.json"
        echo -e "${GREEN}[OK] outbound.json dikembalikan ke versi sebelum WARP.${NC}"
    else
        # Fallback: tulis ulang config dasar tanpa WARP kalau backup gak ada
        cat > "$XRAY_CONFDIR/outbound.json" <<'EOF'
{
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "inboundTag": [
          "api_in"
        ],
        "outboundTag": "api_out",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  }
}
EOF
        echo -e "${YELLOW}[INFO] Backup outbound.json.no_warp tidak ditemukan, dipakai config dasar (direct/blocked saja).${NC}"
    fi

    if xray -test -confdir "$XRAY_CONFDIR" >/tmp/xray_test.log 2>&1; then
        systemctl restart xray 2>/dev/null
        echo -e "${GREEN}[OK] Xray sudah di-restart tanpa routing WARP.${NC}"
    else
        echo -e "${RED}[GAGAL] Config hasil restore tidak valid, cek log:${NC}"
        cat /tmp/xray_test.log
    fi

    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}[SELESAI] WARP Cloudflare sudah dinonaktifkan.${NC}"
    echo -e "${WHITE}Catatan: geosite.dat custom & wireproxy tetap terpasang, cuma dimatikan.${NC}"
    echo -e "${WHITE}Untuk aktifkan lagi, pilih menu [1] Install Warp Cloudflare.${NC}"
    read -p "Tekan Enter untuk kembali..."
}

function warp_restart() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${PURPLE}         RESTART WARP CLOUDFLARE                ${NC}"
    echo -e "${CYAN}=================================================${NC}"

    echo -e "${YELLOW}Mencari service Wireproxy...${NC}"
    WP_SERVICE=$(systemctl list-units --all --type=service --plain --no-legend 2>/dev/null | awk '{print $1}' | grep -i wireproxy | head -n1)
    if [[ -z "$WP_SERVICE" ]]; then
        echo -e "${RED}[GAGAL] Service wireproxy tidak ditemukan. Install dulu lewat menu [1].${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi

    echo -e "${YELLOW}Merestart ${WP_SERVICE}...${NC}"
    systemctl restart "$WP_SERVICE" 2>/dev/null
    sleep 2
    if systemctl is-active --quiet "$WP_SERVICE"; then
        echo -e "${GREEN}[OK] ${WP_SERVICE} berhasil direstart & aktif.${NC}"
    else
        echo -e "${RED}[WARN] ${WP_SERVICE} sudah di-restart tapi statusnya tidak aktif, cek log:${NC}"
        systemctl status "$WP_SERVICE" --no-pager -l | tail -n 15
    fi

    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Merestart Xray...${NC}"
    systemctl restart xray 2>/dev/null
    sleep 1
    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}[OK] Xray berhasil direstart & aktif.${NC}"
    else
        echo -e "${RED}[WARN] Xray sudah di-restart tapi statusnya tidak aktif, cek: systemctl status xray${NC}"
    fi

    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Tips cek koneksi WARP: curl -s --socks5 127.0.0.1:40000 https://www.cloudflare.com/cdn-cgi/trace/ | grep warp${NC}"
    read -p "Tekan Enter untuk kembali..."
}

function warp_menu() {
    while true; do header_sub
        echo -e "${CYAN}├── WARP CLOUDFLARE ───────────────────────────────────┤${NC}"
        print_line " [1] Install Warp Cloudflare (Wireproxy, Port 40000)"
        print_line " [2] Nonaktifkan Warp Cloudflare"
        print_line " [3] Restart Warp Cloudflare"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) warp_install ;;
            2) warp_disable ;;
            3) warp_restart ;;
            x) return;;
        esac
    done
}


function features_menu() {
    while true; do header_sub
        echo -e "${CYAN}├── MONITORING & INFO ─────────────────────────────────┤${NC}"
        print_line " [1] Information System"
        print_line " [2] Check Bandwidth"
        print_line " [3] Speedtest by Ookla"
        print_line " [4] Check Benchmark VPS"
        print_line " [5] Check Services"
        echo -e "${CYAN}├── SYSTEM MAINTENANCE ────────────────────────────────┤${NC}"
        print_line " [6] Restart All Services"
        print_line " [7] Clear Cache RAM"
        print_line " [8] Set Auto Reboot"
        print_line " [9] Rebuild VPS"
        echo -e "${CYAN}├── KONFIGURASI ───────────────────────────────────────┤${NC}"
        print_line " [10] Change Domain VPS"
        print_line " [11] Change Banner SSH"
        echo -e "${CYAN}├── BACKUP & RESTORE ──────────────────────────────────┤${NC}"
        print_line " [12] Backup Data VPS"
        print_line " [13] Restore Data VPS"
        echo -e "${CYAN}├── BOT TELEGRAM ──────────────────────────────────────┤${NC}"
        print_line " [14] Setup Bot Telegram"
        echo -e "${CYAN}├── NETWORK ───────────────────────────────────────────┤${NC}"
        print_line " [15] Setup Warp Cloudflare Vps Biznet"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) neofetch --source /etc/neofetch/tendo_ascii.txt --ascii_colors 1 7; read -p "Enter...";;
            2) vnstat -l -i $(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1); read -p "Enter...";;
            3) speedtest; read -p "Enter...";;
            4) echo -e "${YELLOW}Running Benchmark...${NC}"; wget -qO- bench.sh | bash; read -p "Enter...";;
            5) check_services ;;
            6) systemctl restart xray zivpn vnstat dropbear stunnel4 ws-proxy; echo -e "${GREEN}Services Restarted!${NC}"; sleep 2;;
            7) sync; echo 3 > /proc/sys/vm/drop_caches; echo -e "${GREEN}Cache Cleared!${NC}"; sleep 1;;
            8) auto_reboot_menu ;;
            9) rebuild_menu ;;
            10) header_sub
               print_center "${YELLOW}WARNING: Mengganti domain = Update Sertifikat SSL!${NC}"
               echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
               read -p "Masukan Domain Baru: " nd
               if [[ -z "$nd" ]]; then continue; fi
               echo -e "${YELLOW}Processing...${NC}"
               echo "$nd" > /usr/local/etc/xray/domain
               openssl req -x509 -newkey rsa:2048 -nodes -sha256 -keyout /usr/local/etc/xray/xray.key -out /usr/local/etc/xray/xray.crt -days 3650 -subj "/CN=$nd" >/dev/null 2>&1
               chmod 644 /usr/local/etc/xray/xray.key; chmod 644 /usr/local/etc/xray/xray.crt
               systemctl restart xray stunnel4
               echo -e "${GREEN}Domain Berhasil Diperbarui menjadi: $nd${NC}"
               sleep 2;;
            11) clear
                echo -e "${YELLOW}Silakan edit banner SSH di Nano Text Editor.${NC}"
                echo -e "${YELLOW}Cara save: Tekan [CTRL+X], lalu ketik [Y], lalu tekan [Enter].${NC}"
                sleep 4
                nano /etc/issue.net
                systemctl restart ssh sshd dropbear 2>/dev/null
                echo -e "${GREEN}Banner SSH Berhasil Diperbarui!${NC}"
                sleep 2;;
            12) 
               clear; echo -e "${YELLOW}Memproses Backup Data VPS...${NC}"
               if ! command -v zip &> /dev/null; then apt-get install -y zip >/dev/null 2>&1; fi
               # Pastikan permission benar SEBELUM di-zip, supaya backup
               # tidak ikut menyimpan permission rusak (600) ke masa depan.
               chmod 644 /usr/local/etc/xray/config.json 2>/dev/null
               chmod 644 /usr/local/etc/xray/outbound.json 2>/dev/null
               chmod 644 /usr/local/etc/xray/xray.key 2>/dev/null
               chmod 644 /usr/local/etc/xray/xray.crt 2>/dev/null
               DATE=$(date +"%Y-%m-%d_%H-%M")
               ZIP_FILE="/root/Backup_${DATE}.zip"
               cd /
               zip -r $ZIP_FILE usr/local/etc/xray/ etc/zivpn/ etc/tendo_bot/ etc/issue.net >/dev/null 2>&1
               cd - >/dev/null 2>&1
               
               if [[ ! -f "$ZIP_FILE" ]]; then
                   echo -e "${RED}Gagal membuat file backup!${NC}"
                   read -p "Tekan Enter untuk kembali..."
                   continue
               fi

               echo -e "${GREEN}File Backup tersimpan di VPS: ${ZIP_FILE}${NC}"
               echo -e "${YELLOW}Mengunggah ke server cloud (Mencari Direct Link)...${NC}"
               LINK=$(curl -s --upload-file $ZIP_FILE https://transfer.sh/Backup_${DATE}.zip)
               echo -e "\n${CYAN}=================================================${NC}"
               echo -e "${GREEN}Sukses! Simpan link di bawah ini untuk Restore:${NC}"
               echo -e "${WHITE}${LINK}${NC}"
               echo -e "${CYAN}=================================================${NC}\n"
               
               local bot_tok=$(cat /etc/tendo_bot/bot_token 2>/dev/null | tr -d '\r\n ')
               local chat_id=$(cat /etc/tendo_bot/chat_id 2>/dev/null | tr -d '\r\n ')
               local IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
               local DOM_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
               local ISP_VPS=$(cat /root/tendo/isp 2>/dev/null)
               
               if [[ -n "$bot_tok" && -n "$chat_id" ]]; then
                   echo -e "${YELLOW}Mengirim backup ke Telegram Bot...${NC}"
                   curl -s -X POST "https://api.telegram.org/bot${bot_tok}/sendDocument" \
                       -F "chat_id=${chat_id}" \
                       -F "document=@${ZIP_FILE}" \
                       -F "caption=[PKG] MANUAL BACKUP VPS"$'\n\n'"IP     : ${IP_VPS}"$'\n'"DOMAIN : ${DOM_VPS}"$'\n'"ISP    : ${ISP_VPS}"$'\n\n'"Date       : ${DATE}"$'\n'"[OK] Backup Successfully generated."$'\n'"Link Direct Link: ${LINK}" > /dev/null
                   echo -e "${GREEN}File backup berhasil dikirim ke Telegram!${NC}"
               fi
               read -p "Tekan Enter untuk kembali..."
               ;;
            13) 
               clear; echo -e "${YELLOW}--- RESTORE DATA VPS ---${NC}"
               echo -e "${RED}Warning: Data saat ini akan ditimpa dengan data dari Backup!${NC}"
               read -p " Masukkan Link Direct Backup (.zip) : " link_res
               if [[ -n "$link_res" ]]; then
                   echo -e "${YELLOW}Mengunduh file backup...${NC}"
                   wget -qO /root/restore.zip "$link_res"
                   if [[ -f "/root/restore.zip" ]]; then
                       echo -e "${YELLOW}Mengekstrak dan memulihkan data (X-ray, ZIVPN, Domain, Bot, Banner)...${NC}"
                       cd /
                       unzip -o /root/restore.zip >/dev/null 2>&1
                       cd - >/dev/null 2>&1
                       rm -f /root/restore.zip

                       # Perbaikan permission: file backup lama mungkin membawa
                       # permission rusak (600) hasil bug versi sebelumnya.
                       # Paksa balik ke permission yang benar & pastikan xray.service
                       # tetap override ke User=root (lihat step Xray Core) setelah restore.
                       mkdir -p /etc/systemd/system/xray.service.d
                       cat > /etc/systemd/system/xray.service.d/override.conf <<'EOFOVR'
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray
User=root
Group=root
ProtectSystem=false
ProtectHome=false
ReadWritePaths=-/var/log/xray -/usr/local/etc/xray
EOFOVR
                       systemctl daemon-reload
                       mkdir -p /var/log/xray
                       chown -R root:root /var/log/xray
                       chmod 644 /usr/local/etc/xray/config.json 2>/dev/null
                       chmod 644 /usr/local/etc/xray/outbound.json 2>/dev/null
                       chmod 644 /usr/local/etc/xray/xray.key 2>/dev/null
                       chmod 644 /usr/local/etc/xray/xray.crt 2>/dev/null

                       chmod -R 700 /etc/tendo_bot/ 2>/dev/null
                       systemctl daemon-reload
                       
                       
                       (crontab -l 2>/dev/null | grep -v "xray-exp"; echo "* * * * * /usr/local/bin/xray-exp") | crontab -
                       (crontab -l 2>/dev/null | grep -v "xray-limit"; echo "* * * * * /usr/local/bin/xray-limit") | crontab -
                       (crontab -l 2>/dev/null | grep -v "xray-quota"; echo "* * * * * /usr/local/bin/xray-quota") | crontab -
                       
                       if [[ "$(cat /etc/tendo_bot/log_stat 2>/dev/null)" == ON* ]]; then
                           dur=$(cat /etc/tendo_bot/log_stat | grep -oP '\(\K[^\)]+')
                           if [[ "$dur" == *m ]]; then c="*/${dur%m} * * * *"; elif [[ "$dur" == *h ]]; then c="0 */${dur%h} * * *"; fi
                           crontab -l | grep -v "bot-login-notif" > /tmp/c.tmp; echo "$c /usr/local/bin/bot-login-notif" >> /tmp/c.tmp; crontab /tmp/c.tmp
                       fi
                       if [[ "$(cat /etc/tendo_bot/bak_stat 2>/dev/null)" == ON* ]]; then
                           dur=$(cat /etc/tendo_bot/bak_stat | grep -oP '\(\K[^\)]+')
                           if [[ "$dur" == *m ]]; then c="*/${dur%m} * * * *"; elif [[ "$dur" == *h ]]; then c="0 */${dur%h} * * *"; fi
                           crontab -l | grep -v "bot-backup" > /tmp/c.tmp; echo "$c /usr/local/bin/bot-backup" >> /tmp/c.tmp; crontab /tmp/c.tmp
                       fi

                       if [[ -f "/usr/local/etc/xray/ssh.txt" ]]; then
                           while IFS="|" read -r u p exp limit stat quota; do
                               [[ -z "$u" ]] && continue
                               grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                               if id "$u" &>/dev/null; then
                                   usermod -e $(date -d "$exp" +"%Y-%m-%d" 2>/dev/null) -s /bin/false "$u" 2>/dev/null
                               else
                                   useradd -e $(date -d "$exp" +"%Y-%m-%d" 2>/dev/null) -s /bin/false -M "$u" 2>/dev/null
                               fi
                               echo "$u:$p" | chpasswd 2>/dev/null
                               if [[ "$stat" == "LOCKED"* || "$stat" == "LOCKED" ]]; then
                                   usermod -L "$u" 2>/dev/null
                               else
                                   usermod -U "$u" 2>/dev/null
                               fi
                           done < "/usr/local/etc/xray/ssh.txt"
                       fi

                       systemctl restart xray zivpn dropbear ws-proxy stunnel4 ssh sshd
                       echo -e "${GREEN}Restore Berhasil! Semua konfigurasi dan akun telah dipulihkan.${NC}"
                       sleep 3
                   else
                       echo -e "${RED}Gagal mengunduh file! Pastikan link direct yang dimasukkan valid.${NC}"
                       read -p "Tekan Enter untuk kembali..."
                   fi
               fi
               ;;
            14) bot_menu ;;
            15) warp_menu ;;
            x) return;;
        esac
    done
}

# ---------------------------------------------
# FUNGSI MENU PROTOKOL (XRAY & ZIVPN)
# ---------------------------------------------
function vmess_menu() {
    while true; do header_sub
        print_line " [1] Create Account Vmess"
        print_line " [2] Delete Account Vmess"
        print_line " [3] Renew Account Vmess"
        print_line " [4] Check Config User"
        print_line " [5] Trial Account Vmess"
        print_line " [6] Lock Account Vmess"
        print_line " [7] Unlock Account Vmess"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Username : " u; [[ -z "$u" ]] && continue
               if ! check_exists "$u"; then continue; fi
               read -p " Password (ID/UUID) : " p; [[ -z "$p" ]] && p=$(uuidgen); id="$p"
               if ! check_uuid "$id"; then continue; fi
               read -p " Expired (days): " ex; [[ -z "$ex" ]] && ex=30; read -p " Limit IP (0 for unlimited): " limit; [[ -z "$limit" ]] && limit=0; read -p " Quota Bandwidth GB (0 for unlimited): " quota; [[ -z "$quota" ]] && quota=0
               exp_date=$(date -d "+$ex days" +"%Y-%m-%d");_tf9=$(mktemp) &&  jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vmess")).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf9" && mv "$_tf9" $CONFIG; chmod 644 $CONFIG; echo "$u|$id|$exp_date|$limit|ACTIVE|$quota" >> $D_VMESS; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               ws_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               grpc_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"grpc\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-grpc\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               show_account_xray "VMESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "0.00" "vmess://$ws_tls" "vmess://$ws_ntls" "vmess://$grpc_tls" "vmess://$upg_tls" "vmess://$upg_ntls"
               ;;
            2) nl $D_VMESS; read -p "No: " n; [[ -z "$n" ]] && continue; u=$(sed -n "${n}p" $D_VMESS | cut -d'|' -f1); sed -i "${n}d" $D_VMESS;_tf10=$(mktemp) &&  jq --arg u "$u" '(.inbounds[] | select(.protocol == "vmess")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf10" && mv "$_tf10" $CONFIG; chmod 644 $CONFIG; rm -f "/usr/local/etc/xray/quota/$u"
               echo -e "${GREEN}Account Deleted!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            3) nl $D_VMESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VMESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp_old=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6); read -p " Add Days: " add_days; exp_new=$(date -d "$exp_old + $add_days days" +"%Y-%m-%d"); sed -i "${n}s/.*/$u|$id|$exp_new|$limit|$stat|$quota/" $D_VMESS
               echo -e "${GREEN}Account $u Renewed until $exp_new!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            4) nl $D_VMESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VMESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp_date=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); quota=$(echo "$line" | cut -d'|' -f6); [[ -z "$quota" ]] && quota=0; DMN=$(cat /usr/local/etc/xray/domain)
               QUOTA_FILE="/usr/local/etc/xray/quota/${u}"
               if [[ -f "$QUOTA_FILE" ]]; then read total_acc last_api < "$QUOTA_FILE"; usage_gb=$(awk "BEGIN {printf \"%.2f\", $total_acc/1073741824}"); else usage_gb="0.00"; fi
               ws_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               ws_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               grpc_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"grpc\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-grpc\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               show_account_xray "VMESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "$usage_gb" "vmess://$ws_tls" "vmess://$ws_ntls" "vmess://$grpc_tls" "vmess://$upg_tls" "vmess://$upg_ntls";;
            5) u="trial-$(tr -dc a-z0-9 </dev/urandom | head -c 5)"; echo -e " Username (Trial): ${GREEN}$u${NC}"; p="$u"; id="$p"; read -p " Duration (e.g., 10m, 1h): " dur;
               if [[ "$dur" == *m ]]; then add_str="+${dur%m} minutes"; elif [[ "$dur" == *h ]]; then add_str="+${dur%h} hours"; else add_str="+1 hours"; fi
               exp_date=$(date -d "$add_str" +"%Y-%m-%d %H:%M:%S"); limit=1; quota=0;_tf11=$(mktemp) &&  jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vmess")).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf11" && mv "$_tf11" $CONFIG; chmod 644 $CONFIG; echo "$u|$id|$exp_date|$limit|ACTIVE|$quota" >> $D_VMESS; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               ws_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               grpc_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"grpc\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-grpc\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_tls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"443\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"tls\",\"sni\":\"${DMN}\"}" | base64 -w 0)
               upg_ntls=$(echo "{\"v\":\"2\",\"ps\":\"${u}\",\"add\":\"${DMN}\",\"port\":\"80\",\"id\":\"${id}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"httpupgrade\",\"type\":\"none\",\"host\":\"${DMN}\",\"path\":\"/vmess-upg\",\"tls\":\"\",\"sni\":\"\"}" | base64 -w 0)
               show_account_xray "VMESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "0.00" "vmess://$ws_tls" "vmess://$ws_ntls" "vmess://$grpc_tls" "vmess://$upg_tls" "vmess://$upg_ntls"
               ;;
            6) nl $D_VMESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VMESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" == "ACTIVE" ]]; then
_tf12=$(mktemp) &&                    jq --arg u "$u" '(.inbounds[] | select(.protocol == "vmess")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf12" && mv "$_tf12" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$id|$exp|$limit|LOCKED|$quota/" $D_VMESS
                   echo -e "${GREEN}Account $u Locked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${RED}Account is already locked!${NC}"; sleep 2
               fi;;
            7) nl $D_VMESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VMESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" != "ACTIVE" ]]; then
_tf13=$(mktemp) &&                    jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vmess")).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf13" && mv "$_tf13" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$id|$exp|$limit|ACTIVE|$quota/" $D_VMESS
                   echo -e "${GREEN}Account $u Unlocked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${YELLOW}Account is already Active!${NC}"; sleep 2
               fi;;
            x) return;;
        esac; done
}

function vless_menu() {
    while true; do header_sub
        print_line " [1] Create Account Vless"
        print_line " [2] Delete Account Vless"
        print_line " [3] Renew Account Vless"
        print_line " [4] Check Config User"
        print_line " [5] Trial Account Vless"
        print_line " [6] Lock Account Vless"
        print_line " [7] Unlock Account Vless"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Username : " u; [[ -z "$u" ]] && continue
               if ! check_exists "$u"; then continue; fi
               read -p " Password (ID/UUID) : " p; [[ -z "$p" ]] && p=$(uuidgen); id="$p"
               if ! check_uuid "$id"; then continue; fi
               read -p " Expired (days): " ex; [[ -z "$ex" ]] && ex=30; read -p " Limit IP (0 for unlimited): " limit; [[ -z "$limit" ]] && limit=0; read -p " Quota Bandwidth GB (0 for unlimited): " quota; [[ -z "$quota" ]] && quota=0
               exp_date=$(date -d "+$ex days" +"%Y-%m-%d");_tf14=$(mktemp) &&  jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vless" and (.tag != "inbound-443" and .tag != "inbound-80"))).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf14" && mv "$_tf14" $CONFIG; chmod 644 $CONFIG; echo "$u|$id|$exp_date|$limit|ACTIVE|$quota" >> $D_VLESS; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls="vless://${id}@${DMN}:443?path=%2Fvless&security=tls&encryption=none&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="vless://${id}@${DMN}:80?path=%2Fvless&security=none&encryption=none&host=${DMN}&type=ws#${u}"
               grpc_tls="vless://${id}@${DMN}:443?security=tls&encryption=none&host=${DMN}&type=grpc&serviceName=vless-grpc&sni=${DMN}#${u}"
               upg_tls="vless://${id}@${DMN}:443?path=%2Fvless-upg&security=tls&encryption=none&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               upg_ntls="vless://${id}@${DMN}:80?path=%2Fvless-upg&security=none&encryption=none&host=${DMN}&type=httpupgrade#${u}"
               show_account_xray "VLESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "0.00" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" "$upg_ntls"
               ;;
            2) nl $D_VLESS; read -p "No: " n; [[ -z "$n" ]] && continue; u=$(sed -n "${n}p" $D_VLESS | cut -d'|' -f1); sed -i "${n}d" $D_VLESS;_tf15=$(mktemp) &&  jq --arg u "$u" '(.inbounds[] | select(.protocol == "vless" and (.tag != "inbound-443" and .tag != "inbound-80"))).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf15" && mv "$_tf15" $CONFIG; chmod 644 $CONFIG; rm -f "/usr/local/etc/xray/quota/$u"
               echo -e "${GREEN}Account Deleted!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            3) nl $D_VLESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VLESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp_old=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6); read -p " Add Days: " add_days; exp_new=$(date -d "$exp_old + $add_days days" +"%Y-%m-%d"); sed -i "${n}s/.*/$u|$id|$exp_new|$limit|$stat|$quota/" $D_VLESS
               echo -e "${GREEN}Account $u Renewed until $exp_new!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            4) nl $D_VLESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VLESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp_date=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); quota=$(echo "$line" | cut -d'|' -f6); [[ -z "$quota" ]] && quota=0; DMN=$(cat /usr/local/etc/xray/domain)
               QUOTA_FILE="/usr/local/etc/xray/quota/${u}"
               if [[ -f "$QUOTA_FILE" ]]; then read total_acc last_api < "$QUOTA_FILE"; usage_gb=$(awk "BEGIN {printf \"%.2f\", $total_acc/1073741824}"); else usage_gb="0.00"; fi
               ws_tls="vless://${id}@${DMN}:443?path=%2Fvless&security=tls&encryption=none&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="vless://${id}@${DMN}:80?path=%2Fvless&security=none&encryption=none&host=${DMN}&type=ws#${u}"
               grpc_tls="vless://${id}@${DMN}:443?security=tls&encryption=none&host=${DMN}&type=grpc&serviceName=vless-grpc&sni=${DMN}#${u}"
               upg_tls="vless://${id}@${DMN}:443?path=%2Fvless-upg&security=tls&encryption=none&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               upg_ntls="vless://${id}@${DMN}:80?path=%2Fvless-upg&security=none&encryption=none&host=${DMN}&type=httpupgrade#${u}"
               show_account_xray "VLESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "$usage_gb" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" "$upg_ntls";;
            5) u="trial-$(tr -dc a-z0-9 </dev/urandom | head -c 5)"; echo -e " Username (Trial): ${GREEN}$u${NC}"; p="$u"; id="$p"; read -p " Duration (e.g., 10m, 1h): " dur;
               if [[ "$dur" == *m ]]; then add_str="+${dur%m} minutes"; elif [[ "$dur" == *h ]]; then add_str="+${dur%h} hours"; else add_str="+1 hours"; fi
               exp_date=$(date -d "$add_str" +"%Y-%m-%d %H:%M:%S"); limit=1; quota=0;_tf16=$(mktemp) &&  jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vless" and (.tag != "inbound-443" and .tag != "inbound-80"))).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf16" && mv "$_tf16" $CONFIG; chmod 644 $CONFIG; echo "$u|$id|$exp_date|$limit|ACTIVE|$quota" >> $D_VLESS; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls="vless://${id}@${DMN}:443?path=%2Fvless&security=tls&encryption=none&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="vless://${id}@${DMN}:80?path=%2Fvless&security=none&encryption=none&host=${DMN}&type=ws#${u}"
               grpc_tls="vless://${id}@${DMN}:443?security=tls&encryption=none&host=${DMN}&type=grpc&serviceName=vless-grpc&sni=${DMN}#${u}"
               upg_tls="vless://${id}@${DMN}:443?path=%2Fvless-upg&security=tls&encryption=none&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               upg_ntls="vless://${id}@${DMN}:80?path=%2Fvless-upg&security=none&encryption=none&host=${DMN}&type=httpupgrade#${u}"
               show_account_xray "VLESS" "$u" "$DMN" "$id" "$exp_date" "$limit" "$quota" "0.00" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" "$upg_ntls"
               ;;
            6) nl $D_VLESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VLESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" == "ACTIVE" ]]; then
_tf17=$(mktemp) &&                    jq --arg u "$u" '(.inbounds[] | select(.protocol == "vless" and (.tag != "inbound-443" and .tag != "inbound-80"))).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf17" && mv "$_tf17" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$id|$exp|$limit|LOCKED|$quota/" $D_VLESS
                   echo -e "${GREEN}Account $u Locked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${RED}Account is already locked!${NC}"; sleep 2
               fi;;
            7) nl $D_VLESS; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_VLESS); u=$(echo "$line" | cut -d'|' -f1); id=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" != "ACTIVE" ]]; then
_tf18=$(mktemp) &&                    jq --arg u "$u" --arg id "$id" '(.inbounds[] | select(.protocol == "vless" and (.tag != "inbound-443" and .tag != "inbound-80"))).settings.clients += [{"id":$id,"email":$u,"level":0}]' $CONFIG > "$_tf18" && mv "$_tf18" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$id|$exp|$limit|ACTIVE|$quota/" $D_VLESS
                   echo -e "${GREEN}Account $u Unlocked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${YELLOW}Account is already Active!${NC}"; sleep 2
               fi;;
            x) return;;
        esac; done
}

function trojan_menu() {
    while true; do header_sub
        print_line " [1] Create Account Trojan"
        print_line " [2] Delete Account Trojan"
        print_line " [3] Renew Account Trojan"
        print_line " [4] Check Config User"
        print_line " [5] Trial Account Trojan"
        print_line " [6] Lock Account Trojan"
        print_line " [7] Unlock Account Trojan"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Username : " u; [[ -z "$u" ]] && continue
               if ! check_exists "$u"; then continue; fi
               read -p " Password : " p; [[ -z "$p" ]] && p="$u"; pass="$p"
               if ! check_uuid "$pass"; then continue; fi
               read -p " Expired (days): " ex; [[ -z "$ex" ]] && ex=30; read -p " Limit IP (0 for unlimited): " limit; [[ -z "$limit" ]] && limit=0; read -p " Quota Bandwidth GB (0 for unlimited): " quota; [[ -z "$quota" ]] && quota=0
               exp_date=$(date -d "+$ex days" +"%Y-%m-%d");_tf19=$(mktemp) &&  jq --arg p "$pass" --arg u "$u" '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password":$p,"email":$u,"level":0}]' $CONFIG > "$_tf19" && mv "$_tf19" $CONFIG; chmod 644 $CONFIG; echo "$u|$pass|$exp_date|$limit|ACTIVE|$quota" >> $D_TROJAN; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan&security=tls&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="trojan://${pass}@${DMN}:80?path=%2Ftrojan&security=none&host=${DMN}&type=ws#${u}"
               grpc_tls="trojan://${pass}@${DMN}:443?security=tls&host=${DMN}&type=grpc&serviceName=trojan-grpc&sni=${DMN}#${u}"
               upg_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan-upg&security=tls&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               show_account_xray "TROJAN" "$u" "$DMN" "$pass" "$exp_date" "$limit" "$quota" "0.00" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" ""
               ;;
            2) nl $D_TROJAN; read -p "No: " n; [[ -z "$n" ]] && continue; u=$(sed -n "${n}p" $D_TROJAN | cut -d'|' -f1); sed -i "${n}d" $D_TROJAN;_tf20=$(mktemp) &&  jq --arg u "$u" '(.inbounds[] | select(.protocol == "trojan")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf20" && mv "$_tf20" $CONFIG; chmod 644 $CONFIG; rm -f "/usr/local/etc/xray/quota/$u"
               echo -e "${GREEN}Account Deleted!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            3) nl $D_TROJAN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_TROJAN); u=$(echo "$line" | cut -d'|' -f1); pass=$(echo "$line" | cut -d'|' -f2); exp_old=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6); read -p " Add Days: " add_days; exp_new=$(date -d "$exp_old + $add_days days" +"%Y-%m-%d"); sed -i "${n}s/.*/$u|$pass|$exp_new|$limit|$stat|$quota/" $D_TROJAN
               echo -e "${GREEN}Account $u Renewed until $exp_new!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2;;
            4) nl $D_TROJAN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_TROJAN); u=$(echo "$line" | cut -d'|' -f1); pass=$(echo "$line" | cut -d'|' -f2); exp_date=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); quota=$(echo "$line" | cut -d'|' -f6); [[ -z "$quota" ]] && quota=0; DMN=$(cat /usr/local/etc/xray/domain)
               QUOTA_FILE="/usr/local/etc/xray/quota/${u}"
               if [[ -f "$QUOTA_FILE" ]]; then read total_acc last_api < "$QUOTA_FILE"; usage_gb=$(awk "BEGIN {printf \"%.2f\", $total_acc/1073741824}"); else usage_gb="0.00"; fi
               ws_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan&security=tls&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="trojan://${pass}@${DMN}:80?path=%2Ftrojan&security=none&host=${DMN}&type=ws#${u}"
               grpc_tls="trojan://${pass}@${DMN}:443?security=tls&host=${DMN}&type=grpc&serviceName=trojan-grpc&sni=${DMN}#${u}"
               upg_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan-upg&security=tls&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               show_account_xray "TROJAN" "$u" "$DMN" "$pass" "$exp_date" "$limit" "$quota" "$usage_gb" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" "";;
            5) u="trial-$(tr -dc a-z0-9 </dev/urandom | head -c 5)"; echo -e " Username (Trial): ${GREEN}$u${NC}"; p="$u"; pass="$p"; read -p " Duration (e.g., 10m, 1h): " dur;
               if [[ "$dur" == *m ]]; then add_str="+${dur%m} minutes"; elif [[ "$dur" == *h ]]; then add_str="+${dur%h} hours"; else add_str="+1 hours"; fi
               exp_date=$(date -d "$add_str" +"%Y-%m-%d %H:%M:%S"); limit=1; quota=0;_tf21=$(mktemp) &&  jq --arg p "$pass" --arg u "$u" '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password":$p,"email":$u,"level":0}]' $CONFIG > "$_tf21" && mv "$_tf21" $CONFIG; chmod 644 $CONFIG; echo "$u|$pass|$exp_date|$limit|ACTIVE|$quota" >> $D_TROJAN; echo "0 0" > "/usr/local/etc/xray/quota/$u"
               DMN=$(cat /usr/local/etc/xray/domain)
               ws_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan&security=tls&host=${DMN}&type=ws&sni=${DMN}#${u}"
               ws_ntls="trojan://${pass}@${DMN}:80?path=%2Ftrojan&security=none&host=${DMN}&type=ws#${u}"
               grpc_tls="trojan://${pass}@${DMN}:443?security=tls&host=${DMN}&type=grpc&serviceName=trojan-grpc&sni=${DMN}#${u}"
               upg_tls="trojan://${pass}@${DMN}:443?path=%2Ftrojan-upg&security=tls&host=${DMN}&type=httpupgrade&sni=${DMN}#${u}"
               show_account_xray "TROJAN" "$u" "$DMN" "$pass" "$exp_date" "$limit" "$quota" "0.00" "$ws_tls" "$ws_ntls" "$grpc_tls" "$upg_tls" ""
               ;;
            6) nl $D_TROJAN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_TROJAN); u=$(echo "$line" | cut -d'|' -f1); pass=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" == "ACTIVE" ]]; then
_tf22=$(mktemp) &&                    jq --arg u "$u" '(.inbounds[] | select(.protocol == "trojan")).settings.clients |= map(select(.email != $u))' $CONFIG > "$_tf22" && mv "$_tf22" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$pass|$exp|$limit|LOCKED|$quota/" $D_TROJAN
                   echo -e "${GREEN}Account $u Locked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${RED}Account is already locked!${NC}"; sleep 2
               fi;;
            7) nl $D_TROJAN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_TROJAN); u=$(echo "$line" | cut -d'|' -f1); pass=$(echo "$line" | cut -d'|' -f2); exp=$(echo "$line" | cut -d'|' -f3); limit=$(echo "$line" | cut -d'|' -f4); stat=$(echo "$line" | cut -d'|' -f5); quota=$(echo "$line" | cut -d'|' -f6)
               if [[ "$stat" != "ACTIVE" ]]; then
_tf23=$(mktemp) &&                    jq --arg p "$pass" --arg u "$u" '(.inbounds[] | select(.protocol == "trojan")).settings.clients += [{"password":$p,"email":$u,"level":0}]' $CONFIG > "$_tf23" && mv "$_tf23" $CONFIG; chmod 644 $CONFIG
                   sed -i "${n}s/.*/$u|$pass|$exp|$limit|ACTIVE|$quota/" $D_TROJAN
                   echo -e "${GREEN}Account $u Unlocked Successfully!${NC}"; systemctl restart xray >/dev/null 2>&1; sleep 2
               else
                   echo -e "${YELLOW}Account is already Active!${NC}"; sleep 2
               fi;;
            x) return;;
        esac; done
}

function zivpn_menu() {
    while true; do header_sub
        print_line " [1] Create Account ZIVPN"
        print_line " [2] Delete Account ZIVPN"
        print_line " [3] Renew Account ZIVPN"
        print_line " [4] Check Config User"
        print_line " [5] Trial Account ZIVPN"
        print_line " [x] Back"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Select Menu : " opt
        case $opt in
            1) read -p " Password : " p; [[ -z "$p" ]] && continue
               u="$p"
               if ! check_exists "$u"; then continue; fi
               if grep -q "|$p|" $D_ZIVPN 2>/dev/null || grep -q "^$p|" $D_ZIVPN 2>/dev/null; then echo -e "${RED}Password '$p' sudah digunakan!${NC}"; sleep 2; continue; fi
               read -p " Expired (days): " ex; [[ -z "$ex" ]] && ex=30; exp=$(date -d "$ex days" +"%Y-%m-%d");_tf25=$(mktemp) &&  jq --arg pwd "$p" '.auth.config += [$pwd]' /etc/zivpn/config.json > "$_tf25" && mv "$_tf25" /etc/zivpn/config.json; echo "$u|$p|$exp" >> $D_ZIVPN; DMN=$(cat /usr/local/etc/xray/domain); show_account_zivpn "$u" "$p" "$DMN" "$exp"
               ;;
            2) nl $D_ZIVPN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_ZIVPN); IFS="|" read -r f1 f2 f3 <<< "$line"; if [[ -z "$f3" ]]; then p="$f1"; else p="$f2"; fi; sed -i "${n}d" $D_ZIVPN;_tf26=$(mktemp) &&  jq --arg pwd "$p" 'del(.auth.config[] | select(. == $pwd))' /etc/zivpn/config.json > "$_tf26" && mv "$_tf26" /etc/zivpn/config.json
               echo -e "${GREEN}Account Deleted!${NC}"; systemctl restart zivpn >/dev/null 2>&1; sleep 2;;
            3) nl $D_ZIVPN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_ZIVPN); IFS="|" read -r f1 f2 f3 <<< "$line"; if [[ -z "$f3" ]]; then u="unknown"; p="$f1"; exp_old="$f2"; else u="$f1"; p="$f2"; exp_old="$f3"; fi; read -p " Add Days: " add_days; exp_new=$(date -d "$exp_old + $add_days days" +"%Y-%m-%d"); if [[ "$u" == "unknown" ]]; then sed -i "${n}s/.*/$p|$exp_new/" $D_ZIVPN; else sed -i "${n}s/.*/$u|$p|$exp_new/" $D_ZIVPN; fi
               echo -e "${GREEN}ZIVPN Account Renewed until $exp_new!${NC}"; systemctl restart zivpn >/dev/null 2>&1; sleep 2;;
            4) nl $D_ZIVPN; read -p "No: " n; [[ -z "$n" ]] && continue; line=$(sed -n "${n}p" $D_ZIVPN); IFS="|" read -r f1 f2 f3 <<< "$line"; if [[ -z "$f3" ]]; then u="unknown"; p="$f1"; exp="$f2"; else u="$f1"; p="$f2"; exp="$f3"; fi; DMN=$(cat /usr/local/etc/xray/domain); show_account_zivpn "$u" "$p" "$DMN" "$exp";;
            5) p="trial-$(tr -dc a-z0-9 </dev/urandom | head -c 5)"; echo -e " Password (Trial): ${GREEN}$p${NC}"; u="$p"; read -p " Duration (e.g., 10m, 1h): " dur;
               if [[ "$dur" == *m ]]; then add_str="+${dur%m} minutes"; elif [[ "$dur" == *h ]]; then add_str="+${dur%h} hours"; else add_str="+1 hours"; fi
               exp=$(date -d "$add_str" +"%Y-%m-%d %H:%M:%S");_tf27=$(mktemp) &&  jq --arg pwd "$p" '.auth.config += [$pwd]' /etc/zivpn/config.json > "$_tf27" && mv "$_tf27" /etc/zivpn/config.json; echo "$u|$p|$exp" >> $D_ZIVPN; DMN=$(cat /usr/local/etc/xray/domain); show_account_zivpn "$u" "$p" "$DMN" "$exp"
               ;;
            x) return;;
        esac; done
}

# ── Helper: Buat/Update config nginx untuk xpanel ───────────────────
function setup_panel_nginx() {
    local DOMAIN="$1"        # subdomain atau domain utama
    local USE_SSL="$2"       # yes / no
    local PANEL_PORT=8181
    local CERT="/usr/local/etc/xray/xray.crt"
    local KEY="/usr/local/etc/xray/xray.key"
    local CONF="/etc/nginx/sites-available/xpanel"
    local XRAY_DOMAIN=$(cat /usr/local/etc/xray/domain 2>/dev/null)

    # Pastikan nginx terinstall
    if ! command -v nginx &>/dev/null; then
        echo -e " Menginstall nginx..."
        apt-get install -y nginx -qq >/dev/null 2>&1
    fi

    # ── Deteksi konflik port ──────────────────────────────────────────
    # Jika domain sama dengan domain Xray DAN pilih HTTPS:
    # Port 443 sudah dipakai Xray → nginx pakai port 8443 (alternatif aman)
    local HTTPS_PORT=443
    local HTTP_PORT=80
    local PORT_SUFFIX=""   # untuk URL akhir, kosong jika port standar

    if [[ "$USE_SSL" == "yes" ]]; then
        # Cek apakah port 443 benar-benar dipakai (Xray selalu bind 443 langsung,
        # terlepas dari domainnya sama atau beda dengan domain panel)
        if ss -tlnp 2>/dev/null | grep -q ':443 ' || \
           systemctl is-active xray &>/dev/null; then
            HTTPS_PORT=8443
            PORT_SUFFIX=":8443"
            echo -e " ${YELLOW}[INFO]${NC} Port 443 sudah dipakai Xray."
            echo -e "        Panel akan pakai port ${WHITE}8443${NC} agar tidak bentrok."
            echo -e "        URL: ${CYAN}https://${DOMAIN}:8443${NC}"

            # Port 8443 sendiri sudah dipakai permanen oleh stunnel4 (dropbear_tls),
            # jadi cek juga sebelum benar-benar memilihnya. Kalau bentrok, geser
            # ke port alternatif lain yang kosong.
            if ss -tlnp 2>/dev/null | grep -q ':8443 ' || \
               systemctl is-active stunnel4 &>/dev/null; then
                HTTPS_PORT=2096
                PORT_SUFFIX=":2096"
                echo -e " ${YELLOW}[INFO]${NC} Port 8443 dipakai Stunnel (SSH TLS)."
                echo -e "        Panel akan pakai port ${WHITE}2096${NC} agar tidak bentrok."
                echo -e "        URL: ${CYAN}https://${DOMAIN}:2096${NC}"
            fi
        fi
    fi

    if [[ "$USE_SSL" == "yes" && -f "$CERT" && -f "$KEY" ]]; then
        # ── HTTPS config ──────────────────────────────────────────────
        if [[ "$HTTPS_PORT" == "443" ]]; then
            # Subdomain baru / domain beda → port 443 aman
            cat > "$CONF" << NGINXEOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate     ${CERT};
    ssl_certificate_key ${KEY};
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    server_tokens off;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_pass         http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }
}
NGINXEOF
        else
            # Domain sama dengan Xray → port 8443, tidak ada redirect port 80
            cat > "$CONF" << NGINXEOF
server {
    listen ${HTTPS_PORT} ssl;
    server_name ${DOMAIN};

    ssl_certificate     ${CERT};
    ssl_certificate_key ${KEY};
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    server_tokens off;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_pass         http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }
}
NGINXEOF
        fi
    else
        # ── HTTP config ───────────────────────────────────────────────
        # Cek apakah port 80 konflik
        if [[ "$DOMAIN" == "$XRAY_DOMAIN" ]] && \
           ss -tlnp 2>/dev/null | grep -q ':80 '; then
            HTTP_PORT=8080
            PORT_SUFFIX=":8080"
            echo -e " ${YELLOW}[INFO]${NC} Port 80 sudah dipakai → panel pakai port ${WHITE}8080${NC}"
            echo -e "        URL: ${CYAN}http://${DOMAIN}:8080${NC}"
        fi
        cat > "$CONF" << NGINXEOF
server {
    listen ${HTTP_PORT};
    server_name ${DOMAIN};
    server_tokens off;

    location / {
        proxy_pass         http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }
}
NGINXEOF
    fi

    # ── Aktifkan site & reload nginx ──────────────────────────────────
    ln -sf "$CONF" /etc/nginx/sites-enabled/xpanel 2>/dev/null
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null

    # Test nginx config sebelum reload
    if nginx -t >/dev/null 2>&1; then
        systemctl enable nginx >/dev/null 2>&1
        systemctl reload nginx >/dev/null 2>&1 || systemctl start nginx >/dev/null 2>&1
    else
        echo -e " ${RED}[WARN]${NC} Konfigurasi nginx ada masalah, cek: nginx -t"
    fi

    # ── Simpan info domain & protokol ke file ────────────────────────
    # Format: baris1=domain, baris2=https/http, baris3=port_suffix
    {
        echo "$DOMAIN"
        [[ "$USE_SSL" == "yes" ]] && echo "https" || echo "http"
        echo "$PORT_SUFFIX"
    } > /etc/tendo_bot/panel_domain
}

# ── Setup Panel (Username, Password, Domain) ─────────────────────────
function panel_setup_menu() {
    clear
    IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
    DOMAIN_VPS=$(cat /usr/local/etc/xray/domain 2>/dev/null)
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_center "SETUP WEB PANEL ADMIN"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    print_line " IP VPS    : ${IP_VPS}"
    print_line " Domain    : ${DOMAIN_VPS:-belum diatur}"
    print_line " Port HTTP : http://${IP_VPS}:8181"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo
    # --- Username
    read -p " Username Admin : " PADMIN
    [[ -z "$PADMIN" ]] && echo -e "${RED} Username tidak boleh kosong!${NC}" && sleep 2 && return
    # --- Password
    while true; do
        read -s -p " Password (min 6 karakter) : " PPASS; echo
        [[ ${#PPASS} -lt 6 ]] && echo -e "${RED} Password minimal 6 karakter!${NC}" && continue
        read -s -p " Konfirmasi Password       : " PPASS2; echo
        [[ "$PPASS" != "$PPASS2" ]] && echo -e "${RED} Password tidak cocok!${NC}" && continue
        break
    done
    # --- Simpan kredensial
    PSALT=$(openssl rand -hex 8)
    PHASH=$(echo -n "${PSALT}${PPASS}" | sha256sum | awk '{print $1}')
    PSECRET=$(openssl rand -hex 32)
    mkdir -p /etc/tendo_bot
    echo "${PADMIN}:${PSALT}:${PHASH}:8181:${PSECRET}" > /etc/tendo_bot/panel.conf
    chmod 600 /etc/tendo_bot/panel.conf
    # --- Domain otomatis mengikuti domain Xray (tidak perlu input manual)
    FINAL_URL="http://${IP_VPS}:8181"
    if [[ -n "$DOMAIN_VPS" ]]; then
        setup_panel_nginx "$DOMAIN_VPS" "yes"
        _PDOM_PROTO=$(sed -n '2p' /etc/tendo_bot/panel_domain 2>/dev/null)
        _PDOM_SUFFIX=$(sed -n '3p' /etc/tendo_bot/panel_domain 2>/dev/null)
        FINAL_URL="${_PDOM_PROTO:-https}://${DOMAIN_VPS}${_PDOM_SUFFIX}"
    fi
    systemctl restart xpanel >/dev/null 2>&1
    echo
    echo -e "${GREEN} ┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN} │           [OK] Setup Panel Berhasil!           │${NC}"
    echo -e "${GREEN} └─────────────────────────────────────────────────┘${NC}"
    echo -e "${CYAN} URL Utama : ${WHITE}${FINAL_URL}${NC}"
    echo -e "${CYAN} URL Cadgn : http://${IP_VPS}:8181${NC}"
    echo -e "${CYAN} Username  : ${PADMIN}${NC}"
    sleep 4
}

# ── Panel Management Menu ─────────────────────────────────────────────
function panel_menu() {
    while true; do
        clear
        IP_VPS=$(cat /root/tendo/ip 2>/dev/null)
        PANEL_STATUS=$(systemctl is-active xpanel 2>/dev/null)
        PANEL_CONF="/etc/tendo_bot/panel.conf"
        PANEL_DOM_FILE="/etc/tendo_bot/panel_domain"
        PANEL_USER="-"
        [[ -f "$PANEL_CONF" ]] && PANEL_USER=$(cut -d: -f1 "$PANEL_CONF")
        # Baca domain, protokol, dan port_suffix dari file
        PANEL_DOM=""; PANEL_PROTO="http"; PANEL_PORT_SUFFIX=""
        if [[ -f "$PANEL_DOM_FILE" ]]; then
            PANEL_DOM=$(sed -n '1p' "$PANEL_DOM_FILE")
            PANEL_PROTO=$(sed -n '2p' "$PANEL_DOM_FILE")
            PANEL_PORT_SUFFIX=$(sed -n '3p' "$PANEL_DOM_FILE")
        fi
        if [[ -n "$PANEL_DOM" ]]; then
            URL_MAIN="${PANEL_PROTO}://${PANEL_DOM}${PANEL_PORT_SUFFIX}"
        else
            URL_MAIN="http://${IP_VPS}:8181"
        fi
        if [[ "$PANEL_STATUS" == "active" ]]; then
            ST_TEXT="${GREEN}AKTIF${NC}"
        else
            ST_TEXT="${RED}MATI${NC}"
        fi
        echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
        print_center "WEB PANEL ADMIN"
        echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│${NC} Status  : $(echo -e $ST_TEXT)$(printf '%*s' $((37 - ${#PANEL_STATUS})) '')${CYAN}│${NC}"
        print_line " URL      : ${URL_MAIN}"
        [[ -n "$PANEL_DOM" ]] && print_line " Cadangan : http://${IP_VPS}:8181"
        print_line " Login    : ${PANEL_USER}"
        echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
        print_line " [1] Setup Ulang Username & Password"
        print_line " [2] Start Panel"
        print_line " [3] Stop Panel"
        print_line " [4] Restart Panel"
        print_line " [5] Lihat Status & Log Panel"
        print_line " [x] Kembali"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        read -p " Pilih : " opt
        case $opt in
            1) panel_setup_menu ;;
            2) systemctl start xpanel >/dev/null 2>&1
               echo -e "${GREEN} [OK] Panel distart.${NC}"; sleep 2 ;;
            3) systemctl stop xpanel >/dev/null 2>&1
               echo -e "${YELLOW} Panel dihentikan.${NC}"; sleep 2 ;;
            4) systemctl restart xpanel >/dev/null 2>&1
               echo -e "${GREEN} [OK] Panel di-restart.${NC}"; sleep 2 ;;
            5) clear
               echo -e "${CYAN}=== STATUS XPANEL SERVICE ===${NC}"
               systemctl status xpanel --no-pager -l 2>&1 | head -30
               echo
               echo -e "${CYAN}=== LOG TERBARU ===${NC}"
               journalctl -u xpanel --no-pager -n 20 2>/dev/null
               echo
               if command -v nginx &>/dev/null; then
                   echo -e "${CYAN}=== STATUS NGINX ===${NC}"
                   systemctl status nginx --no-pager | head -10
               fi
               read -p " Tekan Enter untuk lanjut..." ;;
            x) return ;;
        esac
    done
}

while true; do header_main
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    print_line " [1] SSH ACCOUNT          [4] FEATURES"
    print_line " [2] X-RAY MANAGER        [5] WEB PANEL"
    print_line " [3] ZIVPN UDP            [x] EXIT"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    read -p " Select Menu : " opt
    case $opt in
        1) ssh_menu ;;
        2) xray_manager_menu ;;
        3) zivpn_menu ;;
        4) features_menu ;;
        5) panel_menu ;;
        x) exit ;;
    esac; done
END_MENU
chmod +x /usr/bin/menu
)
print_ok "Finalisasi Script"

echo -e "\n${GREEN}=================================================${NC}"
if [[ "$INSTALL_MODE" == "update" ]]; then
    echo -e "${GREEN}   [OK] Update Script Selesai!${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e " Yang diperbarui:"
    echo -e "  ${GREEN}+${NC} /usr/bin/menu        (CLI menu)"
    echo -e "  ${GREEN}+${NC} /usr/local/bin/xpanel.py  (Web panel)"
    echo -e "  ${GREEN}+${NC} xpanel.service       (Web panel service)"
    echo -e "  ${GREEN}+${NC} xray-exp/limit/quota (Cron scripts)"
    echo -e "  ${GREEN}+${NC} bot-login-notif/backup (Bot scripts)"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e " Data akun ${GREEN}TIDAK BERUBAH${NC}"
    echo -e " Ketik: ${WHITE}menu${NC} untuk mulai"
elif [[ "$INSTALL_MODE" == "reinstall" ]]; then
    echo -e "${GREEN}   [OK] Full Reinstall Selesai!${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW} [!] Data akun lama sudah di-backup.${NC}"
    echo -e " Untuk restore data lama, jalankan di server:"
    echo -e "  ${WHITE}ls /root/backup_vps_*.zip${NC}  (cek file backup)"
    echo -e "  ${WHITE}cd / && unzip -o /root/backup_vps_TANGGAL.zip${NC}"
    echo -e "  ${WHITE}systemctl restart xray zivpn${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e " Ketik: ${WHITE}menu${NC} untuk mulai"
else
    echo -e "${YELLOW}   Instalasi Selesai! Ketik: ${WHITE}menu${YELLOW} untuk mulai  ${NC}"
fi
echo -e "${GREEN}=================================================${NC}\n"
