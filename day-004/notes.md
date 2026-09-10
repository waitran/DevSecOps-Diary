# 📝 День 4 — SSH, systemd, сервисы и логи

---

## 1. SSH (Secure Shell)

### Что это
Стандарт безопасного удалённого доступа к серверам. Работает поверх TCP, порт **22**.

### Аутентификация: Пароль vs Ключи

| Метод | Безопасность | Комментарий |
|---|---|---|
| **Пароль** | ❌ Низкая | Брутфорс за минуты. **Запрещён в продакшене.** |
| **SSH-ключи** | ✅ Высокая | Public Key Cryptography. Стандарт DevSecOps. |

### SSH-ключи (Public Key Cryptography)

Генерация ключа (современный алгоритм):
```bash
ssh-keygen -t ed25519 -C "email@example.com"
```

Результат:
* `~/.ssh/id_ed25519` — **приватный** ключ (никому не показывай!)
* `~/.ssh/id_ed25519.pub` — **публичный** ключ (кладётся на сервер)

### Права на SSH-файлы (критично!)

| Файл | Права | Почему |
|---|---|---|
| `~/.ssh/` | `700` (`drwx------`) | Только владелец может входить |
| `id_ed25519` (приватный) | `600` (`-rw-------`) | Только владелец читает |
| `id_ed25519.pub` (публичный) | `644` (`-rw-r--r--`) | Можно читать всем |
| `known_hosts` | `600` | Защита от MITM-атак |

⚠️ Если права на приватный ключ не `600`, SSH **откажется его использовать**.

### Подключение по SSH
```bash
ssh user@host                # Подключение по имени/IP
ssh user@localhost           # Подключение к самому себе
ssh -p 2222 user@host        # Нестандартный порт
exit                         # Выйти из SSH-сессии
```

### Конфигурация SSH-сервера
Файл: `/etc/ssh/sshd_config` (с буквой **d** = daemon)

**Best practices безопасности:**
```text
PasswordAuthentication no    # Запретить вход по паролю
PermitRootLogin no           # Запретить прямой вход под root
Port 22                      # (Опционально) Сменить порт
```

⚠️ Не путай файлы:
* `ssh_config` (без d) — конфиг **клиента** (когда ты подключаешься)
* `sshd_config` (с d) — конфиг **сервера** (когда к тебе подключаются)

После изменений:
```bash
sudo systemctl restart ssh
```

---

## 2. systemd и управление сервисами

### Что это
`systemd` — система инициализации и менеджер сервисов в современном Linux. PID 1. Запускает всё при загрузке.

### Основная команда: `systemctl`

| Команда | Что делает |
|---|---|
| `sudo systemctl status <service>` | Статус, PID, последние логи |
| `sudo systemctl start <service>` | Запустить **прямо сейчас** |
| `sudo systemctl stop <service>` | Остановить |
| `sudo systemctl restart <service>` | Перезапустить (применить новые конфиги) |
| `sudo systemctl enable <service>` | Добавить в **автозагрузку** |
| `sudo systemctl disable <service>` | Убрать из автозагрузки |
| `sudo systemctl is-enabled <service>` | Проверить, в автозагрузке ли |
| `sudo systemctl is-active <service>` | Проверить, активен ли сейчас |
| `sudo systemctl daemon-reload` | Перечитать конфиги после изменений |

### Разница `start` vs `enable`

| Команда | Действие | Когда сработает |
|---|---|---|
| `start` | Запустить сейчас | Немедленно |
| `enable` | Добавить в автозагрузку | При следующей загрузке |
| `start` + `enable` | Полная настройка | И сейчас, и в будущем |

### Создание своего systemd-сервиса

**Шаг 1.** Создай скрипт-демон:
```bash
nano ~/my_daemon.sh
```
```bash
#!/bin/bash
while true; do
    echo "$(date): Daemon is running" >> /tmp/my_daemon.log
    sleep 60
done
```
```bash
chmod +x ~/my_daemon.sh
```

**Шаг 2.** Создай юнит-файл:
```bash
sudo nano /etc/systemd/system/my-daemon.service
```
```ini
[Unit]
Description=My Custom DevSecOps Daemon
After=network.target

[Service]
ExecStart=/home/danil/my_daemon.sh
Restart=always
User=danil

[Install]
WantedBy=multi-user.target
```

