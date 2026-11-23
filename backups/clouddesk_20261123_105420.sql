--
-- PostgreSQL database dump
--

\restrict ek68yZ9Zifc0MlSXqoUPYFSfVlh6du4EMOEWsgyYZYFpcp5Kvy0TOmWMOpmhnbF

-- Dumped from database version 17.12 (Debian 17.12-1.pgdg13+1)
-- Dumped by pg_dump version 17.12 (Debian 17.12-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.ticket_events DROP CONSTRAINT IF EXISTS ticket_events_ticket_id_fkey;
DROP TRIGGER IF EXISTS ticket_status_changed ON public.tickets;
ALTER TABLE IF EXISTS ONLY public.tickets DROP CONSTRAINT IF EXISTS tickets_pkey;
ALTER TABLE IF EXISTS ONLY public.ticket_events DROP CONSTRAINT IF EXISTS ticket_events_pkey;
DROP TABLE IF EXISTS public.tickets;
DROP TABLE IF EXISTS public.ticket_events;
DROP FUNCTION IF EXISTS public.log_ticket_status();
--
-- Name: log_ticket_status(); Type: FUNCTION; Schema: public; Owner: clouddesk
--

CREATE FUNCTION public.log_ticket_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO ticket_events (ticket_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_ticket_status() OWNER TO clouddesk;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ticket_events; Type: TABLE; Schema: public; Owner: clouddesk
--

CREATE TABLE public.ticket_events (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    old_status character varying(20) NOT NULL,
    new_status character varying(20) NOT NULL,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.ticket_events OWNER TO clouddesk;

--
-- Name: ticket_events_id_seq; Type: SEQUENCE; Schema: public; Owner: clouddesk
--

ALTER TABLE public.ticket_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.ticket_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: clouddesk
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    title character varying(120) NOT NULL,
    description text NOT NULL,
    priority integer NOT NULL,
    status character varying(20) DEFAULT 'new'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tickets_priority_check CHECK (((priority >= 1) AND (priority <= 3))),
    CONSTRAINT tickets_status_check CHECK (((status)::text = ANY ((ARRAY['new'::character varying, 'in_progress'::character varying, 'done'::character varying])::text[])))
);


ALTER TABLE public.tickets OWNER TO clouddesk;

--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: clouddesk
--

ALTER TABLE public.tickets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: ticket_events; Type: TABLE DATA; Schema: public; Owner: clouddesk
--

COPY public.ticket_events (id, ticket_id, old_status, new_status, changed_at) FROM stdin;
1	7	new	in_progress	2026-11-19 10:49:53.880268+00
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: clouddesk
--

COPY public.tickets (id, title, description, priority, status, created_at) FROM stdin;
1	Не работает интернет	Нет подключения к сети в офисе	1	new	2026-11-19 10:37:19.331432+00
2	Ошибка авторизации	Пользователь не может войти в систему	1	in_progress	2026-11-19 10:37:19.331432+00
3	Установка программы	Необходимо установить рабочее ПО	3	done	2026-11-19 10:37:19.331432+00
4	Медленная работа ПК	Компьютер долго запускается	2	new	2026-11-19 10:37:19.331432+00
5	Не работает принтер	Принтер не печатает документы	2	in_progress	2026-11-19 10:37:19.331432+00
6	Не работает Wi-Fi	Нет подключения в кабинете 205	1	new	2026-11-19 10:42:22.506138+00
7	Ошибка сети	Проверяется подключение	1	in_progress	2026-11-19 10:49:38.63458+00
9	Проверка Redis	Тест кэша	2	new	2026-11-23 10:52:36.648003+00
10	Worker test 1	Queue test	2	new	2026-11-23 10:53:02.919746+00
11	Worker test 2	Queue test	2	new	2026-11-23 10:53:02.929381+00
12	Worker test 3	Queue test	2	new	2026-11-23 10:53:02.939048+00
\.


--
-- Name: ticket_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: clouddesk
--

SELECT pg_catalog.setval('public.ticket_events_id_seq', 1, true);


--
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: clouddesk
--

SELECT pg_catalog.setval('public.tickets_id_seq', 12, true);


--
-- Name: ticket_events ticket_events_pkey; Type: CONSTRAINT; Schema: public; Owner: clouddesk
--

ALTER TABLE ONLY public.ticket_events
    ADD CONSTRAINT ticket_events_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: clouddesk
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tickets ticket_status_changed; Type: TRIGGER; Schema: public; Owner: clouddesk
--

CREATE TRIGGER ticket_status_changed AFTER UPDATE OF status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.log_ticket_status();


--
-- Name: ticket_events ticket_events_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: clouddesk
--

ALTER TABLE ONLY public.ticket_events
    ADD CONSTRAINT ticket_events_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict ek68yZ9Zifc0MlSXqoUPYFSfVlh6du4EMOEWsgyYZYFpcp5Kvy0TOmWMOpmhnbF

