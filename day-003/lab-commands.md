инструмент curl:
curl https://github.com              # GET-запрос, вывести тело ответа
curl -I https://github.com           # Только заголовки (HEAD-запрос)
curl -v https://github.com           # Verbose — показать весь процесс, включая TLS handshake
curl -X POST https://api.example.com # Указать метод (POST, PUT, DELETE)
curl -d "data=value" https://...     # Отправить данные (POST)
curl -H "Authorization: Bearer TOKEN" https://... # Добавить заголовок

ПОРТЫ:
sudo -tuln - посмотреть все открытые порты. Небольшая выноска
*-t — показать только TCP
-u — показать только UDP
-l — только слушающие (listening) порты
-n — показывать числа (порты), а не пытаться резолвить имена сервисов (работает быстрее)

sudo -tulnp - добавляется флаг -p, который позволяет смотреть еще и имена процессов

UFW:
sudo ufw status              # Проверить статус
sudo ufw allow 22/tcp        # Разрешить входящий SSH (ВСЕГДА делай это первым!)
sudo ufw allow 80,443/tcp    # Разрешить веб-трафик
sudo ufw deny 3306           # Явно запретить доступ к БД извне
sudo ufw enable              # Включить фаервол (потребует подтверждения)
sudo ufw reset               # Сбросить все правила (если что-то сломал)

правила:
sudo ufw allow 22/tcp            # Разрешить SSH (ВСЕГДА делай это первым!)
sudo ufw allow 80,443/tcp        # Разрешить HTTP и HTTPS
sudo ufw deny 3306               # Запретить MySQL
sudo ufw allow from 192.168.1.0/24 to any port 22  # Разрешить SSH только из подсети
sudo ufw delete allow 80         # Удалить правило



базовая структура iptables:
iptables -L                      # Показать все правила
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Добавить правило
iptables -D INPUT 1              # Удалить правило по номеру


Logging: Включи логирование заблокированных пакетов для анализа атак
sudo ufw logging on
