# 📋 День 4 — Шпаргалка команд (Cheat Sheet)

---

## 🔐 SSH

### Генерация ключей
```bash
ssh-keygen -t ed25519 -C "email@example.com"   # Современный алгоритм
ssh-keygen -t rsa -b 4096 -C "email@example.com"  # Старый (RSA)
```

### Проверка прав на SSH-файлы
```bash
ls -la ~/.ssh/
ls -la ~/.ssh/id_ed25519        # Должно быть 600
ls -la ~/.ssh/id_ed25519.pub    # Должно быть 644
```

### Исправление прав (если сломаны)
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/known_hosts
```

### Подключение
```bash
ssh user@host                   # Базовое подключение
ssh user@localhost              # К самому себе
ssh -p 2222 user@host           # Нестандартный порт
ssh -i ~/.ssh/my_key user@host  # С конкретным ключом
ssh -v user@host                # Verbose (для отладки)
exit                            # Выйти из сессии
```

### Конфигурация сервера
```bash
sudo nano /etc/ssh/sshd_config  # Конфиг SSH-сервера (с буквой d)
sudo nano /etc/ssh/ssh_config   # Конфиг SSH-клиента (без d)
sudo systemctl restart ssh      # Применить изменения
```

---

## ⚙️ systemd — Управление сервисами

### Базовые команды
```bash
sudo systemctl status <service>     # Статус (Active, PID, логи)
sudo systemctl start <service>      # Запустить сейчас
sudo systemctl stop <service>       # Остановить
sudo systemctl restart <service>    # Перезапустить
sudo systemctl reload <service>     # Перечитать конфиги без остановки
```

### Автозагрузка
```bash
sudo systemctl enable <service>     # Добавить в автозагрузку
sudo systemctl disable <service>    # Убрать из автозагрузки
sudo systemctl is-enabled <service> # Проверить статус автозагрузки
sudo systemctl is-active <service>  # Проверить, активен ли сейчас
```

### После изменений в .service файлах
```bash
sudo systemctl daemon-reload        # Перечитать конфигурации
sudo systemctl restart <service>    # Применить изменения
```

### Создание своего сервиса
```bash
sudo nano /etc/systemd/system/my-service.service
```
```ini
[Unit]
Description=My Service
After=network.target

[Service]
ExecStart=/path/to/script.sh
Restart=always
User=username
WorkingDirectory=/path/to/workdir

[Install]
WantedBy=multi-user.target
```

### Полезные проверки
```bash
systemctl list-units --type=service       # Все сервисы
systemctl list-unit-files --type=service  # Все юнит-файлы
systemctl --failed                        # Упавшие сервисы
```

---

## 📊 journalctl — Логи systemd

### Базовые команды
```bash
sudo journalctl -u <service>                  # Все логи сервиса
sudo journalctl -u <service> -n 20            # Последние 20 строк
sudo journalctl -u <service> -f               # Follow (в реальном времени)
sudo journalctl -u <service> --since "1 hour ago"  # За последний час
sudo journalctl -u <service> --since today    # С начала дня
sudo journalctl -u <service> --since "2026-09-10" --until "2026-09-11"
sudo journalctl -u <service> --no-pager       # Без постраничного вывода
sudo journalctl -u <service> -r               # В обратном порядке (новые сверху)
```

### Фильтрация по приоритету
```bash
sudo journalctl -p err                        # Только ошибки
sudo journalctl -p warning                    # Warnings и ошибки
sudo journalctl -p info                       # Info и выше
# Приоритеты: emerg, alert, crit, err, warning, notice, info, debug
```

### Для конкретного процесса
```bash
sudo journalctl _PID=1234                     # По PID
sudo journalctl _COMM=nginx                   # По имени команды
sudo journalctl _SYSTEMD_UNIT=ssh.service     # По юниту
```

---

## 📁 Классические логи (`/var/log/`)

### Основные файлы
```bash
sudo tail -n 50 /var/log/auth.log             # Последние 50 строк логов аутентификации
sudo tail -f /var/log/auth.log                # Следить в реальном времени
sudo cat /var/log/syslog | tail -n 20         # Системные логи
sudo dmesg | tail -n 20                       # Логи ядра
sudo dmesg -T | tail -n 20                    # Логи ядра с читаемыми датами
```

### Поиск в логах
```bash
# Неудачные попытки входа (брутфорс)
sudo grep "Failed password" /var/log/auth.log

