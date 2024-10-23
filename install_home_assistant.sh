#!/bin/bash

# ==========================================
# Skrypt instalacyjny dla Home Assistant z ZigBee i dodatkowymi serwisami
# ==========================================

# Autor: Twoje Imię
# Data: 2024-10-23
# Licencja: MIT

# Funkcje pomocnicze
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/home_assistant_install.log
}

error_exit() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a /var/log/home_assistant_install.log
    exit 1
}

# Sprawdzenie uprawnień root
if [ "$EUID" -ne 0 ]; then
    error_exit "Skrypt musi być uruchomiony jako root."
fi

log "Rozpoczynanie instalacji Home Assistant z dodatkowymi serwisami."

# Detekcja dystrybucji Linuxa
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        error_exit "Nie można wykryć dystrybucji Linuxa."
    fi
}

detect_distro
log "Wykryta dystrybucja: $DISTRO $VERSION."

# Aktualizacja systemu
update_system() {
    case "$DISTRO" in
        ubuntu|debian)
            apt update && apt upgrade -y
            ;;
        fedora)
            dnf upgrade --refresh -y
            ;;
        *)
            error_exit "Dystrybucja $DISTRO nie jest obsługiwana."
            ;;
    esac
}

update_system
log "System zaktualizowany pomyślnie."

# Instalacja zależności
install_dependencies() {
    case "$DISTRO" in
        ubuntu|debian)
            apt install -y python3 python3-venv python3-pip git curl ufw npm nodejs npm mosquitto mosquitto-clients
            ;;
        fedora)
            dnf install -y python3 python3-venv python3-pip git curl ufw npm nodejs mosquitto mosquitto-clients
            ;;
        *)
            error_exit "Dystrybucja $DISTRO nie jest obsługiwana."
            ;;
    esac
}

install_dependencies
log "Zależności zainstalowane pomyślnie."

# Konfiguracja zapory sieciowej
configure_firewall() {
    case "$DISTRO" in
        ubuntu|debian)
            ufw allow 8123/tcp    # Home Assistant
            ufw allow 1883/tcp    # MQTT
            ufw allow 1880/tcp    # Node-RED
            ufw allow 8443/tcp    # Cloudflared
            ufw allow 9000/tcp    # Speedtest
            ufw --force enable
            ;;
        fedora)
            firewall-cmd --permanent --add-port=8123/tcp
            firewall-cmd --permanent --add-port=1883/tcp
            firewall-cmd --permanent --add-port=1880/tcp
            firewall-cmd --permanent --add-port=8443/tcp
            firewall-cmd --permanent --add-port=9000/tcp
            firewall-cmd --reload
            ;;
        *)
            error_exit "Dystrybucja $DISTRO nie jest obsługiwana."
            ;;
    esac
    log "Zapora sieciowa skonfigurowana pomyślnie."
}

configure_firewall

# Tworzenie użytkownika dla Home Assistant
create_user() {
    if id "ha_user" &>/dev/null; then
        log "Użytkownik ha_user już istnieje."
    else
        useradd -rm -d /srv/homeassistant -s /bin/bash -g sudo -G dialout,cdrom,plugdev,tty,video ha_user
        log "Użytkownik ha_user utworzony pomyślnie."
    fi
}

create_user

# Instalacja Home Assistant
install_home_assistant() {
    sudo -u ha_user -H bash -c " \
        python3 -m venv /srv/homeassistant \
        && source /srv/homeassistant/bin/activate \
        && pip install --upgrade pip \
        && pip install homeassistant \
        && hass --init"
    log "Home Assistant zainstalowany pomyślnie."
}

install_home_assistant

# Instalacja Docker (opcjonalnie)
install_docker() {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ha_user
    rm get-docker.sh
    log "Docker zainstalowany i skonfigurowany pomyślnie."
}

install_docker

# Instalacja Zigbee2MQTT
install_zigbee2mqtt() {
    sudo -u ha_user -H bash -c " \
        mkdir -p /srv/zigbee2mqtt \
        && cd /srv/zigbee2mqtt \
        && git clone https://github.com/Koenkk/zigbee2mqtt.git \
        && cd zigbee2mqtt \
        && npm ci --production"
    log "Zigbee2MQTT zainstalowany pomyślnie."
}

install_zigbee2mqtt

# Konfiguracja ZigBee USB Dongle
configure_zigbee_dongle() {
    # Przykład dla ConBee II
    echo "CONFIGURATION: Proszę podłączyć ZigBee USB Dongle i sprawdzić jego nazwę urządzenia (np. /dev/ttyACM0)."
    read -p "Podaj ścieżkę do ZigBee USB Dongle (domyślnie /dev/ttyACM0): " DONGLE_PATH
    DONGLE_PATH=${DONGLE_PATH:-/dev/ttyACM0}

    sudo -u ha_user -H bash -c " \
        cd /srv/zigbee2mqtt/zigbee2mqtt \
        && cp data/configuration.yaml.example data/configuration.yaml \
        && sed -i 's|^# \?uart:|uart:|' data/configuration.yaml \
        && sed -i 's|port: .*|port: $DONGLE_PATH|' data/configuration.yaml"

    log "ZigBee USB Dongle skonfigurowany na $DONGLE_PATH."
}

configure_zigbee_dongle

# Instalacja i konfiguracja MQTT (Mosquitto)
install_mosquitto() {
    systemctl enable mosquitto
    systemctl start mosquitto
    log "MQTT Broker (Mosquitto) zainstalowany i uruchomiony."
}

