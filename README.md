# HomeAssistantDeploy
# Home Assistant Installation Script

## Opis

Ten skrypt automatycznie instaluje Home Assistant z obsługą ZigBee oraz dodatkowymi serwisami na różnych urządzeniach z systemem Linux (np. Intel NUC, ODROID-N2+, Rock Pi 4). Skrypt jest zaprojektowany tak, aby działał na różnych dystrybucjach Linuxa, takich jak Ubuntu, Debian i Fedora.

## Funkcje

- Automatyczna detekcja dystrybucji Linuxa.
- Instalacja zależności niezbędnych do działania Home Assistant.
- Konfiguracja zapory sieciowej.
- Tworzenie dedykowanego użytkownika dla Home Assistant.
- Instalacja Home Assistant jako usługi systemd.
- Instalacja i konfiguracja Zigbee2MQTT.
- Instalacja i konfiguracja Node-RED.
- Instalacja i konfiguracja MQTT Broker (Mosquitto).
- Instalacja HACS (Home Assistant Community Store).
- Instalacja i konfiguracja Google Backup.
- Instalacja i konfiguracja Cloudflared.
- Instalacja i konfiguracja Speedtest.
- Instalacja i konfiguracja EWeLink Sonoff.
- Automatyczne aktualizacje systemu i oprogramowania.
- Tworzenie backupów systemu.
- Logowanie procesu instalacji.

## Wymagania Systemowe

- **Procesor:** ARM lub x86_64, minimum czterordzeniowy.
- **Pamięć RAM:** Minimum 4 GB (zalecane 8 GB).
- **Pamięć masowa:** SSD o pojemności minimum 32 GB.
- **Łączność:** Stabilne połączenie sieciowe (Ethernet lub Wi-Fi).
- **ZigBee USB Dongle:** (np. ConBee II, CC2531).

## Instalacja

1. **Pobierz skrypt:**

   ```bash
   git clone https://github.com/twoj-uzytkownik/home-assistant-install.git
   cd home-assistant-install
   ```

2. **Nadaj uprawnienia do wykonania:**

   ```bash
   chmod +x install_home_assistant.sh
   ```

3. **Uruchom skrypt jako root:**

   ```bash
   sudo ./install_home_assistant.sh
   ```

4. **Postępuj zgodnie z instrukcjami wyświetlanymi na ekranie.**

## Konfiguracja ZigBee USB Dongle

Po instalacji, upewnij się, że Twój ZigBee USB Dongle jest prawidłowo podłączony. Możesz to zrobić, sprawdzając dostępne urządzenia:

```bash
ls /dev/tty*
```

Wprowadź ścieżkę do swojego dongle podczas konfiguracji skryptu.

## Konfiguracja Dodatkowych Serwisów

### **HACS (Home Assistant Community Store)**

1. **Dodaj HACS do Home Assistant:**

   - Przejdź do `http://<IP_SERWERA>:8123`.
   - Zaloguj się do swojego konta Home Assistant.
   - Przejdź do `Supervisor` > `Add-on Store`.
   - Kliknij na `HACS` i postępuj zgodnie z instrukcjami konfiguracji.

### **Google Backup**

1. **Skonfiguruj rclone:**

   - Uruchom konfigurację rclone:

     ```bash
     rclone config
     ```

   - Postępuj zgodnie z instrukcjami, aby połączyć rclone z Google Drive.

### **Cloudflared**

1. **Skonfiguruj Cloudflared:**

   - Przejdź do [Cloudflare Dashboard](https://dash.cloudflare.com/) i skonfiguruj tunel dla swojego serwera Home Assistant.
   - Postępuj zgodnie z instrukcjami, aby połączyć Cloudflared z Cloudflare.

### **EWeLink Sonoff**

1. **Skonfiguruj EWeLink w Home Assistant:**

   - Przejdź do `http://<IP_SERWERA>:8123`.
   - Przejdź do `Configuration` > `Integrations`.
   - Dodaj integrację `EWeLink Sonoff` i postępuj zgodnie z instrukcjami.

## Aktualizacje

Skrypt konfiguruje automatyczne aktualizacje systemu i Home Assistant. Możesz ręcznie zaktualizować Home Assistant za pomocą:

```bash
sudo systemctl restart home-assistant.service
```

## Backup

Backupy systemu są tworzone automatycznie po instalacji. Możesz je znaleźć w katalogu `/srv/` z prefiksem `home_assistant_backup_`.

## Wsparcie

Jeśli napotkasz problemy podczas instalacji, prosimy o otwarie issue na [GitHubie](https://github.com/twoj-uzytkownik/home-assistant-install/issues).

## Licencja

Ten projekt jest licencjonowany na zasadach licencji MIT - zobacz plik [LICENSE](LICENSE) po więcej informacji.
