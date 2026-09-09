#!/bin/bash

# 1. Shebang указывает, какой интерпретатор использовать
# 2. Переменная с именем процесса для проверки
PROCESS_NAME="sshd"

echo "🔍 Проверка процесса: $PROCESS_NAME..."

# 3. Ищем процесс, перенаправляем stderr в /dev/null (чтобы не видеть ошибки grep)
# pgrep возвращает PID, если процесс найден, и код выхода 0
pgrep -x "$PROCESS_NAME" > /dev/null 2>&1

# 4. Проверяем код выхода последней команды ($?)
if [ $? -eq 0 ]; then
    echo "✅ УСПЕХ: Процесс $PROCESS_NAME запущен."
    # Можно добавить запись в лог:
    # echo "$(date): $PROCESS_NAME is running" >> /var/log/my_monitor.log
else
    echo "❌ ОШИБКА: Процесс $PROCESS_NAME НЕ запущен!"
    # В реальном скрипте здесь был бы вызов alert-системы (Telegram/Slack webhook)
    exit 1 # Завершаем скрипт с кодом ошибки
fi

exit 0 # Успешное завершение
