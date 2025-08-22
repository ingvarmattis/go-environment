# 🚀 Автоматический деплой Docker Swarm на домашний сервер Debian 12

Этот документ описывает, как настроить автоматический деплой вашего Docker Swarm стека на домашний сервер с Debian 12 с помощью GitHub Actions.

## 📋 Предварительные требования

### На домашнем сервере:
- **Debian 12 (Bookworm)** - рекомендуется
- Минимум 4GB RAM
- Минимум 20GB свободного места
- SSH доступ настроен
- Пользователь с правами sudo

### В GitHub репозитории:
- Доступ к настройкам репозитория
- Возможность создания Secrets

## 🔧 Настройка домашнего сервера Debian 12

### 1. Быстрая настройка (рекомендуется)

```bash
# Клонируем репозиторий на сервер
cd /opt
git clone https://github.com/your-username/go-environment.git
cd go-environment

# Запускаем автоматическую настройку
chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh
```

### 2. Ручная настройка Docker и Docker Swarm

```bash
# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем необходимые пакеты
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавляем официальный GPG ключ Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавляем репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Устанавливаем Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запускаем и включаем Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавляем пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Инициализируем Docker Swarm
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
```

### 3. Настройка безопасности

```bash
# Устанавливаем и настраиваем firewall
sudo apt install -y ufw fail2ban

# Настраиваем ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 3100/tcp
sudo ufw allow 3200/tcp
sudo ufw allow 5778/tcp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 5380/tcp
sudo ufw --force enable

# Настраиваем fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 4. Подготовка директорий проекта

```bash
# Создаем директорию для проекта
sudo mkdir -p /opt/go-environment
sudo chown $USER:$USER /opt/go-environment

# Клонируем репозиторий
cd /opt
git clone https://github.com/your-username/go-environment.git
cd go-environment

# Создаем необходимые директории для данных
sudo mkdir -p /data/fast/{prometheus_data,grafana_data,postgres_data,tempo_data,loki_data,promtail_data,technitium-dns-data/zones}
sudo chown -R 1000:1000 /data/fast/
```

## 🔐 Настройка GitHub Secrets

В настройках вашего GitHub репозитория перейдите в **Settings** → **Secrets and variables** → **Actions** и добавьте следующие секреты:

| Имя | Описание | Пример |
|-----|----------|---------|
| `SSH_PRIVATE_KEY` | Приватный SSH ключ для подключения к серверу | Содержимое файла `~/.ssh/id_ed25519` |
| `HOME_SERVER_IP` | IP адрес вашего домашнего сервера | `192.168.1.100` |
| `SSH_USER` | Имя пользователя для SSH подключения | `docker-user` |

### Как получить SSH ключ:

```bash
# На машине, где генерировался ключ
cat ~/.ssh/id_ed25519
# Скопируйте весь вывод (включая BEGIN и END строки)
```

## 🚀 Запуск деплоя

### Автоматический деплой
После каждого push в ветку `main` или `master`, GitHub Actions автоматически запустит деплой.

### Ручной запуск
1. Перейдите в раздел **Actions** вашего репозитория
2. Выберите workflow **Deploy to Home Server**
3. Нажмите **Run workflow**
4. Выберите ветку и нажмите **Run workflow**

## 📊 Мониторинг деплоя

### Проверка статуса в GitHub Actions
- Перейдите в раздел **Actions**
- Выберите последний запуск workflow
- Следите за выполнением каждого шага

### Проверка на сервере

```bash
# Статус сервисов
docker stack services go-environment

# Логи сервиса
docker service logs go-environment_grafana

# Процессы
docker stack ps go-environment

# Статус Docker Swarm
docker info | grep Swarm
```

## 🛠️ Управление через Makefile

```bash
# Показать справку
make help

# Локальный деплой (для тестирования)
make deploy-local

# Статус сервисов
make status

# Логи
make logs

# Остановить стек
make clean

# Перезапустить
make restart
```

## 🔍 Устранение неполадок

### Проблемы с SSH
```bash
# Проверьте подключение
ssh -v username@your-server-ip

# Проверьте права на ключ
chmod 600 ~/.ssh/id_ed25519

# Проверьте настройки SSH на сервере
sudo systemctl status ssh
```

### Проблемы с Docker Swarm
```bash
# Проверьте статус swarm
docker info | grep Swarm

# Переинициализируйте swarm (осторожно!)
docker swarm leave --force
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
```

### Проблемы с правами доступа
```bash
# Проверьте права на директории данных
ls -la /data/fast/

# Исправьте права
sudo chown -R 1000:1000 /data/fast/
```

### Проблемы с Debian 12
```bash
# Проверьте версию
cat /etc/debian_version

# Обновите систему
sudo apt update && sudo apt upgrade -y

# Проверьте статус Docker
sudo systemctl status docker

# Перезапустите Docker
sudo systemctl restart docker
```

## 📝 Логи и отладка

### GitHub Actions логи
- Все логи доступны в разделе Actions
- Каждый шаг показывает детальный вывод команд

### Логи на сервере
```bash
# Логи Docker Swarm
docker service logs go-environment_grafana

# Системные логи
sudo journalctl -u docker

# Логи контейнеров
docker logs $(docker ps -q --filter "name=go-environment")

# Логи fail2ban
sudo journalctl -u fail2ban
```

## 🔄 Обновление конфигурации

1. Внесите изменения в конфигурационные файлы
2. Закоммитьте и запушьте изменения
3. GitHub Actions автоматически запустит деплой
4. Или запустите деплой вручную через Actions

## 🚨 Безопасность для Debian 12

- Используйте SSH ключи вместо паролей
- Firewall (ufw) настроен и включен
- Fail2ban защищает SSH от брутфорса
- Автоматические обновления безопасности включены
- Ограничьте доступ к серверу только необходимыми портами
- Регулярно обновляйте систему: `sudo apt update && sudo apt upgrade`
- Мониторьте логи безопасности: `sudo journalctl -u fail2ban`

## 📊 Производительность Debian 12

### Оптимизации системы
```bash
# Проверьте текущие настройки
sysctl net.core.somaxconn
sysctl vm.max_map_count

# Примените оптимизации
sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w vm.max_map_count=262144
```

### Мониторинг ресурсов
```bash
# Установите htop для мониторинга
sudo apt install -y htop

# Запустите мониторинг
htop
```

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи GitHub Actions
2. Проверьте статус сервисов на сервере
3. Убедитесь в правильности настроек SSH
4. Проверьте права доступа к директориям
5. Проверьте версию Debian: `cat /etc/debian_version`
6. Проверьте статус Docker: `sudo systemctl status docker`