install_mosquitto

# Instalacja Node-RED
install_node_red() {
    sudo -u ha_user -H bash -c " \
        npm install -g --unsafe-perm node-red"
    log "Node-RED zainstalowany pomyślnie."

    # Tworzenie usługi systemd dla Node-RED
    cat <<EOF >/etc/systemd/system/node-red.service
[Unit]
Description=Node-RED
After=network.target

[Service]
Type=simple
User=ha_user
ExecStart=/usr/bin/env node-red
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable node-red.service
    systemctl start node-red.service
    log "Usługa Node-RED utworzona i uruchomiona pomyślnie."
}

install_node_red

# Instalacja HACS (Home Assistant Community Store)
install_hacs() {
    sudo -u ha_user -H bash -c " \
        mkdir -p /home/ha_user/.homeassistant/custom_components \
        && git clone https://github.com/hacs/integration.git /home/ha_user/.homeassistant/custom_components/hacs"
    log "HACS zainstalowany pomyślnie."
}

install_hacs

# Instalacja Google Backup
install_google_backup() {
    # Instalacja rclone
    curl https://rclone.org/install.sh | bash
    log "rclone zainstalowany pomyślnie."

    # Konfiguracja rclone dla Google Drive
    sudo -u ha_user -H bash -c " \
        rclone config file \
        && rclone config create google_drive drive \
        && echo 'Proszę skonfigurować rclone do Google Drive ręcznie.'"
    
    log "Proszę skonfigurować rclone do Google Drive ręcznie, wykonując 'rclone config'."
}

install_google_backup

# Instalacja Cloudflared
install_cloudflared() {
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
    systemctl enable cloudflared
    systemctl start cloudflared
    log "Cloudflared zainstalowany i uruchomiony pomyślnie."
}

install_cloudflared

# Instalacja Speedtest
install_speedtest() {
    npm install -g speedtest-net
    log "Speedtest zainstalowany pomyślnie."

    # Tworzenie usługi systemd dla Speedtest
    cat <<EOF >/etc/systemd/system/speedtest.service
[Unit]
Description=Speedtest
After=network.target

[Service]
Type=simple
User=ha_user
ExecStart=/usr/bin/env speedtest-net --json > /srv/speedtest.json
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable speedtest.service
    systemctl start speedtest.service
    log "Usługa Speedtest utworzona i uruchomiona pomyślnie."
}

install_speedtest

# Instalacja EWeLink Sonoff
install_ewelink_sonoff() {
    sudo -u ha_user -H bash -c " \
        mkdir -p /srv/ewelink_sonoff \
        && cd /srv/ewelink_sonoff \
        && git clone https://github.com/AlexxIT/EWeLink.git \
        && cd EWeLink \
        && pip install -r requirements.txt"
    log "EWeLink Sonoff zainstalowany pomyślnie."
}

install_ewelink_sonoff

# Ustawienie automatycznych aktualizacji
setup_auto_updates() {
    case "$DISTRO" in
        ubuntu|debian)
            apt install -y unattended-upgrades
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        fedora)
            dnf install -y dnf-automatic
            systemctl enable --now dnf-automatic.timer
            ;;
    esac
    log "Automatyczne aktualizacje skonfigurowane pomyślnie."
}

setup_auto_updates

# Tworzenie usługi systemd dla Home Assistant
create_home_assistant_service() {
    cat <<EOF >/etc/systemd/system/home-assistant.service
[Unit]
Description=Home Assistant
After=network.target

[Service]
Type=simple
User=ha_user
WorkingDirectory=/srv/homeassistant
ExecStart=/srv/homeassistant/bin/hass -c "/home/ha_user/.homeassistant"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable home-assistant.service
    systemctl start home-assistant.service
    log "Usługa Home Assistant utworzona i uruchomiona pomyślnie."
}

create_home_assistant_service

# Tworzenie usługi systemd dla Zigbee2MQTT
create_zigbee2mqtt_service() {
    cat <<EOF >/etc/systemd/system/zigbee2mqtt.service
[Unit]
Description=Zigbee2MQTT
After=network.target

[Service]
Type=simple
User=ha_user
WorkingDirectory=/srv/zigbee2mqtt/zigbee2mqtt
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zigbee2mqtt.service
    systemctl start zigbee2mqtt.service
    log "Usługa Zigbee2MQTT utworzona i uruchomiona pomyślnie."
}

create_zigbee2mqtt_service

# Tworzenie usługi systemd dla HACS (opcjonalnie)
create_hacs_service() {
    # HACS integruje się bezpośrednio z Home Assistant, więc dodatkowa usługa nie jest wymagana.
    log "HACS zintegrowany bezpośrednio z Home Assistant."
}

create_hacs_service

# Tworzenie backupu systemu
create_backup() {
    tar -czvf /srv/home_assistant_backup_$(date '+%Y%m%d').tar.gz /srv/homeassistant /srv/zigbee2mqtt /srv/node-red /srv/ewelink_sonoff
    log "Backup systemu utworzony pomyślnie."
}

create_backup

# Testowanie instalacji
test_installation() {
    services=("home-assistant.service" "zigbee2mqtt.service" "node-red.service" "speedtest.service" "cloudflared.service")

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "$service działa poprawnie."
        else
            error_exit "$service nie działa poprawnie."
        fi
    done

    log "Wszystkie usługi działają poprawnie."
}

test_installation

log "Instalacja zakończona pomyślnie. Home Assistant jest dostępny pod adresem http://<IP_SERWERA>:8123"
