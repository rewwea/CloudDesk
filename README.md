
# CloudDesk

Учебный сервис заявок технической поддержки на ASP.NET Core Minimal API, PostgreSQL и Docker Compose.

## 1. Запуск приложения

Для запуска необходим Docker с поддержкой Compose.

```bash
cp .env.example .env
```

В файле `.env` необходимо указать пароль PostgreSQL.

Запуск:

```bash
docker compose up -d --build
```

Проверка:

```bash
docker compose ps
curl http://localhost:8080/health
```

API работает на порту 8080.

## 2. HTTP-маршруты

| Метод | Маршрут | Назначение |
|---|---|---|
| GET | /health | Проверка API и БД |
| GET | /api/tickets | Список заявок |
| GET | /api/tickets/{id} | Получение заявки |
| POST | /api/tickets | Создание заявки |
| PUT | /api/tickets/{id} | Изменение заявки |
| DELETE | /api/tickets/{id} | Удаление заявки |
| GET | /api/stats | Статистика |

Параметры списка:

- `status` — фильтр по статусу.
- `priority` — фильтр по приоритету.
- `q` — поиск по названию.
- `sort=asc/desc` — сортировка по дате.
- `page` и `pageSize` — пагинация.

Пример создания заявки:

```bash
curl -X POST http://localhost:8080/api/tickets \
-H "Content-Type: application/json" \
-d '{"title":"Ошибка сети","description":"Нет подключения","priority":1,"status":"new"}'
```

## 3. Проверка сохранности данных

Создайте заявку и запомните её ID.

Перезапустите сервисы:

```bash
docker compose down
docker compose up -d
```

Проверьте заявку:

```bash
curl http://localhost:8080/api/tickets/ID
```

Данные сохраняются в именованном томе PostgreSQL.

Проверка состояния сервисов:

```bash
docker compose ps
docker compose logs --tail=30 api
```

Проверка отказоустойчивости:

```bash
docker compose stop db
curl -i http://localhost:8080/health
docker compose start db
```

При недоступной базе `/health` возвращает HTTP 503.

История изменения статусов хранится в таблице `ticket_events`.