**Шаг 3.** Активируй и запусти:
```bash
sudo systemctl daemon-reload          # Сообщить systemd о новом файле
sudo systemctl enable my-daemon       # В автозагрузку
sudo systemctl start my-daemon        # Запустить сейчас
sudo systemctl status my-daemon       # Проверить
```

### Где лежат юнит-файлы
* `/lib/systemd/system/` — системные сервисы (не трогать)
* `/etc/systemd/system/` — пользовательские сервисы (наши)

### Частые ошибки systemd

| Код ошибки | Причина | Решение |
|---|---|---|
| **203/EXEC** | Не может выполнить скрипт | `chmod +x`, проверить shebang `#!/bin/bash` |
| **200/CHDIR** | Неверная рабочая директория | Добавить `WorkingDirectory=` в `.service` |
| **217/USER** | Пользователь не существует | Проверить `User=` в `.service` |

---

## 3. Логи (Журналирование)

### `journalctl` — современный инструмент

```bash
sudo journalctl -u ssh                        # Все логи сервиса ssh
sudo journalctl -u ssh -n 15                  # Последние 15 строк
sudo journalctl -u ssh --since "1 hour ago"   # За последний час
sudo journalctl -u ssh -f                     # Follow (в реальном времени)
sudo journalctl -p err                        # Только ошибки
sudo journalctl -u my-daemon --no-pager       # Без постраничного вывода
```

### Классические файлы логов (`/var/log/`)

| Файл | Что хранит |
|---|---|
| `/var/log/auth.log` | **Аутентификация, SSH, sudo** (самый важный для безопасности!) |
| `/var/log/syslog` | Общие системные сообщения |
| `/var/log/dmesg` | Логи ядра (аппаратные ошибки, OOM Killer) |
| `/var/log/kern.log` | Только ядро |

### Поиск подозрительной активности

```bash
# Неудачные попытки входа (брутфорс)
sudo grep "Failed password" /var/log/auth.log

# Успешные входы по ключу
sudo grep "Accepted publickey" /var/log/auth.log

# Подсчёт атак по IP
sudo grep "Failed password" /var/log/auth.log | \
    grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn

# Количество ошибок
sudo grep -c "Failed password" /var/log/auth.log
```

### OOM Killer
Если в `/var/log/dmesg` видишь:
```text
Out of memory: Kill process ...
```
→ Приложению не хватило RAM, ядро Linux убило его.

---

## 4. DevSecOps контекст

| Тема | Применение |
|---|---|
| **SSH** | Только ключи, запрет паролей, запрет root. Вектор атаки №1 |
| **systemd** | Least Privilege — запускать сервисы от отдельного пользователя, не от root |
| **Логи** | Поиск следов взлома, SIEM-системы (Filebeat, Fluentd → Elasticsearch/Loki) |
| **OOM Killer** | Мониторинг утечек памяти в приложениях/контейнерах |

---

## 5. Полезные команды дня

```bash
# SSH
ssh-keygen -t ed25519 -C "comment"
ssh user@host
sudo nano /etc/ssh/sshd_config

# systemd
sudo systemctl status <service>
sudo systemctl start/stop/restart <service>
sudo systemctl enable/disable <service>
sudo systemctl is-enabled/is-active <service>
sudo systemctl daemon-reload

# Логи
sudo journalctl -u <service>
sudo journalctl -u <service> -f
sudo journalctl -u <service> --since "1 hour ago"
sudo grep "Failed password" /var/log/auth.log
sudo tail -n 20 /var/log/auth.log
```

---

## 6. Практика (выполнено)

- [x] Проверены права на SSH-ключи (`600` для приватного, `644` для публичного)
- [x] Изучен конфиг `/etc/ssh/sshd_config`
- [x] Установлен `openssh-server`
- [x] Создан свой systemd-сервис `my-daemon.service`
- [x] Написан скрипт аудита логов `check_auth_logs.sh`
- [x] Разобраны ошибки `203/EXEC` и `Connection refused`

---

## 7. Definition of Done (Критерий завершения)

День считается закрытым, если ты можешь ответить:
1. Почему в продакшене запрещена аутентификация по паролю в SSH?
2. В чём разница между `systemctl start` и `systemctl enable`?
3. Какую команду введёшь, чтобы посмотреть логи `nginx` за последние 30 минут?
4. Где в Linux хранятся логи неудачных попыток входа по SSH?
5. Что означает код ошибки `203/EXEC` в systemd?

---

