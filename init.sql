
-- Таблица заявок
CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    priority INTEGER NOT NULL CHECK (priority BETWEEN 1 AND 3),
    status VARCHAR(20) NOT NULL DEFAULT 'new'
        CHECK (status IN ('new', 'in_progress', 'done')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Начальные заявки
INSERT INTO tickets (title, description, priority, status)
VALUES
('Не работает интернет', 'Нет подключения к сети в офисе', 1, 'new'),
('Ошибка авторизации', 'Пользователь не может войти в систему', 1, 'in_progress'),
('Установка программы', 'Необходимо установить рабочее ПО', 3, 'done'),
('Медленная работа ПК', 'Компьютер долго запускается', 2, 'new'),
('Не работает принтер', 'Принтер не печатает документы', 2, 'in_progress');

-- История изменения статусов
CREATE TABLE IF NOT EXISTS ticket_events (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    old_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Функция записи изменений
CREATE OR REPLACE FUNCTION log_ticket_status()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO ticket_events (ticket_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер изменения статуса
DROP TRIGGER IF EXISTS ticket_status_changed ON tickets;

CREATE TRIGGER ticket_status_changed
AFTER UPDATE OF status ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_ticket_status();