# Успешные входы по ключу
sudo grep "Accepted publickey" /var/log/auth.log

# Успешные входы по паролю
sudo grep "Accepted password" /var/log/auth.log

# Использование sudo
sudo grep "sudo:" /var/log/auth.log

# Подсчёт неудачных попыток
sudo grep -c "Failed password" /var/log/auth.log

# Атаки по IP (топ-10)
sudo grep "Failed password" /var/log/auth.log | \
    grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head

# OOM Killer (нехватка памяти)
sudo grep -i "out of memory" /var/log/dmesg
sudo dmesg | grep -i "killed process"
```

---

## 🔧 Диагностика частых ошибок

### SSH: Connection refused
```bash
sudo systemctl status ssh          # Проверить статус
sudo systemctl start ssh           # Запустить
sudo ss -tuln | grep :22           # Проверить, слушается ли порт 22
```

### SSH: Permission denied (publickey)
```bash
ls -la ~/.ssh/id_ed25519           # Права должны быть 600
ssh-add -l                         # Проверить, загружен ли ключ в ssh-agent
ssh-add ~/.ssh/id_ed25519          # Добавить ключ в ssh-agent
```

### systemd: 203/EXEC (не может выполнить скрипт)
```bash
ls -la /path/to/script.sh          # Проверить права (нужен +x)
head -n 1 /path/to/script.sh       # Проверить shebang (#!/bin/bash)
chmod +x /path/to/script.sh        # Сделать исполняемым
sudo systemctl daemon-reload       # Перечитать конфиги
```

### systemd: сервис падает сразу после запуска
```bash
sudo systemctl status <service> -l              # Детальный статус
sudo journalctl -u <service> -n 50 --no-pager   # Последние 50 строк логов
```

### Проверка, что порт слушается
```bash
sudo ss -tuln | grep :22           # TCP-порты
sudo ss -tulnp | grep :22          # С информацией о процессе
sudo lsof -i :22                   # Альтернатива ss
```

---

## 🎯 Быстрые сценарии

### Сценарий 1: "SSH не работает"
```bash
sudo systemctl status ssh
sudo systemctl start ssh
sudo ss -tuln | grep :22
sudo journalctl -u ssh -n 20
```

### Сценарий 2: "Кто ломится на сервер?"
```bash
sudo grep "Failed password" /var/log/auth.log | tail -n 20
sudo grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn
```

### Сценарий 3: "Сервис упал, почему?"
```bash
sudo systemctl status <service>
sudo journalctl -u <service> -n 50 --no-pager
sudo journalctl -u <service> -p err
```

### Сценарий 4: "Создать новый сервис"
```bash
# 1. Создать скрипт
nano ~/my_script.sh
chmod +x ~/my_script.sh

# 2. Создать юнит
sudo nano /etc/systemd/system/my-service.service

# 3. Активировать
sudo systemctl daemon-reload
sudo systemctl enable my-service
sudo systemctl start my-service
sudo systemctl status my-service
```

---

## 📌 Запомнить навсегда

| Задача | Команда |
|---|---|
| Сгенерировать SSH-ключ | `ssh-keygen -t ed25519` |
| Права на приватный ключ | `chmod 600 ~/.ssh/id_ed25519` |
| Запустить сервис | `sudo systemctl start <service>` |
| Добавить в автозагрузку | `sudo systemctl enable <service>` |
| Посмотреть логи сервиса | `sudo journalctl -u <service> -f` |
| Найти брутфорс | `sudo grep "Failed password" /var/log/auth.log` |
| Перечитать конфиги systemd | `sudo systemctl daemon-reload` |

---
