# 🔐 Настройка GitHub Secrets для автоматического деплоя

Этот документ описывает, как настроить GitHub Secrets для безопасного автоматического деплоя Docker Swarm на ваш домашний сервер.

## 📋 Что такое GitHub Secrets

GitHub Secrets - это зашифрованные переменные окружения, которые можно использовать в GitHub Actions workflows. Они идеально подходят для хранения чувствительных данных, таких как SSH ключи, пароли и API ключи.

## 🔑 Необходимые Secrets

Для работы автоматического деплоя вам понадобятся следующие secrets:

| Имя | Описание | Пример |
|-----|----------|---------|
| `SSH_PRIVATE_KEY` | Приватный SSH ключ для подключения к серверу | Содержимое файла `~/.ssh/id_ed25519` |
| `HOME_SERVER_DOMAIN` | Доменное имя вашего домашнего сервера | `home.mattis.dev` |
| `SSH_USER` | Имя пользователя для SSH подключения | `docker-user` |

## 🚀 Пошаговая настройка

### Шаг 1: Генерация SSH ключа

Если у вас еще нет SSH ключа, создайте его:

```bash
# Генерируем новый SSH ключ
ssh-keygen -t ed25519 -C "github-actions-deploy"

# Или используем существующий ключ
ls ~/.ssh/
```

### Шаг 2: Копирование публичного ключа на сервер

```bash
# Копируем публичный ключ на сервер
ssh-copy-id username@your-server-domain.com

# Тестируем подключение
ssh username@your-server-domain.com "echo 'SSH connection successful!'"
```

### Шаг 3: Получение приватного ключа

```bash
# Показываем содержимое приватного ключа
cat ~/.ssh/id_ed25519

# Скопируйте ВСЕ содержимое (включая BEGIN и END строки)
```

### Шаг 4: Настройка GitHub Secrets

1. Перейдите в ваш GitHub репозиторий
2. Нажмите на вкладку **Settings**
3. В левом меню выберите **Secrets and variables** → **Actions**
4. Нажмите **New repository secret**

#### Добавление SSH_PRIVATE_KEY

1. **Name**: `SSH_PRIVATE_KEY`
2. **Value**: Вставьте содержимое приватного ключа (включая BEGIN и END строки)
3. Нажмите **Add secret**

#### Добавление HOME_SERVER_DOMAIN

1. **Name**: `HOME_SERVER_DOMAIN`
2. **Value**: Доменное имя вашего сервера (например, `home.mattis.dev`)
3. Нажмите **Add secret**

#### Добавление SSH_USER

1. **Name**: `SSH_USER`
2. **Value**: Имя пользователя для SSH (например, `docker-user`)
3. Нажмите **Add secret**

## 🔍 Проверка настройки

После добавления всех secrets:

1. Перейдите в раздел **Actions**
2. Выберите workflow **Deploy to Home Server**
3. Нажмите **Run workflow**
4. Выберите ветку и нажмите **Run workflow**

## 🛠️ Управление Secrets

### Просмотр списка Secrets

В разделе **Settings** → **Secrets and variables** → **Actions** вы увидите список всех добавленных secrets.

### Обновление Secret

1. Нажмите на значок обновления рядом с нужным secret
2. Введите новое значение
3. Нажмите **Update secret**

### Удаление Secret

1. Нажмите на значок удаления рядом с нужным secret
2. Подтвердите удаление

## 🔒 Безопасность

### Рекомендации по безопасности

- **Никогда не коммитьте SSH ключи в репозиторий**
- Используйте SSH ключи с ограниченными правами
- Регулярно ротируйте SSH ключи
- Используйте разные ключи для разных сервисов
- Ограничьте доступ к серверу только необходимыми IP адресами

### Создание ограниченного SSH ключа

```bash
# Создаем ограниченный ключ только для деплоя
ssh-keygen -t ed25519 -f ~/.ssh/github-actions-deploy -C "github-actions-deploy"

# Ограничиваем права доступа
chmod 600 ~/.ssh/github-actions-deploy
chmod 644 ~/.ssh/github-actions-deploy.pub
```

### Настройка ограничений на сервере

В файле `~/.ssh/authorized_keys` на сервере добавьте ограничения:

```bash
# Ограничиваем ключ только для деплоя
command="cd /opt/go-environment && git pull && docker stack deploy -c docker/docker-swarm.yaml go-environment",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... github-actions-deploy
```

## 🚨 Устранение неполадок

### Проблема: SSH подключение не работает

```bash
# Проверьте подключение с подробным выводом
ssh -v username@your-server-ip

# Проверьте права на ключ
chmod 600 ~/.ssh/id_ed25519

# Проверьте настройки SSH на сервере
sudo systemctl status ssh
```

### Проблема: GitHub Actions не может подключиться

1. Проверьте правильность доменного имени в `HOME_SERVER_DOMAIN`
2. Убедитесь, что SSH порт (22) открыт
3. Проверьте, что пользователь существует на сервере
4. Убедитесь, что SSH ключ добавлен в `authorized_keys`

### Проблема: Неправильные права доступа

```bash
# На сервере проверьте права на директории
ls -la /opt/go-environment
ls -la /data/fast/

# Исправьте права если нужно
sudo chown -R docker-user:docker-user /opt/go-environment
sudo chown -R 1000:1000 /data/fast/
```

## 📝 Примеры использования

### В GitHub Actions workflow

```yaml
- name: Deploy to server
  run: |
    ssh ${{ secrets.SSH_USER }}@${{ secrets.HOME_SERVER_DOMAIN }} << 'EOF'
      cd /opt/go-environment
      docker stack deploy -c docker/docker-swarm.yaml go-environment
    EOF
```

### Локальное тестирование

```bash
# Экспортируем переменные для локального тестирования
export SSH_USER="docker-user"
export HOME_SERVER_DOMAIN="home.mattis.dev"

# Тестируем подключение
ssh $SSH_USER@$HOME_SERVER_DOMAIN "echo 'Test successful'"
```

## 🔄 Обновление Secrets

### Ротация SSH ключей

1. Создайте новый SSH ключ
2. Добавьте публичный ключ на сервер
3. Обновите `SSH_PRIVATE_KEY` в GitHub Secrets
4. Удалите старый ключ с сервера

### Изменение доменного имени сервера

1. Обновите `HOME_SERVER_DOMAIN` в GitHub Secrets
2. Убедитесь, что новый домен доступен
3. Обновите DNS записи если необходимо

## 📞 Поддержка

При возникновении проблем с настройкой GitHub Secrets:

1. Проверьте логи GitHub Actions
2. Убедитесь в правильности всех значений
3. Проверьте SSH подключение локально
4. Создайте Issue в репозитории с описанием проблемы
