--
-- PostgreSQL database dump
--

\restrict F51c77eLWOhPys2sHmWyypdIAQDumsQrmrJq6MEfQ5GhJAOFWuJ6T2ncTADLL0Q

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.run_reference_files DROP CONSTRAINT IF EXISTS run_reference_files_run_id_fkey;
ALTER TABLE IF EXISTS ONLY public.run_calibration_file DROP CONSTRAINT IF EXISTS run_calibration_file_run_id_fkey;
ALTER TABLE IF EXISTS ONLY public.password_resets DROP CONSTRAINT IF EXISTS password_resets_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.logger_results DROP CONSTRAINT IF EXISTS logger_results_run_id_fkey;
ALTER TABLE IF EXISTS ONLY public.logger_results DROP CONSTRAINT IF EXISTS logger_results_logger_id_fkey;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS fk_audit_log_run_id;
ALTER TABLE IF EXISTS ONLY public.calibration_runs DROP CONSTRAINT IF EXISTS calibration_runs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_user_id_fkey;
DROP INDEX IF EXISTS public.ix_users_email;
DROP INDEX IF EXISTS public.ix_sessions_user_id;
DROP INDEX IF EXISTS public.ix_run_reference_files_run_id;
DROP INDEX IF EXISTS public.ix_password_resets_user_id;
DROP INDEX IF EXISTS public.ix_loggers_serial_no;
DROP INDEX IF EXISTS public.ix_logger_results_run_id;
DROP INDEX IF EXISTS public.ix_calibration_runs_created_by;
DROP INDEX IF EXISTS public.ix_calibration_runs_created_at;
DROP INDEX IF EXISTS public.ix_audit_log_user_id;
DROP INDEX IF EXISTS public.ix_audit_log_run_id;
DROP INDEX IF EXISTS public.ix_audit_log_at;
DROP INDEX IF EXISTS public.ix_audit_log_action;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_token_hash_key;
ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.run_reference_files DROP CONSTRAINT IF EXISTS run_reference_files_pkey;
ALTER TABLE IF EXISTS ONLY public.run_calibration_file DROP CONSTRAINT IF EXISTS run_calibration_file_run_id_key;
ALTER TABLE IF EXISTS ONLY public.run_calibration_file DROP CONSTRAINT IF EXISTS run_calibration_file_pkey;
ALTER TABLE IF EXISTS ONLY public.password_resets DROP CONSTRAINT IF EXISTS password_resets_token_hash_key;
ALTER TABLE IF EXISTS ONLY public.password_resets DROP CONSTRAINT IF EXISTS password_resets_pkey;
ALTER TABLE IF EXISTS ONLY public.loggers DROP CONSTRAINT IF EXISTS loggers_pkey;
ALTER TABLE IF EXISTS ONLY public.logger_results DROP CONSTRAINT IF EXISTS logger_results_pkey;
ALTER TABLE IF EXISTS ONLY public.calibration_runs DROP CONSTRAINT IF EXISTS calibration_runs_pkey;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_pkey;
ALTER TABLE IF EXISTS ONLY public.alembic_version DROP CONSTRAINT IF EXISTS alembic_version_pkc;
ALTER TABLE IF EXISTS public.audit_log ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.sessions;
DROP TABLE IF EXISTS public.run_reference_files;
DROP TABLE IF EXISTS public.run_calibration_file;
DROP TABLE IF EXISTS public.password_resets;
DROP TABLE IF EXISTS public.loggers;
DROP TABLE IF EXISTS public.logger_results;
DROP TABLE IF EXISTS public.calibration_runs;
DROP SEQUENCE IF EXISTS public.audit_log_id_seq;
DROP TABLE IF EXISTS public.audit_log;
DROP TABLE IF EXISTS public.alembic_version;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO ite;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    user_id uuid,
    run_id uuid,
    action character varying(50) NOT NULL,
    detail jsonb,
    at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_log OWNER TO ite;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: ite
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO ite;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ite
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: calibration_runs; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.calibration_runs (
    id uuid NOT NULL,
    batch_name character varying(200) NOT NULL,
    status character varying(20) NOT NULL,
    testing_start timestamp with time zone NOT NULL,
    testing_end timestamp with time zone NOT NULL,
    certificate_date date NOT NULL,
    threshold_c numeric(5,3) NOT NULL,
    setpoints jsonb NOT NULL,
    template_path text,
    failure_reason jsonb,
    start_cert_no character varying(20) NOT NULL,
    cert_width integer NOT NULL,
    test_date_jp character varying(30) NOT NULL,
    doc_date_jp character varying(30) NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone
);


ALTER TABLE public.calibration_runs OWNER TO ite;

--
-- Name: logger_results; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.logger_results (
    id uuid NOT NULL,
    run_id uuid NOT NULL,
    logger_id uuid,
    sheet_name character varying(200) NOT NULL,
    verdict character varying(20) NOT NULL,
    max_deviation_c numeric(6,3),
    per_setpoint jsonb NOT NULL,
    cert_no character varying(20),
    cert_path text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.logger_results OWNER TO ite;

--
-- Name: loggers; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.loggers (
    id uuid NOT NULL,
    serial_no character varying(100) NOT NULL,
    model character varying(100),
    notes text,
    next_due_at date,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.loggers OWNER TO ite;

--
-- Name: password_resets; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.password_resets (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.password_resets OWNER TO ite;

--
-- Name: run_calibration_file; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.run_calibration_file (
    id uuid NOT NULL,
    run_id uuid NOT NULL,
    original_name character varying(255) NOT NULL,
    stored_path text NOT NULL,
    sha256 character varying(64) NOT NULL,
    sheet_names jsonb NOT NULL,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.run_calibration_file OWNER TO ite;

--
-- Name: run_reference_files; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.run_reference_files (
    id uuid NOT NULL,
    run_id uuid NOT NULL,
    original_name character varying(255) NOT NULL,
    stored_path text NOT NULL,
    sha256 character varying(64) NOT NULL,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.run_reference_files OWNER TO ite;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone
);


ALTER TABLE public.sessions OWNER TO ite;

--
-- Name: users; Type: TABLE; Schema: public; Owner: ite
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(320) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(200) NOT NULL,
    role character varying(20) NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO ite;

--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.alembic_version (version_num) FROM stdin;
a3f1b2c4d5e6
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.audit_log (id, user_id, run_id, action, detail, at) FROM stdin;
1	3ca89926-b65a-4184-b81d-c856c2e0776b	\N	login	{"email": "demo@example.com"}	2026-05-26 01:56:32.143021+00
2	3ca89926-b65a-4184-b81d-c856c2e0776b	\N	logout	null	2026-05-26 01:56:32.197825+00
3	5be91f23-6e80-447e-9b93-48e8ce8da652	\N	login	{"email": "biswas.sub65@icebattery.jp"}	2026-05-26 02:43:28.401984+00
6	5be91f23-6e80-447e-9b93-48e8ce8da652	08e016f3-784c-46b3-8037-f2a67f67d87f	cert.downloaded	{"cert_no": "0000001957", "result_id": "cd582485-55cb-49c0-8160-0fb2bb5d58dc"}	2026-06-02 07:38:35.017242+00
7	5be91f23-6e80-447e-9b93-48e8ce8da652	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	certs.zip_downloaded	null	2026-06-02 08:08:58.468177+00
5	5be91f23-6e80-447e-9b93-48e8ce8da652	\N	cert.downloaded	{"cert_no": "0000001946", "result_id": "6d857d0b-0c22-4553-8aeb-bd6cd3e8b9ca"}	2026-06-02 07:30:40.472057+00
4	5be91f23-6e80-447e-9b93-48e8ce8da652	\N	cert.downloaded	{"cert_no": "0000001741", "result_id": "d95ccf30-f02f-4e59-aed1-4b017d94009c"}	2026-06-02 07:24:10.726455+00
8	\N	\N	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 0, "migrated": 105, "workbook": "No. 2450 - No. 2554.xlsx"}	2026-06-03 04:48:48.372098+00
9	\N	\N	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 0, "migrated": 110, "workbook": "No. 2555 - No. 2664.xlsx"}	2026-06-03 04:48:54.163712+00
10	\N	\N	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 2, "migrated": 20, "workbook": "No.190125020000856.2026-04-08 09_13_46-20260415_003951.xlsx"}	2026-06-03 04:48:59.041235+00
11	\N	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 0, "migrated": 105, "workbook": "No. 2450 - No. 2554.xlsx"}	2026-06-03 04:53:14.24483+00
12	\N	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 0, "migrated": 110, "workbook": "No. 2555 - No. 2664.xlsx"}	2026-06-03 04:53:21.177254+00
13	\N	ccd9fb7c-323e-4d24-8aba-f454129354be	run.migrated	{"source": "scripts/migrate_historical.py", "skipped": 2, "migrated": 20, "workbook": "No.190125020000856.2026-04-08 09_13_46-20260415_003951.xlsx"}	2026-06-03 04:53:26.42912+00
\.


--
-- Data for Name: calibration_runs; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.calibration_runs (id, batch_name, status, testing_start, testing_end, certificate_date, threshold_c, setpoints, template_path, failure_reason, start_cert_no, cert_width, test_date_jp, doc_date_jp, created_by, created_at, completed_at) FROM stdin;
55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	Batch 1 — March 4, 2026 (cert 1645)	complete	2026-03-10 00:00:00+00	2026-03-12 17:00:00+00	2026-03-06	0.500	[{"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-10T00:00:00", "target_c": -40.0}, {"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-10T00:00:00", "target_c": 5.0}, {"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-10T00:00:00", "target_c": 40.0}]	/tmp/template.docx	\N	0000001645	10	2026年3月4日	2026年3月6日	\N	2026-06-03 04:53:14.24483+00	2026-06-03 04:53:14.177783+00
32ab0c6f-ec38-40c7-b2f0-e3078370edc5	Calibration October 2025 — ITE Calibration	complete	2025-10-29 09:00:00+00	2025-10-29 09:00:00+00	2025-10-29	0.500	[{"end_at": "2025-10-28T18:00:00+00:00", "start_at": "2025-10-28T15:00:00+00:00", "target_c": 40}, {"end_at": "2025-10-29T12:00:00+00:00", "start_at": "2025-10-29T06:00:00+00:00", "target_c": 5}, {"end_at": "2025-10-29T16:00:00+00:00", "start_at": "2025-10-29T13:00:00+00:00", "target_c": -40}]	\N	\N		10	2025年10月29日	2025年10月29日	\N	2025-10-29 09:00:00+00	2025-10-29 09:00:00+00
320c8e6c-51e2-43ea-b741-1be9b3629848	Alfresa October 2025 — ITE Calibration	complete	2025-10-01 09:00:00+00	2025-10-01 09:00:00+00	2025-10-01	0.500	[{"end_at": "2025-10-01T08:00:00+00:00", "start_at": "2025-10-01T00:00:00+00:00", "target_c": -40}, {"end_at": "2025-10-01T16:00:00+00:00", "start_at": "2025-10-01T08:00:00+00:00", "target_c": 5}, {"end_at": "2025-10-02T00:00:00+00:00", "start_at": "2025-10-01T16:00:00+00:00", "target_c": 40}]	\N	\N	0000001071	10	2025年10月1日	2025年10月1日	\N	2025-10-01 09:00:00+00	2025-10-01 09:00:00+00
08e016f3-784c-46b3-8037-f2a67f67d87f	June 13th 2025 — ITE Calibration	complete	2025-06-13 09:00:00+00	2025-06-13 09:00:00+00	2025-06-13	0.500	[{"end_at": "2025-06-13T08:00:00+00:00", "start_at": "2025-06-13T00:00:00+00:00", "target_c": -40}, {"end_at": "2025-06-13T16:00:00+00:00", "start_at": "2025-06-13T08:00:00+00:00", "target_c": 5}, {"end_at": "2025-06-14T00:00:00+00:00", "start_at": "2025-06-13T16:00:00+00:00", "target_c": 40}]	\N	\N	0000001957	10	2025年6月13日	2025年6月13日	\N	2025-06-13 09:00:00+00	2025-06-13 09:00:00+00
59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	Calibration November 2025 — ITE Calibration	complete	2025-11-14 09:00:00+00	2025-11-14 09:00:00+00	2025-11-14	0.500	[{"end_at": "2025-11-06T17:00:00+00:00", "start_at": "2025-11-05T17:00:00+00:00", "target_c": -40}, {"end_at": "2025-11-07T14:00:00+00:00", "start_at": "2025-11-07T00:00:00+00:00", "target_c": 5}, {"end_at": "2025-11-14T02:00:00+00:00", "start_at": "2025-11-14T00:00:00+00:00", "target_c": 40}]	\N	\N		10	2025年11月14日	2025年11月14日	\N	2025-11-14 09:00:00+00	2025-11-14 09:00:00+00
54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	Batch 2 — March 12, 2026 (cert 1720)	complete	2026-03-11 00:00:00+00	2026-03-12 17:00:00+00	2026-03-13	0.500	[{"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-11T00:00:00", "target_c": -40.0}, {"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-11T00:00:00", "target_c": 5.0}, {"end_at": "2026-03-12T17:00:00", "start_at": "2026-03-11T00:00:00", "target_c": 40.0}]	/tmp/template.docx	\N	0000001720	10	2026年3月12日	2026年3月13日	\N	2026-06-03 04:53:21.177254+00	2026-06-03 04:53:21.176889+00
ccd9fb7c-323e-4d24-8aba-f454129354be	Batch 3 — April 14, 2026 (cert 1935)	complete	2026-04-13 00:00:00+00	2026-04-15 10:00:00+00	2026-04-17	0.500	[{"end_at": "2026-04-15T10:00:00", "start_at": "2026-04-13T00:00:00", "target_c": -40.0}, {"end_at": "2026-04-15T10:00:00", "start_at": "2026-04-13T00:00:00", "target_c": 5.0}, {"end_at": "2026-04-15T10:00:00", "start_at": "2026-04-13T00:00:00", "target_c": 40.0}]	/tmp/template.docx	\N	0000001935	10	2026年4月14日	2026年4月17日	\N	2026-06-03 04:53:26.42912+00	2026-06-03 04:53:26.428695+00
\.


--
-- Data for Name: logger_results; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.logger_results (id, run_id, logger_id, sheet_name, verdict, max_deviation_c, per_setpoint, cert_no, cert_path, created_at) FROM stdin;
60351d17-8833-45b8-b666-61c55865b434	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	9919ce0b-d170-41e9-9f32-f4f8d16df49a	190125020000801	pass	0.494	[{"cal_c": 40.796, "dev_c": -0.494, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.151, "dev_c": -0.281, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.397, "dev_c": -0.032, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
89454aeb-79aa-4295-b635-1a6e6a2aecc6	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	0c12473d-95dc-4f94-bbbe-ba34f84752dd	190125020000802	pass	0.294	[{"cal_c": 41.032, "dev_c": -0.258, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.138, "dev_c": -0.294, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.532, "dev_c": -0.168, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
7f58f86e-06f9-4529-b579-0293fe7c0d8f	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	650a9cdf-acad-4214-8710-e49bf9718157	190125020000803	pass	0.253	[{"cal_c": 41.543, "dev_c": 0.253, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.249, "dev_c": -0.183, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.559, "dev_c": -0.195, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
6bf5124c-7f45-4c61-b3c4-b1a25b264103	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	2009e8a6-4d8d-4d0e-a92e-7ac3c04543a4	190125020000804	pass	0.260	[{"cal_c": 41.364, "dev_c": 0.074, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.172, "dev_c": -0.26, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.365, "dev_c": 0.0, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
33a48f6d-e102-4afc-9a2c-825d2ecac9a0	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	c9fe5a18-1b96-4a1e-b349-6d7f904d7449	190125020000805	pass	0.381	[{"cal_c": 41.475, "dev_c": 0.185, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.117, "dev_c": -0.315, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.746, "dev_c": -0.381, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
71650b2a-c8d9-4cf3-a059-ff700cd5ef0d	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	64b2b1bd-f08d-40fc-a44c-e1eba32f1963	190125020000806	pass	0.307	[{"cal_c": 40.996, "dev_c": -0.294, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.125, "dev_c": -0.307, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.454, "dev_c": -0.089, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
bd190fe2-7e6e-45e4-9a93-bfd061312e32	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	08cfedc4-edb2-4530-8f88-e39a0d564fa9	190125020000808	pass	0.400	[{"cal_c": 41.586, "dev_c": 0.296, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.032, "dev_c": -0.4, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.584, "dev_c": -0.219, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
081af242-9c13-4a7e-bdad-e7cb533d7c50	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	470cb66c-1c69-42b8-b200-8fa73b6f9d95	190125020000809	pass	0.343	[{"cal_c": 41.164, "dev_c": -0.126, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.089, "dev_c": -0.343, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.527, "dev_c": -0.162, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
c0ad267e-d016-4d51-829a-44f7026a6339	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	6420d41e-0ea3-4f0f-a790-d20ba645f949	190125020000810	pass	0.489	[{"cal_c": 41.186, "dev_c": -0.104, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.943, "dev_c": -0.489, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.576, "dev_c": -0.211, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
71d5e5fe-6d49-43e0-b622-dc91bff31413	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	ed7c2f4f-b468-4a05-ad38-463a0122d59d	190125020000811	fail	0.529	[{"cal_c": 41.139, "dev_c": -0.151, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.903, "dev_c": -0.529, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": -40.519, "dev_c": -0.154, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
e6cd6a3c-2162-492c-bde9-5bce1ae4b3b8	320c8e6c-51e2-43ea-b741-1be9b3629848	430223f7-0fe6-4f55-bf28-6e43306ad983	190125070005577	pass	\N	[]	0000001267	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001267_190125070005577.docx	2025-10-01 09:00:00+00
a2e4c341-2002-401a-902e-3d1a55f0bf55	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	31001c8c-6bd0-4893-baf7-368c5393d9ea	190125020000812	pass	0.328	[{"cal_c": 41.039, "dev_c": -0.251, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.104, "dev_c": -0.328, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.597, "dev_c": -0.232, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
c0e666d2-ecca-4a07-a8c9-a75cef6d3b7e	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	c1233832-c5b0-4ed1-9e3e-60d9b41db091	190125020000813	fail	0.506	[{"cal_c": 41.146, "dev_c": -0.144, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.926, "dev_c": -0.506, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": -40.511, "dev_c": -0.146, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
34a7b9db-ee63-40c3-b427-1b5cc08f75dd	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	1a17fe00-15c2-4967-9aac-337f83f7a209	190125020000814	pass	0.332	[{"cal_c": 41.054, "dev_c": -0.237, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.1, "dev_c": -0.332, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.659, "dev_c": -0.295, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
0702a4dd-c483-4ae7-bf31-0b203c2f3c70	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	10bc819f-7f05-4846-944d-2f3039150ac8	190125020000815	pass	0.483	[{"cal_c": 40.807, "dev_c": -0.483, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.153, "dev_c": -0.279, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.516, "dev_c": -0.151, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
6fd01030-963d-490a-ba95-abd96b374142	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	a16d3efb-ddd1-439d-b1ba-5b82d2fa52dc	190125020000816	pass	0.418	[{"cal_c": 40.921, "dev_c": -0.369, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.014, "dev_c": -0.418, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.646, "dev_c": -0.281, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
b6c628f5-8c20-4d22-b0e2-c3e9eae7f17a	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	3fc02715-2205-4ec0-9bd8-6c137037c444	190125020000817	pass	0.311	[{"cal_c": 41.482, "dev_c": 0.192, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.246, "dev_c": -0.186, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.676, "dev_c": -0.311, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
c794a749-79c0-4b91-8bcd-903d2a1656c2	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	d928fe34-f891-4135-88fa-8f99dc7a8b74	190125020000818	pass	0.485	[{"cal_c": 41.211, "dev_c": -0.079, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.947, "dev_c": -0.485, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.516, "dev_c": -0.151, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
d5e7d17b-606e-43bd-9add-7720dae4d9e7	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	fdffcb9e-9b79-443d-8286-56e5a0e73c97	190125020000819	pass	0.272	[{"cal_c": 41.018, "dev_c": -0.272, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.182, "dev_c": -0.25, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.546, "dev_c": -0.181, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
a7e3b2c1-10f8-4a0d-821e-c16751ea95d5	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	f6cb1b88-632f-4cf8-a059-458730998c3b	190125020000820	pass	0.183	[{"cal_c": 41.436, "dev_c": 0.146, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.249, "dev_c": -0.183, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.424, "dev_c": -0.059, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
7410310c-2e22-4c2b-ac7e-3009b54b43bc	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	35d0073e-bf8d-42b1-be28-862d56685aa4	190125020000821	pass	0.241	[{"cal_c": 41.146, "dev_c": -0.144, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.193, "dev_c": -0.239, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.605, "dev_c": -0.241, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
40850aef-746e-43b0-9187-333134bf96c9	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	60f55162-f9d8-4b75-842d-6c7bb433d9c5	190125020000822	pass	0.306	[{"cal_c": 41.482, "dev_c": 0.192, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.126, "dev_c": -0.306, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.641, "dev_c": -0.276, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
e161e715-66bf-4369-9c85-8ba609547805	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	3f0f5ae8-63c4-4b17-afb5-535907f6567c	190125020000823	pass	0.211	[{"cal_c": 41.104, "dev_c": -0.187, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.24, "dev_c": -0.192, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.576, "dev_c": -0.211, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
f7400858-c09d-492b-ad14-ecbeff6a31ff	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	70b2dc95-4d46-448e-ae08-42cda2d2a043	190125020000824	fail	0.558	[{"cal_c": 40.732, "dev_c": -0.558, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 5.049, "dev_c": -0.383, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.503, "dev_c": -0.138, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
61ff9306-80c4-4d22-83ec-3c65abde7e86	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	959a4037-b329-48e5-884b-92313da07081	190125020000825	pass	0.396	[{"cal_c": 41.429, "dev_c": 0.138, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.036, "dev_c": -0.396, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.57, "dev_c": -0.205, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
6eaf44f5-1796-4aa4-abd3-2366cd031eff	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	fecf5d69-8daf-4a08-beb0-a860b9228e3e	190125020000826	pass	0.419	[{"cal_c": 41.264, "dev_c": -0.026, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.013, "dev_c": -0.419, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.635, "dev_c": -0.27, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
fdc295e0-9123-4a0c-9096-4363a8f3bccd	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	47f2bc7d-60f1-4a17-9d6f-99c25ce43338	190125020000827	pass	0.433	[{"cal_c": 40.857, "dev_c": -0.433, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.175, "dev_c": -0.257, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.641, "dev_c": -0.276, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
425baafd-2807-4b13-9d4f-c0b2ac6ef572	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	c3b293e3-4b77-4771-b67c-4e6ca862d41b	190125020000828	fail	0.622	[{"cal_c": 40.668, "dev_c": -0.622, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 4.901, "dev_c": -0.531, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": -40.727, "dev_c": -0.362, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
0631e331-4102-4d6b-8d2e-9202581010b7	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	1b95892e-ec4f-458a-b4cc-953fd36af60b	190125020000829	pass	0.415	[{"cal_c": 40.875, "dev_c": -0.415, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.099, "dev_c": -0.333, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.592, "dev_c": -0.227, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
02c2eee8-d764-44b3-9c10-d717ac5294e2	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	7ef2df0f-fec8-41f5-b72e-ad2c82fb90b3	190125020000830	pass	0.362	[{"cal_c": 41.343, "dev_c": 0.053, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.069, "dev_c": -0.362, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.497, "dev_c": -0.132, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
ea0386bd-0b7b-448d-ba4c-61b6d827b079	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	1b3051af-8a2f-4c6d-8ae5-08e9dd1a6920	190125020000831	pass	0.267	[{"cal_c": 41.136, "dev_c": -0.154, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.165, "dev_c": -0.267, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.559, "dev_c": -0.195, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
4443ab55-439d-4d73-b891-b0c25114d847	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	024fcb06-f4b5-4e76-9e4f-c7b9e29874c9	190125020000832	pass	0.400	[{"cal_c": 5.032, "dev_c": -0.4, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.568, "dev_c": -0.203, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
d536d910-9a23-4c52-a4de-7a578b662f0a	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	0fbe7ceb-d4c5-45a3-b0bd-32bf66f357e3	190125020000833	pass	0.351	[{"cal_c": 40.939, "dev_c": -0.351, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.124, "dev_c": -0.308, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.622, "dev_c": -0.257, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
2ce66550-d76e-4ab8-9ba2-4d11001538a6	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	3a17a0f3-49fe-4275-93fe-ccf8bf96bfcf	190125020000834	pass	0.344	[{"cal_c": 40.946, "dev_c": -0.344, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.15, "dev_c": -0.282, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.522, "dev_c": -0.157, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
bd909920-53fa-4299-8c5c-af55ad11f81e	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	38886df2-1cfd-407b-afc0-f6c6132cfce9	190125020000835	fail	0.554	[{"cal_c": 40.736, "dev_c": -0.554, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 5.168, "dev_c": -0.264, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.773, "dev_c": -0.408, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
3be9e645-c5fc-46f9-a1b7-b769ebe3619f	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	64ce7c41-f333-4733-9a7f-20c970aec2f8	190125020000836	pass	0.401	[{"cal_c": 41.161, "dev_c": -0.129, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.031, "dev_c": -0.401, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.649, "dev_c": -0.284, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
1b85c821-5cd8-462d-9085-0d41c810e79b	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	caf3171a-4312-4e42-9e86-301c3cdf54a2	190125020000837	pass	0.337	[{"cal_c": 40.954, "dev_c": -0.337, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.206, "dev_c": -0.226, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.549, "dev_c": -0.184, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
db895c32-2869-4c81-b8b9-544cc18829c3	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	407bd050-9938-4f8e-b835-95aeeee39301	190125020000838	pass	0.469	[{"cal_c": 40.821, "dev_c": -0.469, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.122, "dev_c": -0.31, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.527, "dev_c": -0.162, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
97f7e882-9bcd-41d7-af9e-bfff7af0e2a6	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	bb6d767e-c77b-4dfb-8a9d-ae533e081a0f	190125020000839	pass	0.397	[{"cal_c": 41.664, "dev_c": 0.374, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.15, "dev_c": -0.282, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.762, "dev_c": -0.397, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
aab34dd3-e407-471d-9a1c-c19b93c5c15a	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	5d6fb015-8d25-4e2a-8b91-fe7316e7054a	190125020000840	fail	0.544	[{"cal_c": 41.114, "dev_c": -0.176, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.888, "dev_c": -0.544, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": -40.584, "dev_c": -0.219, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
9a1616de-b58f-4fe3-af8c-e640efebfc65	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	ebba72cd-2c30-47c9-b74a-b41f94b6f06a	190125020000841	fail	44.903	[{"cal_c": 4.443, "dev_c": -36.847, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 4.424, "dev_c": -1.008, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": 4.538, "dev_c": 44.903, "ref_c": -40.365, "target_c": -40, "within_tol": false}]	\N	\N	2025-10-29 09:00:00+00
1240a9d2-a0d7-4104-bb67-b87e400ca14c	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	7b9f0dcf-607e-4ddb-9b92-01d9a2f86c1c	190125020000842	fail	0.533	[{"cal_c": 40.757, "dev_c": -0.533, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 5.169, "dev_c": -0.263, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.608, "dev_c": -0.243, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
b0f7d945-2c52-4178-ac11-a05d7aafa86e	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	a0b5b5e3-e6e6-4ff9-8af9-cc03b60300a8	190125020000843	fail	0.515	[{"cal_c": 40.775, "dev_c": -0.515, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 5.157, "dev_c": -0.275, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.686, "dev_c": -0.322, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
1f3601aa-06b8-4255-badb-175b74bbdb33	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	27b30da8-319a-4c6d-9aea-431cf63847c2	190125020000844	fail	0.551	[{"cal_c": 40.739, "dev_c": -0.551, "ref_c": 41.29, "target_c": 40, "within_tol": false}, {"cal_c": 5.067, "dev_c": -0.365, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.603, "dev_c": -0.238, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
b5accfa7-b784-407e-b43c-2d2992eccce7	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	575970c9-9c1f-4410-b4f6-84c8ec84039a	190125020000845	pass	0.331	[{"cal_c": 41.393, "dev_c": 0.103, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.101, "dev_c": -0.331, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.478, "dev_c": -0.114, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
c4cb86b9-179c-44f9-9f5b-41fcc68fef44	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	20d0b9de-041e-488d-ad16-5f03e2e91047	190125020000846	pass	0.294	[{"cal_c": 41.104, "dev_c": -0.187, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.138, "dev_c": -0.294, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.595, "dev_c": -0.23, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
92df4c57-b01b-418c-aa96-c413c6777ac4	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	e9307223-1dc7-4c06-9273-b7edc6a201f7	190125020000847	pass	0.424	[{"cal_c": 41.261, "dev_c": -0.029, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.008, "dev_c": -0.424, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.622, "dev_c": -0.257, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
afb5cdf4-96f0-4924-937d-cc7aa37370e4	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	24f11c69-ddaa-4c2c-992b-c7931b7fc8d1	190125020000848	pass	0.481	[{"cal_c": 40.818, "dev_c": -0.472, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.09, "dev_c": -0.342, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.846, "dev_c": -0.481, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
8877bb4d-f739-40a6-bdde-eb9f178642ab	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	64f16e13-52ee-4965-9190-0f568291ee3c	190125020000849	pass	0.467	[{"cal_c": 41.021, "dev_c": -0.269, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.965, "dev_c": -0.467, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.624, "dev_c": -0.259, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
399ff44c-37ec-4d45-b6bc-b76c124cdc7a	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	0a36e20b-7653-4cb8-9452-457b4eaaf763	190125020000850	pass	0.301	[{"cal_c": 41.479, "dev_c": 0.188, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.131, "dev_c": -0.301, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.438, "dev_c": -0.073, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
c9b7a88b-004e-4358-8a1c-12bc69c41283	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	6232c94b-9c8e-40e4-bf05-82338967930d	190125020000876	pass	0.260	[{"cal_c": 41.439, "dev_c": 0.149, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.172, "dev_c": -0.26, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.603, "dev_c": -0.238, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
a98dd35a-2e63-43d8-80e6-52ac68d13dc6	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	aae4f928-4821-4eac-802f-40e56aa40fd1	190125020000877	pass	0.246	[{"cal_c": 41.536, "dev_c": 0.246, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.272, "dev_c": -0.16, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.541, "dev_c": -0.176, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
bfe7bf71-8010-4dce-99bf-9043523208fa	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	21799d2d-afe5-4f6f-a428-1d79c53ca565	190125020000878	pass	0.242	[{"cal_c": 41.532, "dev_c": 0.242, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.261, "dev_c": -0.171, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.503, "dev_c": -0.138, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
4c4a90d6-c950-4e24-ba17-4deb5061c58d	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	ecf6c24c-947c-4c82-9340-a6ec61db9218	190125020000879	pass	0.351	[{"cal_c": 41.418, "dev_c": 0.128, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.158, "dev_c": -0.274, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.716, "dev_c": -0.351, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
64d91018-6f39-4d30-ace3-0263a8978adc	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	7d4ac2ac-28f4-4617-aa4b-feba591599a5	190125020000880	pass	0.392	[{"cal_c": 41.682, "dev_c": 0.392, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.263, "dev_c": -0.169, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.641, "dev_c": -0.276, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
7b09c9c8-2eb3-4eaa-a92c-b6aab3191607	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	92c472d0-8d10-4435-b89f-4c989f8391e4	190125020000881	pass	0.288	[{"cal_c": 41.579, "dev_c": 0.288, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.278, "dev_c": -0.154, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.543, "dev_c": -0.178, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
084cc47c-fc1c-45cd-8cce-47ea8da476bc	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	5e3ecbbb-f21f-410e-9a2f-95e1914808e4	190125020000882	pass	0.349	[{"cal_c": 41.418, "dev_c": 0.128, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.083, "dev_c": -0.349, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.559, "dev_c": -0.195, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
a07cb731-7685-46d1-b188-2a5039ce4c1b	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	cdb61bd2-b793-4dcd-84f8-ad26aa92a878	190125020000883	pass	0.172	[{"cal_c": 41.396, "dev_c": 0.106, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.26, "dev_c": -0.172, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.451, "dev_c": -0.086, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
339889d6-bfb8-4f9b-bd65-e0c1f5e27600	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	7e964076-eb24-4f7e-be1e-ecb5ba3c798a	190125020000884	pass	0.289	[{"cal_c": 41.339, "dev_c": 0.049, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.143, "dev_c": -0.289, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.454, "dev_c": -0.089, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
b331964f-99db-4393-a76d-422030613851	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	5ec805b7-df6f-4588-8242-f74c0dd518cf	190125020000885	pass	0.316	[{"cal_c": 41.593, "dev_c": 0.303, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.206, "dev_c": -0.226, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.681, "dev_c": -0.316, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
eee8be08-f356-4808-8826-23826d246c60	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	f35a91e8-442d-4653-b816-f952e365deb8	190125020000886	pass	0.361	[{"cal_c": 41.35, "dev_c": 0.06, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.071, "dev_c": -0.361, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.595, "dev_c": -0.23, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
4d8770eb-7711-4c92-b073-2c68a5d07c2c	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	c3b0be38-216b-4a09-9b96-3f24ed70a423	190125020000887	pass	0.278	[{"cal_c": 41.429, "dev_c": 0.138, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.25, "dev_c": -0.182, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.643, "dev_c": -0.278, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
054d0632-d6a0-49af-af1a-bc74f68011ad	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	786bbe09-02a2-4431-b6a4-a169f0706187	190125020000888	pass	0.229	[{"cal_c": 41.429, "dev_c": 0.138, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.203, "dev_c": -0.229, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.538, "dev_c": -0.173, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
d3b04aa6-ac78-452a-a766-ab955222e652	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	39a07c5a-97de-4dd6-9530-ba83c4125d41	190125020000889	pass	0.199	[{"cal_c": 41.425, "dev_c": 0.135, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.233, "dev_c": -0.199, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.497, "dev_c": -0.132, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
04258f02-1b3e-42d7-8753-a238ec092a37	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	f5a1400a-a835-4a15-a6d6-8da465f39893	190125020000890	pass	0.286	[{"cal_c": 41.464, "dev_c": 0.174, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.146, "dev_c": -0.286, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.6, "dev_c": -0.235, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
9463ec81-f477-4414-8f00-15c724abde82	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	97480eb4-fb58-4e98-be9f-cf4168c9ba2d	190125020000891	pass	0.303	[{"cal_c": 41.35, "dev_c": 0.06, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.138, "dev_c": -0.294, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.668, "dev_c": -0.303, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
58367d08-c9e5-461f-94e4-12e87371ee89	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	e5680a3b-82c6-41d4-90b3-4a0a6313f545	190125020000892	pass	0.368	[{"cal_c": 41.421, "dev_c": 0.131, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.064, "dev_c": -0.368, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.443, "dev_c": -0.078, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
d1cacc23-98df-40d1-a052-ee8f601703f5	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	15063dd8-fb8d-4582-a942-780518976a5d	190125020000893	pass	0.226	[{"cal_c": 41.304, "dev_c": 0.013, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.206, "dev_c": -0.226, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.419, "dev_c": -0.054, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
6c044356-6aeb-435b-9b64-9da8474dca6c	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	cc1bfa3e-c16c-452f-a02f-2828ea0a1d5f	190125020000894	pass	0.358	[{"cal_c": 41.618, "dev_c": 0.328, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.074, "dev_c": -0.358, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.708, "dev_c": -0.343, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
72c377b0-c611-437b-9e2c-5e8094826a88	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	3f10a4b4-4433-471f-9742-b4357b579e06	190125020000895	fail	0.532	[{"cal_c": 41.271, "dev_c": -0.019, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 4.9, "dev_c": -0.532, "ref_c": 5.432, "target_c": 5, "within_tol": false}, {"cal_c": -40.524, "dev_c": -0.159, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
7e0f688f-600e-4828-972f-17558b40842e	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	baef1ae0-f052-4497-8700-997ce61361bf	190125020000896	pass	0.250	[{"cal_c": 41.268, "dev_c": -0.022, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.182, "dev_c": -0.25, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.543, "dev_c": -0.178, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
547b8c52-5369-4fe7-95e8-7690ee39818a	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	02542a8d-c258-4e50-ac27-32d25a0705ee	190125020000897	pass	0.290	[{"cal_c": 41.407, "dev_c": 0.117, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.142, "dev_c": -0.29, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.549, "dev_c": -0.184, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
b6404240-33ec-47b8-addb-4f0517ee2f85	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	b77e86b7-8d5c-4b66-9ffb-d9a4c674d697	190125020000898	pass	0.386	[{"cal_c": 41.429, "dev_c": 0.138, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.051, "dev_c": -0.381, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.751, "dev_c": -0.386, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
2d59fea3-14ac-4f8e-b27d-c94d0304abd3	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	4ae9a3a2-4345-4576-8f51-4d5771c7ea7d	190125020000899	pass	0.362	[{"cal_c": 41.296, "dev_c": 0.006, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.069, "dev_c": -0.362, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.578, "dev_c": -0.214, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
0b73a597-cf24-46ed-b415-f9a363878628	32ab0c6f-ec38-40c7-b2f0-e3078370edc5	371f751f-43e7-4de6-85e7-7ce2ecebb3b7	190125020000900	pass	0.343	[{"cal_c": 41.536, "dev_c": 0.246, "ref_c": 41.29, "target_c": 40, "within_tol": true}, {"cal_c": 5.171, "dev_c": -0.261, "ref_c": 5.432, "target_c": 5, "within_tol": true}, {"cal_c": -40.708, "dev_c": -0.343, "ref_c": -40.365, "target_c": -40, "within_tol": true}]	\N	\N	2025-10-29 09:00:00+00
f15b4ce3-f9d2-4b28-a058-7f57e7472245	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	26942399-58a1-4fd8-92a7-d13ab52a5b21	190124110002201	fail	0.843	[{"cal_c": -41.263, "dev_c": -0.477, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.748, "dev_c": -0.843, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.312, "dev_c": 0.0, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d49bb0a0-dacc-41a5-9027-d2d6f46bced5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b501583e-f15d-444a-ba15-e3109d9581b9	190124110002202	fail	0.938	[{"cal_c": -41.313, "dev_c": -0.527, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.653, "dev_c": -0.938, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.557, "dev_c": 0.245, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9437af7a-d19c-4f26-9e38-e1571acbcb5c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f793de97-1031-4d42-b6c7-cf8f60b690d2	190124110002203	fail	0.835	[{"cal_c": -41.59, "dev_c": -0.805, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.757, "dev_c": -0.835, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.733, "dev_c": 0.421, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
47746101-d627-4484-8be4-dfc0334c336d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	144649f2-3cac-4cf3-99a4-2ace6eda098f	190124110002204	fail	1.321	[{"cal_c": -42.107, "dev_c": -1.321, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.547, "dev_c": -1.044, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.438, "dev_c": 0.125, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
84344c08-30d2-42cb-a530-c5dfac4d4b59	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e16e8cf3-3034-4d14-83cc-5ed40ae2a8b8	190124110002205	fail	1.121	[{"cal_c": -41.907, "dev_c": -1.121, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.721, "dev_c": -0.871, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a65a5be5-9753-4306-95e4-8ca90c26cc0b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	12f3da06-fdaa-4bcd-b455-5761f32147bf	190124110002206	fail	1.302	[{"cal_c": -42.088, "dev_c": -1.302, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.86, "dev_c": -0.732, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.487, "dev_c": 0.175, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
38ed4b68-937c-442c-bfd2-d36850a90ae5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	366a349b-40cb-46f7-a42e-3713b548b79b	190124110002207	fail	1.075	[{"cal_c": -41.86, "dev_c": -1.075, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.595, "dev_c": -0.997, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2a94976c-6f99-48ae-b1da-6568a11c448c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	92a03455-7af4-4295-8a3b-be301683c3eb	190124110002208	pass	0.388	[{"cal_c": 5.441, "dev_c": -0.15, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8be7d5be-72e6-4bcf-be37-2d236bda1786	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	7f646fc3-d0c2-454a-af7c-327758f7e31d	190124110002209	pass	0.312	[{"cal_c": 5.339, "dev_c": -0.252, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.625, "dev_c": 0.312, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
1f1d3f30-0ee6-43e7-bc2f-033eebe4f69d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	0f6203c2-9978-4620-83d5-0623b84010f7	190124110002210	pass	0.337	[{"cal_c": 5.403, "dev_c": -0.189, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.65, "dev_c": 0.337, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
cede15fb-95f4-4431-84d4-18844faa9a84	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	382facfa-ef09-4e4d-a71f-2c4597f3e745	190124110002211	fail	0.863	[{"cal_c": -41.649, "dev_c": -0.863, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.829, "dev_c": -0.763, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.825, "dev_c": 0.513, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
93036aad-9892-45a6-8015-9feb59ec5702	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	fa1b5532-3452-4e53-95dd-8d2a6eca0f20	190124110002212	fail	0.912	[{"cal_c": -41.697, "dev_c": -0.912, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.807, "dev_c": -0.785, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.72, "dev_c": 0.407, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
581d44a9-d419-49a7-afa9-8c474ba8d66c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9c0e4159-38b5-44e6-99db-7e83f4df42de	190124110002213	fail	0.972	[{"cal_c": -41.666, "dev_c": -0.881, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.619, "dev_c": -0.972, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.617, "dev_c": 0.304, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e4a234dc-a365-4e91-a995-8df9f08f29da	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	81a1b50e-bc58-4ebc-941e-23d06b12e7a8	190124110002214	fail	0.755	[{"cal_c": -40.551, "dev_c": 0.235, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.836, "dev_c": -0.755, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2dc625ad-a66b-4afa-bb39-d7e8b05972fb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6ff2b26a-e6bf-4167-b5a8-6820ab7fd895	190124110002215	fail	1.224	[{"cal_c": -42.009, "dev_c": -1.224, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.809, "dev_c": -0.783, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.686, "dev_c": 0.373, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f402b7bb-0834-4ab6-bebe-55b64c65f74c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2c1495ca-5c79-4efc-b67e-266a82492b53	190124110002216	fail	1.154	[{"cal_c": -41.94, "dev_c": -1.154, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.752, "dev_c": -0.84, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.171, "dev_c": -0.141, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
08ab9551-3a4d-4e50-b9d9-ea8c0975c30f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5e619b20-190f-459e-b4f1-cafbc818aee5	190124110002217	pass	0.402	[{"cal_c": 5.464, "dev_c": -0.128, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.714, "dev_c": 0.402, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
75f31f9d-49a9-4f61-899b-d683512ccf2f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b44601fe-b324-4421-882c-789a5a13b56e	190124110002218	fail	0.502	[{"cal_c": 5.309, "dev_c": -0.283, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.814, "dev_c": 0.502, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
2fbce1a9-630e-466d-be9b-70c2f1554b36	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9c4036b9-d614-47d0-ba97-b7d64597f367	190124110002219	pass	0.263	[{"cal_c": 5.383, "dev_c": -0.209, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.575, "dev_c": 0.263, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
02116440-c0fc-419f-8c85-4a075cd679fa	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	abf8a82c-f864-411a-9ef9-4ee3d01d2ba8	190124110002220	pass	0.373	[{"cal_c": 5.25, "dev_c": -0.342, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.686, "dev_c": 0.373, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f6c10a32-f35d-482a-bb62-1c01a6484563	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	50662844-ecb5-4b74-9d1e-ebb47633783f	190124110002221	pass	0.353	[{"cal_c": 5.238, "dev_c": -0.353, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.629, "dev_c": 0.316, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
071df0c1-4aeb-4238-bb44-d7d07e6e33e3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	8ad7b05f-e719-4cb7-b6bd-0988de9fdef5	190124110002222	pass	0.445	[{"cal_c": 5.354, "dev_c": -0.238, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.757, "dev_c": 0.445, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
86cd8252-f279-4cfd-8fb9-2879cf805ac2	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	afccd246-0d24-4fed-b15e-d1666efcb6f4	190124110002223	pass	0.194	[{"cal_c": 5.398, "dev_c": -0.194, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.475, "dev_c": 0.163, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bfe5dc38-2c31-4722-9420-4e0ed6dcecbf	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1dce26b0-528f-4d8e-b57a-8809539b4e65	190124110002224	pass	0.445	[{"cal_c": 5.482, "dev_c": -0.109, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.757, "dev_c": 0.445, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
aa0e05b3-0c16-4355-a69b-999be56849cc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1d60894a-6252-41d5-9874-ee5719f5b746	190124110002225	pass	0.234	[{"cal_c": 5.358, "dev_c": -0.234, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.288, "dev_c": -0.025, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b9a9d482-c403-4dd8-8f57-aeb3dd0f1096	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	47807a1f-bb59-403b-8049-b55321a88e97	190124110002226	pass	0.350	[{"cal_c": 5.423, "dev_c": -0.169, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.663, "dev_c": 0.35, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
4ccbb180-37c7-4df3-a83c-ef1a08771d95	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	dd18cd65-eab3-44ba-932e-cd3eafd23d36	190124110002227	pass	0.487	[{"cal_c": 5.322, "dev_c": -0.27, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
de7d2597-00db-4c98-a654-7640ab6eebe1	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	70e34747-5d5a-42bc-964f-567c27fa25e4	190124110002228	fail	0.673	[{"cal_c": -41.316, "dev_c": -0.53, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.918, "dev_c": -0.673, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.583, "dev_c": 0.271, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e6c91d5b-ab2c-49d4-a633-ef555cff2d1f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	181fb94a-07c7-49ae-98ca-25792ced0160	190124110002229	pass	0.430	[{"cal_c": 5.264, "dev_c": -0.327, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.743, "dev_c": 0.43, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
aad52084-9147-4d76-a35b-3bce0c22f613	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	70eb9c71-cec0-4454-b63d-d4960cbfdfc5	190124110002230	fail	0.861	[{"cal_c": -41.567, "dev_c": -0.781, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.73, "dev_c": -0.861, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
324c535f-6f25-4c54-9d2f-cd4accda9e64	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	71934d49-622b-463c-b4b6-b56fc441b51e	190124110002231	fail	1.374	[{"cal_c": -42.159, "dev_c": -1.374, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.735, "dev_c": -0.857, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.486, "dev_c": 0.173, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
37879ce1-1dbc-41a0-8873-7cf8e02f8acd	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d0f6a1e2-2282-470e-a155-1faad057778d	190124110002232	fail	0.772	[{"cal_c": -41.155, "dev_c": -0.37, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.82, "dev_c": -0.772, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.263, "dev_c": -0.05, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e77bc966-2f8d-4e9d-8ded-6bf4000eb28e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5a5a8a50-e136-4f36-8966-4344435eaaf3	190124110002233	fail	0.784	[{"cal_c": -41.266, "dev_c": -0.48, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.808, "dev_c": -0.784, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f7078362-e70e-4e01-9526-b091923aca24	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6f2be213-f47c-404e-84c8-111fd4be7a38	190124110002235	pass	0.359	[{"cal_c": 5.367, "dev_c": -0.225, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.671, "dev_c": 0.359, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
eda774d3-106b-4451-9993-b51b9a3c4016	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5283cc42-7c8d-45ea-99bc-f795069ca8c3	190124110002236	pass	0.241	[{"cal_c": 5.351, "dev_c": -0.241, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.475, "dev_c": 0.163, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
98353939-c511-4445-91b9-5c06a4cbfcd5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a69a8e51-fa73-4a7c-940c-686f6b75ccc5	190124110002237	fail	0.779	[{"cal_c": -41.343, "dev_c": -0.558, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.813, "dev_c": -0.779, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.84, "dev_c": 0.527, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
681e7319-088a-4803-8d6d-79677ee97b40	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	aef8ccca-0ecf-493b-bdb2-137ff1237a97	190124110002238	fail	0.957	[{"cal_c": -41.414, "dev_c": -0.628, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.635, "dev_c": -0.957, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.486, "dev_c": 0.173, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ae013bae-8bf0-4619-9d2b-4ebb56a3299e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	93aaffb8-07f0-4fe8-9e6e-7ca4b230d578	190124110002239	pass	0.312	[{"cal_c": 5.394, "dev_c": -0.198, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.0, "dev_c": -0.312, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e1002736-63aa-4267-b576-884aae57cdde	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5524ccfe-42b7-46c5-aabe-9798692f156d	190124110002240	pass	0.487	[{"cal_c": 5.4, "dev_c": -0.192, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a0afb731-9404-4565-9e46-f11d14fcd2a0	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	4df0ce62-48fd-4cb2-ad1a-8893a0b74eb3	190124110002241	fail	0.720	[{"cal_c": -41.217, "dev_c": -0.431, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.872, "dev_c": -0.72, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
22fe672e-8089-42d4-8705-834bbf99e561	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	091edd99-f4c8-4ed8-beac-64f3d07bd035	190124110002242	pass	0.438	[{"cal_c": 5.153, "dev_c": -0.438, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.688, "dev_c": 0.375, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
903044fa-9791-4244-91a8-0b988d939212	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6cc4edf3-b2ba-4efa-8d25-64edb074cd3e	190124110002243	fail	1.350	[{"cal_c": -42.136, "dev_c": -1.35, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.875, "dev_c": -0.717, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 39.888, "dev_c": -0.425, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
81754d75-1fe9-45ba-8497-005db42f352f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	76cd86df-1273-4fad-9588-8927716b1103	190124110002244	fail	0.937	[{"cal_c": -41.723, "dev_c": -0.937, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.873, "dev_c": -0.718, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.65, "dev_c": 0.337, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f76b47b6-26c4-41dd-a72d-42dda9c6d605	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	47be9909-dc55-4ad5-ab60-997e50c9f20a	190124110002245	fail	0.587	[{"cal_c": 5.097, "dev_c": -0.495, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f1c2a2dd-1b3c-4eca-8da2-c45563a1c461	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c761cab5-14de-4052-bfc1-b1ab9dd71628	190124110002246	pass	0.388	[{"cal_c": 5.431, "dev_c": -0.161, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d3d375be-ed50-4b1d-a13b-aca2ac34b8cc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	afbb1858-941b-43b3-b5f7-c0dc5ebf1380	190124110002247	fail	0.903	[{"cal_c": -41.399, "dev_c": -0.613, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.688, "dev_c": -0.903, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.417, "dev_c": 0.104, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8a6c580b-61b2-4b36-a004-0eed090ab443	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e73e50a1-0a94-4b76-892e-c85ed9c380b5	190124110002248	fail	0.754	[{"cal_c": 5.344, "dev_c": -0.248, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.067, "dev_c": 0.754, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
917ca6f2-19c1-432f-92cb-c557db12420c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	7f194e8d-4172-442e-94a4-f377e2a22451	190124110002249	fail	1.355	[{"cal_c": -42.141, "dev_c": -1.355, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.693, "dev_c": -0.899, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.567, "dev_c": 0.254, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
145b3b56-e780-4720-99e2-2d99ab3240a6	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	7190e304-8bf3-4ef1-9814-16f1bb61cdbe	190124110002250	fail	0.668	[{"cal_c": 5.207, "dev_c": -0.385, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.98, "dev_c": 0.668, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
4efedda4-79e7-4db7-a2e0-4e08f61f1b36	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	20a0a937-be2c-4dd4-a4fe-8878292b3450	190124110002251	fail	0.819	[{"cal_c": -41.605, "dev_c": -0.819, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.979, "dev_c": -0.613, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.457, "dev_c": 0.145, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ffbd7244-d7a4-4a09-8fcf-e1ff290f2f0f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c6cf7472-9228-482d-bb12-7f123be39627	190124110002252	fail	0.965	[{"cal_c": -41.75, "dev_c": -0.965, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.697, "dev_c": -0.895, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.567, "dev_c": 0.254, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8495f127-e646-4545-af00-d9af8a84b2e1	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d2f51937-8031-495c-a518-3f4ec27deb96	190124110002253	fail	1.255	[{"cal_c": -42.04, "dev_c": -1.255, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.547, "dev_c": -1.044, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.96, "dev_c": 0.648, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
c120e6e7-ed4c-40b6-a10a-409dccd57f8b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	45a30dd4-067f-4d5e-b244-e7f0d283c6f6	190124110002254	fail	0.571	[{"cal_c": 5.258, "dev_c": -0.334, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.883, "dev_c": 0.571, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
86952df9-ca36-4401-a650-7769bae019e3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3a66670f-ce7f-43ca-83d7-98a6b7eca2aa	190124110002255	fail	0.587	[{"cal_c": 5.255, "dev_c": -0.337, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
70d9427a-1119-4841-b818-3784698bfd91	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1d5ac371-5d0b-4711-9fe9-51929c6f9bb5	190124110002256	fail	0.810	[{"cal_c": -41.402, "dev_c": -0.616, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.781, "dev_c": -0.81, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
0a532fbb-c7a1-49a0-a1ce-ec94afdbe429	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1fb83725-6d6b-42c9-9b11-91b2724bbd95	190124110002257	fail	0.568	[{"cal_c": 5.345, "dev_c": -0.247, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
b909f5f2-0675-4df6-9bc4-d268be0e91cf	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	715c7b63-d4e6-40af-bbca-2b2618b651d7	190124110002258	fail	0.830	[{"cal_c": -41.615, "dev_c": -0.83, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.912, "dev_c": -0.68, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bc296d1b-a80b-4834-986b-41d12a14c748	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c35aad73-3ddd-4e6a-a127-df65ac48bbfb	190124110002259	pass	0.387	[{"cal_c": 5.269, "dev_c": -0.323, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.387, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f52ec51f-054b-465b-9b71-3c9fb03ff78c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	400b5b4e-1b2f-4f4c-b951-4c0ac8331d84	190124110002260	fail	0.749	[{"cal_c": -41.228, "dev_c": -0.442, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.843, "dev_c": -0.749, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.329, "dev_c": 0.016, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
cb5633f2-c633-4372-ba81-c312f8fbde86	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	612c812e-bf14-498e-b93a-a629c4d9a542	190124110002261	pass	0.280	[{"cal_c": 5.312, "dev_c": -0.28, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.475, "dev_c": 0.163, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e82506a5-3c74-48d1-afcd-5a66882742fb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3b9bd127-2c9a-487c-9378-8dfd25b8530c	190124110002262	fail	0.852	[{"cal_c": -41.638, "dev_c": -0.852, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.833, "dev_c": -0.758, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.72, "dev_c": 0.407, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
13649b61-67c8-4414-a448-ba4adabd4ed0	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e9161e28-8ba7-495a-9d02-d19eff7ba14c	190124110002263	fail	0.767	[{"cal_c": 5.265, "dev_c": -0.327, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.08, "dev_c": 0.767, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
ce6db145-d491-4358-b6a6-3d847ad3a781	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e8027d2e-7c51-4ac9-b925-7d3ba1242b3f	190124110002264	fail	1.261	[{"cal_c": -42.047, "dev_c": -1.261, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.782, "dev_c": -0.809, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.78, "dev_c": 0.468, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e8db292c-6932-40ba-8a54-ea8821c62da5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5ff13dcb-c2e9-4f22-b80d-1f37486371de	190124110002265	fail	0.502	[{"cal_c": 5.382, "dev_c": -0.209, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.814, "dev_c": 0.502, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
e9292d76-7c75-4210-afc9-d432bae26488	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f35df738-3d01-4ae2-9f93-7b6830a022d0	190124110002266	fail	0.627	[{"cal_c": 5.235, "dev_c": -0.357, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.94, "dev_c": 0.627, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
c49930d9-c3fb-47c0-aeb6-45b37daa63ce	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	893d8048-a8cc-4136-afa3-d9fa576ff43d	190124110002267	pass	0.438	[{"cal_c": 5.422, "dev_c": -0.17, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.75, "dev_c": 0.438, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2d872764-6967-40ff-9409-34d4ad040e13	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	67e68b87-1b04-4041-af4e-ee7779e08642	190124110002268	pass	0.225	[{"cal_c": 5.438, "dev_c": -0.153, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.538, "dev_c": 0.225, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9cea77eb-e93e-40e3-9cc1-b8162488c2a5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	4dce63b6-3fea-4bcf-8f2e-6cade4f60204	190124110002269	fail	0.538	[{"cal_c": 5.316, "dev_c": -0.275, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.85, "dev_c": 0.538, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
e433eae8-2d92-4e97-8d4e-fe518c72d548	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	faa8cb56-f024-4faf-8427-50994c769b25	190124110002270	pass	0.197	[{"cal_c": 5.395, "dev_c": -0.197, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
83abb367-41ea-49ad-bc70-8714407975a6	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c823f54d-7125-4dcd-950a-fde74b11984e	190124110002271	fail	0.742	[{"cal_c": -41.527, "dev_c": -0.742, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.884, "dev_c": -0.708, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.614, "dev_c": 0.302, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
90ec5095-8311-4bdd-957c-66b41933af19	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5e260b05-a9fd-4633-b9b2-61a4a16effed	190124110002272	fail	0.803	[{"cal_c": -41.573, "dev_c": -0.788, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.789, "dev_c": -0.803, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.533, "dev_c": 0.221, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a1debb35-04cb-48f7-b17b-047ff661c6ef	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	372148cf-4fe1-413c-a9a3-df1ffcde640d	190124110002273	fail	0.878	[{"cal_c": -41.663, "dev_c": -0.878, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.844, "dev_c": -0.748, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
89a53282-8931-4864-a036-013802308679	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6a3094bc-22e6-40cf-a330-c9ef2983d7d1	190124110002274	fail	0.734	[{"cal_c": -41.266, "dev_c": -0.48, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.858, "dev_c": -0.734, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.487, "dev_c": 0.175, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b1f477ca-aaff-4b36-abe8-c2afbda23f2c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a4b28f19-d1bd-448a-b0db-0ca74ce5d192	190124110002275	fail	0.778	[{"cal_c": -41.276, "dev_c": -0.49, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.813, "dev_c": -0.778, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.283, "dev_c": -0.029, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f90c2e0a-beed-403b-bd8d-2b165a90381d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	52526594-98e3-48b0-8e03-443d6b90b811	190124110002276	fail	0.730	[{"cal_c": -41.356, "dev_c": -0.57, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.861, "dev_c": -0.73, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a4e1fd06-d7c7-4601-8724-83b379bdb02b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2d8f2ee9-d732-4962-ba42-9b8c507ce103	190124110002277	fail	0.803	[{"cal_c": 4.788, "dev_c": -0.803, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.457, "dev_c": 0.145, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
34619b53-9e4c-4509-a7ae-6d0b887a3172	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b8393a23-39eb-4422-aab5-55d4049d594e	190124110002278	pass	0.325	[{"cal_c": 5.341, "dev_c": -0.251, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.638, "dev_c": 0.325, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
0f69a88a-353c-4897-9174-acfaf0ae2b28	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	de7bf3dc-31fe-47b7-8f2f-680b9b953944	190124110002279	pass	0.345	[{"cal_c": 5.348, "dev_c": -0.243, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.657, "dev_c": 0.345, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
fd5a2d15-a2ea-4f79-99f4-16b102987e9b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	dfbe9a87-42f6-4993-ba68-adec522f2afb	190124110002280	pass	0.497	[{"cal_c": 5.095, "dev_c": -0.497, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.767, "dev_c": 0.454, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
27914b8f-73db-452e-b3d8-a803e4af4a8b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5a73aa8b-8a72-444b-afbc-906e067f27aa	190124110002281	fail	0.721	[{"cal_c": 5.359, "dev_c": -0.232, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.033, "dev_c": 0.721, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
5ed22220-1e63-4292-9fb5-6541433ceefb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b2d31def-3bf1-4c96-b182-285aeedbf531	190124110002282	pass	0.438	[{"cal_c": 5.443, "dev_c": -0.149, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.75, "dev_c": 0.438, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
88907f59-b678-47be-861a-bf292f02f74e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1bf83bfe-f791-42e2-ad95-e81befd4a135	190124110002283	fail	0.780	[{"cal_c": -41.331, "dev_c": -0.546, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.812, "dev_c": -0.78, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.443, "dev_c": 0.13, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2cece593-d568-4dce-9d08-73ccc3c5218b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c56541ab-8f29-4142-abb8-845832d31e6e	190124110002284	pass	0.275	[{"cal_c": 5.478, "dev_c": -0.113, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.587, "dev_c": 0.275, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ed9c41bd-00ca-48e8-bf15-47154458c35b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f8e8522a-0674-4a15-981a-1d18be34e033	190124110002285	pass	0.426	[{"cal_c": 5.165, "dev_c": -0.426, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.55, "dev_c": 0.237, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
425c0704-596f-44e2-926e-8870dc641060	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f5de2a55-35fa-4d11-b6f2-d748841fc026	190124110002287	pass	0.487	[{"cal_c": 5.255, "dev_c": -0.337, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
17b5f73f-a2e1-4553-87b0-901ab9ee9d9f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	4dde7a2a-961b-45f5-b6bc-95a8100bc514	190124110002288	fail	0.811	[{"cal_c": -41.46, "dev_c": -0.674, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.781, "dev_c": -0.811, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.85, "dev_c": 0.538, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f5e12aab-02f3-4950-8b26-a47b3831ba50	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	44e159e5-9adc-4116-b9e8-d858aeb12d64	190124110002289	fail	0.538	[{"cal_c": 5.307, "dev_c": -0.284, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.85, "dev_c": 0.538, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
e67690c9-55a6-4717-a1bc-9243a8489a46	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	096f837e-8fa1-4d4b-bc2b-18ebd35ba02f	190124110002290	fail	0.782	[{"cal_c": 4.81, "dev_c": -0.782, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.733, "dev_c": 0.421, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
662a58f4-a83b-4cb6-899e-d4a9cbfbf0fb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	86fdd7c1-91c4-48c6-a1ad-edf5d14f6576	190124110002291	pass	0.430	[{"cal_c": 5.264, "dev_c": -0.327, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.743, "dev_c": 0.43, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
57246953-f410-4079-a37d-a8bbbf0c64f3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	35663830-25a0-457a-956b-42b82278c80c	190124110002292	pass	0.300	[{"cal_c": 5.436, "dev_c": -0.156, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.612, "dev_c": 0.3, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bf300154-388b-4594-a861-b05a4ac29c4b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d3d19ea9-c814-4c23-b4b8-3fc7822c1d81	190124110002293	pass	0.325	[{"cal_c": 5.348, "dev_c": -0.244, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.638, "dev_c": 0.325, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
841dd190-51cc-4424-874b-88a9b566568c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	63d11f38-7155-4fd2-adac-1489111ae929	190124110002294	fail	0.796	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.796, "dev_c": -0.796, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.533, "dev_c": 0.221, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b8f3935f-5fe6-4749-aeff-792f224c71b8	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	36291c1f-ea48-49db-8c70-665768091e09	190124110002295	fail	1.159	[{"cal_c": -41.945, "dev_c": -1.159, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.792, "dev_c": -0.8, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ca04003a-2956-496f-a13e-ae23fad85e5d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2c39820c-0544-443a-8e0c-0a1bfa20fbe1	190124110002296	fail	1.330	[{"cal_c": -42.116, "dev_c": -1.33, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.719, "dev_c": -0.873, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8e7f09db-e7b9-4836-86b2-715b0ef63b7a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	49792685-9b63-4683-818c-fe7381541f45	190124110002297	pass	0.388	[{"cal_c": 5.232, "dev_c": -0.36, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
63cf596d-d7cb-48b8-8a02-d9b51a626cee	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	89c8d684-bbad-4032-a460-01a191959052	190124110002298	pass	0.406	[{"cal_c": 5.185, "dev_c": -0.406, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
7a9acdb2-384e-4093-9889-d0bfca144e74	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ad68f9d3-8e03-4a2a-a978-ede8289822cf	190124110002299	pass	0.388	[{"cal_c": 5.441, "dev_c": -0.151, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bb7285c2-e6cd-47ca-9ae4-e5ad6311aac9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d2b5c4b8-1e2a-4e5b-bf78-d15ae7d874c9	190124110002300	fail	0.587	[{"cal_c": 5.391, "dev_c": -0.201, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
963dea4e-d0ff-43b1-ae84-b511ebb1e1e3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	0bba028e-e8e1-46b6-a749-89efb5bcf617	190124110002301	pass	0.175	[{"cal_c": 5.424, "dev_c": -0.168, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.487, "dev_c": 0.175, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2592637e-c7fa-4bb6-801e-1361ad30c8b5	320c8e6c-51e2-43ea-b741-1be9b3629848	fac4e37d-35ff-48ea-b1a6-6e649a80abb2	190125070005578	pass	\N	[]	0000001268	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001268_190125070005578.docx	2025-10-01 09:00:00+00
d5fbe81a-208d-42a0-82c8-95a7c1d4ffa3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	fe606efe-34c4-4020-873c-abcef660abaf	190124110002302	fail	0.504	[{"cal_c": 5.262, "dev_c": -0.33, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.817, "dev_c": 0.504, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
24c42694-9e39-4aea-ad11-cb70c3414451	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	88ff6900-005d-47ba-99f0-682689854362	190124110002303	fail	1.368	[{"cal_c": -42.153, "dev_c": -1.368, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.49, "dev_c": -1.102, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
5a479fee-a631-4839-9e54-1045f845d6bc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1a7a5736-53a4-4e8e-bb05-e7add55d3ce2	190124110002304	fail	0.934	[{"cal_c": -41.719, "dev_c": -0.934, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.839, "dev_c": -0.753, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.66, "dev_c": 0.348, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
db211966-3d67-4dba-a965-251ed00fa161	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1911123e-2de0-4a56-a22c-521869c03fe4	190124110002305	fail	0.923	[{"cal_c": -41.518, "dev_c": -0.732, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.668, "dev_c": -0.923, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.15, "dev_c": -0.163, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
4d9f4c36-bf34-4df5-90e9-f81d5dd396af	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f4e7a703-cea2-468b-a796-5be73d178c32	190124110002306	fail	0.821	[{"cal_c": -41.606, "dev_c": -0.821, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.809, "dev_c": -0.783, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
68922b0c-5bcf-49ec-b5f0-1afc9bfd387b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3445f112-8a23-4839-8ef6-337eb43ee4b4	190124110002307	pass	0.404	[{"cal_c": 5.389, "dev_c": -0.203, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.717, "dev_c": 0.404, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
17425601-6af7-4255-82ed-279680533980	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	65b3ad70-c89c-47db-a99a-000f2d105f5d	190124110002308	fail	1.413	[{"cal_c": -42.199, "dev_c": -1.413, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.829, "dev_c": -0.763, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.514, "dev_c": 0.202, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2fd512b7-0130-4f04-98d0-24362599257d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3f528bc4-19de-4d77-b9a6-00ae096bbac8	190124110002309	fail	0.725	[{"cal_c": -41.295, "dev_c": -0.51, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.867, "dev_c": -0.725, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.629, "dev_c": 0.316, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e55d2aa3-284f-4ea0-b8ec-67b4ea88fd4d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a91bc509-bbba-44a1-8a58-facd4887cf21	190124110002310	fail	0.502	[{"cal_c": 5.358, "dev_c": -0.233, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.814, "dev_c": 0.502, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
17c40fd8-138a-47ca-a4cd-f238f3c209aa	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5ccd24f5-f2c3-4818-89c3-d5918d1e324f	190124110002311	pass	0.487	[{"cal_c": 5.401, "dev_c": -0.19, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
cecc8d60-dd11-47f8-b5db-efbded0f53f4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c189366c-c42b-4a67-8c2e-a1b8b3f9c391	190124110002312	fail	0.829	[{"cal_c": -41.349, "dev_c": -0.564, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.763, "dev_c": -0.829, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d5164b3c-5f5a-4da7-9b5a-58f2edd25065	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	4783310d-7c7e-428d-aa25-72d4afee3f5c	190124110002313	pass	0.487	[{"cal_c": 5.282, "dev_c": -0.31, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d39308df-17b3-4bab-ad71-9d41c4850adb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9db1d0fa-729e-4cba-b3e1-27f5a5bf8797	190124110002314	pass	0.454	[{"cal_c": 5.409, "dev_c": -0.183, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.767, "dev_c": 0.454, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
88224aa7-b3ab-4af6-8c3c-e28a33f8c0cc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	dfb49559-9483-457e-a2cf-7cb5595d8d02	190124110002315	fail	0.784	[{"cal_c": -41.177, "dev_c": -0.391, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.807, "dev_c": -0.784, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.667, "dev_c": 0.354, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e2ef774a-4a5e-48fe-b4f9-caf5c99e1a5b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d547f5f9-d611-46d9-b5bf-ed7c36ca279f	190124110002316	fail	0.817	[{"cal_c": -41.308, "dev_c": -0.523, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.775, "dev_c": -0.817, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.84, "dev_c": 0.527, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
18a40400-10bf-45d7-b413-c89d1738dd64	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	52352c27-40fb-4904-ad6b-f3065d117302	190124110002317	fail	0.943	[{"cal_c": -41.267, "dev_c": -0.481, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.649, "dev_c": -0.943, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9ebdc334-2dff-42bf-94d7-f08531be2afd	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ee58d746-9c25-4f97-bcf0-df9abdf823a1	190124110002318	fail	0.608	[{"cal_c": 5.248, "dev_c": -0.344, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.92, "dev_c": 0.608, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
2c86258b-d72a-4f27-9168-b42590c10c1c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	98e700e1-cf28-4bbb-b1eb-acae487bc1ea	190124110002319	fail	0.627	[{"cal_c": 5.156, "dev_c": -0.436, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.94, "dev_c": 0.627, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
bf61a523-eefb-45a2-8645-bc73a2393720	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	cd3cd1c1-01f5-4cd2-8232-00206a456fa1	190124110002320	pass	0.487	[{"cal_c": 5.369, "dev_c": -0.223, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bfe5b19c-3c8c-4bef-88bf-8274868d08d8	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d4c7af21-27ad-4bac-acda-2b287cf0ed47	190124110002321	fail	0.785	[{"cal_c": -41.448, "dev_c": -0.663, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.807, "dev_c": -0.785, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.583, "dev_c": 0.271, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
4baaeb09-f8e3-4e62-beac-6747d131ab39	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	aff68fe9-275c-4f97-9017-b0f5cb876aad	190124110002322	fail	0.767	[{"cal_c": -41.239, "dev_c": -0.454, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.825, "dev_c": -0.767, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
cf5fc005-b8a2-40b1-ad67-9cb508237353	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	bfe9c5a6-6ce0-4872-80e0-1b15077650bc	190124110002323	fail	0.772	[{"cal_c": -41.219, "dev_c": -0.433, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.82, "dev_c": -0.772, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.76, "dev_c": 0.447, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2fa253d9-f356-4646-abf1-9d6c7428b520	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ec7b80de-5526-4531-9446-c40364a3a21a	190124110002324	fail	0.822	[{"cal_c": -41.223, "dev_c": -0.437, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.77, "dev_c": -0.822, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.75, "dev_c": 0.438, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
745a671d-336e-485f-a9e8-43ce5ecd796f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	500b0aa9-5fc1-4f00-a171-690a46235efc	190124110002325	fail	0.705	[{"cal_c": -41.267, "dev_c": -0.481, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.887, "dev_c": -0.705, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.86, "dev_c": 0.547, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
7f3adbfc-fa83-464b-a3b7-403ae3bcda09	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3e2ebd29-9b27-4e6c-8ec2-bc690aa02d4b	190124110002326	fail	0.681	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.91, "dev_c": -0.681, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.66, "dev_c": 0.348, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
dc54d7dc-fdee-476b-a6c6-96820b29c2d2	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f20f531d-2f49-430a-a9fb-f90dd3601550	190124110002327	fail	0.678	[{"cal_c": -41.463, "dev_c": -0.678, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.941, "dev_c": -0.651, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.438, "dev_c": 0.125, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ce6be0fe-280e-43c9-81d0-c33e703eacb4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	aacf9ab3-9a52-4fef-ae57-8a36d63f1504	190124110002328	fail	0.666	[{"cal_c": -41.113, "dev_c": -0.327, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.925, "dev_c": -0.666, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.462, "dev_c": 0.15, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
01e71a72-c1a7-41f8-9ace-54baec47f3d3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	746ddc9f-bf77-4cd2-abd0-283de973dbac	190124110002329	fail	1.030	[{"cal_c": -41.815, "dev_c": -1.03, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.956, "dev_c": -0.635, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.513, "dev_c": 0.2, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
7df5ab5e-c566-4cc2-b8e8-8c99d61557a3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	756ebd2c-aac5-4d45-a9ae-3745f927c072	190124110002330	fail	0.568	[{"cal_c": 5.196, "dev_c": -0.395, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
dff86999-1b7e-44a0-9650-e2d56d89d37a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b935c0da-6924-4d9e-849c-b52552af6f1b	190124110002331	fail	0.538	[{"cal_c": 5.278, "dev_c": -0.313, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.85, "dev_c": 0.538, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
a3c7979b-9891-49c7-92e9-23fa684e3594	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9671d203-e182-44ac-8ab6-acb17ef92b3a	190124110002332	fail	0.559	[{"cal_c": 5.353, "dev_c": -0.238, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.871, "dev_c": 0.559, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
541ec92b-6ddc-4f50-a31d-7c2086216f8d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d7394392-0fd9-4b9b-824a-cf1fe1435aaa	190124110002333	fail	0.571	[{"cal_c": 5.405, "dev_c": -0.186, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.883, "dev_c": 0.571, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
59f10876-8105-4dbd-a906-b6954c3fcad5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	54dc8be0-59a2-4259-b001-ffc5c78a1d44	190124110002334	fail	0.638	[{"cal_c": 5.413, "dev_c": -0.179, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.95, "dev_c": 0.638, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f2c2f341-aebf-425b-9ec7-45e385522090	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	759dd178-bb7c-4c14-aa72-99080e933d5d	190124110002335	fail	0.502	[{"cal_c": 5.556, "dev_c": -0.035, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.814, "dev_c": 0.502, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
b5dee7d3-949d-4c39-8c15-bf2b7e0358df	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	fcda8ab8-3caf-48ad-96c0-dee8d3e67668	190124110002336	fail	0.638	[{"cal_c": 5.393, "dev_c": -0.198, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.95, "dev_c": 0.638, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
532eb1ee-abdd-453c-a68e-0676eaf0064e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	0aaa9598-d133-4b9c-a0de-813c2744dee8	190124110002337	fail	0.671	[{"cal_c": 5.198, "dev_c": -0.393, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.983, "dev_c": 0.671, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f2dd0dcc-edb9-4a2c-84b2-8a0ac44c3b98	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5faff10f-904d-48c9-8626-9481b22cb625	190124110002338	fail	0.602	[{"cal_c": 5.22, "dev_c": -0.372, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.914, "dev_c": 0.602, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
d47f4938-3db3-44d4-a758-1e6400198e25	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f1706796-0e13-4d2f-ba9f-e51a0ef26af3	190124110002339	fail	0.571	[{"cal_c": 5.349, "dev_c": -0.243, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.883, "dev_c": 0.571, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f68f16d1-c423-47d8-8fea-6c1fa7b11666	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	d0b68987-7dbb-4751-93d1-c712665afac6	190124110002340	fail	0.521	[{"cal_c": 5.176, "dev_c": -0.416, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.833, "dev_c": 0.521, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
77a3f08e-4ef1-4a41-9789-0f2189e424ea	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6837c69e-9049-480c-9fa7-138c1402a336	190124110002341	fail	0.704	[{"cal_c": 5.19, "dev_c": -0.402, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.017, "dev_c": 0.704, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
640ae766-eae6-4e45-aef2-3eaefd41cb0a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	93477bf4-09f3-4655-881a-8d6a8bcf75e0	190124110002342	fail	1.132	[{"cal_c": -41.918, "dev_c": -1.132, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.787, "dev_c": -0.804, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.667, "dev_c": 0.354, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
c7beed00-a6c7-46ad-9490-7108288047a4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3c6e9b89-45ff-4549-b59a-37e1ec69f0cd	190124110002343	fail	0.587	[{"cal_c": 5.485, "dev_c": -0.107, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
071b89e4-2aa8-41f8-8bf6-7770ece9fec9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6ae51035-a971-424f-8f0f-8cc6fd0d9682	190124110002344	fail	0.688	[{"cal_c": 5.398, "dev_c": -0.194, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.0, "dev_c": 0.688, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
b2ecb4c2-d1a0-460c-9804-8130943048b4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6159f221-a2df-430e-a309-c9669d680012	190124110002345	fail	0.988	[{"cal_c": -41.773, "dev_c": -0.988, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.825, "dev_c": -0.766, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e517d33d-88c6-4e4a-bfad-be9e1ef1ada7	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c08defe5-7e03-4bd5-b1ae-c33c0bcce143	190124110002346	fail	0.818	[{"cal_c": -41.535, "dev_c": -0.75, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.773, "dev_c": -0.818, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bcc94d93-3d32-4cdb-83fa-63a2c5418d5a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a9ed498d-a21a-46e5-9d39-47e3b3b077d8	190124110002347	fail	0.887	[{"cal_c": -41.673, "dev_c": -0.887, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.839, "dev_c": -0.752, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.525, "dev_c": 0.212, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
347903b2-47d9-46f3-8160-78c48c8bb1d4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	cd8ad739-a90f-4e37-a8f3-7da18fd6a86e	190124110002348	fail	0.621	[{"cal_c": 5.459, "dev_c": -0.133, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.933, "dev_c": 0.621, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
d8787a77-ceda-47a7-8e6c-8ee3293cedf0	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	80f5c76c-3db7-4d04-8eff-12aaed57f38d	190124110002349	fail	0.763	[{"cal_c": 5.312, "dev_c": -0.28, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.075, "dev_c": 0.763, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
3504e5bc-7cee-42d3-b1dd-baad5c306d31	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	53562729-9a60-4696-b154-5c50fb61ca7a	190124110002350	fail	0.604	[{"cal_c": 5.295, "dev_c": -0.297, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.917, "dev_c": 0.604, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
8f98064e-f70b-4f8a-9dd5-55d24ec599e7	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	be0dbc11-a6fa-4474-9259-8f5f78320cf6	190124110002351	fail	0.743	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.849, "dev_c": -0.743, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.386, "dev_c": 0.073, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b8f9bd41-bd34-44f8-8ff7-bad20bd36779	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e58e4341-5ee9-4c6c-89ae-887b52d58623	190124110002352	pass	0.212	[{"cal_c": 5.561, "dev_c": -0.031, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.1, "dev_c": -0.212, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
3cea3393-d4fc-4d23-8015-0a3135128728	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9c4cc1d1-000a-416b-83c0-02b1955cdf38	190124110002353	pass	0.263	[{"cal_c": 5.329, "dev_c": -0.263, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.513, "dev_c": 0.2, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b141b894-153f-4b1c-b9fd-f97fb54d65aa	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	212c744e-162e-47d8-a79f-ff6687111f46	190124110002354	fail	1.059	[{"cal_c": -41.845, "dev_c": -1.059, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.746, "dev_c": -0.846, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.487, "dev_c": 0.175, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
127238f4-7aa4-4769-b77b-b82441eb2f57	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c366d9f8-7663-4e6f-862f-24ee32ee3475	190124110002355	fail	0.758	[{"cal_c": -41.44, "dev_c": -0.655, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.833, "dev_c": -0.758, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
86f7e474-b7a5-4a44-aa18-150087fbf30d	320c8e6c-51e2-43ea-b741-1be9b3629848	9bbb9581-98c1-4c58-803c-e2a5b9e75ee9	190125070005579	pass	\N	[]	0000001269	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001269_190125070005579.docx	2025-10-01 09:00:00+00
6579736e-5a6f-4fd5-954d-f83e5c9f1bb3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b31872fb-59e8-47b0-9b9c-0019e645af94	190124110002356	fail	1.669	[{"cal_c": -42.454, "dev_c": -1.669, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.741, "dev_c": -0.85, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.333, "dev_c": 0.021, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b6930961-ce48-4906-9500-5358044ae20d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	8b77134d-22a8-481b-a770-e627d8861578	190124110002357	pass	0.230	[{"cal_c": 5.466, "dev_c": -0.126, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e1e97847-6e23-4de2-baaa-ad871239d91e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	44069c97-e621-484c-8814-00495fee2ef1	190124110002358	fail	0.545	[{"cal_c": 5.321, "dev_c": -0.27, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.857, "dev_c": 0.545, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
1efc957c-545a-4274-bdf6-87e55e43933a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	8bc9ec3e-5134-45ee-8c98-6445c0042cf6	190124110002359	pass	0.306	[{"cal_c": 5.286, "dev_c": -0.306, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.513, "dev_c": 0.2, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9b3bff3f-57b1-402c-9152-331063fbac69	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	261cbeae-9133-4381-b9b3-43ad2bce59a7	190124110002360	pass	0.454	[{"cal_c": 5.35, "dev_c": -0.241, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.767, "dev_c": 0.454, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ce7a4a4a-bbf3-48ee-b0a8-ce4874957e6b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5a3713fa-fdef-495a-b046-3c57ed6f0dd1	190124110002361	fail	0.887	[{"cal_c": -41.294, "dev_c": -0.508, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.705, "dev_c": -0.887, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
27d0fb48-1f77-4b74-a7d2-a7c05274b5f5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	afba72ca-f7f1-4bef-bf68-b442d7c69047	190124110002362	fail	0.748	[{"cal_c": 5.286, "dev_c": -0.306, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.06, "dev_c": 0.748, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
6ca495cf-63cf-4224-aa5b-7bc60a1e7b72	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c376f209-0186-4258-ac02-36aee11bfcf7	190124110002363	pass	0.450	[{"cal_c": 5.142, "dev_c": -0.45, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.629, "dev_c": 0.316, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
427c2da7-4a1b-4250-bd9e-9e639a6756c9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5291e9e2-3564-4440-b337-3141f87c4769	190124110002364	pass	0.350	[{"cal_c": 5.296, "dev_c": -0.295, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.663, "dev_c": 0.35, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d3f1a7b5-3a4b-4faa-934c-9a0f0d5ead9d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a60bccc8-526e-47e5-b8a3-05c845b9186a	190124110002365	pass	0.388	[{"cal_c": 5.45, "dev_c": -0.142, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
63a03e21-a780-4504-9725-7b13fe41a89d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	52f95ebe-5b65-4413-a1bf-bded4073c370	190124110002366	fail	0.667	[{"cal_c": 5.236, "dev_c": -0.355, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.98, "dev_c": 0.667, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
c7e40c74-86af-4401-9968-0eb5cbe51b29	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	10ff1cac-f4a6-4297-88cc-a0516e7fb300	190124110002367	fail	0.708	[{"cal_c": 5.298, "dev_c": -0.293, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.02, "dev_c": 0.708, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
0eedaa02-8673-4283-b979-80f34e886a07	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	afa39b0d-3f24-49cd-a8ea-dee6d3a16b7b	190124110002368	fail	1.135	[{"cal_c": -41.921, "dev_c": -1.135, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.759, "dev_c": -0.833, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.65, "dev_c": 0.337, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
73f2358f-1ad7-4b44-b2b4-4ac581b9f735	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6f68edd4-a681-4d6b-b2b9-be58e1f33cfa	190124110002369	pass	0.388	[{"cal_c": 5.393, "dev_c": -0.199, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
6e463c61-b829-4894-9b92-8eb3facc6007	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3a95487f-03ce-4c8f-af9e-fc4ab8240f36	190124110002370	pass	0.438	[{"cal_c": 5.35, "dev_c": -0.242, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.75, "dev_c": 0.438, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
1423e1ab-2aab-46c7-b81a-d24b5bbd347f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	227f93e5-9a36-4d02-be21-43f9586c5214	190124110002371	fail	0.587	[{"cal_c": 5.34, "dev_c": -0.252, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
f3143059-64aa-4cea-a266-5cdafa525b00	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9cba7b3a-8141-48d9-97c4-153213e3710b	190124110002372	pass	0.163	[{"cal_c": 5.429, "dev_c": -0.163, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.462, "dev_c": 0.15, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9d8458be-d4be-4b89-8115-cb96c88a2880	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	05e37074-ce54-4a70-af80-de5d08b57ad1	190124110002373	pass	0.246	[{"cal_c": 5.435, "dev_c": -0.157, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.067, "dev_c": -0.246, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bf77328d-f5cb-4c6d-beb2-a44341c9454c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	94bb67b0-31b4-4d92-a8a8-844e43ec15b9	190124110002374	pass	0.273	[{"cal_c": 5.58, "dev_c": -0.012, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.586, "dev_c": 0.273, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2acce859-f845-4c5f-922c-e0c209f0f1d5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	84e5d357-f3a3-4993-a270-084664fd9727	190124110002375	fail	0.958	[{"cal_c": -41.385, "dev_c": -0.6, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.634, "dev_c": -0.958, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.74, "dev_c": 0.428, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e9381398-4a72-4e09-84fe-0cc115a2fe99	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	dbecfc35-4679-4f85-8910-3e94c6857df2	190124110002376	fail	1.217	[{"cal_c": -42.003, "dev_c": -1.217, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.674, "dev_c": -0.918, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.567, "dev_c": 0.254, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
48f194d7-1277-4de7-afcb-d35a88506d90	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	65ef1619-28d3-4640-ba54-d1fbda11514d	190124110002377	fail	1.163	[{"cal_c": -41.949, "dev_c": -1.163, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.595, "dev_c": -0.997, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.78, "dev_c": 0.468, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
d24597fc-4ccc-4ebb-ad90-9174f521bb45	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2c3298e2-eb52-460d-8220-bdd5fe3af11f	190124110002378	fail	0.672	[{"cal_c": -41.196, "dev_c": -0.411, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.92, "dev_c": -0.672, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.72, "dev_c": 0.407, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f4163e96-5d6d-49af-8747-1c3fe5dcd99a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f23c9ed4-6105-4b18-abfa-30ff853f4315	190124110002379	fail	0.755	[{"cal_c": -41.316, "dev_c": -0.531, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.836, "dev_c": -0.755, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
4d25477d-f51e-4d7a-b3c4-e292136b0cd8	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	9033c785-2b2a-425b-925c-8d52ffc6c947	190124110002380	fail	1.147	[{"cal_c": -41.933, "dev_c": -1.147, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.552, "dev_c": -1.04, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.65, "dev_c": 0.337, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
bc9c1109-2882-4d8e-8c0d-b0cc24760397	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	665322a2-7190-4f4c-ba13-0caa2069071b	190124110002381	pass	0.487	[{"cal_c": 5.415, "dev_c": -0.177, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
c9c9e0d3-f78f-4a9c-bbdf-890a7f751750	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	51191469-b0eb-450e-bbab-bb94846afbce	190124110002382	pass	0.288	[{"cal_c": 5.358, "dev_c": -0.234, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
fa8a6811-1662-45e2-af47-88ce5a75358d	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e77e2037-2742-4f29-9c5c-01fd01e8c59a	190124110002383	fail	0.873	[{"cal_c": -41.203, "dev_c": -0.418, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.718, "dev_c": -0.873, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8d3fa7d0-bce7-48d0-a511-30439223e1ae	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	650b2bc9-942f-443c-b096-d35feb7fbd01	190124110002384	pass	0.459	[{"cal_c": 5.235, "dev_c": -0.357, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.771, "dev_c": 0.459, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9ea7712b-beaf-4143-a77a-3c5408cf44ae	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	39cafe05-240c-4b24-a8db-11151dfb5098	190124110002385	fail	0.835	[{"cal_c": -41.267, "dev_c": -0.482, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.757, "dev_c": -0.835, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
300e2640-7fb3-4092-874e-9232cd2dfdca	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	295f0fa6-c768-42b6-a773-acf94f029f40	190124110002386	pass	0.312	[{"cal_c": 5.279, "dev_c": -0.312, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.133, "dev_c": -0.179, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
1225f8d5-f582-4f7a-a394-d877963211b5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a8a77e59-fa94-4ab5-97b3-690271953129	190124110002387	pass	0.437	[{"cal_c": 5.155, "dev_c": -0.437, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ae95f01a-a0ba-403b-ab48-1f2aceaf7cc6	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	82e74632-5741-4069-86b3-135fef613f95	190124110002388	fail	0.621	[{"cal_c": 5.318, "dev_c": -0.274, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.933, "dev_c": 0.621, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
3832eb18-f7de-4482-9372-e3f414d584e4	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ea48e90c-2fcd-4fa0-88ad-aa2e497ef270	190124110002389	pass	0.335	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
240d06bd-6397-46c6-ac56-10996d042c3a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ad10783f-3159-4f47-bff7-0700856496d5	190124110002390	pass	0.421	[{"cal_c": 5.368, "dev_c": -0.224, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.733, "dev_c": 0.421, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
83159aa6-23d1-49db-b149-e96a0981fa6f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6e04826c-50c3-42b3-9f07-cea66686e3da	190124110002391	pass	0.487	[{"cal_c": 5.31, "dev_c": -0.281, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b12e5d1c-08f2-4a62-99cb-e1b850cb61bb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2bd11af5-b3ff-41f3-a7ef-d921b43601f6	190124110002392	fail	0.568	[{"cal_c": 5.374, "dev_c": -0.218, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
7ed35754-ab41-404c-9cd1-7409d53bbe84	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	6d961887-335d-4d3a-b63c-4aff1b916e8d	190124110002393	fail	0.665	[{"cal_c": 4.927, "dev_c": -0.665, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.767, "dev_c": 0.454, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
5a9bcb9c-526d-42c5-aa43-2cadf15bd319	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	737600a6-0671-42cf-9720-fb35aa3f2a1b	190124110002394	fail	0.937	[{"cal_c": -41.439, "dev_c": -0.654, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.655, "dev_c": -0.937, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.486, "dev_c": 0.173, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
590696ca-97b7-4518-99b6-43f8115db352	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a5660e19-ca7b-4beb-b4d7-c6f734344640	190124110002395	fail	0.765	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.827, "dev_c": -0.765, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.68, "dev_c": 0.367, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
943b12e7-aff7-4afa-a1c6-eafaf4f45ce7	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	759c4bac-2771-46a1-bf5e-48bb319ff033	190124110002396	fail	0.822	[{"cal_c": -41.6, "dev_c": -0.815, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.77, "dev_c": -0.822, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.74, "dev_c": 0.428, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
ddd8315e-a7da-4210-bbda-5e240cbe9a46	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	52cd91b3-9e15-4a2c-ac7f-dc06eb0442e2	190124110002397	fail	1.263	[{"cal_c": -42.049, "dev_c": -1.263, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.724, "dev_c": -0.868, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
6b565f37-9b06-41db-83e4-ad4cb9e1e03f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	cdd1c28c-0763-482b-9f50-cfb856e51912	190124110002398	fail	1.378	[{"cal_c": -42.163, "dev_c": -1.378, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.698, "dev_c": -0.894, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
7e1f559e-4e28-4205-93c5-07be50363c7a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	83e04cf6-35fd-4b07-b782-a5269ef93153	190124110002399	pass	0.345	[{"cal_c": 5.351, "dev_c": -0.241, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.657, "dev_c": 0.345, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
66358eb5-4189-4d3d-b848-4e15517f6941	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	53420c88-82cc-4e7a-bb05-0d3cb1e7caa4	190124110002400	fail	0.809	[{"cal_c": -41.42, "dev_c": -0.634, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.782, "dev_c": -0.809, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.471, "dev_c": 0.159, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
f3be5f1b-3678-4e4d-814c-7f52d73a815f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	db0dfe95-f3cc-4d9a-90c9-6cd6732b62ba	190124110002401	pass	0.325	[{"cal_c": 5.322, "dev_c": -0.269, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.638, "dev_c": 0.325, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9ecac2a3-073d-4ff2-a54a-b47104aa201f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a3a9dcfb-65f7-4cf2-8709-6b967cf59f16	190124110002402	fail	1.267	[{"cal_c": -42.053, "dev_c": -1.267, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.704, "dev_c": -0.888, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.633, "dev_c": 0.321, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
4e9c5e94-dade-4528-90d8-506854503f20	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	41ff323b-104c-4120-b873-6a5073fa0c8a	190124110002403	fail	1.251	[{"cal_c": -42.036, "dev_c": -1.251, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.727, "dev_c": -0.864, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.438, "dev_c": 0.125, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a703b433-8149-4b11-91d6-df21d40df1fb	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	429f3889-b9aa-4b29-b085-f849542bd7fb	190124110002404	fail	0.587	[{"cal_c": 5.411, "dev_c": -0.181, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.9, "dev_c": 0.587, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
a1f9f12b-196e-49ca-828b-edaf16ee0ccc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a3808ff1-3e17-4e20-b8aa-64de9264e09b	190124110002405	fail	0.538	[{"cal_c": 5.38, "dev_c": -0.212, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.85, "dev_c": 0.538, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
74b2dfd9-94ad-45c3-8d3b-a7646b978e66	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2a31c2eb-185c-42ee-ae26-0600572f9490	190124110002406	fail	0.547	[{"cal_c": 5.196, "dev_c": -0.396, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.86, "dev_c": 0.547, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
118e92cb-030d-486b-8e9c-1ace882e9622	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3ceb9bdc-8ad4-45f5-8d8a-c2b695469542	190124110002407	fail	0.955	[{"cal_c": -41.74, "dev_c": -0.955, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.835, "dev_c": -0.757, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.417, "dev_c": 0.104, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2151f7b3-5c12-4e8e-b92b-8273f2cc3820	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	ccf83fe4-32e1-4719-8f67-8b7403f3aaca	190124110002408	fail	0.869	[{"cal_c": -41.579, "dev_c": -0.794, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.722, "dev_c": -0.869, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.717, "dev_c": 0.404, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
24407f20-d8da-493c-9c73-500e2f18d9a9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c7e2d5c8-1e16-4b7a-b179-adbf53296ff2	190124110002409	fail	1.295	[{"cal_c": -42.08, "dev_c": -1.295, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.679, "dev_c": -0.912, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.75, "dev_c": 0.438, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
1fe1dcf9-1b23-4f57-9bee-05ec6825fb4a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	35773b67-d62c-4bdf-adc4-fa6ada3edef3	190124110002410	fail	0.793	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.799, "dev_c": -0.793, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.733, "dev_c": 0.421, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
5d0df83a-2e76-4769-9819-c90b780b30f6	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	153b14f7-6073-480c-834c-a466b07e51bd	190124110002411	pass	0.237	[{"cal_c": 5.376, "dev_c": -0.215, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.55, "dev_c": 0.237, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2b85c0c5-7661-4eeb-87df-c119a252881c	320c8e6c-51e2-43ea-b741-1be9b3629848	e09a2e99-3c23-4e04-aa16-d6826f2ace8e	190125070005580	pass	\N	[]	0000001270	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001270_190125070005580.docx	2025-10-01 09:00:00+00
1f13b388-1c23-4dad-89ed-9d6ddbb9eabf	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	db87bb44-4bc9-4515-9b14-e73427f41e2e	190124110002412	pass	0.183	[{"cal_c": 5.409, "dev_c": -0.183, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.475, "dev_c": 0.163, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
30105b9b-bb39-45b1-91e6-8ed6682fbc4f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5763e300-c450-4a1b-a380-85bff3b6e921	190124110002413	pass	0.303	[{"cal_c": 5.289, "dev_c": -0.303, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.487, "dev_c": 0.175, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
65a17d78-ba71-42f5-b509-0bdc1447b0f5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	1d1b88ac-1790-46dc-8f5c-873343b051c2	190124110002414	pass	0.300	[{"cal_c": 5.433, "dev_c": -0.158, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.613, "dev_c": 0.3, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
3c66e78f-1ec6-4852-b7ae-71f01eee4a5f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2f842457-dcb3-47cc-adaf-ac2fed191a1f	190124110002415	fail	0.847	[{"cal_c": -41.441, "dev_c": -0.655, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.744, "dev_c": -0.847, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.529, "dev_c": 0.216, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
cdcaa11f-f88c-4277-ba97-a3217dfaf1b1	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a1a78692-4030-4cdd-9441-f933c395bd05	190124110002416	pass	0.388	[{"cal_c": 5.388, "dev_c": -0.203, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
aa871016-e78b-4449-960b-e5b160b1daa1	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	747a736c-3c9d-4d71-bfd7-60cadfb838a4	190124110002417	fail	0.504	[{"cal_c": 5.388, "dev_c": -0.203, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.817, "dev_c": 0.504, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
1a7cf0eb-3bf2-4e84-b787-9f7cbde6588b	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c80024b6-4852-4f85-bfa2-35a6d08525ae	190124110002418	fail	0.788	[{"cal_c": 5.279, "dev_c": -0.312, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.1, "dev_c": 0.788, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
998574e3-4332-4266-b016-2c4e40a64146	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c911088c-b071-475d-9490-d973fe9ef57b	190124110002419	fail	0.787	[{"cal_c": -41.386, "dev_c": -0.601, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.804, "dev_c": -0.787, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.683, "dev_c": 0.371, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
a6bb1651-5ca5-431f-9049-ef62285cb8c9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b5bf088c-e892-4bb4-b0ce-38e1e54594b0	190124110002420	fail	0.797	[{"cal_c": -41.29, "dev_c": -0.505, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.795, "dev_c": -0.797, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
128a4c25-391a-41aa-a56f-92e46408d859	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	92341219-af09-4196-879b-6656bd7a5c84	190124110002421	fail	0.896	[{"cal_c": -41.682, "dev_c": -0.896, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.926, "dev_c": -0.666, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.8, "dev_c": 0.487, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b0a2a22f-46df-41cb-86aa-82881e171cd9	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	2c4987ee-fb4f-4d4e-aa09-8dd4fb691a50	190124110002422	pass	0.230	[{"cal_c": 5.461, "dev_c": -0.13, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
724fc8a0-d032-432f-ab62-4b7d9917bd7a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	85ba8d65-0f11-4084-b2cd-8e799318ff11	190124110002423	pass	0.112	[{"cal_c": 5.537, "dev_c": -0.055, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.425, "dev_c": 0.112, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
5ad0b198-4572-4df2-b097-3a6f2e01bbcc	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	823f313d-5d51-406d-ab9b-20ac449c112c	190124110002424	pass	0.459	[{"cal_c": 5.522, "dev_c": -0.07, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.771, "dev_c": 0.459, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
6d96989b-0cb3-485f-b709-3f3030c551ba	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	23d67ae1-d23b-417d-b169-0093942b049d	190124110002425	pass	0.225	[{"cal_c": 5.424, "dev_c": -0.168, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.538, "dev_c": 0.225, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9372fe74-1e30-4d9f-9483-085853b2e40a	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	624a4631-a3fb-4570-b775-0be534821af8	190124110002426	fail	0.823	[{"cal_c": -41.406, "dev_c": -0.62, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.769, "dev_c": -0.823, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 39.986, "dev_c": -0.327, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
14f7a02b-e95d-46e4-b8db-f83ea804719e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	350d4757-ab50-4e71-ad48-794bf63f459e	190124110002427	fail	0.915	[{"cal_c": -41.445, "dev_c": -0.66, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.676, "dev_c": -0.915, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.543, "dev_c": 0.23, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
e725b15f-ddde-4adf-89c9-9e5c5f5e9426	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a9782450-169b-4d77-9e34-52067515495f	190124110002428	fail	0.900	[{"cal_c": -41.205, "dev_c": -0.419, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.692, "dev_c": -0.9, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.78, "dev_c": 0.468, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
2bb01b4b-2ce5-45d3-933b-60cc21fe4016	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	255d0747-32c1-4be9-9627-f0b93a90250d	190124110002429	fail	0.896	[{"cal_c": -41.605, "dev_c": -0.819, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.696, "dev_c": -0.896, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
cbe7f056-8562-4321-b662-12d6f3c4ace2	320c8e6c-51e2-43ea-b741-1be9b3629848	c32336b3-a3d4-4c2c-9472-381a7715aed2	190125070005581	pass	\N	[]	0000001271	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001271_190125070005581.docx	2025-10-01 09:00:00+00
a02d4d30-20fc-4aaa-b667-ce6f1ea5d251	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5498e2d2-d727-4b16-8eae-d206c9893c9a	190124110002430	fail	0.821	[{"cal_c": -41.555, "dev_c": -0.77, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.77, "dev_c": -0.821, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
31523c54-6ecc-4a07-8afc-2496c72f5ee7	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	87ed32ef-028c-4b76-86eb-dc7d17b64546	190124110002431	fail	0.761	[{"cal_c": -41.153, "dev_c": -0.368, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.83, "dev_c": -0.761, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.6, "dev_c": 0.288, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8a0d606a-8b03-4356-9898-a61457c7a6ab	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	c55c3c9a-395c-4dfa-8b7f-5f3f1e5a13cf	190124110002432	fail	0.568	[{"cal_c": 5.238, "dev_c": -0.354, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.88, "dev_c": 0.568, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
948cfabf-e219-4702-8285-0dbd154b60c3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	7a857904-2c1b-422a-a861-344be8f6da11	190124110002433	fail	1.047	[{"cal_c": -41.833, "dev_c": -1.047, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.812, "dev_c": -0.78, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.733, "dev_c": 0.421, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
9563924f-0a8d-41cb-ad64-ea8edafdfd98	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	8457e305-fdd4-422d-a291-0bc16b8d7bdf	190124110002434	pass	0.330	[{"cal_c": 5.372, "dev_c": -0.22, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.643, "dev_c": 0.33, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
24407c19-1e85-4871-9443-20c188fb2c04	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	b45935ce-14d5-4bfa-b691-3b387fe1a94e	190124110002435	fail	0.710	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.882, "dev_c": -0.71, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.74, "dev_c": 0.428, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
07bcd0fe-b021-4826-8415-d6030af0ab4f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	5ff8f9e7-114d-485d-852d-3a7338f46926	190124110002436	fail	0.678	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.914, "dev_c": -0.678, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.82, "dev_c": 0.508, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
64ff9c11-a312-42e0-996d-a3a1970f2d4e	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	a89f8aa9-4839-4ef0-84c8-650d9c85d4c7	190124110002437	fail	0.803	[{"cal_c": -41.221, "dev_c": -0.435, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.789, "dev_c": -0.803, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.68, "dev_c": 0.367, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
1b4bc834-359b-4bfd-99b4-418cc4ea15e0	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	261f525d-b087-4bf1-b71f-d16c31fba753	190124110002438	fail	0.732	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.86, "dev_c": -0.732, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.7, "dev_c": 0.388, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
7a629cd7-6141-472b-a2d7-789cfc41a2d3	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e0909aa2-7368-4736-b0b9-b803d9d73680	190124110002439	fail	0.780	[{"cal_c": -40.45, "dev_c": 0.335, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.812, "dev_c": -0.78, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.74, "dev_c": 0.428, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
8982fb15-d786-451a-8b78-40c0ce4b51b5	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	f4c1809b-0fee-4be0-b497-9117695e5120	190124110002440	fail	0.879	[{"cal_c": -41.26, "dev_c": -0.474, "ref_c": -40.785, "target_c": -40, "within_tol": true}, {"cal_c": 4.713, "dev_c": -0.879, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.5, "dev_c": 0.188, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
31d26b91-a12b-4355-9d03-7368829b48ed	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	64eae673-b309-468e-9b96-75694623a88b	190124110002441	fail	0.764	[{"cal_c": -41.438, "dev_c": -0.653, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.828, "dev_c": -0.764, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.76, "dev_c": 0.447, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
67eace44-00a0-4870-b4e6-0d4ac0b5ad87	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	cc90a9f7-aaed-4f25-9a19-7637c6d16d7f	190124110002442	fail	0.878	[{"cal_c": -41.619, "dev_c": -0.833, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.714, "dev_c": -0.878, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.513, "dev_c": 0.2, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
82d232bf-47a0-4d24-a4bc-bbd412a6c477	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3a0d6df7-dd49-4964-89d9-8632faa089b1	190124110002443	fail	0.604	[{"cal_c": 5.213, "dev_c": -0.378, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.917, "dev_c": 0.604, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
e7088fa0-ec7e-40a8-9b11-a59fe8338357	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	e5428c6c-db9f-4507-ad63-22517df3fbcd	190124110002444	fail	1.382	[{"cal_c": -42.167, "dev_c": -1.382, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.697, "dev_c": -0.895, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.557, "dev_c": 0.245, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
dc42a20e-14af-42f0-aa90-753fe89b221c	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	77b46439-bea3-4128-8ccf-7bcd43324c79	190124110002445	fail	1.107	[{"cal_c": -41.771, "dev_c": -0.985, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.485, "dev_c": -1.107, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.133, "dev_c": -0.179, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
89199d6f-0069-4819-9f2d-cf4ddbeb4841	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	859c436c-1006-48e8-93a9-c4c22cb270bb	190124110002446	fail	0.881	[{"cal_c": -41.524, "dev_c": -0.739, "ref_c": -40.785, "target_c": -40, "within_tol": false}, {"cal_c": 4.71, "dev_c": -0.881, "ref_c": 5.592, "target_c": 5, "within_tol": false}, {"cal_c": 40.443, "dev_c": 0.13, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
b2d80fad-fc7f-4371-a97f-ef3b5b8a8be1	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	bc159cbe-baee-4cc8-9eda-be91edb2cbf4	190124110002447	fail	0.638	[{"cal_c": 5.412, "dev_c": -0.18, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.95, "dev_c": 0.638, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
007f4157-0f9f-4943-b888-e12ebe5bfb1f	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	da22377e-6b16-47bb-a165-62b6d359043f	190124110002448	fail	0.721	[{"cal_c": 5.396, "dev_c": -0.195, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 41.033, "dev_c": 0.721, "ref_c": 40.312, "target_c": 40, "within_tol": false}]	\N	\N	2025-11-14 09:00:00+00
172c5c92-b96d-42d4-8a76-4e08a4e67761	59649dfc-5dd8-42c8-bc15-fc5598b3c7f6	3f8ee0a0-8299-4ef0-8af7-a75ee3afd9e3	190124110002449	pass	0.404	[{"cal_c": 5.274, "dev_c": -0.318, "ref_c": 5.592, "target_c": 5, "within_tol": true}, {"cal_c": 40.717, "dev_c": 0.404, "ref_c": 40.312, "target_c": 40, "within_tol": true}]	\N	\N	2025-11-14 09:00:00+00
36f51ca3-b83f-4063-8f49-8d798db57287	320c8e6c-51e2-43ea-b741-1be9b3629848	729fd993-980f-4fbd-90ac-946383f87179	190125070005582	pass	\N	[]	0000001272	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001272_190125070005582.docx	2025-10-01 09:00:00+00
825ac484-8c57-4385-ac75-5097618f56e5	320c8e6c-51e2-43ea-b741-1be9b3629848	66c1f3dd-a132-45dc-b6bb-37fa3ed238b3	190125070005583	pass	\N	[]	0000001273	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001273_190125070005583.docx	2025-10-01 09:00:00+00
2f0f878c-e8c7-4e11-b63e-9c344cd19ce8	320c8e6c-51e2-43ea-b741-1be9b3629848	e556e556-4a4e-4e0c-b7f7-d5546e1ac70c	190125070005584	pass	\N	[]	0000001274	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001274_190125070005584.docx	2025-10-01 09:00:00+00
0d656c42-4977-475f-9f51-6b73381d1e58	320c8e6c-51e2-43ea-b741-1be9b3629848	025dce75-a546-466a-b224-393462dbfcbb	190125070005585	pass	\N	[]	0000001275	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001275_190125070005585.docx	2025-10-01 09:00:00+00
c43168bc-c84d-4713-9c36-fae8999ee556	320c8e6c-51e2-43ea-b741-1be9b3629848	58abe216-e862-44fe-8a13-681a0bbed6b4	190125070005586	pass	\N	[]	0000001276	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001276_190125070005586.docx	2025-10-01 09:00:00+00
41e0e261-d885-49ba-bae8-e90fd3825dfa	320c8e6c-51e2-43ea-b741-1be9b3629848	e9d33938-c7ab-411b-b82e-4ee06fca86de	190125070005587	pass	\N	[]	0000001277	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001277_190125070005587.docx	2025-10-01 09:00:00+00
6256f492-c01b-4101-a853-c39dd56ce4cc	320c8e6c-51e2-43ea-b741-1be9b3629848	d2c2e2c6-a2a1-45f2-ab1b-211b63d20afe	190125070005588	pass	\N	[]	0000001278	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001278_190125070005588.docx	2025-10-01 09:00:00+00
e8696f53-4956-4988-a83f-4ebb9c3a5c24	320c8e6c-51e2-43ea-b741-1be9b3629848	d038a824-60c4-40d4-8dbc-9c1bba397225	190125070005589	pass	\N	[]	0000001279	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001279_190125070005589.docx	2025-10-01 09:00:00+00
a5a4696a-ecab-47e7-91db-fa4fbfab86a6	320c8e6c-51e2-43ea-b741-1be9b3629848	c6ed70b1-8083-459b-89a9-20fd076c1275	190125070005590	pass	\N	[]	0000001280	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001280_190125070005590.docx	2025-10-01 09:00:00+00
e6f8a060-2779-4bcf-a9d5-e4d7a1f08657	320c8e6c-51e2-43ea-b741-1be9b3629848	dd441fdd-d552-4fe7-a16c-e82dc8a5321e	190125070005591	pass	\N	[]	0000001281	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001281_190125070005591.docx	2025-10-01 09:00:00+00
5e3cb661-85e1-49ed-8517-a583f9652bcc	320c8e6c-51e2-43ea-b741-1be9b3629848	88f79f59-c8f1-44f2-82b5-c7d64eff0a73	190125070005592	pass	\N	[]	0000001282	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001282_190125070005592.docx	2025-10-01 09:00:00+00
b19c130a-173b-4c6a-ad2e-ef7d1d96f573	320c8e6c-51e2-43ea-b741-1be9b3629848	e214fff6-7f59-4558-b1a8-32b6497034bd	190125070005593	pass	\N	[]	0000001283	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001283_190125070005593.docx	2025-10-01 09:00:00+00
47a376b1-3858-48ba-b498-775ac92a2d6c	320c8e6c-51e2-43ea-b741-1be9b3629848	e3c336a6-e666-4c21-8aa0-d485f487c988	190125070005594	pass	\N	[]	0000001284	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001284_190125070005594.docx	2025-10-01 09:00:00+00
636b9e7b-6d7a-4d76-a7e7-2c85266bf129	320c8e6c-51e2-43ea-b741-1be9b3629848	1edd4786-4d04-4d48-befc-6bf23a4d06ea	190125070005595	pass	\N	[]	0000001285	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001285_190125070005595.docx	2025-10-01 09:00:00+00
5752e626-abc0-4ea1-9567-076fae99866d	320c8e6c-51e2-43ea-b741-1be9b3629848	77d6114a-5ad4-47a3-9140-a8235f0c8242	190125070005596	pass	\N	[]	0000001286	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001286_190125070005596.docx	2025-10-01 09:00:00+00
f0ce7e35-9569-4679-aabd-a71af6306392	320c8e6c-51e2-43ea-b741-1be9b3629848	13369150-0ec8-40ce-8e38-3e29782134b8	190125070005597	pass	\N	[]	0000001287	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001287_190125070005597.docx	2025-10-01 09:00:00+00
ecf152a4-9636-49b5-bac3-e0833c5b4609	320c8e6c-51e2-43ea-b741-1be9b3629848	4a438854-6655-4773-a4cd-0206d6b32718	190125070005598	pass	\N	[]	0000001288	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001288_190125070005598.docx	2025-10-01 09:00:00+00
0af8bf29-52d4-4a4b-8b00-8d9a7c1419ab	320c8e6c-51e2-43ea-b741-1be9b3629848	977231eb-78ef-4abc-9874-1e63a94251e3	190125070005599	pass	\N	[]	0000001289	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001289_190125070005599.docx	2025-10-01 09:00:00+00
f1400643-0631-4797-b2a4-d63a76c5f2a8	320c8e6c-51e2-43ea-b741-1be9b3629848	8f3b7c35-b94d-496a-a6aa-2037a29fb8a1	190125070005600	pass	\N	[]	0000001290	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001290_190125070005600.docx	2025-10-01 09:00:00+00
b60e96d6-8b04-43aa-b81d-9737b358efed	320c8e6c-51e2-43ea-b741-1be9b3629848	6085b8b0-80f8-47fa-9882-0238b11361c1	190125070005601	pass	\N	[]	0000001291	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001291_190125070005601.docx	2025-10-01 09:00:00+00
243b0c74-16cf-4a4e-a825-24dbfe073281	320c8e6c-51e2-43ea-b741-1be9b3629848	8b251e63-f5e9-4b59-91a9-385f5c905bee	190125070005602	pass	\N	[]	0000001292	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001292_190125070005602.docx	2025-10-01 09:00:00+00
f11a8f6b-a494-4ae6-940a-1157020544b3	320c8e6c-51e2-43ea-b741-1be9b3629848	47461580-19e9-43fd-8b11-48be7a4f009b	190125070005603	pass	\N	[]	0000001293	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001293_190125070005603.docx	2025-10-01 09:00:00+00
5e94149f-e128-47a3-b246-9927190d7191	320c8e6c-51e2-43ea-b741-1be9b3629848	ac8057c9-8e4b-40a7-8b74-757cb8fc1771	190125070005604	pass	\N	[]	0000001294	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001294_190125070005604.docx	2025-10-01 09:00:00+00
e0b04479-e80a-48ff-8d3a-1715e33af2b2	320c8e6c-51e2-43ea-b741-1be9b3629848	ea2f0c04-9eb3-4a4a-be4e-5c200adaf1c8	190125070005605	pass	\N	[]	0000001295	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001295_190125070005605.docx	2025-10-01 09:00:00+00
a72c33d4-acfc-4f82-a578-70a215f53fae	320c8e6c-51e2-43ea-b741-1be9b3629848	8dc35a58-1e97-459c-95d2-200e8b7e11f3	190125070005606	pass	\N	[]	0000001296	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001296_190125070005606.docx	2025-10-01 09:00:00+00
cd582485-55cb-49c0-8160-0fb2bb5d58dc	08e016f3-784c-46b3-8037-f2a67f67d87f	ebba72cd-2c30-47c9-b74a-b41f94b6f06a	190125020000841	pass	\N	[]	0000001957	/var/lib/ite-calibration/data/runs/08e016f3-784c-46b3-8037-f2a67f67d87f/certificates/Calibration_Certificate_0000001957_190125020000841.docx	2025-06-13 09:00:00+00
ac7c5f31-29b7-47f4-9069-e2bcd5ac4101	320c8e6c-51e2-43ea-b741-1be9b3629848	7cd86db4-a4d4-49c7-a7ab-e972e170184d	190125070005530	pass	\N	[]	0000001220	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001220_190125070005530.docx	2025-10-01 09:00:00+00
f97eacb6-e89a-4f45-b983-d1111aff5701	320c8e6c-51e2-43ea-b741-1be9b3629848	d470db95-1108-40a0-b83f-150995a0ff3b	190125070005531	pass	\N	[]	0000001221	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001221_190125070005531.docx	2025-10-01 09:00:00+00
1fd8e0b0-5ae0-4754-aca1-961ecf7581ec	320c8e6c-51e2-43ea-b741-1be9b3629848	d74f9445-46e3-4fe8-8d61-f23b75f008ec	190125070005532	pass	\N	[]	0000001222	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001222_190125070005532.docx	2025-10-01 09:00:00+00
2346d127-60ed-49a8-a993-d800699c3194	320c8e6c-51e2-43ea-b741-1be9b3629848	ad7d997b-8d07-4ffb-8e50-73f6e513ff71	190125070005533	pass	\N	[]	0000001223	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001223_190125070005533.docx	2025-10-01 09:00:00+00
bc5c106c-1a68-4ca1-beac-a71d18fa4586	320c8e6c-51e2-43ea-b741-1be9b3629848	916ff964-33f4-4a09-bc8c-90e45b199f74	190125070005534	pass	\N	[]	0000001224	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001224_190125070005534.docx	2025-10-01 09:00:00+00
6ca923a2-f34e-4fce-816d-ebd67c119c98	320c8e6c-51e2-43ea-b741-1be9b3629848	af1f1845-74be-40dc-a93e-e205811a157b	190125070005535	pass	\N	[]	0000001225	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001225_190125070005535.docx	2025-10-01 09:00:00+00
397cf35c-bfde-4a6f-b102-86cf3a00586d	320c8e6c-51e2-43ea-b741-1be9b3629848	342e8cdc-da70-4d7b-bc5a-a7180ad58704	190125070005536	pass	\N	[]	0000001226	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001226_190125070005536.docx	2025-10-01 09:00:00+00
31155f86-ead9-4083-9988-a5263df58166	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	747c9573-c781-49e6-8d56-e4e15b7c7595	190124110002589	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001754	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001754_190124110002589.docx	2026-06-03 04:53:21.177254+00
5a745ad7-0b35-4ef0-83e8-f205ee22d58e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	b8287872-1899-4612-80af-2b3de2f4ad97	190124110002590	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001755	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001755_190124110002590.docx	2026-06-03 04:53:21.177254+00
c104cbc8-14b8-4f9b-a7b7-a5b9b88d4b42	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	ee2750e4-15b8-4288-b05f-1b68766e3b0f	190124110002591	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001756	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001756_190124110002591.docx	2026-06-03 04:53:21.177254+00
51d7842b-166e-4601-8443-ac43741ebe85	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	85229f11-485a-412b-b31d-e35e7f50db7c	190124110002592	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001757	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001757_190124110002592.docx	2026-06-03 04:53:21.177254+00
d0f9394b-59e3-439f-8418-40a302ff3321	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	9c62815c-8539-448c-8627-f1afd188c262	190124110002593	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001758	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001758_190124110002593.docx	2026-06-03 04:53:21.177254+00
b6d311dd-de74-419a-a165-04f7dae01ad5	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	08e01243-7894-41a4-bd28-10f06a0e6ecc	190124110002450	pass	0.400	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001645	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001645_190124110002450.docx	2026-06-03 04:53:14.24483+00
5bb40790-58d5-49b6-9ab7-5285c9ee6d2c	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	532032bc-e5e9-42e6-a35e-713b55bf709a	190124110002451	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001646	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001646_190124110002451.docx	2026-06-03 04:53:14.24483+00
ea8eece2-81ff-402c-b01d-fb95e7e95946	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	6364255c-95fe-4560-80a6-c64d322b32cc	190124110002452	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001647	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001647_190124110002452.docx	2026-06-03 04:53:14.24483+00
1665ef0d-4ef6-4279-8505-8526398f7c4f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ce735a8a-30eb-4a06-8cc9-a84add884a34	190124110002453	pass	0.500	[{"cal_c": -39.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001648	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001648_190124110002453.docx	2026-06-03 04:53:14.24483+00
78545981-7e43-42e3-ad4d-5c0cf5c883d9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e9da61d1-6651-4a71-b6e2-7caf11381152	190124110002454	pass	0.400	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001649	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001649_190124110002454.docx	2026-06-03 04:53:14.24483+00
2cb56167-2d0b-47b7-9789-c75a5d4aff05	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ac841d81-b705-4c63-8fb1-2545747a75cd	190124110002455	pass	0.400	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001650	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001650_190124110002455.docx	2026-06-03 04:53:14.24483+00
fd194d5d-bfa2-415a-bdee-4a1e2a9a8ff8	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	0c9a4fb2-73c7-4a48-85f0-3464f65615bb	190124110002456	pass	0.400	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001651	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001651_190124110002456.docx	2026-06-03 04:53:14.24483+00
1b70e2fd-a229-4c34-b82b-94f78f3bd060	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	906e2c11-920b-480c-a19d-f4dbbdb8be10	190124110002457	pass	0.300	[{"cal_c": -41.0, "dev_c": 0.1, "ref_c": -41.1, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001652	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001652_190124110002457.docx	2026-06-03 04:53:14.24483+00
6cebe3fe-1261-49ed-8ef7-596ec46ff621	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	99ce0090-bad0-4b52-9a8a-7286b2706df0	190124110002458	pass	0.500	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001653	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001653_190124110002458.docx	2026-06-03 04:53:14.24483+00
a60942e2-34ea-4b1a-9960-11c65894249f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	9ae00d9a-6ca3-4f97-8f2f-ae93ca6d4f64	190124110002459	pass	0.400	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001654	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001654_190124110002459.docx	2026-06-03 04:53:14.24483+00
665dcb90-7c9e-4c57-a802-648d72688d9f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	d3085fde-722f-4411-bffc-6b98225ff465	190124110002460	pass	0.500	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001655	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001655_190124110002460.docx	2026-06-03 04:53:14.24483+00
c423651a-0b3a-4e19-8d92-3579a95893ae	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e4c87927-2d7c-44a9-a848-66add20b90a5	190124110002461	pass	0.500	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001656	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001656_190124110002461.docx	2026-06-03 04:53:14.24483+00
3fc2c932-02fe-4eff-a598-1e48f72a2e5a	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	6f093821-74a8-42c3-8f7f-7582942cf084	190124110002462	pass	0.400	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001657	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001657_190124110002462.docx	2026-06-03 04:53:14.24483+00
fa59ffe8-ff13-4a95-a65a-ddd220fe0ef9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e336da56-c8dc-4b5e-8b78-8f209ba68dbe	190124110002463	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001658	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001658_190124110002463.docx	2026-06-03 04:53:14.24483+00
7f1fe5f0-978b-402a-97d4-cf8405ed0646	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	fd0accd1-d387-45eb-84db-72560c3c30c1	190124110002464	pass	0.500	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001659	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001659_190124110002464.docx	2026-06-03 04:53:14.24483+00
853451c6-8ee2-41eb-935c-6ba70080a504	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	d191d428-4433-4fcc-904a-d7215c1c1e6c	190124110002465	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001660	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001660_190124110002465.docx	2026-06-03 04:53:14.24483+00
6b5ad31a-4800-4c5d-a9b4-3c15e24df4f7	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	7f12b49a-e893-443a-9f78-a69601551f18	190124110002466	pass	0.400	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001661	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001661_190124110002466.docx	2026-06-03 04:53:14.24483+00
486820b3-9ffc-4879-a126-119e6aec63e8	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	8d77e35f-a7c9-4b5d-a3ac-8a5bb8668182	190124110002467	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001662	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001662_190124110002467.docx	2026-06-03 04:53:14.24483+00
f5189024-d70a-4e54-a060-c8d7d7837543	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	a0a4ee56-6f04-4f19-b00b-aedf37990be1	190124110002468	pass	0.100	[{"cal_c": -42.2, "dev_c": 0.1, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.5, "dev_c": 0.1, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 26.0, "dev_c": 0.0, "ref_c": 26.0, "target_c": 40.0, "within_tol": true}]	0000001663	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001663_190124110002468.docx	2026-06-03 04:53:14.24483+00
da668165-57d0-4e1e-846d-9842210a75aa	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	2e7f402d-8b6f-4723-a6ed-c4069edfd7db	190124110002469	pass	0.400	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001664	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001664_190124110002469.docx	2026-06-03 04:53:14.24483+00
34cfbb5d-0962-41c8-9c3f-151e0bfe84aa	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	8516b818-93f4-488a-bd9a-5b6e8a9de8e3	190124110002470	pass	0.400	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001665	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001665_190124110002470.docx	2026-06-03 04:53:14.24483+00
72964d9b-c67b-43d7-ad3f-948d7e862ca4	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	99c478df-a86e-4a9a-b8c1-a66c427af4a7	190124110002471	pass	0.500	[{"cal_c": -39.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001666	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001666_190124110002471.docx	2026-06-03 04:53:14.24483+00
2b4c1a7a-b4ee-4a8d-b803-8565960c1139	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	be1c4b4c-7842-4fd9-ba7b-9d36f09f4fcf	190124110002472	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.9, "dev_c": 0.0, "ref_c": 5.9, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001667	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001667_190124110002472.docx	2026-06-03 04:53:14.24483+00
eb8f5b1a-83bf-4bab-8f19-d6d1d8033554	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	f785fe29-267e-480c-83fd-86014a8de3c8	190124110002473	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001668	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001668_190124110002473.docx	2026-06-03 04:53:14.24483+00
683ade56-b41a-486b-9528-e44b7d33f16d	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	4398ae1b-abe4-4f3b-81fd-d992be126487	190124110002474	pass	0.400	[{"cal_c": -40.7, "dev_c": 0.1, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001669	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001669_190124110002474.docx	2026-06-03 04:53:14.24483+00
53d34c54-246f-4fc5-92bd-5dc33bb04cc2	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	de2fa4bb-3dc8-4c07-adfd-162cd3cd1664	190124110002475	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001670	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001670_190124110002475.docx	2026-06-03 04:53:14.24483+00
8e507af8-fd16-4426-ac0b-be78dc5bd56d	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	0c0b6c45-9f0d-477e-aa2f-2fe3528676ab	190124110002476	pass	0.400	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.4, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001671	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001671_190124110002476.docx	2026-06-03 04:53:14.24483+00
1c69ffbb-f117-4dde-83f0-c92bdbf4831b	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	759bd709-4969-41dc-ac91-f5766343a44e	190124110002477	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001672	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001672_190124110002477.docx	2026-06-03 04:53:14.24483+00
ddb19d13-120e-4560-97e8-f21893b40ec2	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	6f32a728-cdd1-44d2-a3f2-ff1bfb904aec	190124110002478	pass	0.500	[{"cal_c": -40.6, "dev_c": 0.1, "ref_c": -40.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001673	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001673_190124110002478.docx	2026-06-03 04:53:14.24483+00
904b40f3-ee14-413a-8757-87437412385c	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	3759f3c9-f27e-4635-ab01-7aaf412f9464	190124110002479	pass	0.400	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001674	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001674_190124110002479.docx	2026-06-03 04:53:14.24483+00
95263f3d-f8a6-4bcd-b213-00d8a1048761	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	8b579bb8-1e6b-419b-b56a-63ddb860a588	190124110002480	pass	0.400	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001675	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001675_190124110002480.docx	2026-06-03 04:53:14.24483+00
1a143b9c-858c-4d41-96f9-35a2d64aabb2	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	d2aeba20-034b-46e8-b00f-3620b5b9f039	190124110002481	pass	0.500	[{"cal_c": -41.0, "dev_c": 0.1, "ref_c": -41.1, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001676	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001676_190124110002481.docx	2026-06-03 04:53:14.24483+00
fefb9a33-fd04-4d21-a6b5-e62b41737186	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ba3c49e7-9046-4027-9a92-c9a15e344f0c	190124110002482	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001677	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001677_190124110002482.docx	2026-06-03 04:53:14.24483+00
fc234017-947b-4d47-9fe9-ca962da3e009	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	8d947eb4-d3d0-40f5-88e7-6a7b0e4d5ff0	190124110002483	pass	0.400	[{"cal_c": -41.3, "dev_c": 0.2, "ref_c": -41.1, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001678	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001678_190124110002483.docx	2026-06-03 04:53:14.24483+00
17d21476-5f76-4d0a-8f39-ce469d9ee533	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	f05f9a4e-683b-461f-9a6c-9c9e057ccf92	190124110002484	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001679	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001679_190124110002484.docx	2026-06-03 04:53:14.24483+00
61f17666-c8ce-4088-a517-de46d47405dd	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ec7b0c56-d06d-4791-8e3a-f474ef2e8bd5	190124110002485	pass	0.500	[{"cal_c": -39.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001680	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001680_190124110002485.docx	2026-06-03 04:53:14.24483+00
2a139666-27b9-40ac-8efe-eb26b22cfa72	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	2a748bf1-9ef9-4bda-b178-972da521158b	190124110002486	pass	0.500	[{"cal_c": -41.1, "dev_c": 0.0, "ref_c": -41.1, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001681	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001681_190124110002486.docx	2026-06-03 04:53:14.24483+00
7940c5bc-e9ad-4885-bf44-3f7ba10e0cc5	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	64c62ad8-2ddc-4ff4-bf39-5b934ebe7a29	190124110002487	pass	0.300	[{"cal_c": -40.6, "dev_c": 0.1, "ref_c": -40.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001682	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001682_190124110002487.docx	2026-06-03 04:53:14.24483+00
b9f55936-cdd6-4ffc-bb57-72889637711e	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	02ef0367-6f21-4927-8ac5-9bf78ff9cfd9	190124110002488	pass	0.400	[{"cal_c": -41.9, "dev_c": 0.0, "ref_c": -41.9, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001683	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001683_190124110002488.docx	2026-06-03 04:53:14.24483+00
44e23994-0613-485c-9e7c-61859b73fde5	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	f61d2863-f5c1-4948-8b49-ba71b47a00cc	190124110002489	pass	0.500	[{"cal_c": -40.7, "dev_c": 0.1, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001684	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001684_190124110002489.docx	2026-06-03 04:53:14.24483+00
8bc4346d-525a-49e4-925a-f79c88189ee9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e21385e6-6dc7-4056-a36d-25d00916d406	190124110002490	pass	0.400	[{"cal_c": -40.7, "dev_c": 0.1, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001685	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001685_190124110002490.docx	2026-06-03 04:53:14.24483+00
11d74c85-1935-4548-ab91-7982c2df44ee	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	6ee0fe91-9ea0-4864-a824-b3eb596ad4e1	190124110002491	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001686	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001686_190124110002491.docx	2026-06-03 04:53:14.24483+00
f4bbde2d-aba2-4701-a8d4-d7fd80484105	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	53f6d74f-72cf-4a4a-9aba-70e0dec66373	190124110002492	pass	0.500	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001687	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001687_190124110002492.docx	2026-06-03 04:53:14.24483+00
01e51b6b-6647-4fb5-b6ba-195a4c1170c1	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	35b8ccb0-50df-4a29-b2d5-92f07f0aa199	190124110002493	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001688	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001688_190124110002493.docx	2026-06-03 04:53:14.24483+00
9bafaf3f-6af0-4472-be21-4283752e2684	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	f26e2e02-d00d-4180-a9be-5c160c6b1593	190124110002494	pass	0.400	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001689	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001689_190124110002494.docx	2026-06-03 04:53:14.24483+00
f5c2706d-4353-43e0-a9e1-82e4500ea987	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	2d9e3c7a-5afb-45f8-8562-efbe80fc5f03	190124110002495	pass	0.400	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.4, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001690	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001690_190124110002495.docx	2026-06-03 04:53:14.24483+00
9d6c0a01-fd5d-48d2-9de1-7d515f6964d8	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e4233b96-3b52-4728-b99c-086b10cbe522	190124110002496	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001691	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001691_190124110002496.docx	2026-06-03 04:53:14.24483+00
8f918470-03b9-4a3f-9cb1-14d06f5f5e20	320c8e6c-51e2-43ea-b741-1be9b3629848	9bd31ad5-b7af-4b30-a274-dc673a650991	190125070005537	pass	\N	[]	0000001227	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001227_190125070005537.docx	2025-10-01 09:00:00+00
d1794690-03c2-45ef-94eb-ff3040492e26	320c8e6c-51e2-43ea-b741-1be9b3629848	452090d1-dcda-48b9-8bac-de745cc6bd15	190125070005538	pass	\N	[]	0000001228	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001228_190125070005538.docx	2025-10-01 09:00:00+00
1523af92-23e2-4e60-94b4-c0018ec0b10e	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	5cc5899d-c62b-43dc-b405-74752bef11f9	190124110002497	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001692	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001692_190124110002497.docx	2026-06-03 04:53:14.24483+00
765d2e44-dd82-4ad9-9d28-cd2360a0e960	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	3a3ab213-dc3b-404d-baaf-143fc0e7974a	190124110002498	pass	0.400	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001693	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001693_190124110002498.docx	2026-06-03 04:53:14.24483+00
3d0cf29b-c0fb-4202-b749-7a485c9d1f2b	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ec36c5ed-fc73-4308-8bfb-36dc1f764039	190124110002499	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001694	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001694_190124110002499.docx	2026-06-03 04:53:14.24483+00
41ed2b92-550e-4145-9a37-d392e032726a	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	78c00f79-2ba9-437d-9613-4fe083e59485	190124110002500	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001695	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001695_190124110002500.docx	2026-06-03 04:53:14.24483+00
a9f51ecc-817b-4847-8078-c30b704342ce	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	b2b1deb9-869f-4618-9dbf-1aba037b5971	190124110002501	pass	0.400	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001696	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001696_190124110002501.docx	2026-06-03 04:53:14.24483+00
665347f5-3bac-46ae-a2c2-763c7e0d67b8	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	79f325fd-9029-4dde-9422-55bc9b32bdd7	190124110002502	pass	0.400	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001697	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001697_190124110002502.docx	2026-06-03 04:53:14.24483+00
ca91fbe4-9cf6-479f-a54e-03a9eaf20f12	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e20b2f1f-be55-4b01-8472-fff205c49078	190124110002503	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001698	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001698_190124110002503.docx	2026-06-03 04:53:14.24483+00
aed4d283-c1f7-4dc7-9087-16b3ddf845ee	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	472f4d6d-996b-4048-b35f-82002ad247ca	190124110002504	pass	0.400	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001699	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001699_190124110002504.docx	2026-06-03 04:53:14.24483+00
7cbfbc37-0e73-441e-b370-1ad8d195e962	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	43442b47-13e2-4172-9a9e-50953ce5685c	190124110002505	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001700	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001700_190124110002505.docx	2026-06-03 04:53:14.24483+00
65446417-1ac8-492e-af69-0fcefb880bb9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	408dd956-db70-486f-8121-dbc917f21d3e	190124110002506	pass	0.400	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001701	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001701_190124110002506.docx	2026-06-03 04:53:14.24483+00
d09e74a7-9f0e-4cd5-a14d-7b7dec40189f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	be29b72a-74e8-4bfb-80bb-f3d5ab6966eb	190124110002507	pass	0.400	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001702	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001702_190124110002507.docx	2026-06-03 04:53:14.24483+00
78c8ce20-4299-4a3f-850e-6e5e314d29a5	320c8e6c-51e2-43ea-b741-1be9b3629848	048b232b-b9f3-42f4-980c-796a8f383d51	190125070005539	pass	\N	[]	0000001229	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001229_190125070005539.docx	2025-10-01 09:00:00+00
2a321e03-3bcb-4e06-9576-1f8326b7b437	320c8e6c-51e2-43ea-b741-1be9b3629848	439a7c8b-3145-4929-b781-99d2727e5516	190125070005540	pass	\N	[]	0000001230	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001230_190125070005540.docx	2025-10-01 09:00:00+00
e61658ac-27a2-4d50-995f-0ce3f1a8961f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	aa785981-e0f2-4fc4-9dff-6d70fac28c07	190124110002508	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001703	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001703_190124110002508.docx	2026-06-03 04:53:14.24483+00
98e5db78-aca9-4f8f-8e3e-e7f9f5ca0aec	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ba53e6c7-5fe5-4de1-a410-bd0ad8384c5c	190124110002509	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001704	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001704_190124110002509.docx	2026-06-03 04:53:14.24483+00
a5c90280-7e44-4375-912b-8c33a3c3d555	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	395c04bb-a101-4cee-9ee2-0e326b5ff6b7	190124110002510	pass	0.400	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001705	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001705_190124110002510.docx	2026-06-03 04:53:14.24483+00
9d7f2c3d-2165-45a0-a314-e169e62182ba	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	23f35c11-745d-478f-b8a9-84fe8e45f461	190124110002511	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001706	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001706_190124110002511.docx	2026-06-03 04:53:14.24483+00
2c487ac6-a18c-4e26-b239-9cd750444833	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	d5bc4a09-61c5-4092-bf68-6dfa67649ec7	190124110002512	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001707	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001707_190124110002512.docx	2026-06-03 04:53:14.24483+00
520cc8ad-a646-49d2-bef2-fbce7ff485f1	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	541a7b26-1b7d-4b9e-9967-2b369db3459e	190124110002513	pass	0.500	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001708	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001708_190124110002513.docx	2026-06-03 04:53:14.24483+00
59c3d8e5-b75a-4715-9f78-86a4cdc6b2b5	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	2b9b8fe7-5c01-4e34-b264-9df6914b76d8	190124110002514	pass	0.400	[{"cal_c": -39.3, "dev_c": 0.1, "ref_c": -39.4, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001709	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001709_190124110002514.docx	2026-06-03 04:53:14.24483+00
16202adb-f82e-426f-b524-66eb38c75875	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	416db7c2-7dda-43e8-ae20-e3480828468f	190124110002515	pass	0.400	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001710	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001710_190124110002515.docx	2026-06-03 04:53:14.24483+00
c73d06da-0832-4a88-b4b8-87a4256b54ef	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	14229efe-a282-48e6-a3a9-7ad94c263231	190124110002516	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001711	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001711_190124110002516.docx	2026-06-03 04:53:14.24483+00
c7bdd87b-ea1d-4cd8-84b4-52a9cd56d201	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	9599854b-c4da-4f71-953d-053d8be954c8	190124110002517	pass	0.400	[{"cal_c": -41.2, "dev_c": 0.4, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.4, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001712	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001712_190124110002517.docx	2026-06-03 04:53:14.24483+00
0f895e36-c6ae-484c-9b1f-d71a1637cc4d	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	5f99c72d-898e-4708-ad63-0dc3f8448d46	190124110002518	pass	0.400	[{"cal_c": -40.9, "dev_c": 0.1, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001713	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001713_190124110002518.docx	2026-06-03 04:53:14.24483+00
be23933b-91ee-4ea7-bb77-b8b64bad12fb	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	9fec62e2-4c82-466d-8014-0cbabf4a5a90	190124110002519	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001714	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001714_190124110002519.docx	2026-06-03 04:53:14.24483+00
56b88801-5fb0-4816-ae48-c707a3e746dd	320c8e6c-51e2-43ea-b741-1be9b3629848	cac670a2-b791-4f01-b3cf-97a1f68ea3e1	190125070005541	pass	\N	[]	0000001231	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001231_190125070005541.docx	2025-10-01 09:00:00+00
1daa72ac-4e0d-495b-ad59-0cd2e50cc59b	320c8e6c-51e2-43ea-b741-1be9b3629848	269adc72-b025-4a9a-bec1-94b74cc6d859	190125070005542	pass	\N	[]	0000001232	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001232_190125070005542.docx	2025-10-01 09:00:00+00
0671bfa4-907c-4284-9e89-13f92643b9e4	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	dfb8b651-c9b3-4738-8fce-71a9047a9c5a	190124110002520	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001715	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001715_190124110002520.docx	2026-06-03 04:53:14.24483+00
8269e974-439d-49fb-9163-7700a7a94e49	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	131a6c74-02f3-4ff3-8b57-b65de1c70ca0	190124110002521	pass	0.300	[{"cal_c": -40.6, "dev_c": 0.1, "ref_c": -40.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001716	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001716_190124110002521.docx	2026-06-03 04:53:14.24483+00
a22b687f-87ce-489c-9cb3-b5707899aefd	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	1ef3e8ae-f162-462c-bee6-d180e18a06c3	190124110002522	pass	0.400	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001717	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001717_190124110002522.docx	2026-06-03 04:53:14.24483+00
daf91f86-370f-46aa-bbd8-cc5230fdf034	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	aa08b63f-3ef5-4705-a45d-18facc0936b7	190124110002523	pass	0.500	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001718	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001718_190124110002523.docx	2026-06-03 04:53:14.24483+00
4ff4ef6a-0407-4569-8418-e72a5b5ef261	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ee4f3bb6-dbca-413f-b12b-6b6d6de6a87b	190124110002524	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001719	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001719_190124110002524.docx	2026-06-03 04:53:14.24483+00
5adacccc-db46-47e5-8314-1fa3aeccf6a4	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	82cc3c2a-0f79-4ad3-9b9c-d821fe405396	190124110002525	pass	0.400	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001720	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001720_190124110002525.docx	2026-06-03 04:53:14.24483+00
915282f4-ee97-4311-849e-7681b10823e5	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ab7feba3-fc20-4579-83e9-d572223daaac	190124110002526	pass	0.500	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001721	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001721_190124110002526.docx	2026-06-03 04:53:14.24483+00
59fc9e12-f094-4787-a647-f2ba4cc3c18d	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	424c5306-c3f3-4c6a-83d1-9ce8f1b64b83	190124110002527	pass	0.500	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001722	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001722_190124110002527.docx	2026-06-03 04:53:14.24483+00
49b9cb0c-6c02-4984-a1aa-9507096256da	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	5eceabda-7d56-4209-baea-5b8800216c89	190124110002528	pass	0.400	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001723	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001723_190124110002528.docx	2026-06-03 04:53:14.24483+00
248e0183-6003-4bec-92c7-9faab0de76e4	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	769be290-10d0-4e03-89fc-10fb95a492c3	190124110002529	pass	0.400	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001724	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001724_190124110002529.docx	2026-06-03 04:53:14.24483+00
57eb5f38-8885-4d28-be4d-a4d56fbc24c2	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	82c97116-658b-468e-b21d-482576db3be9	190124110002530	pass	0.500	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001725	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001725_190124110002530.docx	2026-06-03 04:53:14.24483+00
7f62aea1-3dfe-4631-b91b-251ba8f6d259	320c8e6c-51e2-43ea-b741-1be9b3629848	6385e6e9-5315-49e2-a345-1b8eda7d9893	190125070005543	pass	\N	[]	0000001233	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001233_190125070005543.docx	2025-10-01 09:00:00+00
2d142914-c30a-4288-8e51-6bacdeadd47f	320c8e6c-51e2-43ea-b741-1be9b3629848	bd6a2cdc-966e-4a6a-8adf-b1a54882f501	190125070005544	pass	\N	[]	0000001234	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001234_190125070005544.docx	2025-10-01 09:00:00+00
361428f8-9063-443b-b814-7fb188e508eb	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	2eb0f5af-9645-40a8-aced-b1f7329cf553	190124110002531	pass	0.500	[{"cal_c": -39.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001726	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001726_190124110002531.docx	2026-06-03 04:53:14.24483+00
b05abc81-2c55-4982-a904-14be9a2577e7	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	f7599686-a970-453b-a18c-b57e720c31bc	190124110002532	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001727	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001727_190124110002532.docx	2026-06-03 04:53:14.24483+00
05af13aa-e410-47cb-a010-4a8b0902b440	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	fd06421f-d0aa-4180-9693-aa623d98a145	190124110002533	pass	0.500	[{"cal_c": -40.0, "dev_c": 0.0, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001728	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001728_190124110002533.docx	2026-06-03 04:53:14.24483+00
d0b245b0-7576-4da2-a7a0-071f39cb6eb1	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	38b93129-a46a-4c4c-99b9-f04ebfe80281	190124110002534	pass	0.300	[{"cal_c": -39.7, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001729	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001729_190124110002534.docx	2026-06-03 04:53:14.24483+00
57d46179-a953-4397-a6f8-7105e1dd101e	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	93654f88-2c9e-4590-9ce7-65a3b6d16fdf	190124110002535	pass	0.400	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001730	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001730_190124110002535.docx	2026-06-03 04:53:14.24483+00
2939eabb-65c6-4e34-bead-f52331fe7670	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	506798f6-43f1-4ed2-885e-fa22b9b38f56	190124110002536	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001731	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001731_190124110002536.docx	2026-06-03 04:53:14.24483+00
59c0a21b-c797-41c4-b11e-598fa2c795dd	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	4f2b1829-c185-4f11-b4c4-d85ba570cf27	190124110002537	pass	0.400	[{"cal_c": -40.1, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001732	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001732_190124110002537.docx	2026-06-03 04:53:14.24483+00
36d2d9b8-69c3-4179-9e9b-5b32b158835a	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ac0be53b-d115-4139-835c-53acb050a396	190124110002538	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001733	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001733_190124110002538.docx	2026-06-03 04:53:14.24483+00
14847c75-04ed-46e8-b947-e89444a1c3e7	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	abbfa0a7-7b28-485d-a482-f92153a4a15f	190124110002539	pass	0.500	[{"cal_c": -39.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.6, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001734	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001734_190124110002539.docx	2026-06-03 04:53:14.24483+00
3d3b15b8-16ee-485e-b58d-123d20753c77	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e17aa1c4-8913-4c58-ba71-a28aded3215e	190124110002540	pass	0.400	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001735	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001735_190124110002540.docx	2026-06-03 04:53:14.24483+00
1c4f3fb4-7d41-4b16-af6f-1bda3119f789	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	ca04a929-6d64-4592-8694-e9f2edff24ba	190124110002541	pass	0.500	[{"cal_c": -40.2, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001736	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001736_190124110002541.docx	2026-06-03 04:53:14.24483+00
f28c3577-08d5-4ccd-938b-91a1543b06ea	320c8e6c-51e2-43ea-b741-1be9b3629848	a634a0d9-b909-450e-aec5-5ec40dda3f72	190125070005545	pass	\N	[]	0000001235	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001235_190125070005545.docx	2025-10-01 09:00:00+00
b72905dc-95c0-48b9-8857-d7ad723ea618	320c8e6c-51e2-43ea-b741-1be9b3629848	6caebb24-0efe-4626-ab98-f760809c97e7	190125070005546	pass	\N	[]	0000001236	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001236_190125070005546.docx	2025-10-01 09:00:00+00
1f52f74f-8eb7-40f6-a924-2d36f71fdd69	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	dcc1ba3b-cc7f-4152-938a-a968dd57b0c8	190124110002542	pass	0.500	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001737	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001737_190124110002542.docx	2026-06-03 04:53:14.24483+00
8c250dfa-422f-416c-ac09-646ed0afe5b2	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	89450aee-ed5e-40c9-b18d-23029424afde	190124110002543	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001738	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001738_190124110002543.docx	2026-06-03 04:53:14.24483+00
1735e4de-dd80-4c75-a309-4f2bb0340952	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	97fdc5cd-cedd-421b-9311-543c031393bb	190124110002544	pass	0.300	[{"cal_c": -40.6, "dev_c": 0.2, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.7, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001739	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001739_190124110002544.docx	2026-06-03 04:53:14.24483+00
0452cf5a-38a1-4cc2-ba22-4ba8498cb681	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	7018ba66-dd39-4391-bc5e-acc7dbb21a6b	190124110002545	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001740	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001740_190124110002545.docx	2026-06-03 04:53:14.24483+00
109ee56d-dfe1-4230-9da4-63bd50e48ea9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	7f4d9e46-a29b-4a02-9363-41f2dd5f18dd	190124110002546	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.7, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001741	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001741_190124110002546.docx	2026-06-03 04:53:14.24483+00
259adac2-975b-4101-a688-e52340a53116	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	94814dc1-6dd3-4535-b271-a8b15202773c	190124110002547	pass	0.400	[{"cal_c": -39.8, "dev_c": 0.2, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001742	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001742_190124110002547.docx	2026-06-03 04:53:14.24483+00
dea17250-0e98-489f-9a35-67ed14ddffd9	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	65e49e21-0e1d-4396-a42b-7af51d3a09f7	190124110002548	pass	0.400	[{"cal_c": -41.1, "dev_c": 0.3, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.6, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001743	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001743_190124110002548.docx	2026-06-03 04:53:14.24483+00
d9cae4f0-fa41-4de9-98df-e6b71f2e6225	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	83fe2ecb-b78b-4b85-87c6-b3b24f1ce358	190124110002549	pass	0.500	[{"cal_c": -39.6, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001744	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001744_190124110002549.docx	2026-06-03 04:53:14.24483+00
2ebdd6a0-4763-4a81-b938-ef8cd4e6f93f	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	65e1b112-a23d-4936-b524-152f3e57c0fb	190124110002550	pass	0.500	[{"cal_c": -40.9, "dev_c": 0.4, "ref_c": -40.5, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001745	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001745_190124110002550.docx	2026-06-03 04:53:14.24483+00
d8ebf570-52a7-4cea-8b30-7e815f9621c8	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	a51b54e6-99c1-4dce-b72a-457cfea329d8	190124110002551	pass	0.500	[{"cal_c": -39.9, "dev_c": 0.1, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001746	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001746_190124110002551.docx	2026-06-03 04:53:14.24483+00
4eb5285b-84c5-4188-a08c-689fda76ed51	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	8bbaa9a3-490a-4432-919c-a876fcd39e41	190124110002552	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001747	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001747_190124110002552.docx	2026-06-03 04:53:14.24483+00
ececb12d-01a8-4cea-a5d5-85756a79fe05	320c8e6c-51e2-43ea-b741-1be9b3629848	e4943593-b1d0-44a7-b364-9ed7601c7892	190125070005547	pass	\N	[]	0000001237	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001237_190125070005547.docx	2025-10-01 09:00:00+00
ed2338e5-ae29-436a-b20f-59a7944d6a66	320c8e6c-51e2-43ea-b741-1be9b3629848	44d776be-2d40-4379-8ff0-f42a82af41e7	190125070005548	pass	\N	[]	0000001238	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001238_190125070005548.docx	2025-10-01 09:00:00+00
6c3cc43a-d91b-422e-a6e1-7817109786fa	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	324e4352-d3e5-4684-8da9-c40a62c86261	190124110002553	pass	0.500	[{"cal_c": -40.3, "dev_c": 0.3, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001748	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001748_190124110002553.docx	2026-06-03 04:53:14.24483+00
1d02be50-5370-4051-905b-a3eaf743c452	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	e9fdc393-54e7-4116-a5b3-346c8a5097e8	190124110002554	pass	0.500	[{"cal_c": -40.8, "dev_c": 0.0, "ref_c": -40.8, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.5, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 39.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001749	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/certificates/Calibration_Certificate_0000001749_190124110002554.docx	2026-06-03 04:53:14.24483+00
cf33c87d-5008-49b1-abb0-a42f6bc0d2b0	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	f726579d-0d1d-40a1-ba48-38a5c7ab6818	190124110002555	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001720	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001720_190124110002555.docx	2026-06-03 04:53:21.177254+00
c940364a-bbf2-4021-81b1-3af1ec49aa9c	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	fd4756a1-92b7-4efb-a814-085640abd29b	190124110002556	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001721	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001721_190124110002556.docx	2026-06-03 04:53:21.177254+00
4f627270-6685-4b3f-97d9-584f6d1596cb	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	525b052c-0127-4fc8-af45-ec1d25724d2d	190124110002557	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001722	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001722_190124110002557.docx	2026-06-03 04:53:21.177254+00
5e82118a-9e51-4a39-81da-857ba067c9bf	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	c0443eff-db68-4de6-bbb1-986dc0286bb3	190124110002558	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001723	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001723_190124110002558.docx	2026-06-03 04:53:21.177254+00
cb854479-d01b-4930-9dcd-f11b5af17d89	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	7c79651f-44cb-479c-88b2-4022a454b980	190124110002559	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001724	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001724_190124110002559.docx	2026-06-03 04:53:21.177254+00
d1c6272a-20c1-426e-91ef-0e665a1f987b	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	938cdb54-9ca0-4c3b-83b2-61959fe666fe	190124110002560	pass	0.500	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001725	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001725_190124110002560.docx	2026-06-03 04:53:21.177254+00
55fd95bf-d086-46c8-b506-b0e099f37329	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	8e64249c-1b2a-4808-992d-257e4b0635ef	190124110002561	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.9, "dev_c": 0.0, "ref_c": 5.9, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001726	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001726_190124110002561.docx	2026-06-03 04:53:21.177254+00
76cb0e74-e76a-4fe8-8c87-db5c3d04796e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e021fb9d-6f9b-4e2b-9d02-ffb01cf5f4a3	190124110002562	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001727	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001727_190124110002562.docx	2026-06-03 04:53:21.177254+00
101c9173-e52e-4693-b38b-945ec65b5fe4	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	5c289e19-7cb3-4365-a7db-85185f305b6b	190124110002563	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001728	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001728_190124110002563.docx	2026-06-03 04:53:21.177254+00
d0b5bf87-c21a-4983-971c-2c13985cf805	320c8e6c-51e2-43ea-b741-1be9b3629848	38c738db-79ed-4810-8206-c73af3003ca4	190125070005549	pass	\N	[]	0000001239	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001239_190125070005549.docx	2025-10-01 09:00:00+00
0782ce10-af51-4659-aaba-e4c4855dcd0c	320c8e6c-51e2-43ea-b741-1be9b3629848	bd67a58c-1fcc-47eb-8227-987dd33f1e4d	190125070005550	pass	\N	[]	0000001240	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001240_190125070005550.docx	2025-10-01 09:00:00+00
9846c314-5763-4cc1-8d92-7be76b47e7a9	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e25253b0-d9ab-4616-87eb-3b1d54a995c4	190124110002564	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.5, "dev_c": 0.1, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001729	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001729_190124110002564.docx	2026-06-03 04:53:21.177254+00
8a4f93c2-01c8-4f6b-8f22-d898e5e551dd	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	a1ca75a6-1e31-4d12-a506-dad9c80e2be5	190124110002565	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001730	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001730_190124110002565.docx	2026-06-03 04:53:21.177254+00
e564cf4f-eab9-4ceb-a4a4-c2cf89edd50e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	ad4aa6f9-821c-405e-9064-316e613b7627	190124110002566	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001731	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001731_190124110002566.docx	2026-06-03 04:53:21.177254+00
924d7d61-adeb-42f1-a0b8-84d8bd00191f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	0e5c7a83-e46c-4516-b464-1b63b1532649	190124110002567	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001732	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001732_190124110002567.docx	2026-06-03 04:53:21.177254+00
0f5e679c-b982-4f3b-bc61-db71f47fb28f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	7a8663d9-0035-418e-9c40-b22004cd2fdb	190124110002568	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001733	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001733_190124110002568.docx	2026-06-03 04:53:21.177254+00
2ccccefd-8e0d-4999-bdac-b0b1a46e3013	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	693d5fd5-5a61-4745-99da-e401066e6fd4	190124110002569	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001734	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001734_190124110002569.docx	2026-06-03 04:53:21.177254+00
79998b09-a82a-483a-95ab-e9322f453f10	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	029dff4d-9229-463c-93e5-ed46ad783e07	190124110002570	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.1, "dev_c": 0.1, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001735	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001735_190124110002570.docx	2026-06-03 04:53:21.177254+00
52e65073-7165-4361-920c-404ba0022dce	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	8c45f4c1-6d01-47c7-a09e-ab1884d8a3d5	190124110002571	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001736	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001736_190124110002571.docx	2026-06-03 04:53:21.177254+00
475aec2e-7ae8-451b-91c5-f071c04fefd9	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d48f8447-16a4-4142-b157-48c59787693d	190124110002572	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001737	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001737_190124110002572.docx	2026-06-03 04:53:21.177254+00
85972ae5-47b0-49f2-9728-3a10dfeae94e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	b978ff0d-65ef-4de2-90e2-fa4d62753467	190124110002573	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001738	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001738_190124110002573.docx	2026-06-03 04:53:21.177254+00
9962d04b-9cec-475d-a076-b2681f17a365	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	0a65c73b-885d-4633-87e7-298185da46c1	190124110002574	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001739	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001739_190124110002574.docx	2026-06-03 04:53:21.177254+00
d6ab2c57-18c0-4cd1-b594-d8ae438cda86	320c8e6c-51e2-43ea-b741-1be9b3629848	27385204-4d6f-4e6e-a841-5635cb88e680	190125070005551	pass	\N	[]	0000001241	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001241_190125070005551.docx	2025-10-01 09:00:00+00
3eb6455a-f0df-422a-b50e-6e414e56fc54	320c8e6c-51e2-43ea-b741-1be9b3629848	9e4732ff-e556-4a9f-9b2f-0b7eb2eba432	190125070005552	pass	\N	[]	0000001242	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001242_190125070005552.docx	2025-10-01 09:00:00+00
0648402f-712c-48bc-b498-9fed2062ad61	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	87160477-acd2-44cf-b410-d6ba956795bb	190124110002575	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001740	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001740_190124110002575.docx	2026-06-03 04:53:21.177254+00
832c365e-abe6-45e2-926f-5f68cadfebb0	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	cd3845fa-d65c-4175-bf97-f53964d4cee0	190124110002576	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001741	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001741_190124110002576.docx	2026-06-03 04:53:21.177254+00
1a6015aa-e765-44a9-9d28-b77471eb765a	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e87e06d6-45dd-4fa7-9e5a-1eab46fdd010	190124110002577	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001742	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001742_190124110002577.docx	2026-06-03 04:53:21.177254+00
7cafe9f8-ac97-4446-89af-4e638418b3da	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	aa9f975b-2756-4f56-9d3a-0d31f5e8d8d7	190124110002578	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.6, "dev_c": 0.0, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001743	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001743_190124110002578.docx	2026-06-03 04:53:21.177254+00
e6c5e228-8cff-4037-a1e4-4f3076cb5ad3	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	f98e6ebb-7b02-4be5-8620-446ab10df87b	190124110002579	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001744	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001744_190124110002579.docx	2026-06-03 04:53:21.177254+00
deb052fc-bb4d-47dd-94da-697667026d8f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	14b424b0-730f-4abd-929d-6d8f608b4cf6	190124110002580	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001745	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001745_190124110002580.docx	2026-06-03 04:53:21.177254+00
d0eb079a-f08f-4598-bcf3-23deb1956367	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	31b663da-9f60-4fe3-a652-c18d4914f3b5	190124110002581	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001746	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001746_190124110002581.docx	2026-06-03 04:53:21.177254+00
847674f7-d485-4ae6-b7d9-d98f9f1bd38e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	fe926ab4-6a78-4c4a-9e30-3e8b683a34a8	190124110002582	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001747	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001747_190124110002582.docx	2026-06-03 04:53:21.177254+00
f43ca1d7-19d0-480e-b59e-8735953f467f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2a65850d-5e3e-498c-8605-3d834023eeba	190124110002583	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001748	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001748_190124110002583.docx	2026-06-03 04:53:21.177254+00
7d2c3bb8-a833-4ea9-b08e-b2974e1d2413	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	3ddc6b13-0c18-4bc2-bedb-b115aea5d97b	190124110002584	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001749	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001749_190124110002584.docx	2026-06-03 04:53:21.177254+00
3d69f500-7008-498f-945a-268d1ce6f54c	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	11f772ee-c6ce-4c4d-978d-b8c45cfd83f7	190124110002585	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001750	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001750_190124110002585.docx	2026-06-03 04:53:21.177254+00
7c6ada65-c656-49f0-b9d6-0ece3a40237a	320c8e6c-51e2-43ea-b741-1be9b3629848	ccb9db45-b875-469c-8cc0-0db9f90ebce5	190125070005553	pass	\N	[]	0000001243	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001243_190125070005553.docx	2025-10-01 09:00:00+00
d75211db-0760-4ab2-b79a-2a8cbc19bad5	320c8e6c-51e2-43ea-b741-1be9b3629848	f62d03ab-0490-46f7-ac60-672b6d30e33c	190125070005554	pass	\N	[]	0000001244	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001244_190125070005554.docx	2025-10-01 09:00:00+00
ab8084af-6e11-4082-aee7-df51646f7129	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	12d17c7e-19e5-42b2-a015-5ef05720151b	190124110002586	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001751	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001751_190124110002586.docx	2026-06-03 04:53:21.177254+00
6eec2881-363d-474c-9249-25a64765ad5f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	66307657-f4c1-469a-8a26-c74ffa9bc25c	190124110002587	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001752	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001752_190124110002587.docx	2026-06-03 04:53:21.177254+00
7545b724-b96e-4a7e-bd5f-b6cab2fc60c9	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	5ea0e660-0862-4da6-8697-10710bd74695	190124110002588	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001753	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001753_190124110002588.docx	2026-06-03 04:53:21.177254+00
3e566a1f-23ee-45de-9fd2-07a000029b61	320c8e6c-51e2-43ea-b741-1be9b3629848	641bcb94-6b7a-4897-8011-e06e546d68dd	190125070005555	pass	\N	[]	0000001245	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001245_190125070005555.docx	2025-10-01 09:00:00+00
80a4bb0c-2eda-489e-97fb-adbb450abb81	320c8e6c-51e2-43ea-b741-1be9b3629848	dc6a8052-9f35-4300-bc66-95a2bc9680e2	190125070005556	pass	\N	[]	0000001246	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001246_190125070005556.docx	2025-10-01 09:00:00+00
81729fcd-b83a-4a7f-94ce-da6e12215e0c	320c8e6c-51e2-43ea-b741-1be9b3629848	2f371c9b-2f60-43a7-971e-b77db8ea0217	190125070005557	pass	\N	[]	0000001247	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001247_190125070005557.docx	2025-10-01 09:00:00+00
c18bafbb-d53e-4335-8c65-1cd50be1c5c2	320c8e6c-51e2-43ea-b741-1be9b3629848	55ad9464-863d-4f5e-93f2-f13c01b36730	190125070005558	pass	\N	[]	0000001248	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001248_190125070005558.docx	2025-10-01 09:00:00+00
bf134793-1cae-4856-abcd-d1f341abdc24	320c8e6c-51e2-43ea-b741-1be9b3629848	912cc02f-4def-4a58-80fd-9203c9e1d942	190125070005559	pass	\N	[]	0000001249	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001249_190125070005559.docx	2025-10-01 09:00:00+00
c43fa23d-6646-4e89-87ff-763d14372357	320c8e6c-51e2-43ea-b741-1be9b3629848	61e6aa78-8b91-4ae9-b0cc-1687d0681b79	190125070005560	pass	\N	[]	0000001250	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001250_190125070005560.docx	2025-10-01 09:00:00+00
8b6fdf5c-b705-4ead-a42f-783b39541370	320c8e6c-51e2-43ea-b741-1be9b3629848	cc114f3a-dec6-44e0-995e-aa363721fd6f	190125070005561	pass	\N	[]	0000001251	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001251_190125070005561.docx	2025-10-01 09:00:00+00
5e37cf3a-d04d-497e-8b1b-309980b297dd	320c8e6c-51e2-43ea-b741-1be9b3629848	2d08fee6-517a-4b06-8dc8-09c6e7455119	190125070005562	pass	\N	[]	0000001252	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001252_190125070005562.docx	2025-10-01 09:00:00+00
dd79a6af-fae8-4fc4-a1ca-6695c086cb0e	320c8e6c-51e2-43ea-b741-1be9b3629848	2f0c49f7-bc75-499f-8260-3d6d5ce4b5e4	190125070005563	pass	\N	[]	0000001253	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001253_190125070005563.docx	2025-10-01 09:00:00+00
c0adf81b-2c50-4f8d-8811-a948b3f2d68f	320c8e6c-51e2-43ea-b741-1be9b3629848	f78a85a2-f755-4f7b-afc1-5bc2bab1517b	190125070005564	pass	\N	[]	0000001254	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001254_190125070005564.docx	2025-10-01 09:00:00+00
595ca95d-be84-40b8-85c3-7d4c3668b05e	320c8e6c-51e2-43ea-b741-1be9b3629848	19990ba1-8cd4-46e3-9a21-93666a0a8cc9	190125070005565	pass	\N	[]	0000001255	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001255_190125070005565.docx	2025-10-01 09:00:00+00
b4ab7547-eb35-4dc2-93a3-34d4fe3d589e	320c8e6c-51e2-43ea-b741-1be9b3629848	7a2f55f8-6d99-43ac-8ec5-bd6d1f293bb3	190125070005566	pass	\N	[]	0000001256	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001256_190125070005566.docx	2025-10-01 09:00:00+00
2ee91876-4c5c-40d3-b7c1-27f2817fe7a7	320c8e6c-51e2-43ea-b741-1be9b3629848	86b10bff-d82b-4e41-a0da-1e3e258f3ce8	190125070005567	pass	\N	[]	0000001257	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001257_190125070005567.docx	2025-10-01 09:00:00+00
59f5e03d-08a5-4d58-9e77-faee66f925e1	320c8e6c-51e2-43ea-b741-1be9b3629848	c0557358-65d3-4977-af55-8d73062e6150	190125070005568	pass	\N	[]	0000001258	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001258_190125070005568.docx	2025-10-01 09:00:00+00
5ebb04f5-6da7-451d-8c2c-f50bc2c71126	320c8e6c-51e2-43ea-b741-1be9b3629848	e7b4be30-4bc5-42de-98c1-5dbb2ce66d34	190125070005569	pass	\N	[]	0000001259	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001259_190125070005569.docx	2025-10-01 09:00:00+00
9db9d9c3-ffdf-4731-baa1-c9619f296da0	320c8e6c-51e2-43ea-b741-1be9b3629848	8e58123a-9d37-48f7-831d-ccd5bfab036f	190125070005570	pass	\N	[]	0000001260	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001260_190125070005570.docx	2025-10-01 09:00:00+00
69193f2c-7b94-45e2-9b63-3ae1560a954a	320c8e6c-51e2-43ea-b741-1be9b3629848	40933c40-9f8c-4061-b52b-7a14e22a1122	190125070005571	pass	\N	[]	0000001261	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001261_190125070005571.docx	2025-10-01 09:00:00+00
bda17355-b985-4bbf-8316-a52c69db7fbe	320c8e6c-51e2-43ea-b741-1be9b3629848	3005cf98-a6d8-4174-b569-665185a266eb	190125070005572	pass	\N	[]	0000001262	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001262_190125070005572.docx	2025-10-01 09:00:00+00
c16780da-4284-423b-be5e-98a269b72e47	320c8e6c-51e2-43ea-b741-1be9b3629848	63895f81-cf42-478a-b36e-ef449f72afd2	190125070005573	pass	\N	[]	0000001263	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001263_190125070005573.docx	2025-10-01 09:00:00+00
13d1b07f-0e28-4c94-a16c-39a499fbad70	320c8e6c-51e2-43ea-b741-1be9b3629848	85ff2173-b84b-4d67-bee7-c573465d1306	190125070005574	pass	\N	[]	0000001264	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001264_190125070005574.docx	2025-10-01 09:00:00+00
37f2ebb6-977e-4472-a798-a0b45d8370b5	320c8e6c-51e2-43ea-b741-1be9b3629848	0a057cf6-9687-4161-bbf7-69efd36d1b43	190125070005575	pass	\N	[]	0000001265	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001265_190125070005575.docx	2025-10-01 09:00:00+00
cdadc31e-4409-4e44-bf3c-f7ae110934cf	320c8e6c-51e2-43ea-b741-1be9b3629848	80948324-6214-4260-94b9-293308feeda5	190125070005576	pass	\N	[]	0000001266	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001266_190125070005576.docx	2025-10-01 09:00:00+00
44207f7c-dd9f-40e3-917c-102e70071ca3	320c8e6c-51e2-43ea-b741-1be9b3629848	e5a29b29-4937-4aec-852d-bd1cc36ed11d	190125070005607	pass	\N	[]	0000001297	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001297_190125070005607.docx	2025-10-01 09:00:00+00
411fbb5b-d8b6-45e3-8f5e-e6296290fb4e	320c8e6c-51e2-43ea-b741-1be9b3629848	620a10f6-8b80-4057-82e6-d343bdc04fc4	190125070005608	pass	\N	[]	0000001298	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001298_190125070005608.docx	2025-10-01 09:00:00+00
28c7208e-0b65-4ab3-88a5-72e9688b7131	320c8e6c-51e2-43ea-b741-1be9b3629848	7040f3bc-9a1f-4606-8cb4-16c95f73afce	190125070005609	pass	\N	[]	0000001299	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001299_190125070005609.docx	2025-10-01 09:00:00+00
087e4a3b-cf91-4417-9a28-d8ec23c5a482	320c8e6c-51e2-43ea-b741-1be9b3629848	bfd212b6-2854-4f4d-9af8-12ac055c867e	190125070005610	pass	\N	[]	0000001300	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001300_190125070005610.docx	2025-10-01 09:00:00+00
bef98d01-746b-4afc-adeb-1e70a1b9009b	320c8e6c-51e2-43ea-b741-1be9b3629848	b1a82efd-a66c-4819-b963-f3cecf0ecfc8	190125070005611	pass	\N	[]	0000001301	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001301_190125070005611.docx	2025-10-01 09:00:00+00
a34f2742-d0bf-4ba2-b6e6-4d307babb252	320c8e6c-51e2-43ea-b741-1be9b3629848	8935959f-b2ac-426a-8d61-73f4bc447b77	190125070005612	pass	\N	[]	0000001302	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001302_190125070005612.docx	2025-10-01 09:00:00+00
29218999-4968-4b23-9479-8af61b3ef258	320c8e6c-51e2-43ea-b741-1be9b3629848	5931bfe5-8d41-4807-8d11-36c255273bc0	190125070005613	pass	\N	[]	0000001303	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001303_190125070005613.docx	2025-10-01 09:00:00+00
552f6da3-35e4-4432-9623-7938ccb6ac12	320c8e6c-51e2-43ea-b741-1be9b3629848	f0094a0b-f5c7-4bc3-bdb9-8e874dc65aa3	190125070005614	pass	\N	[]	0000001304	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001304_190125070005614.docx	2025-10-01 09:00:00+00
3d39ce3d-d985-438e-aa49-d4d9fe2ef6c8	320c8e6c-51e2-43ea-b741-1be9b3629848	2da6f744-491c-4e32-9168-ef6d31a368b3	190125070005615	pass	\N	[]	0000001305	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001305_190125070005615.docx	2025-10-01 09:00:00+00
cad211a4-28ee-4107-9567-ec97e4bd650a	320c8e6c-51e2-43ea-b741-1be9b3629848	eb7b20af-05f1-421e-8d03-7be7b1997d4c	190125070005616	pass	\N	[]	0000001306	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001306_190125070005616.docx	2025-10-01 09:00:00+00
4b2738ad-05d3-44d0-8745-3ffb677349f4	320c8e6c-51e2-43ea-b741-1be9b3629848	97d820e3-00b2-4d3f-8651-0a894075d097	190125070005617	pass	\N	[]	0000001307	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001307_190125070005617.docx	2025-10-01 09:00:00+00
f7e2100f-990d-4c3b-842b-95d12edb70e1	320c8e6c-51e2-43ea-b741-1be9b3629848	c7ff7b29-cfa2-4c74-aabc-72dfbdfb62a5	190125070005618	pass	\N	[]	0000001308	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001308_190125070005618.docx	2025-10-01 09:00:00+00
67ad7eab-1300-4de9-a325-b524351037e6	320c8e6c-51e2-43ea-b741-1be9b3629848	7a7e2556-af52-4989-94b6-d304f0c1e4f8	190125070005619	pass	\N	[]	0000001309	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001309_190125070005619.docx	2025-10-01 09:00:00+00
1b303b3e-f7b7-474e-8f67-0e924b24e304	320c8e6c-51e2-43ea-b741-1be9b3629848	1e81d3da-96aa-4e9b-913b-af8f0bb444ee	190125070005620	pass	\N	[]	0000001310	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001310_190125070005620.docx	2025-10-01 09:00:00+00
d172f0fa-41c5-43b0-9793-fe37bf988a3c	320c8e6c-51e2-43ea-b741-1be9b3629848	f13f93e9-dfe2-41e1-92dc-047140b57d0e	190125070005621	pass	\N	[]	0000001311	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001311_190125070005621.docx	2025-10-01 09:00:00+00
1f2bbd17-ff22-44a3-b120-1ac74b517704	320c8e6c-51e2-43ea-b741-1be9b3629848	c98e8a93-5d7d-41ea-8de7-f6251a452c36	190125070005622	pass	\N	[]	0000001312	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001312_190125070005622.docx	2025-10-01 09:00:00+00
5e247c29-5be3-42e2-89de-fdd65d3c2e79	320c8e6c-51e2-43ea-b741-1be9b3629848	01837953-1a5a-4499-b4ae-0bc3905bcdc8	190125070005623	pass	\N	[]	0000001313	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001313_190125070005623.docx	2025-10-01 09:00:00+00
81871f35-4d8e-4602-bfae-a59cd526b810	320c8e6c-51e2-43ea-b741-1be9b3629848	6ce9bf30-4235-4b9f-a504-cb6d6309df6d	190125070005624	pass	\N	[]	0000001314	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001314_190125070005624.docx	2025-10-01 09:00:00+00
f48d26e6-13a1-4952-aec8-5f72dd6d531f	320c8e6c-51e2-43ea-b741-1be9b3629848	9422b830-5b6a-456b-b5e7-fdf00bb0daf0	190125070005625	pass	\N	[]	0000001315	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001315_190125070005625.docx	2025-10-01 09:00:00+00
e03b8789-edf5-408f-b083-ed2af4f9bf97	320c8e6c-51e2-43ea-b741-1be9b3629848	cb874b7c-87b8-42b7-a57d-e8f0abdef4d9	190125070005626	pass	\N	[]	0000001316	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001316_190125070005626.docx	2025-10-01 09:00:00+00
00bf522a-b1ad-45d8-9e04-8078053ce48a	320c8e6c-51e2-43ea-b741-1be9b3629848	428f3f29-00f3-47db-98a3-a14e268b7bab	190125070005627	pass	\N	[]	0000001317	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001317_190125070005627.docx	2025-10-01 09:00:00+00
90144d5e-0eaa-42d6-906a-ebf350a52d92	320c8e6c-51e2-43ea-b741-1be9b3629848	5fe6839d-975b-42a0-af50-4355f61592a5	190125070005628	pass	\N	[]	0000001318	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001318_190125070005628.docx	2025-10-01 09:00:00+00
d8684da8-3112-4612-9205-5469d1258089	320c8e6c-51e2-43ea-b741-1be9b3629848	ad6b5e09-0774-4739-a594-145e51ecc941	190125070005629	pass	\N	[]	0000001319	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001319_190125070005629.docx	2025-10-01 09:00:00+00
734f7cba-0d6d-45e2-b08d-bd95a12cee7d	320c8e6c-51e2-43ea-b741-1be9b3629848	1f20a638-2e76-444c-8f8e-999df941ea10	190125070005630	pass	\N	[]	0000001320	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001320_190125070005630.docx	2025-10-01 09:00:00+00
624bf3aa-8ee7-4427-9ec0-f67c6c280c33	320c8e6c-51e2-43ea-b741-1be9b3629848	af92c448-c88d-41d5-8202-569c7c38a54f	190125070005528	pass	\N	[]	0000001218	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001218_190125070005528.docx	2025-10-01 09:00:00+00
1bb71a4a-9614-4076-91fa-8fcb43d257b6	320c8e6c-51e2-43ea-b741-1be9b3629848	f95c1148-d55e-4307-b1a3-2656e3fbec98	190125070005487	pass	\N	[]	0000001177	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001177_190125070005487.docx	2025-10-01 09:00:00+00
d0d6e799-6806-43ae-a331-19106361eb1a	320c8e6c-51e2-43ea-b741-1be9b3629848	0cf9b360-372b-40c2-85dc-31edffb43551	190125070005488	pass	\N	[]	0000001178	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001178_190125070005488.docx	2025-10-01 09:00:00+00
f8e3c641-0075-45b4-9c2f-68e58c259d38	320c8e6c-51e2-43ea-b741-1be9b3629848	cee84803-f01d-49fb-913d-769ebfc93a70	190125070005489	pass	\N	[]	0000001179	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001179_190125070005489.docx	2025-10-01 09:00:00+00
3a4218bf-90cc-442a-a972-be48df608e0e	320c8e6c-51e2-43ea-b741-1be9b3629848	72aa1e02-25f9-4536-ac81-e5c69bfb97b6	190125070005490	pass	\N	[]	0000001180	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001180_190125070005490.docx	2025-10-01 09:00:00+00
5dd35704-f9fb-4242-a9a3-190f363c1f35	320c8e6c-51e2-43ea-b741-1be9b3629848	81805888-614c-411c-85c6-c9fb69c31364	190125070005491	pass	\N	[]	0000001181	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001181_190125070005491.docx	2025-10-01 09:00:00+00
75c83ee9-6a42-402f-9c6d-07febe1fd1ac	320c8e6c-51e2-43ea-b741-1be9b3629848	eee4c9c9-f59f-4f56-ab11-74aee354b020	190125070005492	pass	\N	[]	0000001182	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001182_190125070005492.docx	2025-10-01 09:00:00+00
857a0538-483f-44e3-bdfd-a906cb88b3bb	320c8e6c-51e2-43ea-b741-1be9b3629848	da36ef6b-cbdc-4c2c-aedb-b9b2f428d930	190125070005493	pass	\N	[]	0000001183	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001183_190125070005493.docx	2025-10-01 09:00:00+00
96292089-b7a6-49e3-b956-281bc15ab47d	320c8e6c-51e2-43ea-b741-1be9b3629848	5a0aec2e-3742-458a-b325-0bdad377711d	190125070005494	pass	\N	[]	0000001184	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001184_190125070005494.docx	2025-10-01 09:00:00+00
383c04cb-c4b4-4194-800c-69c4f88d798f	320c8e6c-51e2-43ea-b741-1be9b3629848	11c83bcc-951b-45cb-96e3-b1d55d2b1f0a	190125070005495	pass	\N	[]	0000001185	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001185_190125070005495.docx	2025-10-01 09:00:00+00
5dd71e1c-8755-4644-a5b5-6a0d391b7905	320c8e6c-51e2-43ea-b741-1be9b3629848	6e7ee035-4027-49c9-8bbf-4035e23b91d4	190125070005496	pass	\N	[]	0000001186	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001186_190125070005496.docx	2025-10-01 09:00:00+00
2832f3c7-bfde-4c3b-a778-7f959b88648a	320c8e6c-51e2-43ea-b741-1be9b3629848	b50e46b3-dee2-4ec1-9a9d-a9c60beb89b2	190125070005497	pass	\N	[]	0000001187	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001187_190125070005497.docx	2025-10-01 09:00:00+00
90f88b69-9241-4913-9d3a-9e86e8d8cc64	320c8e6c-51e2-43ea-b741-1be9b3629848	f3490e0f-70df-45e6-bad8-9125518e9eba	190125070005498	pass	\N	[]	0000001188	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001188_190125070005498.docx	2025-10-01 09:00:00+00
228ee6c1-ffa8-429d-9b63-fada537b9870	320c8e6c-51e2-43ea-b741-1be9b3629848	5f5ac71b-93aa-4447-816a-483b54088169	190125070005499	pass	\N	[]	0000001189	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001189_190125070005499.docx	2025-10-01 09:00:00+00
af707c73-6217-40ef-907b-245518d1e585	320c8e6c-51e2-43ea-b741-1be9b3629848	3d0bf9c3-4c5e-4f57-95d5-d95f3bdb0a64	190125070005500	pass	\N	[]	0000001190	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001190_190125070005500.docx	2025-10-01 09:00:00+00
48860c5f-da42-40e7-85ae-0cf076eff34d	320c8e6c-51e2-43ea-b741-1be9b3629848	40ab3171-7f5f-4a27-b4af-0ef24b4c09f1	190125070005501	pass	\N	[]	0000001191	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001191_190125070005501.docx	2025-10-01 09:00:00+00
f9f43d2f-991b-45df-a52a-d3b683be0739	320c8e6c-51e2-43ea-b741-1be9b3629848	f7594b46-0ee7-461d-8b19-a20d140c7cf4	190125070005502	pass	\N	[]	0000001192	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001192_190125070005502.docx	2025-10-01 09:00:00+00
ec83e98f-3693-4304-aa23-1578eb7d9c34	320c8e6c-51e2-43ea-b741-1be9b3629848	f9881a34-cd86-4707-aca8-3a4eb8bc63e5	190125070005503	pass	\N	[]	0000001193	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001193_190125070005503.docx	2025-10-01 09:00:00+00
0c072668-2f02-41c0-b69f-1b12ae3741c1	320c8e6c-51e2-43ea-b741-1be9b3629848	cc0664f1-bbc7-4b69-b124-d92f527825df	190125070005504	pass	\N	[]	0000001194	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001194_190125070005504.docx	2025-10-01 09:00:00+00
e5c44bc8-e4d1-49b3-81ed-b29dc4aef352	320c8e6c-51e2-43ea-b741-1be9b3629848	0080c1a6-80e3-49b3-ab4e-9d35f6b978ff	190125070005505	pass	\N	[]	0000001195	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001195_190125070005505.docx	2025-10-01 09:00:00+00
6a506440-d0dc-4c27-a6e1-806a8b2cbfe6	320c8e6c-51e2-43ea-b741-1be9b3629848	37e0888b-0bd0-4a59-bd41-18617fabbeb9	190125070005506	pass	\N	[]	0000001196	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001196_190125070005506.docx	2025-10-01 09:00:00+00
2de34d23-4d19-4abc-83fb-e6f0ce22bae4	320c8e6c-51e2-43ea-b741-1be9b3629848	1a6c7813-d185-45f5-8824-68c26f1bf44e	190125070005507	pass	\N	[]	0000001197	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001197_190125070005507.docx	2025-10-01 09:00:00+00
cd6211e1-57e0-4bca-9b56-7f308941233a	320c8e6c-51e2-43ea-b741-1be9b3629848	32be710e-b91f-4a16-ba2f-6b0e01cd7233	190125070005508	pass	\N	[]	0000001198	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001198_190125070005508.docx	2025-10-01 09:00:00+00
16dd673d-bdf8-41fb-90f9-0c7827b486e7	320c8e6c-51e2-43ea-b741-1be9b3629848	c83ca333-ee34-4f66-99b7-480470fa196c	190125070005509	pass	\N	[]	0000001199	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001199_190125070005509.docx	2025-10-01 09:00:00+00
4696d99d-b7aa-4123-b2f0-63e3f00599e3	320c8e6c-51e2-43ea-b741-1be9b3629848	ed84a038-5fb5-468f-aab6-b4d58cf38866	190125070005510	pass	\N	[]	0000001200	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001200_190125070005510.docx	2025-10-01 09:00:00+00
ccf63afb-64f7-4c70-9d79-59d3b893c813	320c8e6c-51e2-43ea-b741-1be9b3629848	c45b0d00-ae30-442e-ac9e-ccd9185ac5e2	190125070005511	pass	\N	[]	0000001201	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001201_190125070005511.docx	2025-10-01 09:00:00+00
32e8cb25-d301-4138-a355-a56fd9c834f2	320c8e6c-51e2-43ea-b741-1be9b3629848	3288eb92-27b7-4e3c-9d4d-c659c2ca9f3f	190125070005512	pass	\N	[]	0000001202	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001202_190125070005512.docx	2025-10-01 09:00:00+00
d7313239-097d-4dcf-a965-b08d4e7bd434	320c8e6c-51e2-43ea-b741-1be9b3629848	894eb2e3-5be6-4a91-8246-7723430d9031	190125070005513	pass	\N	[]	0000001203	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001203_190125070005513.docx	2025-10-01 09:00:00+00
e3c9cbc4-a823-421d-9a87-79b7f2f6168c	320c8e6c-51e2-43ea-b741-1be9b3629848	5047002a-5791-4081-8c76-3c84bc4266c8	190125070005514	pass	\N	[]	0000001204	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001204_190125070005514.docx	2025-10-01 09:00:00+00
3faae32d-be27-4a43-a84b-6f0b964f11f3	320c8e6c-51e2-43ea-b741-1be9b3629848	91572410-1623-49ce-85fe-92fb71d71542	190125070005515	pass	\N	[]	0000001205	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001205_190125070005515.docx	2025-10-01 09:00:00+00
7c170ef8-b070-43f8-98ab-75b434a8b03e	320c8e6c-51e2-43ea-b741-1be9b3629848	99ca5d1f-6666-4c1d-b88c-7125eff517f5	190125070005516	pass	\N	[]	0000001206	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001206_190125070005516.docx	2025-10-01 09:00:00+00
b8e5bbb7-5c5b-4ff0-a597-a4e0f43af802	320c8e6c-51e2-43ea-b741-1be9b3629848	ab9e9157-7731-4345-ad7d-69ae98eb51bf	190125070005517	pass	\N	[]	0000001207	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001207_190125070005517.docx	2025-10-01 09:00:00+00
3c96b0b8-3ee1-4144-90bb-92a34e76cd94	320c8e6c-51e2-43ea-b741-1be9b3629848	f7470370-61cf-4543-958c-fffd35368f30	190125070005518	pass	\N	[]	0000001208	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001208_190125070005518.docx	2025-10-01 09:00:00+00
7a27b0bd-ba45-4d15-a1eb-2fa05d1ac52d	320c8e6c-51e2-43ea-b741-1be9b3629848	caa1e1ca-3740-469b-95ea-46a05fccc4e7	190125070005519	pass	\N	[]	0000001209	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001209_190125070005519.docx	2025-10-01 09:00:00+00
388f5dc4-c167-41b1-a92e-33febd1cff99	320c8e6c-51e2-43ea-b741-1be9b3629848	a18aaf37-11c1-42d4-8e05-7528ba75002b	190125070005520	pass	\N	[]	0000001210	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001210_190125070005520.docx	2025-10-01 09:00:00+00
6732ccbc-9fea-48ab-b84e-53cdfdab8353	320c8e6c-51e2-43ea-b741-1be9b3629848	504206cd-80ea-4d2c-8630-41fbf11b6965	190125070005521	pass	\N	[]	0000001211	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001211_190125070005521.docx	2025-10-01 09:00:00+00
1ce8640d-115b-42e2-b52a-202edeb21871	320c8e6c-51e2-43ea-b741-1be9b3629848	761c0a91-892d-4d12-971d-0ec684c90606	190125070005522	pass	\N	[]	0000001212	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001212_190125070005522.docx	2025-10-01 09:00:00+00
79482821-aec3-4dbb-82a2-0fca085fe38a	320c8e6c-51e2-43ea-b741-1be9b3629848	0f9883a9-b4d8-4809-82c6-b835d8f730f3	190125070005523	pass	\N	[]	0000001213	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001213_190125070005523.docx	2025-10-01 09:00:00+00
30e178fe-cc9a-4c82-8403-30c32d3d1eed	320c8e6c-51e2-43ea-b741-1be9b3629848	8ad97cf7-4a55-4735-90a8-cec260225ca0	190125070005524	pass	\N	[]	0000001214	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001214_190125070005524.docx	2025-10-01 09:00:00+00
45478fd3-5b0e-4f43-92db-c79dd64f3ba7	320c8e6c-51e2-43ea-b741-1be9b3629848	bd6dcced-6398-4a9a-abde-f21492dc8388	190125070005525	pass	\N	[]	0000001215	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001215_190125070005525.docx	2025-10-01 09:00:00+00
4f35a07b-9f9a-4eb0-a1ce-b483097cc850	320c8e6c-51e2-43ea-b741-1be9b3629848	46770c6f-639a-491d-a2bc-acdd8a4b1e60	190125070005526	pass	\N	[]	0000001216	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001216_190125070005526.docx	2025-10-01 09:00:00+00
8c0d9ac0-32a5-49fc-996e-baacf64d2473	320c8e6c-51e2-43ea-b741-1be9b3629848	5a4eceb9-a20b-40d6-85c3-e6f4f259c325	190125070005527	pass	\N	[]	0000001217	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001217_190125070005527.docx	2025-10-01 09:00:00+00
bfd9073d-8f7a-45f1-a87e-027aae741492	320c8e6c-51e2-43ea-b741-1be9b3629848	badec15b-2537-4c1b-9577-4e681c5d0a56	190125070005529	pass	\N	[]	0000001219	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001219_190125070005529.docx	2025-10-01 09:00:00+00
776d076d-c7db-428d-9f52-e8c8aa044b6f	320c8e6c-51e2-43ea-b741-1be9b3629848	4bce4bb3-50a0-4acc-a976-8621b4596cd1	190125070005381	pass	\N	[]	0000001071	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001071_190125070005381.docx	2025-10-01 09:00:00+00
f8cfdef2-d707-462a-af83-88e9784d4579	320c8e6c-51e2-43ea-b741-1be9b3629848	0b84c402-43c4-42c5-9b07-c3d86a1377de	190125070005382	pass	\N	[]	0000001072	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001072_190125070005382.docx	2025-10-01 09:00:00+00
db500a6f-d3fc-4ce5-bf08-b106a144d0ce	320c8e6c-51e2-43ea-b741-1be9b3629848	3e3c98f3-f460-4026-8f9b-62564af261a4	190125070005383	pass	\N	[]	0000001073	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001073_190125070005383.docx	2025-10-01 09:00:00+00
66640d71-6494-4565-adc4-471ccb106934	320c8e6c-51e2-43ea-b741-1be9b3629848	ef3ffd7a-34e0-4e70-a807-d1e0f12d1fa3	190125070005384	pass	\N	[]	0000001074	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001074_190125070005384.docx	2025-10-01 09:00:00+00
a2ea5277-164a-4213-9692-dd73c78317b9	320c8e6c-51e2-43ea-b741-1be9b3629848	77977915-6e66-476d-9701-ba221ca0e3b1	190125070005385	pass	\N	[]	0000001075	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001075_190125070005385.docx	2025-10-01 09:00:00+00
0efdb141-2161-455f-a450-46a4573b1518	320c8e6c-51e2-43ea-b741-1be9b3629848	d3ceebca-fe92-4d19-9ae5-0bb967b9dfe1	190125070005386	pass	\N	[]	0000001076	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001076_190125070005386.docx	2025-10-01 09:00:00+00
cb7bc5df-b02e-4670-b042-13272281c4be	320c8e6c-51e2-43ea-b741-1be9b3629848	4b755862-093a-48d7-8ff8-ca19ad77c3bf	190125070005387	pass	\N	[]	0000001077	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001077_190125070005387.docx	2025-10-01 09:00:00+00
564ca781-a2d1-4529-9f40-0c6321369218	320c8e6c-51e2-43ea-b741-1be9b3629848	40e1f202-15a4-4014-a73c-b8aeda813ec1	190125070005388	pass	\N	[]	0000001078	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001078_190125070005388.docx	2025-10-01 09:00:00+00
8a073795-5a36-4baa-88f3-c4ccf17e5b44	320c8e6c-51e2-43ea-b741-1be9b3629848	1a4f721a-8dbc-492a-be5d-fad5cb2e1174	190125070005389	pass	\N	[]	0000001079	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001079_190125070005389.docx	2025-10-01 09:00:00+00
4eec3811-8e96-4770-9e30-b4868da3f5ad	320c8e6c-51e2-43ea-b741-1be9b3629848	3bb0b215-6d5a-448e-b291-bbc869a01791	190125070005390	pass	\N	[]	0000001080	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001080_190125070005390.docx	2025-10-01 09:00:00+00
7c93d512-613e-4c66-93de-cabe2a02b13c	320c8e6c-51e2-43ea-b741-1be9b3629848	d529337a-e0c1-4e88-8353-99a2c306417c	190125070005391	pass	\N	[]	0000001081	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001081_190125070005391.docx	2025-10-01 09:00:00+00
0678e3cf-db09-448b-81cb-859a708b86fd	320c8e6c-51e2-43ea-b741-1be9b3629848	9a1cea4c-09ea-4a6d-8fea-c134c2cd686e	190125070005392	pass	\N	[]	0000001082	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001082_190125070005392.docx	2025-10-01 09:00:00+00
68a3c9bd-1bb4-4af9-93ba-55f0d81a89ca	320c8e6c-51e2-43ea-b741-1be9b3629848	e23c726b-4fc1-4269-aea0-8a5f19b1a705	190125070005393	pass	\N	[]	0000001083	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001083_190125070005393.docx	2025-10-01 09:00:00+00
13458c00-fe95-4269-86cd-c63bc041633a	320c8e6c-51e2-43ea-b741-1be9b3629848	07b378d4-4b47-4156-8fd6-594c5d848991	190125070005394	pass	\N	[]	0000001084	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001084_190125070005394.docx	2025-10-01 09:00:00+00
7982c190-1854-4b4d-83ef-f7102f5f0b90	320c8e6c-51e2-43ea-b741-1be9b3629848	d8c41519-a773-474c-ba8f-7ba474a84922	190125070005395	pass	\N	[]	0000001085	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001085_190125070005395.docx	2025-10-01 09:00:00+00
55e3ea09-c004-469f-90c7-07346fed19da	320c8e6c-51e2-43ea-b741-1be9b3629848	1bfba840-5bee-4462-87c5-7288a40d4784	190125070005396	pass	\N	[]	0000001086	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001086_190125070005396.docx	2025-10-01 09:00:00+00
6a7583c8-248c-4a3b-a522-76081751f41e	320c8e6c-51e2-43ea-b741-1be9b3629848	9371f303-f41d-466f-ad79-457d2e8a1eb1	190125070005397	pass	\N	[]	0000001087	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001087_190125070005397.docx	2025-10-01 09:00:00+00
2699dc57-3c73-4fee-b1a4-f9483fa37acd	320c8e6c-51e2-43ea-b741-1be9b3629848	f889e97e-7c3c-471f-9a6b-2ae9f1294232	190125070005398	pass	\N	[]	0000001088	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001088_190125070005398.docx	2025-10-01 09:00:00+00
ce3ea9dc-0ddf-43b7-bdc3-dd55aec6c30c	320c8e6c-51e2-43ea-b741-1be9b3629848	6ea06b84-2d7d-4ffd-83fc-5aa0e397e5a1	190125070005399	pass	\N	[]	0000001089	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001089_190125070005399.docx	2025-10-01 09:00:00+00
a465883d-ecd6-4ed9-95a4-d01144eb6f28	320c8e6c-51e2-43ea-b741-1be9b3629848	a3bbf459-793b-4c76-a70b-ce1e432209c1	190125070005400	pass	\N	[]	0000001090	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001090_190125070005400.docx	2025-10-01 09:00:00+00
ea2d4912-c1f6-4dbd-ab79-0979ca9e36fb	320c8e6c-51e2-43ea-b741-1be9b3629848	7b228bc7-8ade-45cd-b178-d5880b72397e	190125070005401	pass	\N	[]	0000001091	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001091_190125070005401.docx	2025-10-01 09:00:00+00
02f9fb9c-684e-489f-863f-87b6d4cd6355	320c8e6c-51e2-43ea-b741-1be9b3629848	66d95a30-65ff-44f1-8a2a-07305d8f75b8	190125070005402	pass	\N	[]	0000001092	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001092_190125070005402.docx	2025-10-01 09:00:00+00
b660c90b-051c-433d-b505-5b9b97e4887c	320c8e6c-51e2-43ea-b741-1be9b3629848	f546b7e2-a81f-431b-9bdf-c0b744f193f4	190125070005403	pass	\N	[]	0000001093	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001093_190125070005403.docx	2025-10-01 09:00:00+00
d96bd280-a996-4c13-aec8-bc6ca6c96c91	320c8e6c-51e2-43ea-b741-1be9b3629848	e81ec33c-cd03-4008-8de7-c1e1b23ee265	190125070005404	pass	\N	[]	0000001094	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001094_190125070005404.docx	2025-10-01 09:00:00+00
4c458e98-f434-40e8-8366-ce31d3ea9e5d	320c8e6c-51e2-43ea-b741-1be9b3629848	5a74f773-9d85-4e0f-8862-30b7fc70ea64	190125070005405	pass	\N	[]	0000001095	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001095_190125070005405.docx	2025-10-01 09:00:00+00
a32c981a-81cc-4dc2-83a1-958cc6e01cea	320c8e6c-51e2-43ea-b741-1be9b3629848	a497e375-ac17-44d2-ae04-76d339dcea1b	190125070005406	pass	\N	[]	0000001096	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001096_190125070005406.docx	2025-10-01 09:00:00+00
ba037441-69b6-42d5-bad6-9ed62183b1d7	320c8e6c-51e2-43ea-b741-1be9b3629848	f7b8fb6e-3e80-4556-882f-6c92a737cc4a	190125070005407	pass	\N	[]	0000001097	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001097_190125070005407.docx	2025-10-01 09:00:00+00
b5ec805a-6932-40fc-bd48-54bb576ecadb	320c8e6c-51e2-43ea-b741-1be9b3629848	484b1045-e4b9-414b-ba32-7309be6bf17b	190125070005408	pass	\N	[]	0000001098	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001098_190125070005408.docx	2025-10-01 09:00:00+00
cfe3aff0-6b5f-4fd1-8206-18d38eebf55b	320c8e6c-51e2-43ea-b741-1be9b3629848	deb69da2-0359-41fe-b56a-fb7420cf647e	190125070005409	pass	\N	[]	0000001099	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001099_190125070005409.docx	2025-10-01 09:00:00+00
b7bf9f89-35a4-4816-b759-9b642e1b24b6	320c8e6c-51e2-43ea-b741-1be9b3629848	34b26dcf-2b97-45a9-b042-5822b734ca0b	190125070005410	pass	\N	[]	0000001100	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001100_190125070005410.docx	2025-10-01 09:00:00+00
30c3577c-c2ee-480b-8f7a-20ae903ef9a7	320c8e6c-51e2-43ea-b741-1be9b3629848	eea8e56d-5d7c-44e0-a4a2-f6f319c59235	190125070005411	pass	\N	[]	0000001101	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001101_190125070005411.docx	2025-10-01 09:00:00+00
11349119-40e7-4062-8598-7d6c5d657824	320c8e6c-51e2-43ea-b741-1be9b3629848	419e81e1-b4ee-4181-8e8a-433a89461c12	190125070005412	pass	\N	[]	0000001102	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001102_190125070005412.docx	2025-10-01 09:00:00+00
4981934c-2ad6-47dd-a57f-1d610e85e5f4	320c8e6c-51e2-43ea-b741-1be9b3629848	29d00382-3637-4600-ae68-3a58799a1913	190125070005413	pass	\N	[]	0000001103	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001103_190125070005413.docx	2025-10-01 09:00:00+00
09c93d0f-7131-45f4-beff-e4a725e875a2	320c8e6c-51e2-43ea-b741-1be9b3629848	d61004d0-0246-42c1-b7dd-3bdf2ac5b8a2	190125070005414	pass	\N	[]	0000001104	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001104_190125070005414.docx	2025-10-01 09:00:00+00
7e047dd0-4e8a-4dc8-b6bc-2c0b9cfbae2a	320c8e6c-51e2-43ea-b741-1be9b3629848	7bc3f543-3996-4857-b17e-47a7fa301805	190125070005415	pass	\N	[]	0000001105	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001105_190125070005415.docx	2025-10-01 09:00:00+00
e551e4f2-5cc9-446d-9079-d4a8b6d90afc	320c8e6c-51e2-43ea-b741-1be9b3629848	8d3d3ffb-8cd3-45b8-98fc-8ed8ea9ddd71	190125070005416	pass	\N	[]	0000001106	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001106_190125070005416.docx	2025-10-01 09:00:00+00
68046dee-203a-42fd-b5eb-806f12b01804	320c8e6c-51e2-43ea-b741-1be9b3629848	c2593d84-40bc-458a-960b-4e3a9471270c	190125070005417	pass	\N	[]	0000001107	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001107_190125070005417.docx	2025-10-01 09:00:00+00
97cddbef-ef7e-49de-8c00-3d89ee9fdbf7	320c8e6c-51e2-43ea-b741-1be9b3629848	82069425-5717-49d1-862b-7b91e0a8c9db	190125070005418	pass	\N	[]	0000001108	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001108_190125070005418.docx	2025-10-01 09:00:00+00
944d4974-8c2e-4523-a1c9-4007313522b4	320c8e6c-51e2-43ea-b741-1be9b3629848	725dda3a-b6d1-484f-8064-a323587b54fc	190125070005419	pass	\N	[]	0000001109	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001109_190125070005419.docx	2025-10-01 09:00:00+00
66114a4b-128d-4790-8eba-9b53a84713a6	320c8e6c-51e2-43ea-b741-1be9b3629848	63863ea3-8766-43f2-a139-53aa2c0e2fba	190125070005420	pass	\N	[]	0000001110	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001110_190125070005420.docx	2025-10-01 09:00:00+00
9eedb7c0-1107-4d9d-b369-e9038ad027d6	320c8e6c-51e2-43ea-b741-1be9b3629848	ae7c8c9b-c4c3-43cd-98df-da24af4c8cac	190125070005421	pass	\N	[]	0000001111	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001111_190125070005421.docx	2025-10-01 09:00:00+00
e68b0eab-78f9-4f51-898d-832aa10282fc	320c8e6c-51e2-43ea-b741-1be9b3629848	964f92b4-b051-49b9-b065-399e4d4f9af0	190125070005422	pass	\N	[]	0000001112	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001112_190125070005422.docx	2025-10-01 09:00:00+00
6e1e61f4-9440-4a55-a8f4-e8f05a352d63	320c8e6c-51e2-43ea-b741-1be9b3629848	1b8bf689-f566-46bd-93b9-9273eff4c8fa	190125070005423	pass	\N	[]	0000001113	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001113_190125070005423.docx	2025-10-01 09:00:00+00
0ca11c1f-79ce-4b8c-b9cc-7f3a14482997	320c8e6c-51e2-43ea-b741-1be9b3629848	52abc167-0499-42fa-9db3-4832f1a4cb6d	190125070005424	pass	\N	[]	0000001114	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001114_190125070005424.docx	2025-10-01 09:00:00+00
a002ee37-b3d8-413f-a065-828512a58c40	320c8e6c-51e2-43ea-b741-1be9b3629848	763f3183-4a31-41c3-9696-dac2bb7cae12	190125070005425	pass	\N	[]	0000001115	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001115_190125070005425.docx	2025-10-01 09:00:00+00
4eafab8d-50fc-424c-9289-d5d7115f4f26	320c8e6c-51e2-43ea-b741-1be9b3629848	386a6dfd-76f6-4979-b564-1c4a53ba9bd0	190125070005426	pass	\N	[]	0000001116	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001116_190125070005426.docx	2025-10-01 09:00:00+00
0e2c8ae8-fda4-40d2-abf9-0bb428d5c79f	320c8e6c-51e2-43ea-b741-1be9b3629848	cf2959c8-9855-4199-94cb-302997c65fa1	190125070005427	pass	\N	[]	0000001117	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001117_190125070005427.docx	2025-10-01 09:00:00+00
691b6905-887a-494a-bc65-c960a2ffe760	320c8e6c-51e2-43ea-b741-1be9b3629848	198b6f60-4015-4fa0-9825-b2b8dc63cdfd	190125070005428	pass	\N	[]	0000001118	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001118_190125070005428.docx	2025-10-01 09:00:00+00
d8fa2b4b-7f18-4cf9-98c9-7aa76f7c15c1	320c8e6c-51e2-43ea-b741-1be9b3629848	aac83204-b562-4948-b642-53ddab6fef5a	190125070005429	pass	\N	[]	0000001119	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001119_190125070005429.docx	2025-10-01 09:00:00+00
3c6cb251-5f13-4e70-9bdb-93bd342882fe	320c8e6c-51e2-43ea-b741-1be9b3629848	8bde73ca-101e-4a0b-bd4d-e270bb34c8a9	190125070005430	pass	\N	[]	0000001120	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001120_190125070005430.docx	2025-10-01 09:00:00+00
dcd46b13-fccc-465b-846d-c73e9ecfa2e6	320c8e6c-51e2-43ea-b741-1be9b3629848	c3624f01-8aae-4da0-890d-37e30a47cf0c	190125070005431	pass	\N	[]	0000001121	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001121_190125070005431.docx	2025-10-01 09:00:00+00
5fe9e735-4ebc-4726-bd93-bfbb4ceab068	320c8e6c-51e2-43ea-b741-1be9b3629848	cf6edef9-5f43-4a2f-b2cb-82d0bbcf5cf9	190125070005432	pass	\N	[]	0000001122	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001122_190125070005432.docx	2025-10-01 09:00:00+00
dacec878-a48d-40f1-83d5-fbf5766e45e9	320c8e6c-51e2-43ea-b741-1be9b3629848	2563fa77-3d84-4cc9-ab9f-076148be5215	190125070005433	pass	\N	[]	0000001123	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001123_190125070005433.docx	2025-10-01 09:00:00+00
89791d6c-ccb7-4936-a556-c03e716f6399	320c8e6c-51e2-43ea-b741-1be9b3629848	e1338493-bfc2-4fb7-acbc-850d7a22ab58	190125070005434	pass	\N	[]	0000001124	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001124_190125070005434.docx	2025-10-01 09:00:00+00
635bd908-de6d-485e-8a8a-5dc2159b8ebd	320c8e6c-51e2-43ea-b741-1be9b3629848	b2fc2f4a-3646-4de5-b1a1-a7230ac8c46d	190125070005435	pass	\N	[]	0000001125	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001125_190125070005435.docx	2025-10-01 09:00:00+00
9d9d53fb-2917-4d13-b37f-d7c2e894d246	320c8e6c-51e2-43ea-b741-1be9b3629848	05047249-0cd2-47c5-888b-5588bbb90aee	190125070005436	pass	\N	[]	0000001126	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001126_190125070005436.docx	2025-10-01 09:00:00+00
5f706809-afc4-4a92-af79-d0da77b3f449	320c8e6c-51e2-43ea-b741-1be9b3629848	56d63e76-8e7c-4598-850c-156b28b27863	190125070005437	pass	\N	[]	0000001127	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001127_190125070005437.docx	2025-10-01 09:00:00+00
343ee264-35c7-4b23-9857-8a5ed45332fa	320c8e6c-51e2-43ea-b741-1be9b3629848	25d96e2b-55c7-4ce6-97c8-ea0f062b16d5	190125070005438	pass	\N	[]	0000001128	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001128_190125070005438.docx	2025-10-01 09:00:00+00
b55f88f8-8af8-4d6d-abdb-b10347140d47	320c8e6c-51e2-43ea-b741-1be9b3629848	81b779d7-f084-461a-b3ef-8ebc5a1e376f	190125070005439	pass	\N	[]	0000001129	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001129_190125070005439.docx	2025-10-01 09:00:00+00
270fb1c5-ffc0-40ed-88a5-524d9914f26c	320c8e6c-51e2-43ea-b741-1be9b3629848	4b3ee8fb-c12c-427c-831b-1362ab03bba1	190125070005440	pass	\N	[]	0000001130	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001130_190125070005440.docx	2025-10-01 09:00:00+00
392f9d71-9969-4841-9e74-151354d9a9fa	320c8e6c-51e2-43ea-b741-1be9b3629848	48fc9605-0a42-4f00-a62a-79d053a2f125	190125070005441	pass	\N	[]	0000001131	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001131_190125070005441.docx	2025-10-01 09:00:00+00
c1517f37-2e47-4990-b9fe-fbe41a82efb3	320c8e6c-51e2-43ea-b741-1be9b3629848	566d56fb-674a-4197-bb72-778954ae8677	190125070005442	pass	\N	[]	0000001132	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001132_190125070005442.docx	2025-10-01 09:00:00+00
b656c6a3-b5fc-46ae-a324-d25a37d16318	320c8e6c-51e2-43ea-b741-1be9b3629848	7662010c-f253-4fa0-b3d0-70e6b0ee5c26	190125070005443	pass	\N	[]	0000001133	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001133_190125070005443.docx	2025-10-01 09:00:00+00
b19f8d05-e8ca-4213-bf9c-07747da7ccf7	320c8e6c-51e2-43ea-b741-1be9b3629848	87d7f55b-8f90-4f02-bf41-72c3ae30f40e	190125070005444	pass	\N	[]	0000001134	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001134_190125070005444.docx	2025-10-01 09:00:00+00
a88af296-cc04-45f9-b512-6de8a4721520	320c8e6c-51e2-43ea-b741-1be9b3629848	b166448a-ddab-4df2-854a-078e6ddb6413	190125070005445	pass	\N	[]	0000001135	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001135_190125070005445.docx	2025-10-01 09:00:00+00
7ada819d-4797-424d-bc7d-52362b0e73d3	320c8e6c-51e2-43ea-b741-1be9b3629848	2ee46f2f-c4d6-42a1-bd9f-2810792bc290	190125070005446	pass	\N	[]	0000001136	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001136_190125070005446.docx	2025-10-01 09:00:00+00
16c1b933-16f5-4967-86c2-6344dbbf9af0	320c8e6c-51e2-43ea-b741-1be9b3629848	89ca082f-60b3-4096-86e3-c61797ba5489	190125070005447	pass	\N	[]	0000001137	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001137_190125070005447.docx	2025-10-01 09:00:00+00
68fd30fb-f812-418a-853e-1f33155c149c	320c8e6c-51e2-43ea-b741-1be9b3629848	f114f810-50a5-4387-b824-62e486165894	190125070005448	pass	\N	[]	0000001138	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001138_190125070005448.docx	2025-10-01 09:00:00+00
5c995140-0335-482c-b645-aef8b00dc54a	320c8e6c-51e2-43ea-b741-1be9b3629848	05cb8e85-b20e-488c-8548-a7365d3b558b	190125070005449	pass	\N	[]	0000001139	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001139_190125070005449.docx	2025-10-01 09:00:00+00
5d79e4d9-7af4-43cc-909c-46de35fb3476	320c8e6c-51e2-43ea-b741-1be9b3629848	1bad12b4-ea1f-4184-918c-0c4f077ca881	190125070005450	pass	\N	[]	0000001140	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001140_190125070005450.docx	2025-10-01 09:00:00+00
4b477430-519f-4c62-9b2c-8c382d728ca6	320c8e6c-51e2-43ea-b741-1be9b3629848	582e0b46-659e-4642-bd7c-68f1b52aa7b3	190125070005451	pass	\N	[]	0000001141	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001141_190125070005451.docx	2025-10-01 09:00:00+00
085fb252-2f06-4638-979e-b57aba3ba2b3	320c8e6c-51e2-43ea-b741-1be9b3629848	fb7c0ce3-be63-4829-927a-c6472002d115	190125070005452	pass	\N	[]	0000001142	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001142_190125070005452.docx	2025-10-01 09:00:00+00
aa40a21c-abdf-4710-88eb-b806d1061fd5	320c8e6c-51e2-43ea-b741-1be9b3629848	77aa9804-9890-4cf0-9c45-a50940534ad3	190125070005453	pass	\N	[]	0000001143	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001143_190125070005453.docx	2025-10-01 09:00:00+00
c76cd6db-7968-4a1f-8858-a6d65f11d889	320c8e6c-51e2-43ea-b741-1be9b3629848	7218b954-49b2-4a63-ac14-13cd8623e509	190125070005454	pass	\N	[]	0000001144	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001144_190125070005454.docx	2025-10-01 09:00:00+00
9628fd67-9ef9-4230-a3d1-c9af2195bd11	320c8e6c-51e2-43ea-b741-1be9b3629848	2bb6ee56-9d8a-4b0e-b04e-818a7cc7c05b	190125070005455	pass	\N	[]	0000001145	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001145_190125070005455.docx	2025-10-01 09:00:00+00
a7d51d7c-0f76-4d6a-b9c2-23f4312affdf	320c8e6c-51e2-43ea-b741-1be9b3629848	4490308b-576e-443c-8617-3fe4dbfd4ad8	190125070005456	pass	\N	[]	0000001146	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001146_190125070005456.docx	2025-10-01 09:00:00+00
f7511abc-e853-44a3-916c-fca2229be991	320c8e6c-51e2-43ea-b741-1be9b3629848	cd3b831d-0a12-45a5-984b-7842bf3e2eb0	190125070005457	pass	\N	[]	0000001147	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001147_190125070005457.docx	2025-10-01 09:00:00+00
0cba2ca7-7e48-4b2c-a517-3e9f3ec3d490	320c8e6c-51e2-43ea-b741-1be9b3629848	b32cc967-91b6-4b30-95d7-c3b8fd819a2b	190125070005458	pass	\N	[]	0000001148	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001148_190125070005458.docx	2025-10-01 09:00:00+00
7bbd8111-33c3-4c67-a402-ac058bc5ea55	320c8e6c-51e2-43ea-b741-1be9b3629848	c5d745f2-56e4-4bac-acd5-eefa9db99f8a	190125070005459	pass	\N	[]	0000001149	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001149_190125070005459.docx	2025-10-01 09:00:00+00
487ec439-92d2-44d4-a93c-49ec2d798899	320c8e6c-51e2-43ea-b741-1be9b3629848	5dccd4bb-3d9b-4da6-962c-cd872ca7dd59	190125070005460	pass	\N	[]	0000001150	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001150_190125070005460.docx	2025-10-01 09:00:00+00
d2aea993-70e2-4e35-b93f-c326fcd99e89	320c8e6c-51e2-43ea-b741-1be9b3629848	661a0786-70b1-4ef7-ad6b-589a7575aae0	190125070005461	pass	\N	[]	0000001151	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001151_190125070005461.docx	2025-10-01 09:00:00+00
0bff3c13-38e6-4d04-9541-cf896a057f87	320c8e6c-51e2-43ea-b741-1be9b3629848	a6f974c2-1e1e-4873-b452-6cf6613b9d39	190125070005462	pass	\N	[]	0000001152	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001152_190125070005462.docx	2025-10-01 09:00:00+00
320eb12d-49c7-495e-8c34-13d7be42fa7e	320c8e6c-51e2-43ea-b741-1be9b3629848	bb021623-c7a0-4211-bd76-afa438f587c1	190125070005463	pass	\N	[]	0000001153	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001153_190125070005463.docx	2025-10-01 09:00:00+00
08688a02-e524-4cfe-a292-13cd45344017	320c8e6c-51e2-43ea-b741-1be9b3629848	b8ad7997-9631-4c6d-a0e9-f27df0df2610	190125070005464	pass	\N	[]	0000001154	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001154_190125070005464.docx	2025-10-01 09:00:00+00
0108f2cc-b96c-4596-a391-0db62b6032b4	320c8e6c-51e2-43ea-b741-1be9b3629848	d9cb8165-207e-4666-97f3-9e8bbfb43222	190125070005465	pass	\N	[]	0000001155	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001155_190125070005465.docx	2025-10-01 09:00:00+00
bb34aae4-8b1a-46b3-8e3c-059f653f4d1d	320c8e6c-51e2-43ea-b741-1be9b3629848	c65f9ed5-e333-4862-9ec9-7213b2db7a56	190125070005466	pass	\N	[]	0000001156	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001156_190125070005466.docx	2025-10-01 09:00:00+00
e8ad0f10-0fd6-4cc6-88f4-04a2464b7589	320c8e6c-51e2-43ea-b741-1be9b3629848	f115a438-16ff-4391-baa6-5f2d07d74e4c	190125070005467	pass	\N	[]	0000001157	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001157_190125070005467.docx	2025-10-01 09:00:00+00
21ef4b74-025b-4b34-85cc-b6c5208df876	320c8e6c-51e2-43ea-b741-1be9b3629848	70438b52-bd54-4494-8866-f78ab66aaa8e	190125070005468	pass	\N	[]	0000001158	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001158_190125070005468.docx	2025-10-01 09:00:00+00
e53bf6a4-97c1-4ac4-9f51-83d3d1f4f65c	320c8e6c-51e2-43ea-b741-1be9b3629848	0c82c0a8-f9ef-4a2b-a2aa-e64dcdfd456b	190125070005469	pass	\N	[]	0000001159	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001159_190125070005469.docx	2025-10-01 09:00:00+00
910ca092-89a1-423b-adf5-fb72581aef6a	320c8e6c-51e2-43ea-b741-1be9b3629848	cdc5670e-d834-427f-b8bc-5dd77aac1d86	190125070005470	pass	\N	[]	0000001160	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001160_190125070005470.docx	2025-10-01 09:00:00+00
e6038a28-9c11-4cc9-b4a6-ec394d013131	320c8e6c-51e2-43ea-b741-1be9b3629848	21a4ea28-a3c2-4c0f-b2c7-cdafc2271286	190125070005471	pass	\N	[]	0000001161	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001161_190125070005471.docx	2025-10-01 09:00:00+00
68f3a163-eaf8-4c48-9a5a-8b470109ec90	320c8e6c-51e2-43ea-b741-1be9b3629848	abca22d4-a8f3-4f51-8be1-5cf6b459e6de	190125070005472	pass	\N	[]	0000001162	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001162_190125070005472.docx	2025-10-01 09:00:00+00
64667fd7-0fbe-40cb-a921-52bd2c041d85	320c8e6c-51e2-43ea-b741-1be9b3629848	e86c2233-989e-4998-a9cd-51edc458b115	190125070005473	pass	\N	[]	0000001163	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001163_190125070005473.docx	2025-10-01 09:00:00+00
70e649e4-e19b-4b9f-9770-81657035c66e	320c8e6c-51e2-43ea-b741-1be9b3629848	b565b854-28fc-42ac-a2de-72a63a48a08b	190125070005474	pass	\N	[]	0000001164	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001164_190125070005474.docx	2025-10-01 09:00:00+00
c6d6919b-d9a9-4f65-9cc1-95c4fc0aebea	320c8e6c-51e2-43ea-b741-1be9b3629848	6c20bf41-b7dc-4a61-b026-fbbd9a62f3f2	190125070005475	pass	\N	[]	0000001165	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001165_190125070005475.docx	2025-10-01 09:00:00+00
d61e66b2-8546-4447-a168-d0aeed7dcd33	320c8e6c-51e2-43ea-b741-1be9b3629848	ff5bb2ea-0671-4cb4-afd3-cc8a730fd4dd	190125070005476	pass	\N	[]	0000001166	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001166_190125070005476.docx	2025-10-01 09:00:00+00
e43a74cc-fd5d-4957-b635-06743f953ef4	320c8e6c-51e2-43ea-b741-1be9b3629848	412d0e57-009a-4b65-9863-8e09143a5917	190125070005477	pass	\N	[]	0000001167	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001167_190125070005477.docx	2025-10-01 09:00:00+00
fefb08f9-19c6-47fe-a01f-2de109c6aea5	320c8e6c-51e2-43ea-b741-1be9b3629848	28209f08-72a9-4917-8fa0-28ac7bad0a02	190125070005478	pass	\N	[]	0000001168	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001168_190125070005478.docx	2025-10-01 09:00:00+00
47d7eaa9-fd37-46f5-9161-e7d9233a74ac	320c8e6c-51e2-43ea-b741-1be9b3629848	0c9e23cc-fe2e-4ec1-b099-d129c34cec7b	190125070005479	pass	\N	[]	0000001169	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001169_190125070005479.docx	2025-10-01 09:00:00+00
5d5e9e72-4888-4a32-8816-ab36abd7a7c4	320c8e6c-51e2-43ea-b741-1be9b3629848	c35b3ea3-d093-479e-9d8e-7bceac400013	190125070005480	pass	\N	[]	0000001170	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001170_190125070005480.docx	2025-10-01 09:00:00+00
2505385c-0233-467b-9f58-78b5f0cf84fb	320c8e6c-51e2-43ea-b741-1be9b3629848	23aa1d69-9f59-4d93-8fae-0a1e2960dc82	190125070005481	pass	\N	[]	0000001171	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001171_190125070005481.docx	2025-10-01 09:00:00+00
7da42200-c0d5-4610-87f9-01742d3764dd	320c8e6c-51e2-43ea-b741-1be9b3629848	cfd49371-50bb-4e7b-9a9d-67240ee95ac3	190125070005482	pass	\N	[]	0000001172	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001172_190125070005482.docx	2025-10-01 09:00:00+00
71e27e11-389b-40c6-b450-91086971118e	320c8e6c-51e2-43ea-b741-1be9b3629848	62d5c317-284d-4188-b332-a612c3724d0d	190125070005483	pass	\N	[]	0000001173	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001173_190125070005483.docx	2025-10-01 09:00:00+00
580c2ca7-ca2a-412a-8a16-9d2d67dcfd58	320c8e6c-51e2-43ea-b741-1be9b3629848	b76a78bc-d7e8-4cef-9d9a-47a15221f522	190125070005484	pass	\N	[]	0000001174	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001174_190125070005484.docx	2025-10-01 09:00:00+00
f2854549-8379-4679-8b1d-e1bf1b662427	320c8e6c-51e2-43ea-b741-1be9b3629848	e3b5b3c3-61ca-42d7-ba21-8cfbacdc9a6c	190125070005485	pass	\N	[]	0000001175	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001175_190125070005485.docx	2025-10-01 09:00:00+00
9e11e00a-eb2d-4f5e-b2d4-a27f492ed888	320c8e6c-51e2-43ea-b741-1be9b3629848	2ee9ba28-cf48-4447-8829-892df2aae4c7	190125070005486	pass	\N	[]	0000001176	/var/lib/ite-calibration/data/runs/320c8e6c-51e2-43ea-b741-1be9b3629848/certificates/Calibration_Certificate_0000001176_190125070005486.docx	2025-10-01 09:00:00+00
4ca7901f-ce62-475d-910a-45a9fc3e51f4	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	984456ac-3806-4ae2-9c2c-a95dcde37fce	190124110002594	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001759	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001759_190124110002594.docx	2026-06-03 04:53:21.177254+00
5fd0825a-f798-4645-b34f-a3649c9c5a9e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d34b36fe-090d-4b11-bc88-1a579cb4066d	190124110002595	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001760	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001760_190124110002595.docx	2026-06-03 04:53:21.177254+00
239b66bf-df95-4384-b64a-0807ae878405	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	bea966c5-488f-4eeb-98e5-e51145aeb583	190124110002596	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.9, "dev_c": 0.1, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001761	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001761_190124110002596.docx	2026-06-03 04:53:21.177254+00
a043c4e7-31e2-48da-a87f-b3e7ba512010	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	8f32e70b-b72d-4896-bd97-452d6aeea7a5	190124110002597	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001762	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001762_190124110002597.docx	2026-06-03 04:53:21.177254+00
e7b35d97-6c3d-4e83-849f-aa53f3fbd41b	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	6ccf876d-728c-4a4c-b0d4-6ef2270f7b58	190124110002598	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001763	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001763_190124110002598.docx	2026-06-03 04:53:21.177254+00
64ce5f88-5ae6-4499-a160-03453f2f5daa	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2f66477d-cadb-418a-ab53-3389ec4e9fdf	190124110002599	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001764	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001764_190124110002599.docx	2026-06-03 04:53:21.177254+00
e8c08e0b-6403-4f90-85b8-bb1f9bf5396f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	31fdc681-7580-4ae2-b37f-349d82bff775	190124110002600	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001765	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001765_190124110002600.docx	2026-06-03 04:53:21.177254+00
2b1dddcd-8959-4d7c-9e44-cc797e17fb36	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	1e51ab78-7e79-40e7-b396-aaf7fff65f67	190124110002601	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001766	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001766_190124110002601.docx	2026-06-03 04:53:21.177254+00
b3f62cce-6496-4d0a-958a-663d5356114d	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	788ab88d-3213-42c1-973e-712b1184aa1b	190124110002602	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001767	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001767_190124110002602.docx	2026-06-03 04:53:21.177254+00
82a3e216-7c71-464c-8c8f-f36fc0c196db	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	db23c71b-3385-4191-bfb5-6aa6939d3121	190124110002603	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001768	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001768_190124110002603.docx	2026-06-03 04:53:21.177254+00
cd713dc0-646e-4ef3-ba8d-21637f091cef	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	70da94a7-6516-4eb2-9c11-0d79e32d504a	190124110002604	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001769	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001769_190124110002604.docx	2026-06-03 04:53:21.177254+00
cf198d71-225e-4d69-a69b-8039576ee70f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	234fc15d-aeba-4b57-b229-ea5063b3b9d9	190124110002605	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001770	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001770_190124110002605.docx	2026-06-03 04:53:21.177254+00
17859887-a81a-45b1-b6ff-53758ad1d49e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	29dc060c-0e3b-4b58-b3e7-5c14087965e8	190124110002606	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001771	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001771_190124110002606.docx	2026-06-03 04:53:21.177254+00
79a801fb-e870-4827-8ca3-7fb5ec1b5c03	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	9d960f2e-67c5-412f-97dc-5f71cebd939a	190124110002607	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001772	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001772_190124110002607.docx	2026-06-03 04:53:21.177254+00
6c99803b-6a92-4d1c-a46b-c9377797d88c	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	c9160e1b-7669-4e6f-946f-31e6c84e09d5	190124110002608	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001773	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001773_190124110002608.docx	2026-06-03 04:53:21.177254+00
78cd9789-7a33-41bd-a5b6-7ff86cda5e6f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	b20f5059-3904-47e2-b63a-80eb72e527e4	190124110002609	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001774	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001774_190124110002609.docx	2026-06-03 04:53:21.177254+00
74102720-e3de-40c8-b906-59df774c96dd	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	28d12950-60ff-41ce-adb6-36c0dacbcca1	190124110002610	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001775	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001775_190124110002610.docx	2026-06-03 04:53:21.177254+00
3a683cb8-ad60-4dce-a9db-e25f739d8f39	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	ac8b54a9-7695-45d9-84d2-e78f8e8c2c9e	190124110002611	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 4.8, "dev_c": 0.0, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001776	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001776_190124110002611.docx	2026-06-03 04:53:21.177254+00
6195ea64-31a3-4657-b66e-74e51b786a59	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	1a23e547-e4d7-497c-b44c-2f8e3a88dc24	190124110002612	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001777	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001777_190124110002612.docx	2026-06-03 04:53:21.177254+00
7e356929-b37f-496f-8305-3c7302ca30a4	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	80d3568e-e982-4e4c-ba3d-e07a58bdffc9	190124110002613	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001778	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001778_190124110002613.docx	2026-06-03 04:53:21.177254+00
329e52f8-ae90-434a-a6f0-c92c403cc894	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	f9615a98-3cfc-497a-bd4c-6c063752c5d8	190124110002614	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.1, "dev_c": 0.1, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001779	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001779_190124110002614.docx	2026-06-03 04:53:21.177254+00
47d48a64-eb41-4fb1-ad48-071dcf8df9cf	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	643e5d84-97fe-4676-9adb-0a466ecb5665	190124110002615	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001780	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001780_190124110002615.docx	2026-06-03 04:53:21.177254+00
aa173096-f5c5-4885-987c-db239286b5fc	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	4e57826c-f7f2-4016-bb64-9a2caa793977	190124110002616	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001781	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001781_190124110002616.docx	2026-06-03 04:53:21.177254+00
3643b38a-8739-494e-bfb5-63f0f6219be6	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	cd89c550-05a4-4707-851e-f1d78f6187e9	190124110002617	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001782	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001782_190124110002617.docx	2026-06-03 04:53:21.177254+00
9f82a682-84d7-4b66-8aa9-2b708cc193ec	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	9568cab9-a355-4894-9c96-51fbef2ed5ac	190124110002618	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.0, "dev_c": 0.0, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001783	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001783_190124110002618.docx	2026-06-03 04:53:21.177254+00
2d96113e-09c5-455a-b05b-b3fb67327757	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e2835136-9ccf-4dcc-b828-554625f3a5de	190124110002619	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001784	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001784_190124110002619.docx	2026-06-03 04:53:21.177254+00
0e99da48-e69e-41b8-9775-bc3a5f350894	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	966f072a-a3dc-47be-9ce6-2cf418adaacb	190124110002620	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001785	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001785_190124110002620.docx	2026-06-03 04:53:21.177254+00
042637a7-4575-4de0-b674-65c5f11c8df9	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	53bd0122-eceb-46d1-bc7f-0d46e5ec64d6	190124110002621	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001786	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001786_190124110002621.docx	2026-06-03 04:53:21.177254+00
d8d09b6a-7b11-4600-b8ee-452e44434740	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	5c526faf-f9e0-4870-be0a-b8e45d696801	190124110002622	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001787	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001787_190124110002622.docx	2026-06-03 04:53:21.177254+00
4cbf4538-6b62-4ed4-809b-8c93a364f3b1	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	ea3eda22-e5f7-42fd-8d1d-c321b2a89641	190124110002623	pass	0.400	[{"cal_c": -40.4, "dev_c": 0.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001788	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001788_190124110002623.docx	2026-06-03 04:53:21.177254+00
732afe24-7e6f-414b-b954-2da1357c6ac6	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	3a4ee35c-7d79-4010-b9f7-c266e630d0f2	190124110002624	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001789	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001789_190124110002624.docx	2026-06-03 04:53:21.177254+00
100dfc8e-56ab-4d2c-b8c5-6e859bbba0f1	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	55871bf7-14d3-4438-be48-5adfe1c17762	190124110002625	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001790	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001790_190124110002625.docx	2026-06-03 04:53:21.177254+00
5e989bb9-cc1e-48ed-b2bc-fbad13e51dac	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	744c786a-531c-4296-8f05-36a1b9ab773d	190124110002626	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001791	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001791_190124110002626.docx	2026-06-03 04:53:21.177254+00
446f953c-f135-41fb-abdc-d0a2a5a0602d	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2d8b2ddf-a1ef-454b-89ec-2b5968c284d2	190124110002627	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001792	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001792_190124110002627.docx	2026-06-03 04:53:21.177254+00
ada60004-03e8-48f2-8e61-da88820f5596	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	94937da5-b2bc-43c3-9d9c-1193b491497e	190124110002628	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001793	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001793_190124110002628.docx	2026-06-03 04:53:21.177254+00
e18b7820-5a4a-4787-8559-6b805d379d02	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	afa23be0-c25e-4292-b23a-0f842eec23d6	190124110002629	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001794	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001794_190124110002629.docx	2026-06-03 04:53:21.177254+00
f40513c3-c60b-4f07-8e6e-0aab7b6b4ae9	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	120d3b57-93f7-4fea-9cf7-05bef9d9c8d8	190124110002630	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001795	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001795_190124110002630.docx	2026-06-03 04:53:21.177254+00
cecf27e3-dfb2-43a3-9d73-5bde0cc5cd63	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	47602676-e825-488d-adf7-3659c24a2589	190124110002631	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.0, "dev_c": 0.2, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001796	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001796_190124110002631.docx	2026-06-03 04:53:21.177254+00
d3cec00c-25d5-4b45-bb36-a143c4cbbdd8	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	4621651f-f4f2-43bd-b729-32ef5085ef67	190124110002632	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001797	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001797_190124110002632.docx	2026-06-03 04:53:21.177254+00
415ca982-9195-4d2c-bc0e-abc3052f4d51	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	23732efb-3e59-4a9a-a5d4-9a1b333b871c	190124110002633	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001798	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001798_190124110002633.docx	2026-06-03 04:53:21.177254+00
051c9e9d-180f-433f-9074-93692de5f28c	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2a339732-0f36-45b1-8246-09c6f78cc05e	190124110002634	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001799	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001799_190124110002634.docx	2026-06-03 04:53:21.177254+00
a838020e-ecb3-449b-b5ce-9004a838858d	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	a6ecc99f-1485-4634-8af3-548731bf289d	190124110002635	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001800	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001800_190124110002635.docx	2026-06-03 04:53:21.177254+00
aeac77f9-5971-4137-a2be-c42706acd0f4	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	abc36506-4d82-4a4d-94ad-eb6d48945195	190124110002636	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001801	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001801_190124110002636.docx	2026-06-03 04:53:21.177254+00
52c0f005-e358-45f5-bcfa-34889c87d4dd	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	a126a041-0aed-4869-85bb-3b9a8fc4b8b5	190124110002637	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001802	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001802_190124110002637.docx	2026-06-03 04:53:21.177254+00
e707c67d-894a-4fcb-9c73-d75072ef7b98	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d9437561-184f-46ba-8c46-b94047027869	190124110002638	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 6.2, "dev_c": 0.2, "ref_c": 6.4, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001803	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001803_190124110002638.docx	2026-06-03 04:53:21.177254+00
c4d9cf87-1ff3-4acb-8a4f-d0d8a72d3083	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	f67c99cb-bc04-44d4-b2dc-f21b47621cce	190124110002639	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.7, "dev_c": 0.0, "ref_c": 5.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001804	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001804_190124110002639.docx	2026-06-03 04:53:21.177254+00
37b0fa79-8e80-454b-88f8-de844b6b1c80	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	6d7824cd-65b3-404b-8939-fbe876a4cea1	190124110002640	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001805	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001805_190124110002640.docx	2026-06-03 04:53:21.177254+00
e33fc38a-65cc-402a-b204-1917063a69ee	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2e3ef878-4e80-47c2-bd00-f22119acd1ac	190124110002641	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001806	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001806_190124110002641.docx	2026-06-03 04:53:21.177254+00
1e3c5551-c3eb-457f-8ba5-247b5ffeb7c8	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	2cfb9300-7f2c-44e5-ade9-ae4b5c6bcd41	190124110002642	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001807	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001807_190124110002642.docx	2026-06-03 04:53:21.177254+00
65feeda8-d9ac-4b1d-b982-e631d0164d0a	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	5975f9d0-e402-4c16-a389-4e3b39ed1e5a	190124110002643	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001808	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001808_190124110002643.docx	2026-06-03 04:53:21.177254+00
9c8f3ecd-20c8-412b-9802-77737aa130db	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	0d3b4dcb-bec1-4438-95d3-d5e4a9666e4c	190124110002644	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001809	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001809_190124110002644.docx	2026-06-03 04:53:21.177254+00
92ba26ea-aad6-4b68-b4f1-33e2193e0493	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	66019495-0cfb-46c1-bd6d-df176436a191	190124110002645	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.6, "dev_c": 0.0, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001810	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001810_190124110002645.docx	2026-06-03 04:53:21.177254+00
e6efa312-3c61-40bd-bf79-4eb6705b515b	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	982e4a01-fbf6-4b52-bed0-33f8a860a2c3	190124110002646	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001811	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001811_190124110002646.docx	2026-06-03 04:53:21.177254+00
b5809d44-c4a2-416a-a06d-40c21d6c2c72	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	c6b268a0-5d72-4176-98fc-b538aad869a1	190124110002647	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001812	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001812_190124110002647.docx	2026-06-03 04:53:21.177254+00
2319e057-55d9-45f4-8fc8-09de81d59a6a	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	f753299c-6fa6-4eff-b5f6-e31fd0968c74	190124110002648	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 6.0, "dev_c": 0.1, "ref_c": 5.9, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001813	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001813_190124110002648.docx	2026-06-03 04:53:21.177254+00
6172dd12-88f1-4d17-a9dc-617bb7441a61	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	fe086026-2c40-43b8-8f1c-f64f6d95bd0f	190124110002649	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.5, "dev_c": 0.1, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001814	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001814_190124110002649.docx	2026-06-03 04:53:21.177254+00
68e3f192-b795-4c94-bdbc-79511228e592	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d34510f0-29a8-4ee9-ba50-faa3da9d20c0	190124110002650	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.1, "dev_c": 0.3, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001815	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001815_190124110002650.docx	2026-06-03 04:53:21.177254+00
70e75dc9-6e0c-42f8-8cbc-f3435b35fa18	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d45a9ac9-7903-4b75-9c80-dcad0ca5022e	190124110002651	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001816	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001816_190124110002651.docx	2026-06-03 04:53:21.177254+00
765756f9-135a-4519-afd6-b426189cb5f1	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	faed4590-df02-4e4d-8d68-1e0e656277c5	190124110002652	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001817	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001817_190124110002652.docx	2026-06-03 04:53:21.177254+00
121606e6-66fc-49e1-bbcd-e92bbc9021f4	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	10a8e65c-f77e-4a70-aded-35f0be17daea	190124110002653	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001818	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001818_190124110002653.docx	2026-06-03 04:53:21.177254+00
2642bb80-d920-4400-996f-033f1377d8b8	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	198ec4ab-0aed-4f77-a908-5cd611e1e1a2	190124110002654	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.7, "dev_c": 0.0, "ref_c": 5.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001819	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001819_190124110002654.docx	2026-06-03 04:53:21.177254+00
89a050ab-851a-48ca-9b75-9c3fb2b4fa74	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	30c30719-7758-419f-a8b2-ac4f2d9e5b71	190124110002655	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001820	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001820_190124110002655.docx	2026-06-03 04:53:21.177254+00
e87c66f8-085b-4d64-9f1e-64a10b033925	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	67562a42-0c4b-408b-97ed-8c50a260e91e	190124110002656	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.2, "dev_c": 0.4, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.4, "dev_c": 0.4, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001821	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001821_190124110002656.docx	2026-06-03 04:53:21.177254+00
80aa8d3b-e838-47c3-92d8-530e02c2f8f8	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	d43a1a2e-fd9e-4c4c-9380-2f1b56525a01	190124110002657	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001822	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001822_190124110002657.docx	2026-06-03 04:53:21.177254+00
976fc97d-357d-4b61-81fd-bccccab58e3f	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e1a1053f-d84a-4ea3-8167-d3822e02f820	190124110002658	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001823	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001823_190124110002658.docx	2026-06-03 04:53:21.177254+00
14d0e798-4d89-413d-9508-2d38fbd954d5	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	671b49dd-34d4-48cf-977b-3c3929da24ae	190124110002659	fail	\N	[{"cal_c": null, "dev_c": null, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 5.0, "target_c": 5.0, "within_tol": false}, {"cal_c": null, "dev_c": null, "ref_c": 40.0, "target_c": 40.0, "within_tol": false}]	0000001824	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001824_190124110002659.docx	2026-06-03 04:53:21.177254+00
41f52471-a10b-4721-8b71-e79926ab2f2b	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	7361718b-6330-4758-86d9-2332f3c31512	190124110002660	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.5, "dev_c": 0.1, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.5, "dev_c": 0.5, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001825	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001825_190124110002660.docx	2026-06-03 04:53:21.177254+00
96c3ae39-d8e3-40ec-8718-4a86066fe127	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	acde45f0-b5d2-42a6-8ecd-a854bcc7fb6d	190124110002661	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.4, "dev_c": 0.2, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001826	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001826_190124110002661.docx	2026-06-03 04:53:21.177254+00
17983759-e986-48d1-9c53-fd3f28341ba7	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	009ea815-2494-401e-bc42-d7ed2dde8159	190124110002662	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.6, "dev_c": 0.0, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001827	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001827_190124110002662.docx	2026-06-03 04:53:21.177254+00
0395fb85-1541-46e4-b847-4e7470f46e74	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	e5aea8d8-cfbf-40d8-9af3-1692ba62ecdb	190124110002663	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.3, "dev_c": 0.5, "ref_c": 4.8, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.2, "dev_c": 0.2, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001828	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001828_190124110002663.docx	2026-06-03 04:53:21.177254+00
cedfb67d-f340-4cf4-9697-d83815e3835e	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	ad5ff8d2-3b5a-4e7f-acce-e7da2ae10404	190124110002664	pass	0.500	[{"cal_c": -40.5, "dev_c": 0.5, "ref_c": -40.0, "target_c": -40.0, "within_tol": true}, {"cal_c": 5.5, "dev_c": 0.1, "ref_c": 5.6, "target_c": 5.0, "within_tol": true}, {"cal_c": 40.3, "dev_c": 0.3, "ref_c": 40.0, "target_c": 40.0, "within_tol": true}]	0000001829	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/certificates/Calibration_Certificate_0000001829_190124110002664.docx	2026-06-03 04:53:21.177254+00
678f542c-50fe-4959-b359-1a72369791ef	ccd9fb7c-323e-4d24-8aba-f454129354be	8e34c7a7-6e00-4334-875f-acc432152f70	190125020000856	pass	0.500	[{"cal_c": -42.3, "dev_c": 0.0, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.5, "dev_c": 0.2, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 45.1, "dev_c": 0.5, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001937	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001937_190125020000856.docx	2026-06-03 04:53:26.42912+00
db69eea5-6ee3-4fca-9963-8ec2e9b56c3f	ccd9fb7c-323e-4d24-8aba-f454129354be	a348d54b-3cb6-4e7d-8467-f0662b6ebed4	190125020000857	pass	0.400	[{"cal_c": -42.2, "dev_c": 0.1, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.3, "dev_c": 0.4, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.8, "dev_c": 0.2, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001938	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001938_190125020000857.docx	2026-06-03 04:53:26.42912+00
535f6c08-1231-4ea3-8992-406bc9430035	ccd9fb7c-323e-4d24-8aba-f454129354be	1e847395-bcc0-446d-8c83-5a8c98b4dbf6	190125020000858	pass	0.500	[{"cal_c": -42.5, "dev_c": 0.2, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.9, "dev_c": 0.3, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001939	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001939_190125020000858.docx	2026-06-03 04:53:26.42912+00
77f8a8af-e271-4b60-8044-7567d9d02029	ccd9fb7c-323e-4d24-8aba-f454129354be	f28903a7-3f18-471e-8e60-9e792deb420b	190125020000859	pass	0.400	[{"cal_c": -42.5, "dev_c": 0.2, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.3, "dev_c": 0.4, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.4, "dev_c": 0.2, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001940	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001940_190125020000859.docx	2026-06-03 04:53:26.42912+00
340959b4-53c8-4c3e-b76b-316d529c89f0	ccd9fb7c-323e-4d24-8aba-f454129354be	363f0c67-afab-4732-a78a-e4b843d397f4	190125020000860	pass	0.500	[{"cal_c": -42.8, "dev_c": 0.5, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.9, "dev_c": 0.2, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.8, "dev_c": 0.2, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001941	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001941_190125020000860.docx	2026-06-03 04:53:26.42912+00
551323b9-d2ee-4517-8b7c-24466c68f3e7	ccd9fb7c-323e-4d24-8aba-f454129354be	59fa2228-1b85-40d3-8b6a-7066357443ec	190125020000861	pass	0.300	[{"cal_c": -42.4, "dev_c": 0.1, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.8, "dev_c": 0.1, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.9, "dev_c": 0.3, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001942	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001942_190125020000861.docx	2026-06-03 04:53:26.42912+00
ff024bc9-065b-487b-acb9-9c7003cbe6c6	ccd9fb7c-323e-4d24-8aba-f454129354be	4108fa82-d409-4efa-8452-2e891d4204cd	190125020000862	pass	0.500	[{"cal_c": -42.8, "dev_c": 0.5, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.9, "dev_c": 0.2, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.6, "dev_c": 0.0, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001943	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001943_190125020000862.docx	2026-06-03 04:53:26.42912+00
630d7ba9-2310-48aa-a5cb-cb03aef4196f	ccd9fb7c-323e-4d24-8aba-f454129354be	5610e7b2-e4e1-47df-970f-a64d083d8781	190125020000863	pass	0.400	[{"cal_c": -42.5, "dev_c": 0.2, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 8.1, "dev_c": 0.4, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.7, "dev_c": 0.1, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001944	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001944_190125020000863.docx	2026-06-03 04:53:26.42912+00
95c23f7f-68de-4fc7-b145-f201a095f6e6	ccd9fb7c-323e-4d24-8aba-f454129354be	517ab4d0-ca49-417a-b3dc-93f550e5673c	190125020000864	pass	0.400	[{"cal_c": -42.7, "dev_c": 0.4, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 8.1, "dev_c": 0.4, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.7, "dev_c": 0.1, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001945	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001945_190125020000864.docx	2026-06-03 04:53:26.42912+00
f4441d68-6118-4aea-970f-d0417f6b363f	ccd9fb7c-323e-4d24-8aba-f454129354be	b74c211d-3e75-4bed-ae95-3049444e2b9b	190125020000865	pass	0.500	[{"cal_c": -41.8, "dev_c": 0.5, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.8, "dev_c": 0.1, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.5, "dev_c": 0.1, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001946	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001946_190125020000865.docx	2026-06-03 04:53:26.42912+00
72d5e0eb-cb4b-41aa-8847-bc3ec8fb82f7	ccd9fb7c-323e-4d24-8aba-f454129354be	a2df681d-70bc-46a6-9025-60e27ebe3119	190125020000866	pass	0.400	[{"cal_c": -42.6, "dev_c": 0.3, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.7, "dev_c": 0.0, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 45.0, "dev_c": 0.4, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001947	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001947_190125020000866.docx	2026-06-03 04:53:26.42912+00
15ba952f-373a-49b8-9591-d40f7d35acb0	ccd9fb7c-323e-4d24-8aba-f454129354be	41da07ff-d697-441d-b6ef-9a2b6d499335	190125020000867	pass	0.400	[{"cal_c": -43.1, "dev_c": 0.4, "ref_c": -42.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 8.0, "dev_c": 0.3, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.7, "dev_c": 0.1, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001948	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001948_190125020000867.docx	2026-06-03 04:53:26.42912+00
e9283604-d067-405a-9b0b-edbbf091fb84	ccd9fb7c-323e-4d24-8aba-f454129354be	727d574b-72ff-4edd-baa9-d428627442a4	190125020000868	pass	0.300	[{"cal_c": -42.9, "dev_c": 0.2, "ref_c": -42.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.4, "dev_c": 0.3, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.6, "dev_c": 0.0, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001949	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001949_190125020000868.docx	2026-06-03 04:53:26.42912+00
2d802611-b46e-4ec1-921a-a80887b8f374	ccd9fb7c-323e-4d24-8aba-f454129354be	3f11c33f-b686-42b5-8474-c0b45a8341d5	190125020000869	pass	0.500	[{"cal_c": -42.6, "dev_c": 0.3, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.8, "dev_c": 0.2, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001950	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001950_190125020000869.docx	2026-06-03 04:53:26.42912+00
5ac7df9d-6d23-4fff-9328-2a4750a27145	ccd9fb7c-323e-4d24-8aba-f454129354be	f579dffe-f74f-462c-9fa1-9fec794ebe2f	190125020000870	pass	0.400	[{"cal_c": -42.2, "dev_c": 0.1, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.3, "dev_c": 0.4, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.6, "dev_c": 0.0, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001951	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001951_190125020000870.docx	2026-06-03 04:53:26.42912+00
34954674-bd4b-41cf-add1-f5cf0f93f7e7	ccd9fb7c-323e-4d24-8aba-f454129354be	59bf6229-3b85-4e45-a5aa-ced5b03bdb5f	190125020000871	pass	0.500	[{"cal_c": -43.2, "dev_c": 0.5, "ref_c": -42.7, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.5, "dev_c": 0.1, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001952	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001952_190125020000871.docx	2026-06-03 04:53:26.42912+00
6cd57a04-1401-48e7-9f9b-4b8c722dd193	ccd9fb7c-323e-4d24-8aba-f454129354be	1a677a84-a4a2-44cc-b6e2-4435a5073602	190125020000872	pass	0.400	[{"cal_c": -42.7, "dev_c": 0.4, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.4, "dev_c": 0.3, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.4, "dev_c": 0.2, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001953	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001953_190125020000872.docx	2026-06-03 04:53:26.42912+00
d1a9bed8-6938-456e-86c5-d0b209b7cc2e	ccd9fb7c-323e-4d24-8aba-f454129354be	923e7a33-0309-4420-baf8-96cd0e4a373c	190125020000873	pass	0.500	[{"cal_c": -42.8, "dev_c": 0.5, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.9, "dev_c": 0.3, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001954	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001954_190125020000873.docx	2026-06-03 04:53:26.42912+00
1822da1d-ff4f-4fff-bf6a-c53627eadb61	ccd9fb7c-323e-4d24-8aba-f454129354be	fded9a0e-1a76-4f7e-8201-12eebf2cecaf	190125020000874	pass	0.500	[{"cal_c": -42.6, "dev_c": 0.3, "ref_c": -42.3, "target_c": -40.0, "within_tol": true}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 44.9, "dev_c": 0.3, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001955	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001955_190125020000874.docx	2026-06-03 04:53:26.42912+00
7102be00-8496-4bc4-b065-215dcfaa9ebb	ccd9fb7c-323e-4d24-8aba-f454129354be	11786266-42a8-4490-8acb-114f4c503cc0	190125020000875	fail	3.400	[{"cal_c": -43.4, "dev_c": 3.4, "ref_c": -40.0, "target_c": -40.0, "within_tol": false}, {"cal_c": 7.2, "dev_c": 0.5, "ref_c": 7.7, "target_c": 5.0, "within_tol": true}, {"cal_c": 45.0, "dev_c": 0.4, "ref_c": 44.6, "target_c": 40.0, "within_tol": true}]	0000001956	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/certificates/Calibration_Certificate_0000001956_190125020000875.docx	2026-06-03 04:53:26.42912+00
\.


--
-- Data for Name: loggers; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.loggers (id, serial_no, model, notes, next_due_at, created_at) FROM stdin;
747a736c-3c9d-4d71-bfd7-60cadfb838a4	190124110002417	\N	\N	\N	2026-03-06 09:00:00+00
c80024b6-4852-4f85-bfa2-35a6d08525ae	190124110002418	\N	\N	\N	2026-03-06 09:00:00+00
c911088c-b071-475d-9490-d973fe9ef57b	190124110002419	\N	\N	\N	2026-03-06 09:00:00+00
b5bf088c-e892-4bb4-b0ce-38e1e54594b0	190124110002420	\N	\N	\N	2026-03-06 09:00:00+00
92341219-af09-4196-879b-6656bd7a5c84	190124110002421	\N	\N	\N	2026-03-06 09:00:00+00
2c4987ee-fb4f-4d4e-aa09-8dd4fb691a50	190124110002422	\N	\N	\N	2026-03-06 09:00:00+00
85ba8d65-0f11-4084-b2cd-8e799318ff11	190124110002423	\N	\N	\N	2026-03-06 09:00:00+00
823f313d-5d51-406d-ab9b-20ac449c112c	190124110002424	\N	\N	\N	2026-03-06 09:00:00+00
23d67ae1-d23b-417d-b169-0093942b049d	190124110002425	\N	\N	\N	2026-03-06 09:00:00+00
624a4631-a3fb-4570-b775-0be534821af8	190124110002426	\N	\N	\N	2026-03-06 09:00:00+00
350d4757-ab50-4e71-ad48-794bf63f459e	190124110002427	\N	\N	\N	2026-03-06 09:00:00+00
a9782450-169b-4d77-9e34-52067515495f	190124110002428	\N	\N	\N	2026-03-06 09:00:00+00
255d0747-32c1-4be9-9627-f0b93a90250d	190124110002429	\N	\N	\N	2026-03-06 09:00:00+00
5498e2d2-d727-4b16-8eae-d206c9893c9a	190124110002430	\N	\N	\N	2026-03-06 09:00:00+00
87ed32ef-028c-4b76-86eb-dc7d17b64546	190124110002431	\N	\N	\N	2026-03-06 09:00:00+00
c55c3c9a-395c-4dfa-8b7f-5f3f1e5a13cf	190124110002432	\N	\N	\N	2026-03-06 09:00:00+00
7a857904-2c1b-422a-a861-344be8f6da11	190124110002433	\N	\N	\N	2026-03-06 09:00:00+00
8457e305-fdd4-422d-a291-0bc16b8d7bdf	190124110002434	\N	\N	\N	2026-03-06 09:00:00+00
b45935ce-14d5-4bfa-b691-3b387fe1a94e	190124110002435	\N	\N	\N	2026-03-06 09:00:00+00
5ff8f9e7-114d-485d-852d-3a7338f46926	190124110002436	\N	\N	\N	2026-03-06 09:00:00+00
4bce4bb3-50a0-4acc-a976-8621b4596cd1	190125070005381	\N	\N	\N	2025-10-01 09:00:00+00
0b84c402-43c4-42c5-9b07-c3d86a1377de	190125070005382	\N	\N	\N	2025-10-01 09:00:00+00
3e3c98f3-f460-4026-8f9b-62564af261a4	190125070005383	\N	\N	\N	2025-10-01 09:00:00+00
ef3ffd7a-34e0-4e70-a807-d1e0f12d1fa3	190125070005384	\N	\N	\N	2025-10-01 09:00:00+00
77977915-6e66-476d-9701-ba221ca0e3b1	190125070005385	\N	\N	\N	2025-10-01 09:00:00+00
d3ceebca-fe92-4d19-9ae5-0bb967b9dfe1	190125070005386	\N	\N	\N	2025-10-01 09:00:00+00
4b755862-093a-48d7-8ff8-ca19ad77c3bf	190125070005387	\N	\N	\N	2025-10-01 09:00:00+00
40e1f202-15a4-4014-a73c-b8aeda813ec1	190125070005388	\N	\N	\N	2025-10-01 09:00:00+00
1a4f721a-8dbc-492a-be5d-fad5cb2e1174	190125070005389	\N	\N	\N	2025-10-01 09:00:00+00
3bb0b215-6d5a-448e-b291-bbc869a01791	190125070005390	\N	\N	\N	2025-10-01 09:00:00+00
d529337a-e0c1-4e88-8353-99a2c306417c	190125070005391	\N	\N	\N	2025-10-01 09:00:00+00
9a1cea4c-09ea-4a6d-8fea-c134c2cd686e	190125070005392	\N	\N	\N	2025-10-01 09:00:00+00
e23c726b-4fc1-4269-aea0-8a5f19b1a705	190125070005393	\N	\N	\N	2025-10-01 09:00:00+00
07b378d4-4b47-4156-8fd6-594c5d848991	190125070005394	\N	\N	\N	2025-10-01 09:00:00+00
d8c41519-a773-474c-ba8f-7ba474a84922	190125070005395	\N	\N	\N	2025-10-01 09:00:00+00
1bfba840-5bee-4462-87c5-7288a40d4784	190125070005396	\N	\N	\N	2025-10-01 09:00:00+00
9371f303-f41d-466f-ad79-457d2e8a1eb1	190125070005397	\N	\N	\N	2025-10-01 09:00:00+00
f889e97e-7c3c-471f-9a6b-2ae9f1294232	190125070005398	\N	\N	\N	2025-10-01 09:00:00+00
6ea06b84-2d7d-4ffd-83fc-5aa0e397e5a1	190125070005399	\N	\N	\N	2025-10-01 09:00:00+00
a3bbf459-793b-4c76-a70b-ce1e432209c1	190125070005400	\N	\N	\N	2025-10-01 09:00:00+00
7b228bc7-8ade-45cd-b178-d5880b72397e	190125070005401	\N	\N	\N	2025-10-01 09:00:00+00
66d95a30-65ff-44f1-8a2a-07305d8f75b8	190125070005402	\N	\N	\N	2025-10-01 09:00:00+00
f546b7e2-a81f-431b-9bdf-c0b744f193f4	190125070005403	\N	\N	\N	2025-10-01 09:00:00+00
e81ec33c-cd03-4008-8de7-c1e1b23ee265	190125070005404	\N	\N	\N	2025-10-01 09:00:00+00
5a74f773-9d85-4e0f-8862-30b7fc70ea64	190125070005405	\N	\N	\N	2025-10-01 09:00:00+00
a497e375-ac17-44d2-ae04-76d339dcea1b	190125070005406	\N	\N	\N	2025-10-01 09:00:00+00
f7b8fb6e-3e80-4556-882f-6c92a737cc4a	190125070005407	\N	\N	\N	2025-10-01 09:00:00+00
484b1045-e4b9-414b-ba32-7309be6bf17b	190125070005408	\N	\N	\N	2025-10-01 09:00:00+00
deb69da2-0359-41fe-b56a-fb7420cf647e	190125070005409	\N	\N	\N	2025-10-01 09:00:00+00
34b26dcf-2b97-45a9-b042-5822b734ca0b	190125070005410	\N	\N	\N	2025-10-01 09:00:00+00
eea8e56d-5d7c-44e0-a4a2-f6f319c59235	190125070005411	\N	\N	\N	2025-10-01 09:00:00+00
419e81e1-b4ee-4181-8e8a-433a89461c12	190125070005412	\N	\N	\N	2025-10-01 09:00:00+00
29d00382-3637-4600-ae68-3a58799a1913	190125070005413	\N	\N	\N	2025-10-01 09:00:00+00
d61004d0-0246-42c1-b7dd-3bdf2ac5b8a2	190125070005414	\N	\N	\N	2025-10-01 09:00:00+00
7bc3f543-3996-4857-b17e-47a7fa301805	190125070005415	\N	\N	\N	2025-10-01 09:00:00+00
8d3d3ffb-8cd3-45b8-98fc-8ed8ea9ddd71	190125070005416	\N	\N	\N	2025-10-01 09:00:00+00
c2593d84-40bc-458a-960b-4e3a9471270c	190125070005417	\N	\N	\N	2025-10-01 09:00:00+00
82069425-5717-49d1-862b-7b91e0a8c9db	190125070005418	\N	\N	\N	2025-10-01 09:00:00+00
725dda3a-b6d1-484f-8064-a323587b54fc	190125070005419	\N	\N	\N	2025-10-01 09:00:00+00
63863ea3-8766-43f2-a139-53aa2c0e2fba	190125070005420	\N	\N	\N	2025-10-01 09:00:00+00
ae7c8c9b-c4c3-43cd-98df-da24af4c8cac	190125070005421	\N	\N	\N	2025-10-01 09:00:00+00
964f92b4-b051-49b9-b065-399e4d4f9af0	190125070005422	\N	\N	\N	2025-10-01 09:00:00+00
1b8bf689-f566-46bd-93b9-9273eff4c8fa	190125070005423	\N	\N	\N	2025-10-01 09:00:00+00
52abc167-0499-42fa-9db3-4832f1a4cb6d	190125070005424	\N	\N	\N	2025-10-01 09:00:00+00
763f3183-4a31-41c3-9696-dac2bb7cae12	190125070005425	\N	\N	\N	2025-10-01 09:00:00+00
386a6dfd-76f6-4979-b564-1c4a53ba9bd0	190125070005426	\N	\N	\N	2025-10-01 09:00:00+00
cf2959c8-9855-4199-94cb-302997c65fa1	190125070005427	\N	\N	\N	2025-10-01 09:00:00+00
198b6f60-4015-4fa0-9825-b2b8dc63cdfd	190125070005428	\N	\N	\N	2025-10-01 09:00:00+00
aac83204-b562-4948-b642-53ddab6fef5a	190125070005429	\N	\N	\N	2025-10-01 09:00:00+00
8bde73ca-101e-4a0b-bd4d-e270bb34c8a9	190125070005430	\N	\N	\N	2025-10-01 09:00:00+00
c3624f01-8aae-4da0-890d-37e30a47cf0c	190125070005431	\N	\N	\N	2025-10-01 09:00:00+00
cf6edef9-5f43-4a2f-b2cb-82d0bbcf5cf9	190125070005432	\N	\N	\N	2025-10-01 09:00:00+00
2563fa77-3d84-4cc9-ab9f-076148be5215	190125070005433	\N	\N	\N	2025-10-01 09:00:00+00
e1338493-bfc2-4fb7-acbc-850d7a22ab58	190125070005434	\N	\N	\N	2025-10-01 09:00:00+00
b2fc2f4a-3646-4de5-b1a1-a7230ac8c46d	190125070005435	\N	\N	\N	2025-10-01 09:00:00+00
05047249-0cd2-47c5-888b-5588bbb90aee	190125070005436	\N	\N	\N	2025-10-01 09:00:00+00
56d63e76-8e7c-4598-850c-156b28b27863	190125070005437	\N	\N	\N	2025-10-01 09:00:00+00
25d96e2b-55c7-4ce6-97c8-ea0f062b16d5	190125070005438	\N	\N	\N	2025-10-01 09:00:00+00
81b779d7-f084-461a-b3ef-8ebc5a1e376f	190125070005439	\N	\N	\N	2025-10-01 09:00:00+00
4b3ee8fb-c12c-427c-831b-1362ab03bba1	190125070005440	\N	\N	\N	2025-10-01 09:00:00+00
48fc9605-0a42-4f00-a62a-79d053a2f125	190125070005441	\N	\N	\N	2025-10-01 09:00:00+00
566d56fb-674a-4197-bb72-778954ae8677	190125070005442	\N	\N	\N	2025-10-01 09:00:00+00
7662010c-f253-4fa0-b3d0-70e6b0ee5c26	190125070005443	\N	\N	\N	2025-10-01 09:00:00+00
87d7f55b-8f90-4f02-bf41-72c3ae30f40e	190125070005444	\N	\N	\N	2025-10-01 09:00:00+00
b166448a-ddab-4df2-854a-078e6ddb6413	190125070005445	\N	\N	\N	2025-10-01 09:00:00+00
2ee46f2f-c4d6-42a1-bd9f-2810792bc290	190125070005446	\N	\N	\N	2025-10-01 09:00:00+00
89ca082f-60b3-4096-86e3-c61797ba5489	190125070005447	\N	\N	\N	2025-10-01 09:00:00+00
f114f810-50a5-4387-b824-62e486165894	190125070005448	\N	\N	\N	2025-10-01 09:00:00+00
05cb8e85-b20e-488c-8548-a7365d3b558b	190125070005449	\N	\N	\N	2025-10-01 09:00:00+00
1bad12b4-ea1f-4184-918c-0c4f077ca881	190125070005450	\N	\N	\N	2025-10-01 09:00:00+00
582e0b46-659e-4642-bd7c-68f1b52aa7b3	190125070005451	\N	\N	\N	2025-10-01 09:00:00+00
fb7c0ce3-be63-4829-927a-c6472002d115	190125070005452	\N	\N	\N	2025-10-01 09:00:00+00
77aa9804-9890-4cf0-9c45-a50940534ad3	190125070005453	\N	\N	\N	2025-10-01 09:00:00+00
7218b954-49b2-4a63-ac14-13cd8623e509	190125070005454	\N	\N	\N	2025-10-01 09:00:00+00
2bb6ee56-9d8a-4b0e-b04e-818a7cc7c05b	190125070005455	\N	\N	\N	2025-10-01 09:00:00+00
4490308b-576e-443c-8617-3fe4dbfd4ad8	190125070005456	\N	\N	\N	2025-10-01 09:00:00+00
cd3b831d-0a12-45a5-984b-7842bf3e2eb0	190125070005457	\N	\N	\N	2025-10-01 09:00:00+00
b32cc967-91b6-4b30-95d7-c3b8fd819a2b	190125070005458	\N	\N	\N	2025-10-01 09:00:00+00
c5d745f2-56e4-4bac-acd5-eefa9db99f8a	190125070005459	\N	\N	\N	2025-10-01 09:00:00+00
5dccd4bb-3d9b-4da6-962c-cd872ca7dd59	190125070005460	\N	\N	\N	2025-10-01 09:00:00+00
661a0786-70b1-4ef7-ad6b-589a7575aae0	190125070005461	\N	\N	\N	2025-10-01 09:00:00+00
a6f974c2-1e1e-4873-b452-6cf6613b9d39	190125070005462	\N	\N	\N	2025-10-01 09:00:00+00
bb021623-c7a0-4211-bd76-afa438f587c1	190125070005463	\N	\N	\N	2025-10-01 09:00:00+00
b8ad7997-9631-4c6d-a0e9-f27df0df2610	190125070005464	\N	\N	\N	2025-10-01 09:00:00+00
d9cb8165-207e-4666-97f3-9e8bbfb43222	190125070005465	\N	\N	\N	2025-10-01 09:00:00+00
c65f9ed5-e333-4862-9ec9-7213b2db7a56	190125070005466	\N	\N	\N	2025-10-01 09:00:00+00
f115a438-16ff-4391-baa6-5f2d07d74e4c	190125070005467	\N	\N	\N	2025-10-01 09:00:00+00
70438b52-bd54-4494-8866-f78ab66aaa8e	190125070005468	\N	\N	\N	2025-10-01 09:00:00+00
0c82c0a8-f9ef-4a2b-a2aa-e64dcdfd456b	190125070005469	\N	\N	\N	2025-10-01 09:00:00+00
cdc5670e-d834-427f-b8bc-5dd77aac1d86	190125070005470	\N	\N	\N	2025-10-01 09:00:00+00
21a4ea28-a3c2-4c0f-b2c7-cdafc2271286	190125070005471	\N	\N	\N	2025-10-01 09:00:00+00
abca22d4-a8f3-4f51-8be1-5cf6b459e6de	190125070005472	\N	\N	\N	2025-10-01 09:00:00+00
e86c2233-989e-4998-a9cd-51edc458b115	190125070005473	\N	\N	\N	2025-10-01 09:00:00+00
b565b854-28fc-42ac-a2de-72a63a48a08b	190125070005474	\N	\N	\N	2025-10-01 09:00:00+00
6c20bf41-b7dc-4a61-b026-fbbd9a62f3f2	190125070005475	\N	\N	\N	2025-10-01 09:00:00+00
ff5bb2ea-0671-4cb4-afd3-cc8a730fd4dd	190125070005476	\N	\N	\N	2025-10-01 09:00:00+00
412d0e57-009a-4b65-9863-8e09143a5917	190125070005477	\N	\N	\N	2025-10-01 09:00:00+00
28209f08-72a9-4917-8fa0-28ac7bad0a02	190125070005478	\N	\N	\N	2025-10-01 09:00:00+00
0c9e23cc-fe2e-4ec1-b099-d129c34cec7b	190125070005479	\N	\N	\N	2025-10-01 09:00:00+00
c35b3ea3-d093-479e-9d8e-7bceac400013	190125070005480	\N	\N	\N	2025-10-01 09:00:00+00
23aa1d69-9f59-4d93-8fae-0a1e2960dc82	190125070005481	\N	\N	\N	2025-10-01 09:00:00+00
cfd49371-50bb-4e7b-9a9d-67240ee95ac3	190125070005482	\N	\N	\N	2025-10-01 09:00:00+00
62d5c317-284d-4188-b332-a612c3724d0d	190125070005483	\N	\N	\N	2025-10-01 09:00:00+00
b76a78bc-d7e8-4cef-9d9a-47a15221f522	190125070005484	\N	\N	\N	2025-10-01 09:00:00+00
e3b5b3c3-61ca-42d7-ba21-8cfbacdc9a6c	190125070005485	\N	\N	\N	2025-10-01 09:00:00+00
2ee9ba28-cf48-4447-8829-892df2aae4c7	190125070005486	\N	\N	\N	2025-10-01 09:00:00+00
f95c1148-d55e-4307-b1a3-2656e3fbec98	190125070005487	\N	\N	\N	2025-10-01 09:00:00+00
0cf9b360-372b-40c2-85dc-31edffb43551	190125070005488	\N	\N	\N	2025-10-01 09:00:00+00
cee84803-f01d-49fb-913d-769ebfc93a70	190125070005489	\N	\N	\N	2025-10-01 09:00:00+00
72aa1e02-25f9-4536-ac81-e5c69bfb97b6	190125070005490	\N	\N	\N	2025-10-01 09:00:00+00
81805888-614c-411c-85c6-c9fb69c31364	190125070005491	\N	\N	\N	2025-10-01 09:00:00+00
eee4c9c9-f59f-4f56-ab11-74aee354b020	190125070005492	\N	\N	\N	2025-10-01 09:00:00+00
da36ef6b-cbdc-4c2c-aedb-b9b2f428d930	190125070005493	\N	\N	\N	2025-10-01 09:00:00+00
5a0aec2e-3742-458a-b325-0bdad377711d	190125070005494	\N	\N	\N	2025-10-01 09:00:00+00
11c83bcc-951b-45cb-96e3-b1d55d2b1f0a	190125070005495	\N	\N	\N	2025-10-01 09:00:00+00
6e7ee035-4027-49c9-8bbf-4035e23b91d4	190125070005496	\N	\N	\N	2025-10-01 09:00:00+00
b50e46b3-dee2-4ec1-9a9d-a9c60beb89b2	190125070005497	\N	\N	\N	2025-10-01 09:00:00+00
f3490e0f-70df-45e6-bad8-9125518e9eba	190125070005498	\N	\N	\N	2025-10-01 09:00:00+00
5f5ac71b-93aa-4447-816a-483b54088169	190125070005499	\N	\N	\N	2025-10-01 09:00:00+00
3d0bf9c3-4c5e-4f57-95d5-d95f3bdb0a64	190125070005500	\N	\N	\N	2025-10-01 09:00:00+00
40ab3171-7f5f-4a27-b4af-0ef24b4c09f1	190125070005501	\N	\N	\N	2025-10-01 09:00:00+00
f7594b46-0ee7-461d-8b19-a20d140c7cf4	190125070005502	\N	\N	\N	2025-10-01 09:00:00+00
f9881a34-cd86-4707-aca8-3a4eb8bc63e5	190125070005503	\N	\N	\N	2025-10-01 09:00:00+00
cc0664f1-bbc7-4b69-b124-d92f527825df	190125070005504	\N	\N	\N	2025-10-01 09:00:00+00
0080c1a6-80e3-49b3-ab4e-9d35f6b978ff	190125070005505	\N	\N	\N	2025-10-01 09:00:00+00
37e0888b-0bd0-4a59-bd41-18617fabbeb9	190125070005506	\N	\N	\N	2025-10-01 09:00:00+00
1a6c7813-d185-45f5-8824-68c26f1bf44e	190125070005507	\N	\N	\N	2025-10-01 09:00:00+00
32be710e-b91f-4a16-ba2f-6b0e01cd7233	190125070005508	\N	\N	\N	2025-10-01 09:00:00+00
c83ca333-ee34-4f66-99b7-480470fa196c	190125070005509	\N	\N	\N	2025-10-01 09:00:00+00
ed84a038-5fb5-468f-aab6-b4d58cf38866	190125070005510	\N	\N	\N	2025-10-01 09:00:00+00
c45b0d00-ae30-442e-ac9e-ccd9185ac5e2	190125070005511	\N	\N	\N	2025-10-01 09:00:00+00
3288eb92-27b7-4e3c-9d4d-c659c2ca9f3f	190125070005512	\N	\N	\N	2025-10-01 09:00:00+00
894eb2e3-5be6-4a91-8246-7723430d9031	190125070005513	\N	\N	\N	2025-10-01 09:00:00+00
5047002a-5791-4081-8c76-3c84bc4266c8	190125070005514	\N	\N	\N	2025-10-01 09:00:00+00
91572410-1623-49ce-85fe-92fb71d71542	190125070005515	\N	\N	\N	2025-10-01 09:00:00+00
99ca5d1f-6666-4c1d-b88c-7125eff517f5	190125070005516	\N	\N	\N	2025-10-01 09:00:00+00
ab9e9157-7731-4345-ad7d-69ae98eb51bf	190125070005517	\N	\N	\N	2025-10-01 09:00:00+00
f7470370-61cf-4543-958c-fffd35368f30	190125070005518	\N	\N	\N	2025-10-01 09:00:00+00
caa1e1ca-3740-469b-95ea-46a05fccc4e7	190125070005519	\N	\N	\N	2025-10-01 09:00:00+00
a18aaf37-11c1-42d4-8e05-7528ba75002b	190125070005520	\N	\N	\N	2025-10-01 09:00:00+00
504206cd-80ea-4d2c-8630-41fbf11b6965	190125070005521	\N	\N	\N	2025-10-01 09:00:00+00
761c0a91-892d-4d12-971d-0ec684c90606	190125070005522	\N	\N	\N	2025-10-01 09:00:00+00
0f9883a9-b4d8-4809-82c6-b835d8f730f3	190125070005523	\N	\N	\N	2025-10-01 09:00:00+00
8ad97cf7-4a55-4735-90a8-cec260225ca0	190125070005524	\N	\N	\N	2025-10-01 09:00:00+00
bd6dcced-6398-4a9a-abde-f21492dc8388	190125070005525	\N	\N	\N	2025-10-01 09:00:00+00
46770c6f-639a-491d-a2bc-acdd8a4b1e60	190125070005526	\N	\N	\N	2025-10-01 09:00:00+00
5a4eceb9-a20b-40d6-85c3-e6f4f259c325	190125070005527	\N	\N	\N	2025-10-01 09:00:00+00
af92c448-c88d-41d5-8202-569c7c38a54f	190125070005528	\N	\N	\N	2025-10-01 09:00:00+00
badec15b-2537-4c1b-9577-4e681c5d0a56	190125070005529	\N	\N	\N	2025-10-01 09:00:00+00
7cd86db4-a4d4-49c7-a7ab-e972e170184d	190125070005530	\N	\N	\N	2025-10-01 09:00:00+00
d470db95-1108-40a0-b83f-150995a0ff3b	190125070005531	\N	\N	\N	2025-10-01 09:00:00+00
d74f9445-46e3-4fe8-8d61-f23b75f008ec	190125070005532	\N	\N	\N	2025-10-01 09:00:00+00
ad7d997b-8d07-4ffb-8e50-73f6e513ff71	190125070005533	\N	\N	\N	2025-10-01 09:00:00+00
916ff964-33f4-4a09-bc8c-90e45b199f74	190125070005534	\N	\N	\N	2025-10-01 09:00:00+00
af1f1845-74be-40dc-a93e-e205811a157b	190125070005535	\N	\N	\N	2025-10-01 09:00:00+00
342e8cdc-da70-4d7b-bc5a-a7180ad58704	190125070005536	\N	\N	\N	2025-10-01 09:00:00+00
9bd31ad5-b7af-4b30-a274-dc673a650991	190125070005537	\N	\N	\N	2025-10-01 09:00:00+00
452090d1-dcda-48b9-8bac-de745cc6bd15	190125070005538	\N	\N	\N	2025-10-01 09:00:00+00
048b232b-b9f3-42f4-980c-796a8f383d51	190125070005539	\N	\N	\N	2025-10-01 09:00:00+00
439a7c8b-3145-4929-b781-99d2727e5516	190125070005540	\N	\N	\N	2025-10-01 09:00:00+00
cac670a2-b791-4f01-b3cf-97a1f68ea3e1	190125070005541	\N	\N	\N	2025-10-01 09:00:00+00
269adc72-b025-4a9a-bec1-94b74cc6d859	190125070005542	\N	\N	\N	2025-10-01 09:00:00+00
6385e6e9-5315-49e2-a345-1b8eda7d9893	190125070005543	\N	\N	\N	2025-10-01 09:00:00+00
bd6a2cdc-966e-4a6a-8adf-b1a54882f501	190125070005544	\N	\N	\N	2025-10-01 09:00:00+00
a634a0d9-b909-450e-aec5-5ec40dda3f72	190125070005545	\N	\N	\N	2025-10-01 09:00:00+00
6caebb24-0efe-4626-ab98-f760809c97e7	190125070005546	\N	\N	\N	2025-10-01 09:00:00+00
e4943593-b1d0-44a7-b364-9ed7601c7892	190125070005547	\N	\N	\N	2025-10-01 09:00:00+00
44d776be-2d40-4379-8ff0-f42a82af41e7	190125070005548	\N	\N	\N	2025-10-01 09:00:00+00
38c738db-79ed-4810-8206-c73af3003ca4	190125070005549	\N	\N	\N	2025-10-01 09:00:00+00
bd67a58c-1fcc-47eb-8227-987dd33f1e4d	190125070005550	\N	\N	\N	2025-10-01 09:00:00+00
27385204-4d6f-4e6e-a841-5635cb88e680	190125070005551	\N	\N	\N	2025-10-01 09:00:00+00
9e4732ff-e556-4a9f-9b2f-0b7eb2eba432	190125070005552	\N	\N	\N	2025-10-01 09:00:00+00
ccb9db45-b875-469c-8cc0-0db9f90ebce5	190125070005553	\N	\N	\N	2025-10-01 09:00:00+00
f62d03ab-0490-46f7-ac60-672b6d30e33c	190125070005554	\N	\N	\N	2025-10-01 09:00:00+00
641bcb94-6b7a-4897-8011-e06e546d68dd	190125070005555	\N	\N	\N	2025-10-01 09:00:00+00
dc6a8052-9f35-4300-bc66-95a2bc9680e2	190125070005556	\N	\N	\N	2025-10-01 09:00:00+00
2f371c9b-2f60-43a7-971e-b77db8ea0217	190125070005557	\N	\N	\N	2025-10-01 09:00:00+00
55ad9464-863d-4f5e-93f2-f13c01b36730	190125070005558	\N	\N	\N	2025-10-01 09:00:00+00
912cc02f-4def-4a58-80fd-9203c9e1d942	190125070005559	\N	\N	\N	2025-10-01 09:00:00+00
61e6aa78-8b91-4ae9-b0cc-1687d0681b79	190125070005560	\N	\N	\N	2025-10-01 09:00:00+00
cc114f3a-dec6-44e0-995e-aa363721fd6f	190125070005561	\N	\N	\N	2025-10-01 09:00:00+00
2d08fee6-517a-4b06-8dc8-09c6e7455119	190125070005562	\N	\N	\N	2025-10-01 09:00:00+00
2f0c49f7-bc75-499f-8260-3d6d5ce4b5e4	190125070005563	\N	\N	\N	2025-10-01 09:00:00+00
f78a85a2-f755-4f7b-afc1-5bc2bab1517b	190125070005564	\N	\N	\N	2025-10-01 09:00:00+00
19990ba1-8cd4-46e3-9a21-93666a0a8cc9	190125070005565	\N	\N	\N	2025-10-01 09:00:00+00
7a2f55f8-6d99-43ac-8ec5-bd6d1f293bb3	190125070005566	\N	\N	\N	2025-10-01 09:00:00+00
86b10bff-d82b-4e41-a0da-1e3e258f3ce8	190125070005567	\N	\N	\N	2025-10-01 09:00:00+00
c0557358-65d3-4977-af55-8d73062e6150	190125070005568	\N	\N	\N	2025-10-01 09:00:00+00
e7b4be30-4bc5-42de-98c1-5dbb2ce66d34	190125070005569	\N	\N	\N	2025-10-01 09:00:00+00
8e58123a-9d37-48f7-831d-ccd5bfab036f	190125070005570	\N	\N	\N	2025-10-01 09:00:00+00
40933c40-9f8c-4061-b52b-7a14e22a1122	190125070005571	\N	\N	\N	2025-10-01 09:00:00+00
3005cf98-a6d8-4174-b569-665185a266eb	190125070005572	\N	\N	\N	2025-10-01 09:00:00+00
63895f81-cf42-478a-b36e-ef449f72afd2	190125070005573	\N	\N	\N	2025-10-01 09:00:00+00
85ff2173-b84b-4d67-bee7-c573465d1306	190125070005574	\N	\N	\N	2025-10-01 09:00:00+00
0a057cf6-9687-4161-bbf7-69efd36d1b43	190125070005575	\N	\N	\N	2025-10-01 09:00:00+00
80948324-6214-4260-94b9-293308feeda5	190125070005576	\N	\N	\N	2025-10-01 09:00:00+00
430223f7-0fe6-4f55-bf28-6e43306ad983	190125070005577	\N	\N	\N	2025-10-01 09:00:00+00
fac4e37d-35ff-48ea-b1a6-6e649a80abb2	190125070005578	\N	\N	\N	2025-10-01 09:00:00+00
9bbb9581-98c1-4c58-803c-e2a5b9e75ee9	190125070005579	\N	\N	\N	2025-10-01 09:00:00+00
e09a2e99-3c23-4e04-aa16-d6826f2ace8e	190125070005580	\N	\N	\N	2025-10-01 09:00:00+00
c32336b3-a3d4-4c2c-9472-381a7715aed2	190125070005581	\N	\N	\N	2025-10-01 09:00:00+00
729fd993-980f-4fbd-90ac-946383f87179	190125070005582	\N	\N	\N	2025-10-01 09:00:00+00
66c1f3dd-a132-45dc-b6bb-37fa3ed238b3	190125070005583	\N	\N	\N	2025-10-01 09:00:00+00
e556e556-4a4e-4e0c-b7f7-d5546e1ac70c	190125070005584	\N	\N	\N	2025-10-01 09:00:00+00
025dce75-a546-466a-b224-393462dbfcbb	190125070005585	\N	\N	\N	2025-10-01 09:00:00+00
58abe216-e862-44fe-8a13-681a0bbed6b4	190125070005586	\N	\N	\N	2025-10-01 09:00:00+00
e9d33938-c7ab-411b-b82e-4ee06fca86de	190125070005587	\N	\N	\N	2025-10-01 09:00:00+00
d2c2e2c6-a2a1-45f2-ab1b-211b63d20afe	190125070005588	\N	\N	\N	2025-10-01 09:00:00+00
d038a824-60c4-40d4-8dbc-9c1bba397225	190125070005589	\N	\N	\N	2025-10-01 09:00:00+00
c6ed70b1-8083-459b-89a9-20fd076c1275	190125070005590	\N	\N	\N	2025-10-01 09:00:00+00
dd441fdd-d552-4fe7-a16c-e82dc8a5321e	190125070005591	\N	\N	\N	2025-10-01 09:00:00+00
88f79f59-c8f1-44f2-82b5-c7d64eff0a73	190125070005592	\N	\N	\N	2025-10-01 09:00:00+00
e214fff6-7f59-4558-b1a8-32b6497034bd	190125070005593	\N	\N	\N	2025-10-01 09:00:00+00
e3c336a6-e666-4c21-8aa0-d485f487c988	190125070005594	\N	\N	\N	2025-10-01 09:00:00+00
1edd4786-4d04-4d48-befc-6bf23a4d06ea	190125070005595	\N	\N	\N	2025-10-01 09:00:00+00
77d6114a-5ad4-47a3-9140-a8235f0c8242	190125070005596	\N	\N	\N	2025-10-01 09:00:00+00
13369150-0ec8-40ce-8e38-3e29782134b8	190125070005597	\N	\N	\N	2025-10-01 09:00:00+00
4a438854-6655-4773-a4cd-0206d6b32718	190125070005598	\N	\N	\N	2025-10-01 09:00:00+00
977231eb-78ef-4abc-9874-1e63a94251e3	190125070005599	\N	\N	\N	2025-10-01 09:00:00+00
8f3b7c35-b94d-496a-a6aa-2037a29fb8a1	190125070005600	\N	\N	\N	2025-10-01 09:00:00+00
6085b8b0-80f8-47fa-9882-0238b11361c1	190125070005601	\N	\N	\N	2025-10-01 09:00:00+00
8b251e63-f5e9-4b59-91a9-385f5c905bee	190125070005602	\N	\N	\N	2025-10-01 09:00:00+00
47461580-19e9-43fd-8b11-48be7a4f009b	190125070005603	\N	\N	\N	2025-10-01 09:00:00+00
ac8057c9-8e4b-40a7-8b74-757cb8fc1771	190125070005604	\N	\N	\N	2025-10-01 09:00:00+00
ea2f0c04-9eb3-4a4a-be4e-5c200adaf1c8	190125070005605	\N	\N	\N	2025-10-01 09:00:00+00
8dc35a58-1e97-459c-95d2-200e8b7e11f3	190125070005606	\N	\N	\N	2025-10-01 09:00:00+00
e5a29b29-4937-4aec-852d-bd1cc36ed11d	190125070005607	\N	\N	\N	2025-10-01 09:00:00+00
620a10f6-8b80-4057-82e6-d343bdc04fc4	190125070005608	\N	\N	\N	2025-10-01 09:00:00+00
7040f3bc-9a1f-4606-8cb4-16c95f73afce	190125070005609	\N	\N	\N	2025-10-01 09:00:00+00
bfd212b6-2854-4f4d-9af8-12ac055c867e	190125070005610	\N	\N	\N	2025-10-01 09:00:00+00
b1a82efd-a66c-4819-b963-f3cecf0ecfc8	190125070005611	\N	\N	\N	2025-10-01 09:00:00+00
8935959f-b2ac-426a-8d61-73f4bc447b77	190125070005612	\N	\N	\N	2025-10-01 09:00:00+00
5931bfe5-8d41-4807-8d11-36c255273bc0	190125070005613	\N	\N	\N	2025-10-01 09:00:00+00
f0094a0b-f5c7-4bc3-bdb9-8e874dc65aa3	190125070005614	\N	\N	\N	2025-10-01 09:00:00+00
2da6f744-491c-4e32-9168-ef6d31a368b3	190125070005615	\N	\N	\N	2025-10-01 09:00:00+00
eb7b20af-05f1-421e-8d03-7be7b1997d4c	190125070005616	\N	\N	\N	2025-10-01 09:00:00+00
97d820e3-00b2-4d3f-8651-0a894075d097	190125070005617	\N	\N	\N	2025-10-01 09:00:00+00
c7ff7b29-cfa2-4c74-aabc-72dfbdfb62a5	190125070005618	\N	\N	\N	2025-10-01 09:00:00+00
7a7e2556-af52-4989-94b6-d304f0c1e4f8	190125070005619	\N	\N	\N	2025-10-01 09:00:00+00
1e81d3da-96aa-4e9b-913b-af8f0bb444ee	190125070005620	\N	\N	\N	2025-10-01 09:00:00+00
f13f93e9-dfe2-41e1-92dc-047140b57d0e	190125070005621	\N	\N	\N	2025-10-01 09:00:00+00
c98e8a93-5d7d-41ea-8de7-f6251a452c36	190125070005622	\N	\N	\N	2025-10-01 09:00:00+00
01837953-1a5a-4499-b4ae-0bc3905bcdc8	190125070005623	\N	\N	\N	2025-10-01 09:00:00+00
6ce9bf30-4235-4b9f-a504-cb6d6309df6d	190125070005624	\N	\N	\N	2025-10-01 09:00:00+00
9422b830-5b6a-456b-b5e7-fdf00bb0daf0	190125070005625	\N	\N	\N	2025-10-01 09:00:00+00
cb874b7c-87b8-42b7-a57d-e8f0abdef4d9	190125070005626	\N	\N	\N	2025-10-01 09:00:00+00
428f3f29-00f3-47db-98a3-a14e268b7bab	190125070005627	\N	\N	\N	2025-10-01 09:00:00+00
5fe6839d-975b-42a0-af50-4355f61592a5	190125070005628	\N	\N	\N	2025-10-01 09:00:00+00
ad6b5e09-0774-4739-a594-145e51ecc941	190125070005629	\N	\N	\N	2025-10-01 09:00:00+00
1f20a638-2e76-444c-8f8e-999df941ea10	190125070005630	\N	\N	\N	2025-10-01 09:00:00+00
ebba72cd-2c30-47c9-b74a-b41f94b6f06a	190125020000841	\N	\N	\N	2025-06-13 09:00:00+00
9919ce0b-d170-41e9-9f32-f4f8d16df49a	190125020000801	\N	\N	\N	2025-10-29 09:00:00+00
0c12473d-95dc-4f94-bbbe-ba34f84752dd	190125020000802	\N	\N	\N	2025-10-29 09:00:00+00
650a9cdf-acad-4214-8710-e49bf9718157	190125020000803	\N	\N	\N	2025-10-29 09:00:00+00
2009e8a6-4d8d-4d0e-a92e-7ac3c04543a4	190125020000804	\N	\N	\N	2025-10-29 09:00:00+00
c9fe5a18-1b96-4a1e-b349-6d7f904d7449	190125020000805	\N	\N	\N	2025-10-29 09:00:00+00
64b2b1bd-f08d-40fc-a44c-e1eba32f1963	190125020000806	\N	\N	\N	2025-10-29 09:00:00+00
08cfedc4-edb2-4530-8f88-e39a0d564fa9	190125020000808	\N	\N	\N	2025-10-29 09:00:00+00
470cb66c-1c69-42b8-b200-8fa73b6f9d95	190125020000809	\N	\N	\N	2025-10-29 09:00:00+00
6420d41e-0ea3-4f0f-a790-d20ba645f949	190125020000810	\N	\N	\N	2025-10-29 09:00:00+00
ed7c2f4f-b468-4a05-ad38-463a0122d59d	190125020000811	\N	\N	\N	2025-10-29 09:00:00+00
31001c8c-6bd0-4893-baf7-368c5393d9ea	190125020000812	\N	\N	\N	2025-10-29 09:00:00+00
c1233832-c5b0-4ed1-9e3e-60d9b41db091	190125020000813	\N	\N	\N	2025-10-29 09:00:00+00
1a17fe00-15c2-4967-9aac-337f83f7a209	190125020000814	\N	\N	\N	2025-10-29 09:00:00+00
10bc819f-7f05-4846-944d-2f3039150ac8	190125020000815	\N	\N	\N	2025-10-29 09:00:00+00
a16d3efb-ddd1-439d-b1ba-5b82d2fa52dc	190125020000816	\N	\N	\N	2025-10-29 09:00:00+00
3fc02715-2205-4ec0-9bd8-6c137037c444	190125020000817	\N	\N	\N	2025-10-29 09:00:00+00
d928fe34-f891-4135-88fa-8f99dc7a8b74	190125020000818	\N	\N	\N	2025-10-29 09:00:00+00
fdffcb9e-9b79-443d-8286-56e5a0e73c97	190125020000819	\N	\N	\N	2025-10-29 09:00:00+00
f6cb1b88-632f-4cf8-a059-458730998c3b	190125020000820	\N	\N	\N	2025-10-29 09:00:00+00
35d0073e-bf8d-42b1-be28-862d56685aa4	190125020000821	\N	\N	\N	2025-10-29 09:00:00+00
60f55162-f9d8-4b75-842d-6c7bb433d9c5	190125020000822	\N	\N	\N	2025-10-29 09:00:00+00
3f0f5ae8-63c4-4b17-afb5-535907f6567c	190125020000823	\N	\N	\N	2025-10-29 09:00:00+00
70b2dc95-4d46-448e-ae08-42cda2d2a043	190125020000824	\N	\N	\N	2025-10-29 09:00:00+00
959a4037-b329-48e5-884b-92313da07081	190125020000825	\N	\N	\N	2025-10-29 09:00:00+00
fecf5d69-8daf-4a08-beb0-a860b9228e3e	190125020000826	\N	\N	\N	2025-10-29 09:00:00+00
47f2bc7d-60f1-4a17-9d6f-99c25ce43338	190125020000827	\N	\N	\N	2025-10-29 09:00:00+00
c3b293e3-4b77-4771-b67c-4e6ca862d41b	190125020000828	\N	\N	\N	2025-10-29 09:00:00+00
1b95892e-ec4f-458a-b4cc-953fd36af60b	190125020000829	\N	\N	\N	2025-10-29 09:00:00+00
7ef2df0f-fec8-41f5-b72e-ad2c82fb90b3	190125020000830	\N	\N	\N	2025-10-29 09:00:00+00
1b3051af-8a2f-4c6d-8ae5-08e9dd1a6920	190125020000831	\N	\N	\N	2025-10-29 09:00:00+00
024fcb06-f4b5-4e76-9e4f-c7b9e29874c9	190125020000832	\N	\N	\N	2025-10-29 09:00:00+00
0fbe7ceb-d4c5-45a3-b0bd-32bf66f357e3	190125020000833	\N	\N	\N	2025-10-29 09:00:00+00
3a17a0f3-49fe-4275-93fe-ccf8bf96bfcf	190125020000834	\N	\N	\N	2025-10-29 09:00:00+00
38886df2-1cfd-407b-afc0-f6c6132cfce9	190125020000835	\N	\N	\N	2025-10-29 09:00:00+00
64ce7c41-f333-4733-9a7f-20c970aec2f8	190125020000836	\N	\N	\N	2025-10-29 09:00:00+00
caf3171a-4312-4e42-9e86-301c3cdf54a2	190125020000837	\N	\N	\N	2025-10-29 09:00:00+00
407bd050-9938-4f8e-b835-95aeeee39301	190125020000838	\N	\N	\N	2025-10-29 09:00:00+00
bb6d767e-c77b-4dfb-8a9d-ae533e081a0f	190125020000839	\N	\N	\N	2025-10-29 09:00:00+00
5d6fb015-8d25-4e2a-8b91-fe7316e7054a	190125020000840	\N	\N	\N	2025-10-29 09:00:00+00
7b9f0dcf-607e-4ddb-9b92-01d9a2f86c1c	190125020000842	\N	\N	\N	2025-10-29 09:00:00+00
a0b5b5e3-e6e6-4ff9-8af9-cc03b60300a8	190125020000843	\N	\N	\N	2025-10-29 09:00:00+00
27b30da8-319a-4c6d-9aea-431cf63847c2	190125020000844	\N	\N	\N	2025-10-29 09:00:00+00
575970c9-9c1f-4410-b4f6-84c8ec84039a	190125020000845	\N	\N	\N	2025-10-29 09:00:00+00
20d0b9de-041e-488d-ad16-5f03e2e91047	190125020000846	\N	\N	\N	2025-10-29 09:00:00+00
e9307223-1dc7-4c06-9273-b7edc6a201f7	190125020000847	\N	\N	\N	2025-10-29 09:00:00+00
24f11c69-ddaa-4c2c-992b-c7931b7fc8d1	190125020000848	\N	\N	\N	2025-10-29 09:00:00+00
64f16e13-52ee-4965-9190-0f568291ee3c	190125020000849	\N	\N	\N	2025-10-29 09:00:00+00
0a36e20b-7653-4cb8-9452-457b4eaaf763	190125020000850	\N	\N	\N	2025-10-29 09:00:00+00
6232c94b-9c8e-40e4-bf05-82338967930d	190125020000876	\N	\N	\N	2025-10-29 09:00:00+00
aae4f928-4821-4eac-802f-40e56aa40fd1	190125020000877	\N	\N	\N	2025-10-29 09:00:00+00
21799d2d-afe5-4f6f-a428-1d79c53ca565	190125020000878	\N	\N	\N	2025-10-29 09:00:00+00
ecf6c24c-947c-4c82-9340-a6ec61db9218	190125020000879	\N	\N	\N	2025-10-29 09:00:00+00
7d4ac2ac-28f4-4617-aa4b-feba591599a5	190125020000880	\N	\N	\N	2025-10-29 09:00:00+00
92c472d0-8d10-4435-b89f-4c989f8391e4	190125020000881	\N	\N	\N	2025-10-29 09:00:00+00
5e3ecbbb-f21f-410e-9a2f-95e1914808e4	190125020000882	\N	\N	\N	2025-10-29 09:00:00+00
cdb61bd2-b793-4dcd-84f8-ad26aa92a878	190125020000883	\N	\N	\N	2025-10-29 09:00:00+00
7e964076-eb24-4f7e-be1e-ecb5ba3c798a	190125020000884	\N	\N	\N	2025-10-29 09:00:00+00
5ec805b7-df6f-4588-8242-f74c0dd518cf	190125020000885	\N	\N	\N	2025-10-29 09:00:00+00
f35a91e8-442d-4653-b816-f952e365deb8	190125020000886	\N	\N	\N	2025-10-29 09:00:00+00
c3b0be38-216b-4a09-9b96-3f24ed70a423	190125020000887	\N	\N	\N	2025-10-29 09:00:00+00
786bbe09-02a2-4431-b6a4-a169f0706187	190125020000888	\N	\N	\N	2025-10-29 09:00:00+00
39a07c5a-97de-4dd6-9530-ba83c4125d41	190125020000889	\N	\N	\N	2025-10-29 09:00:00+00
f5a1400a-a835-4a15-a6d6-8da465f39893	190125020000890	\N	\N	\N	2025-10-29 09:00:00+00
97480eb4-fb58-4e98-be9f-cf4168c9ba2d	190125020000891	\N	\N	\N	2025-10-29 09:00:00+00
e5680a3b-82c6-41d4-90b3-4a0a6313f545	190125020000892	\N	\N	\N	2025-10-29 09:00:00+00
15063dd8-fb8d-4582-a942-780518976a5d	190125020000893	\N	\N	\N	2025-10-29 09:00:00+00
cc1bfa3e-c16c-452f-a02f-2828ea0a1d5f	190125020000894	\N	\N	\N	2025-10-29 09:00:00+00
3f10a4b4-4433-471f-9742-b4357b579e06	190125020000895	\N	\N	\N	2025-10-29 09:00:00+00
baef1ae0-f052-4497-8700-997ce61361bf	190125020000896	\N	\N	\N	2025-10-29 09:00:00+00
02542a8d-c258-4e50-ac27-32d25a0705ee	190125020000897	\N	\N	\N	2025-10-29 09:00:00+00
b77e86b7-8d5c-4b66-9ffb-d9a4c674d697	190125020000898	\N	\N	\N	2025-10-29 09:00:00+00
4ae9a3a2-4345-4576-8f51-4d5771c7ea7d	190125020000899	\N	\N	\N	2025-10-29 09:00:00+00
371f751f-43e7-4de6-85e7-7ce2ecebb3b7	190125020000900	\N	\N	\N	2025-10-29 09:00:00+00
26942399-58a1-4fd8-92a7-d13ab52a5b21	190124110002201	\N	\N	\N	2025-11-14 09:00:00+00
b501583e-f15d-444a-ba15-e3109d9581b9	190124110002202	\N	\N	\N	2025-11-14 09:00:00+00
f793de97-1031-4d42-b6c7-cf8f60b690d2	190124110002203	\N	\N	\N	2025-11-14 09:00:00+00
144649f2-3cac-4cf3-99a4-2ace6eda098f	190124110002204	\N	\N	\N	2025-11-14 09:00:00+00
e16e8cf3-3034-4d14-83cc-5ed40ae2a8b8	190124110002205	\N	\N	\N	2025-11-14 09:00:00+00
12f3da06-fdaa-4bcd-b455-5761f32147bf	190124110002206	\N	\N	\N	2025-11-14 09:00:00+00
366a349b-40cb-46f7-a42e-3713b548b79b	190124110002207	\N	\N	\N	2025-11-14 09:00:00+00
92a03455-7af4-4295-8a3b-be301683c3eb	190124110002208	\N	\N	\N	2025-11-14 09:00:00+00
7f646fc3-d0c2-454a-af7c-327758f7e31d	190124110002209	\N	\N	\N	2025-11-14 09:00:00+00
0f6203c2-9978-4620-83d5-0623b84010f7	190124110002210	\N	\N	\N	2025-11-14 09:00:00+00
382facfa-ef09-4e4d-a71f-2c4597f3e745	190124110002211	\N	\N	\N	2025-11-14 09:00:00+00
fa1b5532-3452-4e53-95dd-8d2a6eca0f20	190124110002212	\N	\N	\N	2025-11-14 09:00:00+00
9c0e4159-38b5-44e6-99db-7e83f4df42de	190124110002213	\N	\N	\N	2025-11-14 09:00:00+00
81a1b50e-bc58-4ebc-941e-23d06b12e7a8	190124110002214	\N	\N	\N	2025-11-14 09:00:00+00
6ff2b26a-e6bf-4167-b5a8-6820ab7fd895	190124110002215	\N	\N	\N	2025-11-14 09:00:00+00
2c1495ca-5c79-4efc-b67e-266a82492b53	190124110002216	\N	\N	\N	2025-11-14 09:00:00+00
5e619b20-190f-459e-b4f1-cafbc818aee5	190124110002217	\N	\N	\N	2025-11-14 09:00:00+00
b44601fe-b324-4421-882c-789a5a13b56e	190124110002218	\N	\N	\N	2025-11-14 09:00:00+00
9c4036b9-d614-47d0-ba97-b7d64597f367	190124110002219	\N	\N	\N	2025-11-14 09:00:00+00
abf8a82c-f864-411a-9ef9-4ee3d01d2ba8	190124110002220	\N	\N	\N	2025-11-14 09:00:00+00
50662844-ecb5-4b74-9d1e-ebb47633783f	190124110002221	\N	\N	\N	2025-11-14 09:00:00+00
8ad7b05f-e719-4cb7-b6bd-0988de9fdef5	190124110002222	\N	\N	\N	2025-11-14 09:00:00+00
afccd246-0d24-4fed-b15e-d1666efcb6f4	190124110002223	\N	\N	\N	2025-11-14 09:00:00+00
1dce26b0-528f-4d8e-b57a-8809539b4e65	190124110002224	\N	\N	\N	2025-11-14 09:00:00+00
1d60894a-6252-41d5-9874-ee5719f5b746	190124110002225	\N	\N	\N	2025-11-14 09:00:00+00
47807a1f-bb59-403b-8049-b55321a88e97	190124110002226	\N	\N	\N	2025-11-14 09:00:00+00
dd18cd65-eab3-44ba-932e-cd3eafd23d36	190124110002227	\N	\N	\N	2025-11-14 09:00:00+00
70e34747-5d5a-42bc-964f-567c27fa25e4	190124110002228	\N	\N	\N	2025-11-14 09:00:00+00
181fb94a-07c7-49ae-98ca-25792ced0160	190124110002229	\N	\N	\N	2025-11-14 09:00:00+00
70eb9c71-cec0-4454-b63d-d4960cbfdfc5	190124110002230	\N	\N	\N	2025-11-14 09:00:00+00
71934d49-622b-463c-b4b6-b56fc441b51e	190124110002231	\N	\N	\N	2025-11-14 09:00:00+00
d0f6a1e2-2282-470e-a155-1faad057778d	190124110002232	\N	\N	\N	2025-11-14 09:00:00+00
5a5a8a50-e136-4f36-8966-4344435eaaf3	190124110002233	\N	\N	\N	2025-11-14 09:00:00+00
6f2be213-f47c-404e-84c8-111fd4be7a38	190124110002235	\N	\N	\N	2025-11-14 09:00:00+00
5283cc42-7c8d-45ea-99bc-f795069ca8c3	190124110002236	\N	\N	\N	2025-11-14 09:00:00+00
a69a8e51-fa73-4a7c-940c-686f6b75ccc5	190124110002237	\N	\N	\N	2025-11-14 09:00:00+00
aef8ccca-0ecf-493b-bdb2-137ff1237a97	190124110002238	\N	\N	\N	2025-11-14 09:00:00+00
93aaffb8-07f0-4fe8-9e6e-7ca4b230d578	190124110002239	\N	\N	\N	2025-11-14 09:00:00+00
5524ccfe-42b7-46c5-aabe-9798692f156d	190124110002240	\N	\N	\N	2025-11-14 09:00:00+00
4df0ce62-48fd-4cb2-ad1a-8893a0b74eb3	190124110002241	\N	\N	\N	2025-11-14 09:00:00+00
091edd99-f4c8-4ed8-beac-64f3d07bd035	190124110002242	\N	\N	\N	2025-11-14 09:00:00+00
6cc4edf3-b2ba-4efa-8d25-64edb074cd3e	190124110002243	\N	\N	\N	2025-11-14 09:00:00+00
76cd86df-1273-4fad-9588-8927716b1103	190124110002244	\N	\N	\N	2025-11-14 09:00:00+00
47be9909-dc55-4ad5-ab60-997e50c9f20a	190124110002245	\N	\N	\N	2025-11-14 09:00:00+00
c761cab5-14de-4052-bfc1-b1ab9dd71628	190124110002246	\N	\N	\N	2025-11-14 09:00:00+00
afbb1858-941b-43b3-b5f7-c0dc5ebf1380	190124110002247	\N	\N	\N	2025-11-14 09:00:00+00
e73e50a1-0a94-4b76-892e-c85ed9c380b5	190124110002248	\N	\N	\N	2025-11-14 09:00:00+00
7f194e8d-4172-442e-94a4-f377e2a22451	190124110002249	\N	\N	\N	2025-11-14 09:00:00+00
7190e304-8bf3-4ef1-9814-16f1bb61cdbe	190124110002250	\N	\N	\N	2025-11-14 09:00:00+00
20a0a937-be2c-4dd4-a4fe-8878292b3450	190124110002251	\N	\N	\N	2025-11-14 09:00:00+00
c6cf7472-9228-482d-bb12-7f123be39627	190124110002252	\N	\N	\N	2025-11-14 09:00:00+00
d2f51937-8031-495c-a518-3f4ec27deb96	190124110002253	\N	\N	\N	2025-11-14 09:00:00+00
45a30dd4-067f-4d5e-b244-e7f0d283c6f6	190124110002254	\N	\N	\N	2025-11-14 09:00:00+00
3a66670f-ce7f-43ca-83d7-98a6b7eca2aa	190124110002255	\N	\N	\N	2025-11-14 09:00:00+00
1d5ac371-5d0b-4711-9fe9-51929c6f9bb5	190124110002256	\N	\N	\N	2025-11-14 09:00:00+00
1fb83725-6d6b-42c9-9b11-91b2724bbd95	190124110002257	\N	\N	\N	2025-11-14 09:00:00+00
715c7b63-d4e6-40af-bbca-2b2618b651d7	190124110002258	\N	\N	\N	2025-11-14 09:00:00+00
c35aad73-3ddd-4e6a-a127-df65ac48bbfb	190124110002259	\N	\N	\N	2025-11-14 09:00:00+00
400b5b4e-1b2f-4f4c-b951-4c0ac8331d84	190124110002260	\N	\N	\N	2025-11-14 09:00:00+00
612c812e-bf14-498e-b93a-a629c4d9a542	190124110002261	\N	\N	\N	2025-11-14 09:00:00+00
3b9bd127-2c9a-487c-9378-8dfd25b8530c	190124110002262	\N	\N	\N	2025-11-14 09:00:00+00
e9161e28-8ba7-495a-9d02-d19eff7ba14c	190124110002263	\N	\N	\N	2025-11-14 09:00:00+00
e8027d2e-7c51-4ac9-b925-7d3ba1242b3f	190124110002264	\N	\N	\N	2025-11-14 09:00:00+00
5ff13dcb-c2e9-4f22-b80d-1f37486371de	190124110002265	\N	\N	\N	2025-11-14 09:00:00+00
f35df738-3d01-4ae2-9f93-7b6830a022d0	190124110002266	\N	\N	\N	2025-11-14 09:00:00+00
893d8048-a8cc-4136-afa3-d9fa576ff43d	190124110002267	\N	\N	\N	2025-11-14 09:00:00+00
67e68b87-1b04-4041-af4e-ee7779e08642	190124110002268	\N	\N	\N	2025-11-14 09:00:00+00
4dce63b6-3fea-4bcf-8f2e-6cade4f60204	190124110002269	\N	\N	\N	2025-11-14 09:00:00+00
faa8cb56-f024-4faf-8427-50994c769b25	190124110002270	\N	\N	\N	2025-11-14 09:00:00+00
c823f54d-7125-4dcd-950a-fde74b11984e	190124110002271	\N	\N	\N	2025-11-14 09:00:00+00
5e260b05-a9fd-4633-b9b2-61a4a16effed	190124110002272	\N	\N	\N	2025-11-14 09:00:00+00
372148cf-4fe1-413c-a9a3-df1ffcde640d	190124110002273	\N	\N	\N	2025-11-14 09:00:00+00
6a3094bc-22e6-40cf-a330-c9ef2983d7d1	190124110002274	\N	\N	\N	2025-11-14 09:00:00+00
a4b28f19-d1bd-448a-b0db-0ca74ce5d192	190124110002275	\N	\N	\N	2025-11-14 09:00:00+00
52526594-98e3-48b0-8e03-443d6b90b811	190124110002276	\N	\N	\N	2025-11-14 09:00:00+00
2d8f2ee9-d732-4962-ba42-9b8c507ce103	190124110002277	\N	\N	\N	2025-11-14 09:00:00+00
b8393a23-39eb-4422-aab5-55d4049d594e	190124110002278	\N	\N	\N	2025-11-14 09:00:00+00
de7bf3dc-31fe-47b7-8f2f-680b9b953944	190124110002279	\N	\N	\N	2025-11-14 09:00:00+00
dfbe9a87-42f6-4993-ba68-adec522f2afb	190124110002280	\N	\N	\N	2025-11-14 09:00:00+00
5a73aa8b-8a72-444b-afbc-906e067f27aa	190124110002281	\N	\N	\N	2025-11-14 09:00:00+00
b2d31def-3bf1-4c96-b182-285aeedbf531	190124110002282	\N	\N	\N	2025-11-14 09:00:00+00
1bf83bfe-f791-42e2-ad95-e81befd4a135	190124110002283	\N	\N	\N	2025-11-14 09:00:00+00
c56541ab-8f29-4142-abb8-845832d31e6e	190124110002284	\N	\N	\N	2025-11-14 09:00:00+00
f8e8522a-0674-4a15-981a-1d18be34e033	190124110002285	\N	\N	\N	2025-11-14 09:00:00+00
f5de2a55-35fa-4d11-b6f2-d748841fc026	190124110002287	\N	\N	\N	2025-11-14 09:00:00+00
4dde7a2a-961b-45f5-b6bc-95a8100bc514	190124110002288	\N	\N	\N	2025-11-14 09:00:00+00
44e159e5-9adc-4116-b9e8-d858aeb12d64	190124110002289	\N	\N	\N	2025-11-14 09:00:00+00
096f837e-8fa1-4d4b-bc2b-18ebd35ba02f	190124110002290	\N	\N	\N	2025-11-14 09:00:00+00
86fdd7c1-91c4-48c6-a1ad-edf5d14f6576	190124110002291	\N	\N	\N	2025-11-14 09:00:00+00
35663830-25a0-457a-956b-42b82278c80c	190124110002292	\N	\N	\N	2025-11-14 09:00:00+00
d3d19ea9-c814-4c23-b4b8-3fc7822c1d81	190124110002293	\N	\N	\N	2025-11-14 09:00:00+00
63d11f38-7155-4fd2-adac-1489111ae929	190124110002294	\N	\N	\N	2025-11-14 09:00:00+00
36291c1f-ea48-49db-8c70-665768091e09	190124110002295	\N	\N	\N	2025-11-14 09:00:00+00
2c39820c-0544-443a-8e0c-0a1bfa20fbe1	190124110002296	\N	\N	\N	2025-11-14 09:00:00+00
49792685-9b63-4683-818c-fe7381541f45	190124110002297	\N	\N	\N	2025-11-14 09:00:00+00
89c8d684-bbad-4032-a460-01a191959052	190124110002298	\N	\N	\N	2025-11-14 09:00:00+00
ad68f9d3-8e03-4a2a-a978-ede8289822cf	190124110002299	\N	\N	\N	2025-11-14 09:00:00+00
d2b5c4b8-1e2a-4e5b-bf78-d15ae7d874c9	190124110002300	\N	\N	\N	2025-11-14 09:00:00+00
0bba028e-e8e1-46b6-a749-89efb5bcf617	190124110002301	\N	\N	\N	2025-11-14 09:00:00+00
fe606efe-34c4-4020-873c-abcef660abaf	190124110002302	\N	\N	\N	2025-11-14 09:00:00+00
88ff6900-005d-47ba-99f0-682689854362	190124110002303	\N	\N	\N	2025-11-14 09:00:00+00
1a7a5736-53a4-4e8e-bb05-e7add55d3ce2	190124110002304	\N	\N	\N	2025-11-14 09:00:00+00
1911123e-2de0-4a56-a22c-521869c03fe4	190124110002305	\N	\N	\N	2025-11-14 09:00:00+00
f4e7a703-cea2-468b-a796-5be73d178c32	190124110002306	\N	\N	\N	2025-11-14 09:00:00+00
3445f112-8a23-4839-8ef6-337eb43ee4b4	190124110002307	\N	\N	\N	2025-11-14 09:00:00+00
65b3ad70-c89c-47db-a99a-000f2d105f5d	190124110002308	\N	\N	\N	2025-11-14 09:00:00+00
3f528bc4-19de-4d77-b9a6-00ae096bbac8	190124110002309	\N	\N	\N	2025-11-14 09:00:00+00
a91bc509-bbba-44a1-8a58-facd4887cf21	190124110002310	\N	\N	\N	2025-11-14 09:00:00+00
5ccd24f5-f2c3-4818-89c3-d5918d1e324f	190124110002311	\N	\N	\N	2025-11-14 09:00:00+00
c189366c-c42b-4a67-8c2e-a1b8b3f9c391	190124110002312	\N	\N	\N	2025-11-14 09:00:00+00
4783310d-7c7e-428d-aa25-72d4afee3f5c	190124110002313	\N	\N	\N	2025-11-14 09:00:00+00
9db1d0fa-729e-4cba-b3e1-27f5a5bf8797	190124110002314	\N	\N	\N	2025-11-14 09:00:00+00
dfb49559-9483-457e-a2cf-7cb5595d8d02	190124110002315	\N	\N	\N	2025-11-14 09:00:00+00
d547f5f9-d611-46d9-b5bf-ed7c36ca279f	190124110002316	\N	\N	\N	2025-11-14 09:00:00+00
52352c27-40fb-4904-ad6b-f3065d117302	190124110002317	\N	\N	\N	2025-11-14 09:00:00+00
ee58d746-9c25-4f97-bcf0-df9abdf823a1	190124110002318	\N	\N	\N	2025-11-14 09:00:00+00
98e700e1-cf28-4bbb-b1eb-acae487bc1ea	190124110002319	\N	\N	\N	2025-11-14 09:00:00+00
cd3cd1c1-01f5-4cd2-8232-00206a456fa1	190124110002320	\N	\N	\N	2025-11-14 09:00:00+00
d4c7af21-27ad-4bac-acda-2b287cf0ed47	190124110002321	\N	\N	\N	2025-11-14 09:00:00+00
aff68fe9-275c-4f97-9017-b0f5cb876aad	190124110002322	\N	\N	\N	2025-11-14 09:00:00+00
bfe9c5a6-6ce0-4872-80e0-1b15077650bc	190124110002323	\N	\N	\N	2025-11-14 09:00:00+00
ec7b80de-5526-4531-9446-c40364a3a21a	190124110002324	\N	\N	\N	2025-11-14 09:00:00+00
500b0aa9-5fc1-4f00-a171-690a46235efc	190124110002325	\N	\N	\N	2025-11-14 09:00:00+00
3e2ebd29-9b27-4e6c-8ec2-bc690aa02d4b	190124110002326	\N	\N	\N	2025-11-14 09:00:00+00
f20f531d-2f49-430a-a9fb-f90dd3601550	190124110002327	\N	\N	\N	2025-11-14 09:00:00+00
aacf9ab3-9a52-4fef-ae57-8a36d63f1504	190124110002328	\N	\N	\N	2025-11-14 09:00:00+00
746ddc9f-bf77-4cd2-abd0-283de973dbac	190124110002329	\N	\N	\N	2025-11-14 09:00:00+00
756ebd2c-aac5-4d45-a9ae-3745f927c072	190124110002330	\N	\N	\N	2025-11-14 09:00:00+00
b935c0da-6924-4d9e-849c-b52552af6f1b	190124110002331	\N	\N	\N	2025-11-14 09:00:00+00
9671d203-e182-44ac-8ab6-acb17ef92b3a	190124110002332	\N	\N	\N	2025-11-14 09:00:00+00
d7394392-0fd9-4b9b-824a-cf1fe1435aaa	190124110002333	\N	\N	\N	2025-11-14 09:00:00+00
54dc8be0-59a2-4259-b001-ffc5c78a1d44	190124110002334	\N	\N	\N	2025-11-14 09:00:00+00
759dd178-bb7c-4c14-aa72-99080e933d5d	190124110002335	\N	\N	\N	2025-11-14 09:00:00+00
fcda8ab8-3caf-48ad-96c0-dee8d3e67668	190124110002336	\N	\N	\N	2025-11-14 09:00:00+00
0aaa9598-d133-4b9c-a0de-813c2744dee8	190124110002337	\N	\N	\N	2025-11-14 09:00:00+00
5faff10f-904d-48c9-8626-9481b22cb625	190124110002338	\N	\N	\N	2025-11-14 09:00:00+00
f1706796-0e13-4d2f-ba9f-e51a0ef26af3	190124110002339	\N	\N	\N	2025-11-14 09:00:00+00
d0b68987-7dbb-4751-93d1-c712665afac6	190124110002340	\N	\N	\N	2025-11-14 09:00:00+00
6837c69e-9049-480c-9fa7-138c1402a336	190124110002341	\N	\N	\N	2025-11-14 09:00:00+00
93477bf4-09f3-4655-881a-8d6a8bcf75e0	190124110002342	\N	\N	\N	2025-11-14 09:00:00+00
3c6e9b89-45ff-4549-b59a-37e1ec69f0cd	190124110002343	\N	\N	\N	2025-11-14 09:00:00+00
6ae51035-a971-424f-8f0f-8cc6fd0d9682	190124110002344	\N	\N	\N	2025-11-14 09:00:00+00
6159f221-a2df-430e-a309-c9669d680012	190124110002345	\N	\N	\N	2025-11-14 09:00:00+00
c08defe5-7e03-4bd5-b1ae-c33c0bcce143	190124110002346	\N	\N	\N	2025-11-14 09:00:00+00
a9ed498d-a21a-46e5-9d39-47e3b3b077d8	190124110002347	\N	\N	\N	2025-11-14 09:00:00+00
cd8ad739-a90f-4e37-a8f3-7da18fd6a86e	190124110002348	\N	\N	\N	2025-11-14 09:00:00+00
80f5c76c-3db7-4d04-8eff-12aaed57f38d	190124110002349	\N	\N	\N	2025-11-14 09:00:00+00
53562729-9a60-4696-b154-5c50fb61ca7a	190124110002350	\N	\N	\N	2025-11-14 09:00:00+00
be0dbc11-a6fa-4474-9259-8f5f78320cf6	190124110002351	\N	\N	\N	2025-11-14 09:00:00+00
e58e4341-5ee9-4c6c-89ae-887b52d58623	190124110002352	\N	\N	\N	2025-11-14 09:00:00+00
9c4cc1d1-000a-416b-83c0-02b1955cdf38	190124110002353	\N	\N	\N	2025-11-14 09:00:00+00
212c744e-162e-47d8-a79f-ff6687111f46	190124110002354	\N	\N	\N	2025-11-14 09:00:00+00
c366d9f8-7663-4e6f-862f-24ee32ee3475	190124110002355	\N	\N	\N	2025-11-14 09:00:00+00
b31872fb-59e8-47b0-9b9c-0019e645af94	190124110002356	\N	\N	\N	2025-11-14 09:00:00+00
8b77134d-22a8-481b-a770-e627d8861578	190124110002357	\N	\N	\N	2025-11-14 09:00:00+00
44069c97-e621-484c-8814-00495fee2ef1	190124110002358	\N	\N	\N	2025-11-14 09:00:00+00
8bc9ec3e-5134-45ee-8c98-6445c0042cf6	190124110002359	\N	\N	\N	2025-11-14 09:00:00+00
261cbeae-9133-4381-b9b3-43ad2bce59a7	190124110002360	\N	\N	\N	2025-11-14 09:00:00+00
5a3713fa-fdef-495a-b046-3c57ed6f0dd1	190124110002361	\N	\N	\N	2025-11-14 09:00:00+00
afba72ca-f7f1-4bef-bf68-b442d7c69047	190124110002362	\N	\N	\N	2025-11-14 09:00:00+00
c376f209-0186-4258-ac02-36aee11bfcf7	190124110002363	\N	\N	\N	2025-11-14 09:00:00+00
5291e9e2-3564-4440-b337-3141f87c4769	190124110002364	\N	\N	\N	2025-11-14 09:00:00+00
a60bccc8-526e-47e5-b8a3-05c845b9186a	190124110002365	\N	\N	\N	2025-11-14 09:00:00+00
52f95ebe-5b65-4413-a1bf-bded4073c370	190124110002366	\N	\N	\N	2025-11-14 09:00:00+00
10ff1cac-f4a6-4297-88cc-a0516e7fb300	190124110002367	\N	\N	\N	2025-11-14 09:00:00+00
afa39b0d-3f24-49cd-a8ea-dee6d3a16b7b	190124110002368	\N	\N	\N	2025-11-14 09:00:00+00
6f68edd4-a681-4d6b-b2b9-be58e1f33cfa	190124110002369	\N	\N	\N	2025-11-14 09:00:00+00
3a95487f-03ce-4c8f-af9e-fc4ab8240f36	190124110002370	\N	\N	\N	2025-11-14 09:00:00+00
227f93e5-9a36-4d02-be21-43f9586c5214	190124110002371	\N	\N	\N	2025-11-14 09:00:00+00
9cba7b3a-8141-48d9-97c4-153213e3710b	190124110002372	\N	\N	\N	2025-11-14 09:00:00+00
05e37074-ce54-4a70-af80-de5d08b57ad1	190124110002373	\N	\N	\N	2025-11-14 09:00:00+00
94bb67b0-31b4-4d92-a8a8-844e43ec15b9	190124110002374	\N	\N	\N	2025-11-14 09:00:00+00
84e5d357-f3a3-4993-a270-084664fd9727	190124110002375	\N	\N	\N	2025-11-14 09:00:00+00
dbecfc35-4679-4f85-8910-3e94c6857df2	190124110002376	\N	\N	\N	2025-11-14 09:00:00+00
65ef1619-28d3-4640-ba54-d1fbda11514d	190124110002377	\N	\N	\N	2025-11-14 09:00:00+00
2c3298e2-eb52-460d-8220-bdd5fe3af11f	190124110002378	\N	\N	\N	2025-11-14 09:00:00+00
f23c9ed4-6105-4b18-abfa-30ff853f4315	190124110002379	\N	\N	\N	2025-11-14 09:00:00+00
9033c785-2b2a-425b-925c-8d52ffc6c947	190124110002380	\N	\N	\N	2025-11-14 09:00:00+00
665322a2-7190-4f4c-ba13-0caa2069071b	190124110002381	\N	\N	\N	2025-11-14 09:00:00+00
51191469-b0eb-450e-bbab-bb94846afbce	190124110002382	\N	\N	\N	2025-11-14 09:00:00+00
e77e2037-2742-4f29-9c5c-01fd01e8c59a	190124110002383	\N	\N	\N	2025-11-14 09:00:00+00
650b2bc9-942f-443c-b096-d35feb7fbd01	190124110002384	\N	\N	\N	2025-11-14 09:00:00+00
39cafe05-240c-4b24-a8db-11151dfb5098	190124110002385	\N	\N	\N	2025-11-14 09:00:00+00
295f0fa6-c768-42b6-a773-acf94f029f40	190124110002386	\N	\N	\N	2025-11-14 09:00:00+00
a8a77e59-fa94-4ab5-97b3-690271953129	190124110002387	\N	\N	\N	2025-11-14 09:00:00+00
82e74632-5741-4069-86b3-135fef613f95	190124110002388	\N	\N	\N	2025-11-14 09:00:00+00
ea48e90c-2fcd-4fa0-88ad-aa2e497ef270	190124110002389	\N	\N	\N	2025-11-14 09:00:00+00
ad10783f-3159-4f47-bff7-0700856496d5	190124110002390	\N	\N	\N	2025-11-14 09:00:00+00
6e04826c-50c3-42b3-9f07-cea66686e3da	190124110002391	\N	\N	\N	2025-11-14 09:00:00+00
2bd11af5-b3ff-41f3-a7ef-d921b43601f6	190124110002392	\N	\N	\N	2025-11-14 09:00:00+00
6d961887-335d-4d3a-b63c-4aff1b916e8d	190124110002393	\N	\N	\N	2025-11-14 09:00:00+00
737600a6-0671-42cf-9720-fb35aa3f2a1b	190124110002394	\N	\N	\N	2025-11-14 09:00:00+00
a5660e19-ca7b-4beb-b4d7-c6f734344640	190124110002395	\N	\N	\N	2025-11-14 09:00:00+00
759c4bac-2771-46a1-bf5e-48bb319ff033	190124110002396	\N	\N	\N	2025-11-14 09:00:00+00
52cd91b3-9e15-4a2c-ac7f-dc06eb0442e2	190124110002397	\N	\N	\N	2025-11-14 09:00:00+00
cdd1c28c-0763-482b-9f50-cfb856e51912	190124110002398	\N	\N	\N	2025-11-14 09:00:00+00
83e04cf6-35fd-4b07-b782-a5269ef93153	190124110002399	\N	\N	\N	2025-11-14 09:00:00+00
53420c88-82cc-4e7a-bb05-0d3cb1e7caa4	190124110002400	\N	\N	\N	2025-11-14 09:00:00+00
db0dfe95-f3cc-4d9a-90c9-6cd6732b62ba	190124110002401	\N	\N	\N	2025-11-14 09:00:00+00
a3a9dcfb-65f7-4cf2-8709-6b967cf59f16	190124110002402	\N	\N	\N	2025-11-14 09:00:00+00
41ff323b-104c-4120-b873-6a5073fa0c8a	190124110002403	\N	\N	\N	2025-11-14 09:00:00+00
429f3889-b9aa-4b29-b085-f849542bd7fb	190124110002404	\N	\N	\N	2025-11-14 09:00:00+00
a3808ff1-3e17-4e20-b8aa-64de9264e09b	190124110002405	\N	\N	\N	2025-11-14 09:00:00+00
2a31c2eb-185c-42ee-ae26-0600572f9490	190124110002406	\N	\N	\N	2025-11-14 09:00:00+00
3ceb9bdc-8ad4-45f5-8d8a-c2b695469542	190124110002407	\N	\N	\N	2025-11-14 09:00:00+00
ccf83fe4-32e1-4719-8f67-8b7403f3aaca	190124110002408	\N	\N	\N	2025-11-14 09:00:00+00
c7e2d5c8-1e16-4b7a-b179-adbf53296ff2	190124110002409	\N	\N	\N	2025-11-14 09:00:00+00
35773b67-d62c-4bdf-adc4-fa6ada3edef3	190124110002410	\N	\N	\N	2025-11-14 09:00:00+00
153b14f7-6073-480c-834c-a466b07e51bd	190124110002411	\N	\N	\N	2025-11-14 09:00:00+00
db87bb44-4bc9-4515-9b14-e73427f41e2e	190124110002412	\N	\N	\N	2025-11-14 09:00:00+00
5763e300-c450-4a1b-a380-85bff3b6e921	190124110002413	\N	\N	\N	2025-11-14 09:00:00+00
1d1b88ac-1790-46dc-8f5c-873343b051c2	190124110002414	\N	\N	\N	2025-11-14 09:00:00+00
2f842457-dcb3-47cc-adaf-ac2fed191a1f	190124110002415	\N	\N	\N	2025-11-14 09:00:00+00
a1a78692-4030-4cdd-9441-f933c395bd05	190124110002416	\N	\N	\N	2025-11-14 09:00:00+00
a89f8aa9-4839-4ef0-84c8-650d9c85d4c7	190124110002437	\N	\N	\N	2025-11-14 09:00:00+00
261f525d-b087-4bf1-b71f-d16c31fba753	190124110002438	\N	\N	\N	2025-11-14 09:00:00+00
e0909aa2-7368-4736-b0b9-b803d9d73680	190124110002439	\N	\N	\N	2025-11-14 09:00:00+00
f4c1809b-0fee-4be0-b497-9117695e5120	190124110002440	\N	\N	\N	2025-11-14 09:00:00+00
64eae673-b309-468e-9b96-75694623a88b	190124110002441	\N	\N	\N	2025-11-14 09:00:00+00
cc90a9f7-aaed-4f25-9a19-7637c6d16d7f	190124110002442	\N	\N	\N	2025-11-14 09:00:00+00
3a0d6df7-dd49-4964-89d9-8632faa089b1	190124110002443	\N	\N	\N	2025-11-14 09:00:00+00
e5428c6c-db9f-4507-ad63-22517df3fbcd	190124110002444	\N	\N	\N	2025-11-14 09:00:00+00
77b46439-bea3-4128-8ccf-7bcd43324c79	190124110002445	\N	\N	\N	2025-11-14 09:00:00+00
859c436c-1006-48e8-93a9-c4c22cb270bb	190124110002446	\N	\N	\N	2025-11-14 09:00:00+00
bc159cbe-baee-4cc8-9eda-be91edb2cbf4	190124110002447	\N	\N	\N	2025-11-14 09:00:00+00
da22377e-6b16-47bb-a165-62b6d359043f	190124110002448	\N	\N	\N	2025-11-14 09:00:00+00
3f8ee0a0-8299-4ef0-8af7-a75ee3afd9e3	190124110002449	\N	\N	\N	2025-11-14 09:00:00+00
08e01243-7894-41a4-bd28-10f06a0e6ecc	190124110002450	\N	\N	\N	2026-06-03 04:53:14.24483+00
532032bc-e5e9-42e6-a35e-713b55bf709a	190124110002451	\N	\N	\N	2026-06-03 04:53:14.24483+00
6364255c-95fe-4560-80a6-c64d322b32cc	190124110002452	\N	\N	\N	2026-06-03 04:53:14.24483+00
ce735a8a-30eb-4a06-8cc9-a84add884a34	190124110002453	\N	\N	\N	2026-06-03 04:53:14.24483+00
e9da61d1-6651-4a71-b6e2-7caf11381152	190124110002454	\N	\N	\N	2026-06-03 04:53:14.24483+00
ac841d81-b705-4c63-8fb1-2545747a75cd	190124110002455	\N	\N	\N	2026-06-03 04:53:14.24483+00
0c9a4fb2-73c7-4a48-85f0-3464f65615bb	190124110002456	\N	\N	\N	2026-06-03 04:53:14.24483+00
906e2c11-920b-480c-a19d-f4dbbdb8be10	190124110002457	\N	\N	\N	2026-06-03 04:53:14.24483+00
99ce0090-bad0-4b52-9a8a-7286b2706df0	190124110002458	\N	\N	\N	2026-06-03 04:53:14.24483+00
9ae00d9a-6ca3-4f97-8f2f-ae93ca6d4f64	190124110002459	\N	\N	\N	2026-06-03 04:53:14.24483+00
d3085fde-722f-4411-bffc-6b98225ff465	190124110002460	\N	\N	\N	2026-06-03 04:53:14.24483+00
e4c87927-2d7c-44a9-a848-66add20b90a5	190124110002461	\N	\N	\N	2026-06-03 04:53:14.24483+00
6f093821-74a8-42c3-8f7f-7582942cf084	190124110002462	\N	\N	\N	2026-06-03 04:53:14.24483+00
e336da56-c8dc-4b5e-8b78-8f209ba68dbe	190124110002463	\N	\N	\N	2026-06-03 04:53:14.24483+00
fd0accd1-d387-45eb-84db-72560c3c30c1	190124110002464	\N	\N	\N	2026-06-03 04:53:14.24483+00
d191d428-4433-4fcc-904a-d7215c1c1e6c	190124110002465	\N	\N	\N	2026-06-03 04:53:14.24483+00
7f12b49a-e893-443a-9f78-a69601551f18	190124110002466	\N	\N	\N	2026-06-03 04:53:14.24483+00
8d77e35f-a7c9-4b5d-a3ac-8a5bb8668182	190124110002467	\N	\N	\N	2026-06-03 04:53:14.24483+00
a0a4ee56-6f04-4f19-b00b-aedf37990be1	190124110002468	\N	\N	\N	2026-06-03 04:53:14.24483+00
2e7f402d-8b6f-4723-a6ed-c4069edfd7db	190124110002469	\N	\N	\N	2026-06-03 04:53:14.24483+00
8516b818-93f4-488a-bd9a-5b6e8a9de8e3	190124110002470	\N	\N	\N	2026-06-03 04:53:14.24483+00
99c478df-a86e-4a9a-b8c1-a66c427af4a7	190124110002471	\N	\N	\N	2026-06-03 04:53:14.24483+00
be1c4b4c-7842-4fd9-ba7b-9d36f09f4fcf	190124110002472	\N	\N	\N	2026-06-03 04:53:14.24483+00
f785fe29-267e-480c-83fd-86014a8de3c8	190124110002473	\N	\N	\N	2026-06-03 04:53:14.24483+00
4398ae1b-abe4-4f3b-81fd-d992be126487	190124110002474	\N	\N	\N	2026-06-03 04:53:14.24483+00
de2fa4bb-3dc8-4c07-adfd-162cd3cd1664	190124110002475	\N	\N	\N	2026-06-03 04:53:14.24483+00
0c0b6c45-9f0d-477e-aa2f-2fe3528676ab	190124110002476	\N	\N	\N	2026-06-03 04:53:14.24483+00
759bd709-4969-41dc-ac91-f5766343a44e	190124110002477	\N	\N	\N	2026-06-03 04:53:14.24483+00
6f32a728-cdd1-44d2-a3f2-ff1bfb904aec	190124110002478	\N	\N	\N	2026-06-03 04:53:14.24483+00
3759f3c9-f27e-4635-ab01-7aaf412f9464	190124110002479	\N	\N	\N	2026-06-03 04:53:14.24483+00
8b579bb8-1e6b-419b-b56a-63ddb860a588	190124110002480	\N	\N	\N	2026-06-03 04:53:14.24483+00
d2aeba20-034b-46e8-b00f-3620b5b9f039	190124110002481	\N	\N	\N	2026-06-03 04:53:14.24483+00
ba3c49e7-9046-4027-9a92-c9a15e344f0c	190124110002482	\N	\N	\N	2026-06-03 04:53:14.24483+00
8d947eb4-d3d0-40f5-88e7-6a7b0e4d5ff0	190124110002483	\N	\N	\N	2026-06-03 04:53:14.24483+00
f05f9a4e-683b-461f-9a6c-9c9e057ccf92	190124110002484	\N	\N	\N	2026-06-03 04:53:14.24483+00
ec7b0c56-d06d-4791-8e3a-f474ef2e8bd5	190124110002485	\N	\N	\N	2026-06-03 04:53:14.24483+00
2a748bf1-9ef9-4bda-b178-972da521158b	190124110002486	\N	\N	\N	2026-06-03 04:53:14.24483+00
64c62ad8-2ddc-4ff4-bf39-5b934ebe7a29	190124110002487	\N	\N	\N	2026-06-03 04:53:14.24483+00
02ef0367-6f21-4927-8ac5-9bf78ff9cfd9	190124110002488	\N	\N	\N	2026-06-03 04:53:14.24483+00
f61d2863-f5c1-4948-8b49-ba71b47a00cc	190124110002489	\N	\N	\N	2026-06-03 04:53:14.24483+00
e21385e6-6dc7-4056-a36d-25d00916d406	190124110002490	\N	\N	\N	2026-06-03 04:53:14.24483+00
6ee0fe91-9ea0-4864-a824-b3eb596ad4e1	190124110002491	\N	\N	\N	2026-06-03 04:53:14.24483+00
53f6d74f-72cf-4a4a-9aba-70e0dec66373	190124110002492	\N	\N	\N	2026-06-03 04:53:14.24483+00
35b8ccb0-50df-4a29-b2d5-92f07f0aa199	190124110002493	\N	\N	\N	2026-06-03 04:53:14.24483+00
f26e2e02-d00d-4180-a9be-5c160c6b1593	190124110002494	\N	\N	\N	2026-06-03 04:53:14.24483+00
2d9e3c7a-5afb-45f8-8562-efbe80fc5f03	190124110002495	\N	\N	\N	2026-06-03 04:53:14.24483+00
e4233b96-3b52-4728-b99c-086b10cbe522	190124110002496	\N	\N	\N	2026-06-03 04:53:14.24483+00
5cc5899d-c62b-43dc-b405-74752bef11f9	190124110002497	\N	\N	\N	2026-06-03 04:53:14.24483+00
3a3ab213-dc3b-404d-baaf-143fc0e7974a	190124110002498	\N	\N	\N	2026-06-03 04:53:14.24483+00
ec36c5ed-fc73-4308-8bfb-36dc1f764039	190124110002499	\N	\N	\N	2026-06-03 04:53:14.24483+00
78c00f79-2ba9-437d-9613-4fe083e59485	190124110002500	\N	\N	\N	2026-06-03 04:53:14.24483+00
b2b1deb9-869f-4618-9dbf-1aba037b5971	190124110002501	\N	\N	\N	2026-06-03 04:53:14.24483+00
79f325fd-9029-4dde-9422-55bc9b32bdd7	190124110002502	\N	\N	\N	2026-06-03 04:53:14.24483+00
e20b2f1f-be55-4b01-8472-fff205c49078	190124110002503	\N	\N	\N	2026-06-03 04:53:14.24483+00
472f4d6d-996b-4048-b35f-82002ad247ca	190124110002504	\N	\N	\N	2026-06-03 04:53:14.24483+00
43442b47-13e2-4172-9a9e-50953ce5685c	190124110002505	\N	\N	\N	2026-06-03 04:53:14.24483+00
408dd956-db70-486f-8121-dbc917f21d3e	190124110002506	\N	\N	\N	2026-06-03 04:53:14.24483+00
be29b72a-74e8-4bfb-80bb-f3d5ab6966eb	190124110002507	\N	\N	\N	2026-06-03 04:53:14.24483+00
aa785981-e0f2-4fc4-9dff-6d70fac28c07	190124110002508	\N	\N	\N	2026-06-03 04:53:14.24483+00
ba53e6c7-5fe5-4de1-a410-bd0ad8384c5c	190124110002509	\N	\N	\N	2026-06-03 04:53:14.24483+00
395c04bb-a101-4cee-9ee2-0e326b5ff6b7	190124110002510	\N	\N	\N	2026-06-03 04:53:14.24483+00
23f35c11-745d-478f-b8a9-84fe8e45f461	190124110002511	\N	\N	\N	2026-06-03 04:53:14.24483+00
d5bc4a09-61c5-4092-bf68-6dfa67649ec7	190124110002512	\N	\N	\N	2026-06-03 04:53:14.24483+00
541a7b26-1b7d-4b9e-9967-2b369db3459e	190124110002513	\N	\N	\N	2026-06-03 04:53:14.24483+00
2b9b8fe7-5c01-4e34-b264-9df6914b76d8	190124110002514	\N	\N	\N	2026-06-03 04:53:14.24483+00
416db7c2-7dda-43e8-ae20-e3480828468f	190124110002515	\N	\N	\N	2026-06-03 04:53:14.24483+00
14229efe-a282-48e6-a3a9-7ad94c263231	190124110002516	\N	\N	\N	2026-06-03 04:53:14.24483+00
9599854b-c4da-4f71-953d-053d8be954c8	190124110002517	\N	\N	\N	2026-06-03 04:53:14.24483+00
5f99c72d-898e-4708-ad63-0dc3f8448d46	190124110002518	\N	\N	\N	2026-06-03 04:53:14.24483+00
9fec62e2-4c82-466d-8014-0cbabf4a5a90	190124110002519	\N	\N	\N	2026-06-03 04:53:14.24483+00
dfb8b651-c9b3-4738-8fce-71a9047a9c5a	190124110002520	\N	\N	\N	2026-06-03 04:53:14.24483+00
131a6c74-02f3-4ff3-8b57-b65de1c70ca0	190124110002521	\N	\N	\N	2026-06-03 04:53:14.24483+00
1ef3e8ae-f162-462c-bee6-d180e18a06c3	190124110002522	\N	\N	\N	2026-06-03 04:53:14.24483+00
aa08b63f-3ef5-4705-a45d-18facc0936b7	190124110002523	\N	\N	\N	2026-06-03 04:53:14.24483+00
ee4f3bb6-dbca-413f-b12b-6b6d6de6a87b	190124110002524	\N	\N	\N	2026-06-03 04:53:14.24483+00
82cc3c2a-0f79-4ad3-9b9c-d821fe405396	190124110002525	\N	\N	\N	2026-06-03 04:53:14.24483+00
ab7feba3-fc20-4579-83e9-d572223daaac	190124110002526	\N	\N	\N	2026-06-03 04:53:14.24483+00
424c5306-c3f3-4c6a-83d1-9ce8f1b64b83	190124110002527	\N	\N	\N	2026-06-03 04:53:14.24483+00
5eceabda-7d56-4209-baea-5b8800216c89	190124110002528	\N	\N	\N	2026-06-03 04:53:14.24483+00
769be290-10d0-4e03-89fc-10fb95a492c3	190124110002529	\N	\N	\N	2026-06-03 04:53:14.24483+00
82c97116-658b-468e-b21d-482576db3be9	190124110002530	\N	\N	\N	2026-06-03 04:53:14.24483+00
2eb0f5af-9645-40a8-aced-b1f7329cf553	190124110002531	\N	\N	\N	2026-06-03 04:53:14.24483+00
f7599686-a970-453b-a18c-b57e720c31bc	190124110002532	\N	\N	\N	2026-06-03 04:53:14.24483+00
fd06421f-d0aa-4180-9693-aa623d98a145	190124110002533	\N	\N	\N	2026-06-03 04:53:14.24483+00
38b93129-a46a-4c4c-99b9-f04ebfe80281	190124110002534	\N	\N	\N	2026-06-03 04:53:14.24483+00
93654f88-2c9e-4590-9ce7-65a3b6d16fdf	190124110002535	\N	\N	\N	2026-06-03 04:53:14.24483+00
506798f6-43f1-4ed2-885e-fa22b9b38f56	190124110002536	\N	\N	\N	2026-06-03 04:53:14.24483+00
4f2b1829-c185-4f11-b4c4-d85ba570cf27	190124110002537	\N	\N	\N	2026-06-03 04:53:14.24483+00
ac0be53b-d115-4139-835c-53acb050a396	190124110002538	\N	\N	\N	2026-06-03 04:53:14.24483+00
abbfa0a7-7b28-485d-a482-f92153a4a15f	190124110002539	\N	\N	\N	2026-06-03 04:53:14.24483+00
e17aa1c4-8913-4c58-ba71-a28aded3215e	190124110002540	\N	\N	\N	2026-06-03 04:53:14.24483+00
ca04a929-6d64-4592-8694-e9f2edff24ba	190124110002541	\N	\N	\N	2026-06-03 04:53:14.24483+00
dcc1ba3b-cc7f-4152-938a-a968dd57b0c8	190124110002542	\N	\N	\N	2026-06-03 04:53:14.24483+00
89450aee-ed5e-40c9-b18d-23029424afde	190124110002543	\N	\N	\N	2026-06-03 04:53:14.24483+00
97fdc5cd-cedd-421b-9311-543c031393bb	190124110002544	\N	\N	\N	2026-06-03 04:53:14.24483+00
7018ba66-dd39-4391-bc5e-acc7dbb21a6b	190124110002545	\N	\N	\N	2026-06-03 04:53:14.24483+00
7f4d9e46-a29b-4a02-9363-41f2dd5f18dd	190124110002546	\N	\N	\N	2026-06-03 04:53:14.24483+00
94814dc1-6dd3-4535-b271-a8b15202773c	190124110002547	\N	\N	\N	2026-06-03 04:53:14.24483+00
65e49e21-0e1d-4396-a42b-7af51d3a09f7	190124110002548	\N	\N	\N	2026-06-03 04:53:14.24483+00
83fe2ecb-b78b-4b85-87c6-b3b24f1ce358	190124110002549	\N	\N	\N	2026-06-03 04:53:14.24483+00
65e1b112-a23d-4936-b524-152f3e57c0fb	190124110002550	\N	\N	\N	2026-06-03 04:53:14.24483+00
a51b54e6-99c1-4dce-b72a-457cfea329d8	190124110002551	\N	\N	\N	2026-06-03 04:53:14.24483+00
8bbaa9a3-490a-4432-919c-a876fcd39e41	190124110002552	\N	\N	\N	2026-06-03 04:53:14.24483+00
324e4352-d3e5-4684-8da9-c40a62c86261	190124110002553	\N	\N	\N	2026-06-03 04:53:14.24483+00
e9fdc393-54e7-4116-a5b3-346c8a5097e8	190124110002554	\N	\N	\N	2026-06-03 04:53:14.24483+00
f726579d-0d1d-40a1-ba48-38a5c7ab6818	190124110002555	\N	\N	\N	2026-06-03 04:53:21.177254+00
fd4756a1-92b7-4efb-a814-085640abd29b	190124110002556	\N	\N	\N	2026-06-03 04:53:21.177254+00
525b052c-0127-4fc8-af45-ec1d25724d2d	190124110002557	\N	\N	\N	2026-06-03 04:53:21.177254+00
c0443eff-db68-4de6-bbb1-986dc0286bb3	190124110002558	\N	\N	\N	2026-06-03 04:53:21.177254+00
7c79651f-44cb-479c-88b2-4022a454b980	190124110002559	\N	\N	\N	2026-06-03 04:53:21.177254+00
938cdb54-9ca0-4c3b-83b2-61959fe666fe	190124110002560	\N	\N	\N	2026-06-03 04:53:21.177254+00
8e64249c-1b2a-4808-992d-257e4b0635ef	190124110002561	\N	\N	\N	2026-06-03 04:53:21.177254+00
e021fb9d-6f9b-4e2b-9d02-ffb01cf5f4a3	190124110002562	\N	\N	\N	2026-06-03 04:53:21.177254+00
5c289e19-7cb3-4365-a7db-85185f305b6b	190124110002563	\N	\N	\N	2026-06-03 04:53:21.177254+00
e25253b0-d9ab-4616-87eb-3b1d54a995c4	190124110002564	\N	\N	\N	2026-06-03 04:53:21.177254+00
a1ca75a6-1e31-4d12-a506-dad9c80e2be5	190124110002565	\N	\N	\N	2026-06-03 04:53:21.177254+00
ad4aa6f9-821c-405e-9064-316e613b7627	190124110002566	\N	\N	\N	2026-06-03 04:53:21.177254+00
0e5c7a83-e46c-4516-b464-1b63b1532649	190124110002567	\N	\N	\N	2026-06-03 04:53:21.177254+00
7a8663d9-0035-418e-9c40-b22004cd2fdb	190124110002568	\N	\N	\N	2026-06-03 04:53:21.177254+00
693d5fd5-5a61-4745-99da-e401066e6fd4	190124110002569	\N	\N	\N	2026-06-03 04:53:21.177254+00
029dff4d-9229-463c-93e5-ed46ad783e07	190124110002570	\N	\N	\N	2026-06-03 04:53:21.177254+00
8c45f4c1-6d01-47c7-a09e-ab1884d8a3d5	190124110002571	\N	\N	\N	2026-06-03 04:53:21.177254+00
d48f8447-16a4-4142-b157-48c59787693d	190124110002572	\N	\N	\N	2026-06-03 04:53:21.177254+00
b978ff0d-65ef-4de2-90e2-fa4d62753467	190124110002573	\N	\N	\N	2026-06-03 04:53:21.177254+00
0a65c73b-885d-4633-87e7-298185da46c1	190124110002574	\N	\N	\N	2026-06-03 04:53:21.177254+00
87160477-acd2-44cf-b410-d6ba956795bb	190124110002575	\N	\N	\N	2026-06-03 04:53:21.177254+00
cd3845fa-d65c-4175-bf97-f53964d4cee0	190124110002576	\N	\N	\N	2026-06-03 04:53:21.177254+00
e87e06d6-45dd-4fa7-9e5a-1eab46fdd010	190124110002577	\N	\N	\N	2026-06-03 04:53:21.177254+00
aa9f975b-2756-4f56-9d3a-0d31f5e8d8d7	190124110002578	\N	\N	\N	2026-06-03 04:53:21.177254+00
f98e6ebb-7b02-4be5-8620-446ab10df87b	190124110002579	\N	\N	\N	2026-06-03 04:53:21.177254+00
14b424b0-730f-4abd-929d-6d8f608b4cf6	190124110002580	\N	\N	\N	2026-06-03 04:53:21.177254+00
31b663da-9f60-4fe3-a652-c18d4914f3b5	190124110002581	\N	\N	\N	2026-06-03 04:53:21.177254+00
fe926ab4-6a78-4c4a-9e30-3e8b683a34a8	190124110002582	\N	\N	\N	2026-06-03 04:53:21.177254+00
2a65850d-5e3e-498c-8605-3d834023eeba	190124110002583	\N	\N	\N	2026-06-03 04:53:21.177254+00
3ddc6b13-0c18-4bc2-bedb-b115aea5d97b	190124110002584	\N	\N	\N	2026-06-03 04:53:21.177254+00
11f772ee-c6ce-4c4d-978d-b8c45cfd83f7	190124110002585	\N	\N	\N	2026-06-03 04:53:21.177254+00
12d17c7e-19e5-42b2-a015-5ef05720151b	190124110002586	\N	\N	\N	2026-06-03 04:53:21.177254+00
66307657-f4c1-469a-8a26-c74ffa9bc25c	190124110002587	\N	\N	\N	2026-06-03 04:53:21.177254+00
5ea0e660-0862-4da6-8697-10710bd74695	190124110002588	\N	\N	\N	2026-06-03 04:53:21.177254+00
747c9573-c781-49e6-8d56-e4e15b7c7595	190124110002589	\N	\N	\N	2026-06-03 04:53:21.177254+00
b8287872-1899-4612-80af-2b3de2f4ad97	190124110002590	\N	\N	\N	2026-06-03 04:53:21.177254+00
ee2750e4-15b8-4288-b05f-1b68766e3b0f	190124110002591	\N	\N	\N	2026-06-03 04:53:21.177254+00
85229f11-485a-412b-b31d-e35e7f50db7c	190124110002592	\N	\N	\N	2026-06-03 04:53:21.177254+00
9c62815c-8539-448c-8627-f1afd188c262	190124110002593	\N	\N	\N	2026-06-03 04:53:21.177254+00
984456ac-3806-4ae2-9c2c-a95dcde37fce	190124110002594	\N	\N	\N	2026-06-03 04:53:21.177254+00
d34b36fe-090d-4b11-bc88-1a579cb4066d	190124110002595	\N	\N	\N	2026-06-03 04:53:21.177254+00
bea966c5-488f-4eeb-98e5-e51145aeb583	190124110002596	\N	\N	\N	2026-06-03 04:53:21.177254+00
8f32e70b-b72d-4896-bd97-452d6aeea7a5	190124110002597	\N	\N	\N	2026-06-03 04:53:21.177254+00
6ccf876d-728c-4a4c-b0d4-6ef2270f7b58	190124110002598	\N	\N	\N	2026-06-03 04:53:21.177254+00
2f66477d-cadb-418a-ab53-3389ec4e9fdf	190124110002599	\N	\N	\N	2026-06-03 04:53:21.177254+00
31fdc681-7580-4ae2-b37f-349d82bff775	190124110002600	\N	\N	\N	2026-06-03 04:53:21.177254+00
1e51ab78-7e79-40e7-b396-aaf7fff65f67	190124110002601	\N	\N	\N	2026-06-03 04:53:21.177254+00
788ab88d-3213-42c1-973e-712b1184aa1b	190124110002602	\N	\N	\N	2026-06-03 04:53:21.177254+00
db23c71b-3385-4191-bfb5-6aa6939d3121	190124110002603	\N	\N	\N	2026-06-03 04:53:21.177254+00
70da94a7-6516-4eb2-9c11-0d79e32d504a	190124110002604	\N	\N	\N	2026-06-03 04:53:21.177254+00
234fc15d-aeba-4b57-b229-ea5063b3b9d9	190124110002605	\N	\N	\N	2026-06-03 04:53:21.177254+00
29dc060c-0e3b-4b58-b3e7-5c14087965e8	190124110002606	\N	\N	\N	2026-06-03 04:53:21.177254+00
9d960f2e-67c5-412f-97dc-5f71cebd939a	190124110002607	\N	\N	\N	2026-06-03 04:53:21.177254+00
c9160e1b-7669-4e6f-946f-31e6c84e09d5	190124110002608	\N	\N	\N	2026-06-03 04:53:21.177254+00
b20f5059-3904-47e2-b63a-80eb72e527e4	190124110002609	\N	\N	\N	2026-06-03 04:53:21.177254+00
28d12950-60ff-41ce-adb6-36c0dacbcca1	190124110002610	\N	\N	\N	2026-06-03 04:53:21.177254+00
ac8b54a9-7695-45d9-84d2-e78f8e8c2c9e	190124110002611	\N	\N	\N	2026-06-03 04:53:21.177254+00
1a23e547-e4d7-497c-b44c-2f8e3a88dc24	190124110002612	\N	\N	\N	2026-06-03 04:53:21.177254+00
80d3568e-e982-4e4c-ba3d-e07a58bdffc9	190124110002613	\N	\N	\N	2026-06-03 04:53:21.177254+00
f9615a98-3cfc-497a-bd4c-6c063752c5d8	190124110002614	\N	\N	\N	2026-06-03 04:53:21.177254+00
643e5d84-97fe-4676-9adb-0a466ecb5665	190124110002615	\N	\N	\N	2026-06-03 04:53:21.177254+00
4e57826c-f7f2-4016-bb64-9a2caa793977	190124110002616	\N	\N	\N	2026-06-03 04:53:21.177254+00
cd89c550-05a4-4707-851e-f1d78f6187e9	190124110002617	\N	\N	\N	2026-06-03 04:53:21.177254+00
9568cab9-a355-4894-9c96-51fbef2ed5ac	190124110002618	\N	\N	\N	2026-06-03 04:53:21.177254+00
e2835136-9ccf-4dcc-b828-554625f3a5de	190124110002619	\N	\N	\N	2026-06-03 04:53:21.177254+00
966f072a-a3dc-47be-9ce6-2cf418adaacb	190124110002620	\N	\N	\N	2026-06-03 04:53:21.177254+00
53bd0122-eceb-46d1-bc7f-0d46e5ec64d6	190124110002621	\N	\N	\N	2026-06-03 04:53:21.177254+00
5c526faf-f9e0-4870-be0a-b8e45d696801	190124110002622	\N	\N	\N	2026-06-03 04:53:21.177254+00
ea3eda22-e5f7-42fd-8d1d-c321b2a89641	190124110002623	\N	\N	\N	2026-06-03 04:53:21.177254+00
3a4ee35c-7d79-4010-b9f7-c266e630d0f2	190124110002624	\N	\N	\N	2026-06-03 04:53:21.177254+00
55871bf7-14d3-4438-be48-5adfe1c17762	190124110002625	\N	\N	\N	2026-06-03 04:53:21.177254+00
744c786a-531c-4296-8f05-36a1b9ab773d	190124110002626	\N	\N	\N	2026-06-03 04:53:21.177254+00
2d8b2ddf-a1ef-454b-89ec-2b5968c284d2	190124110002627	\N	\N	\N	2026-06-03 04:53:21.177254+00
94937da5-b2bc-43c3-9d9c-1193b491497e	190124110002628	\N	\N	\N	2026-06-03 04:53:21.177254+00
afa23be0-c25e-4292-b23a-0f842eec23d6	190124110002629	\N	\N	\N	2026-06-03 04:53:21.177254+00
120d3b57-93f7-4fea-9cf7-05bef9d9c8d8	190124110002630	\N	\N	\N	2026-06-03 04:53:21.177254+00
47602676-e825-488d-adf7-3659c24a2589	190124110002631	\N	\N	\N	2026-06-03 04:53:21.177254+00
4621651f-f4f2-43bd-b729-32ef5085ef67	190124110002632	\N	\N	\N	2026-06-03 04:53:21.177254+00
23732efb-3e59-4a9a-a5d4-9a1b333b871c	190124110002633	\N	\N	\N	2026-06-03 04:53:21.177254+00
2a339732-0f36-45b1-8246-09c6f78cc05e	190124110002634	\N	\N	\N	2026-06-03 04:53:21.177254+00
a6ecc99f-1485-4634-8af3-548731bf289d	190124110002635	\N	\N	\N	2026-06-03 04:53:21.177254+00
abc36506-4d82-4a4d-94ad-eb6d48945195	190124110002636	\N	\N	\N	2026-06-03 04:53:21.177254+00
a126a041-0aed-4869-85bb-3b9a8fc4b8b5	190124110002637	\N	\N	\N	2026-06-03 04:53:21.177254+00
d9437561-184f-46ba-8c46-b94047027869	190124110002638	\N	\N	\N	2026-06-03 04:53:21.177254+00
f67c99cb-bc04-44d4-b2dc-f21b47621cce	190124110002639	\N	\N	\N	2026-06-03 04:53:21.177254+00
6d7824cd-65b3-404b-8939-fbe876a4cea1	190124110002640	\N	\N	\N	2026-06-03 04:53:21.177254+00
2e3ef878-4e80-47c2-bd00-f22119acd1ac	190124110002641	\N	\N	\N	2026-06-03 04:53:21.177254+00
2cfb9300-7f2c-44e5-ade9-ae4b5c6bcd41	190124110002642	\N	\N	\N	2026-06-03 04:53:21.177254+00
5975f9d0-e402-4c16-a389-4e3b39ed1e5a	190124110002643	\N	\N	\N	2026-06-03 04:53:21.177254+00
0d3b4dcb-bec1-4438-95d3-d5e4a9666e4c	190124110002644	\N	\N	\N	2026-06-03 04:53:21.177254+00
66019495-0cfb-46c1-bd6d-df176436a191	190124110002645	\N	\N	\N	2026-06-03 04:53:21.177254+00
982e4a01-fbf6-4b52-bed0-33f8a860a2c3	190124110002646	\N	\N	\N	2026-06-03 04:53:21.177254+00
c6b268a0-5d72-4176-98fc-b538aad869a1	190124110002647	\N	\N	\N	2026-06-03 04:53:21.177254+00
f753299c-6fa6-4eff-b5f6-e31fd0968c74	190124110002648	\N	\N	\N	2026-06-03 04:53:21.177254+00
fe086026-2c40-43b8-8f1c-f64f6d95bd0f	190124110002649	\N	\N	\N	2026-06-03 04:53:21.177254+00
d34510f0-29a8-4ee9-ba50-faa3da9d20c0	190124110002650	\N	\N	\N	2026-06-03 04:53:21.177254+00
d45a9ac9-7903-4b75-9c80-dcad0ca5022e	190124110002651	\N	\N	\N	2026-06-03 04:53:21.177254+00
faed4590-df02-4e4d-8d68-1e0e656277c5	190124110002652	\N	\N	\N	2026-06-03 04:53:21.177254+00
10a8e65c-f77e-4a70-aded-35f0be17daea	190124110002653	\N	\N	\N	2026-06-03 04:53:21.177254+00
198ec4ab-0aed-4f77-a908-5cd611e1e1a2	190124110002654	\N	\N	\N	2026-06-03 04:53:21.177254+00
30c30719-7758-419f-a8b2-ac4f2d9e5b71	190124110002655	\N	\N	\N	2026-06-03 04:53:21.177254+00
67562a42-0c4b-408b-97ed-8c50a260e91e	190124110002656	\N	\N	\N	2026-06-03 04:53:21.177254+00
d43a1a2e-fd9e-4c4c-9380-2f1b56525a01	190124110002657	\N	\N	\N	2026-06-03 04:53:21.177254+00
e1a1053f-d84a-4ea3-8167-d3822e02f820	190124110002658	\N	\N	\N	2026-06-03 04:53:21.177254+00
671b49dd-34d4-48cf-977b-3c3929da24ae	190124110002659	\N	\N	\N	2026-06-03 04:53:21.177254+00
7361718b-6330-4758-86d9-2332f3c31512	190124110002660	\N	\N	\N	2026-06-03 04:53:21.177254+00
acde45f0-b5d2-42a6-8ecd-a854bcc7fb6d	190124110002661	\N	\N	\N	2026-06-03 04:53:21.177254+00
009ea815-2494-401e-bc42-d7ed2dde8159	190124110002662	\N	\N	\N	2026-06-03 04:53:21.177254+00
e5aea8d8-cfbf-40d8-9af3-1692ba62ecdb	190124110002663	\N	\N	\N	2026-06-03 04:53:21.177254+00
ad5ff8d2-3b5a-4e7f-acce-e7da2ae10404	190124110002664	\N	\N	\N	2026-06-03 04:53:21.177254+00
8e34c7a7-6e00-4334-875f-acc432152f70	190125020000856	\N	\N	\N	2026-06-03 04:53:26.42912+00
a348d54b-3cb6-4e7d-8467-f0662b6ebed4	190125020000857	\N	\N	\N	2026-06-03 04:53:26.42912+00
1e847395-bcc0-446d-8c83-5a8c98b4dbf6	190125020000858	\N	\N	\N	2026-06-03 04:53:26.42912+00
f28903a7-3f18-471e-8e60-9e792deb420b	190125020000859	\N	\N	\N	2026-06-03 04:53:26.42912+00
363f0c67-afab-4732-a78a-e4b843d397f4	190125020000860	\N	\N	\N	2026-06-03 04:53:26.42912+00
59fa2228-1b85-40d3-8b6a-7066357443ec	190125020000861	\N	\N	\N	2026-06-03 04:53:26.42912+00
4108fa82-d409-4efa-8452-2e891d4204cd	190125020000862	\N	\N	\N	2026-06-03 04:53:26.42912+00
5610e7b2-e4e1-47df-970f-a64d083d8781	190125020000863	\N	\N	\N	2026-06-03 04:53:26.42912+00
517ab4d0-ca49-417a-b3dc-93f550e5673c	190125020000864	\N	\N	\N	2026-06-03 04:53:26.42912+00
b74c211d-3e75-4bed-ae95-3049444e2b9b	190125020000865	\N	\N	\N	2026-06-03 04:53:26.42912+00
a2df681d-70bc-46a6-9025-60e27ebe3119	190125020000866	\N	\N	\N	2026-06-03 04:53:26.42912+00
41da07ff-d697-441d-b6ef-9a2b6d499335	190125020000867	\N	\N	\N	2026-06-03 04:53:26.42912+00
727d574b-72ff-4edd-baa9-d428627442a4	190125020000868	\N	\N	\N	2026-06-03 04:53:26.42912+00
3f11c33f-b686-42b5-8474-c0b45a8341d5	190125020000869	\N	\N	\N	2026-06-03 04:53:26.42912+00
f579dffe-f74f-462c-9fa1-9fec794ebe2f	190125020000870	\N	\N	\N	2026-06-03 04:53:26.42912+00
59bf6229-3b85-4e45-a5aa-ced5b03bdb5f	190125020000871	\N	\N	\N	2026-06-03 04:53:26.42912+00
1a677a84-a4a2-44cc-b6e2-4435a5073602	190125020000872	\N	\N	\N	2026-06-03 04:53:26.42912+00
923e7a33-0309-4420-baf8-96cd0e4a373c	190125020000873	\N	\N	\N	2026-06-03 04:53:26.42912+00
fded9a0e-1a76-4f7e-8201-12eebf2cecaf	190125020000874	\N	\N	\N	2026-06-03 04:53:26.42912+00
11786266-42a8-4490-8acb-114f4c503cc0	190125020000875	\N	\N	\N	2026-06-03 04:53:26.42912+00
\.


--
-- Data for Name: password_resets; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.password_resets (id, user_id, token_hash, expires_at, used_at, created_at) FROM stdin;
\.


--
-- Data for Name: run_calibration_file; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.run_calibration_file (id, run_id, original_name, stored_path, sha256, sheet_names, uploaded_at) FROM stdin;
c4e2bb16-81e1-459e-9279-077526236157	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	No. 2450 - No. 2554.xlsx	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/calibration/a2d9b58c-9fb3-4a75-9c49-a956111e7cf9__No._2450_-_No._2554.xlsx	630176982d9b7e14f292eee010f79680edddb29c0331e3eec456442df2dbb3d6	["190124110002450", "190124110002451", "190124110002452", "190124110002453", "190124110002454", "190124110002455", "190124110002456", "190124110002457", "190124110002458", "190124110002459", "190124110002460", "190124110002461", "190124110002462", "190124110002463", "190124110002464", "190124110002465", "190124110002466", "190124110002467", "190124110002468", "190124110002469", "190124110002470", "190124110002471", "190124110002472", "190124110002473", "190124110002474", "190124110002475", "190124110002476", "190124110002477", "190124110002478", "190124110002479", "190124110002480", "190124110002481", "190124110002482", "190124110002483", "190124110002484", "190124110002485", "190124110002486", "190124110002487", "190124110002488", "190124110002489", "190124110002490", "190124110002491", "190124110002492", "190124110002493", "190124110002494", "190124110002495", "190124110002496", "190124110002497", "190124110002498", "190124110002499", "190124110002500", "190124110002501", "190124110002502", "190124110002503", "190124110002504", "190124110002505", "190124110002506", "190124110002507", "190124110002508", "190124110002509", "190124110002510", "190124110002511", "190124110002512", "190124110002513", "190124110002514", "190124110002515", "190124110002516", "190124110002517", "190124110002518", "190124110002519", "190124110002520", "190124110002521", "190124110002522", "190124110002523", "190124110002524", "190124110002525", "190124110002526", "190124110002527", "190124110002528", "190124110002529", "190124110002530", "190124110002531", "190124110002532", "190124110002533", "190124110002534", "190124110002535", "190124110002536", "190124110002537", "190124110002538", "190124110002539", "190124110002540", "190124110002541", "190124110002542", "190124110002543", "190124110002544", "190124110002545", "190124110002546", "190124110002547", "190124110002548", "190124110002549", "190124110002550", "190124110002551", "190124110002552", "190124110002553", "190124110002554"]	2026-06-03 04:53:14.24483+00
caff1552-9a01-4a55-b13b-b8c479d0542a	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	No. 2555 - No. 2664.xlsx	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/calibration/15d8846c-9dea-4d1c-a5f5-82b3aef864ce__No._2555_-_No._2664.xlsx	d05e6c915b6897a002bac14754807b9d80ab96f1fd732c168dc54fdd7a58cb7f	["190124110002555", "190124110002556", "190124110002557", "190124110002558", "190124110002559", "190124110002560", "190124110002561", "190124110002562", "190124110002563", "190124110002564", "190124110002565", "190124110002566", "190124110002567", "190124110002568", "190124110002569", "190124110002570", "190124110002571", "190124110002572", "190124110002573", "190124110002574", "190124110002575", "190124110002576", "190124110002577", "190124110002578", "190124110002579", "190124110002580", "190124110002581", "190124110002582", "190124110002583", "190124110002584", "190124110002585", "190124110002586", "190124110002587", "190124110002588", "190124110002589", "190124110002590", "190124110002591", "190124110002592", "190124110002593", "190124110002594", "190124110002595", "190124110002596", "190124110002597", "190124110002598", "190124110002599", "190124110002600", "190124110002601", "190124110002602", "190124110002603", "190124110002604", "190124110002605", "190124110002606", "190124110002607", "190124110002608", "190124110002609", "190124110002610", "190124110002611", "190124110002612", "190124110002613", "190124110002614", "190124110002615", "190124110002616", "190124110002617", "190124110002618", "190124110002619", "190124110002620", "190124110002621", "190124110002622", "190124110002623", "190124110002624", "190124110002625", "190124110002626", "190124110002627", "190124110002628", "190124110002629", "190124110002630", "190124110002631", "190124110002632", "190124110002633", "190124110002634", "190124110002635", "190124110002636", "190124110002637", "190124110002638", "190124110002639", "190124110002640", "190124110002641", "190124110002642", "190124110002643", "190124110002644", "190124110002645", "190124110002646", "190124110002647", "190124110002648", "190124110002649", "190124110002650", "190124110002651", "190124110002652", "190124110002653", "190124110002654", "190124110002655", "190124110002656", "190124110002657", "190124110002658", "190124110002659", "190124110002660", "190124110002661", "190124110002662", "190124110002663", "190124110002664"]	2026-06-03 04:53:21.177254+00
e8486f04-4353-4cab-a862-92eb7112c9d3	ccd9fb7c-323e-4d24-8aba-f454129354be	No.190125020000856.2026-04-08 09_13_46-20260415_003951.xlsx	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/calibration/8f09ef99-fa0a-41ec-a350-c7c8cd930ebe__No.190125020000856.2026-04-08_09_13_46-20260415_003951.xlsx	7e6a58683b5721f28d8944e2b887776059a874f795b61048dbe02ece14da8762	["190124110002508", "190124110002582", "190125020000856", "190125020000857", "190125020000858", "190125020000859", "190125020000860", "190125020000861", "190125020000862", "190125020000863", "190125020000864", "190125020000865", "190125020000866", "190125020000867", "190125020000868", "190125020000869", "190125020000870", "190125020000871", "190125020000872", "190125020000873", "190125020000874", "190125020000875"]	2026-06-03 04:53:26.42912+00
\.


--
-- Data for Name: run_reference_files; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.run_reference_files (id, run_id, original_name, stored_path, sha256, uploaded_at) FROM stdin;
0667bb2d-b740-49a2-9de2-6a764822c9da	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	Standard Logger 1.csv	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/references/d22acbea-d733-4726-8103-9991c8a17ad8__Standard_Logger_1.csv	73224dfa7f793779e7f4de729cc6717f21b7c92bd77394a7ee7a2b81c64b4af9	2026-06-03 04:53:14.24483+00
c38be4ec-f919-49cf-9163-83c1182f3fa6	55b6fe2b-db0b-4a57-bc08-af1ef35e15aa	Standard logger 2.csv	/var/lib/ite-calibration/data/runs/55b6fe2b-db0b-4a57-bc08-af1ef35e15aa/references/6a416777-3502-4481-b2b7-1c7612d8ba70__Standard_logger_2.csv	43ebb34112b8afb7212a62af4e1f66ded77fa7001b21ee656db97e758dc05804	2026-06-03 04:53:14.24483+00
6dc63eaa-eef1-4aaa-8099-b512a36f5f48	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	Standard Logger 1.csv	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/references/4d544a83-e1ce-4d7b-b8eb-12cb5dafbb84__Standard_Logger_1.csv	73224dfa7f793779e7f4de729cc6717f21b7c92bd77394a7ee7a2b81c64b4af9	2026-06-03 04:53:21.177254+00
cc54f450-cd5a-4a95-a472-13f25f777c67	54d41f9b-9d07-427f-b9c8-1dee00dc3a0b	Standard logger 2.csv	/var/lib/ite-calibration/data/runs/54d41f9b-9d07-427f-b9c8-1dee00dc3a0b/references/24e630d5-85c0-4879-85fa-495413dde571__Standard_logger_2.csv	43ebb34112b8afb7212a62af4e1f66ded77fa7001b21ee656db97e758dc05804	2026-06-03 04:53:21.177254+00
9ab9fd48-a9c9-4681-805f-a45332c30ce4	ccd9fb7c-323e-4d24-8aba-f454129354be	Calibration-Standard Data-260414.csv	/var/lib/ite-calibration/data/runs/ccd9fb7c-323e-4d24-8aba-f454129354be/references/14bc92ac-0a20-43cd-95a3-dff31ce637f8__Calibration-Standard_Data-260414.csv	0c3702df560eba602c30633cc7f9d15970fbe0d299cef1570d16804265425878	2026-06-03 04:53:26.42912+00
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.sessions (id, user_id, token_hash, expires_at, created_at, revoked_at) FROM stdin;
62e3b206-ccf3-4674-8a29-385c6226fbae	3ca89926-b65a-4184-b81d-c856c2e0776b	12aca069f364526264f30165f1c3e359346acf4951720d94429b2935fb40cd87	2026-06-09 01:56:32.16929+00	2026-05-26 01:56:32.143021+00	2026-05-26 01:56:32.198292+00
f200f5d8-5efb-4777-a7cf-245a1cefd381	5be91f23-6e80-447e-9b93-48e8ce8da652	9c99dbb4fe41a231f597467a447522e9accb9bdf9f90b53d89098d3d7229428f	2026-06-17 06:21:27.01573+00	2026-05-26 02:43:28.401984+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: ite
--

COPY public.users (id, email, password_hash, full_name, role, disabled, created_at, last_login_at) FROM stdin;
3ca89926-b65a-4184-b81d-c856c2e0776b	demo@example.com	$argon2id$v=19$m=65536,t=3,p=4$ff3DV2CjJPbj6p6ej0aglg$zhAXombDE8Y5qDqd1V2HqxEQjroZNUryNDhxexvqKCI	Demo	admin	f	2026-05-26 01:56:32.051816+00	2026-05-26 01:56:32.169362+00
5be91f23-6e80-447e-9b93-48e8ce8da652	biswas.sub65@icebattery.jp	$argon2id$v=19$m=65536,t=3,p=4$m4SxRjbs2p11ar0cy5MGPg$N2kySaEMrO/dB2hk3jXaz1AL0/nmVvskMx3LsGrmRxA	Subhanshu Biswas	admin	f	2026-05-26 02:42:45.375654+00	2026-05-26 02:43:28.434406+00
f8636b7b-686c-4ff4-a6e0-cc2284c30a20	admin@ite.local	$argon2id$v=19$m=65536,t=3,p=4$R1cep+6lCAmmizNv6UyijA$6HmiElnbqEC1h8LGhMYXXF5oVWfwSEb34QEzj7Ms0Yw	Admin	admin	f	2026-05-26 06:39:05.764366+00	\N
0617b893-583f-4879-8d40-8c84e447bc61	demo@ite.local	$argon2id$v=19$m=65536,t=3,p=4$4aBodCsIGzZayeOKS1GvEw$/FgRvK++nToqKisvtnw5vuyl/PcslEPeVRmKu0pFR5Q	Demo	admin	f	2026-05-26 01:54:07.134384+00	\N
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ite
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 13, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: calibration_runs calibration_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.calibration_runs
    ADD CONSTRAINT calibration_runs_pkey PRIMARY KEY (id);


--
-- Name: logger_results logger_results_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.logger_results
    ADD CONSTRAINT logger_results_pkey PRIMARY KEY (id);


--
-- Name: loggers loggers_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.loggers
    ADD CONSTRAINT loggers_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_token_hash_key UNIQUE (token_hash);


--
-- Name: run_calibration_file run_calibration_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.run_calibration_file
    ADD CONSTRAINT run_calibration_file_pkey PRIMARY KEY (id);


--
-- Name: run_calibration_file run_calibration_file_run_id_key; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.run_calibration_file
    ADD CONSTRAINT run_calibration_file_run_id_key UNIQUE (run_id);


--
-- Name: run_reference_files run_reference_files_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.run_reference_files
    ADD CONSTRAINT run_reference_files_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_audit_log_action; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: ix_audit_log_at; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_audit_log_at ON public.audit_log USING btree (at);


--
-- Name: ix_audit_log_run_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_audit_log_run_id ON public.audit_log USING btree (run_id);


--
-- Name: ix_audit_log_user_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_audit_log_user_id ON public.audit_log USING btree (user_id);


--
-- Name: ix_calibration_runs_created_at; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_calibration_runs_created_at ON public.calibration_runs USING btree (created_at);


--
-- Name: ix_calibration_runs_created_by; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_calibration_runs_created_by ON public.calibration_runs USING btree (created_by);


--
-- Name: ix_logger_results_run_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_logger_results_run_id ON public.logger_results USING btree (run_id);


--
-- Name: ix_loggers_serial_no; Type: INDEX; Schema: public; Owner: ite
--

CREATE UNIQUE INDEX ix_loggers_serial_no ON public.loggers USING btree (serial_no);


--
-- Name: ix_password_resets_user_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_password_resets_user_id ON public.password_resets USING btree (user_id);


--
-- Name: ix_run_reference_files_run_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_run_reference_files_run_id ON public.run_reference_files USING btree (run_id);


--
-- Name: ix_sessions_user_id; Type: INDEX; Schema: public; Owner: ite
--

CREATE INDEX ix_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: ite
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: calibration_runs calibration_runs_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.calibration_runs
    ADD CONSTRAINT calibration_runs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: audit_log fk_audit_log_run_id; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT fk_audit_log_run_id FOREIGN KEY (run_id) REFERENCES public.calibration_runs(id) ON DELETE SET NULL;


--
-- Name: logger_results logger_results_logger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.logger_results
    ADD CONSTRAINT logger_results_logger_id_fkey FOREIGN KEY (logger_id) REFERENCES public.loggers(id) ON DELETE SET NULL;


--
-- Name: logger_results logger_results_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.logger_results
    ADD CONSTRAINT logger_results_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.calibration_runs(id) ON DELETE CASCADE;


--
-- Name: password_resets password_resets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: run_calibration_file run_calibration_file_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.run_calibration_file
    ADD CONSTRAINT run_calibration_file_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.calibration_runs(id) ON DELETE CASCADE;


--
-- Name: run_reference_files run_reference_files_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.run_reference_files
    ADD CONSTRAINT run_reference_files_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.calibration_runs(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ite
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict F51c77eLWOhPys2sHmWyypdIAQDumsQrmrJq6MEfQ5GhJAOFWuJ6T2ncTADLL0Q

