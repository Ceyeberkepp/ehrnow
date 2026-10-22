# EHRNow Private Database Web GUI

EHRNow uses PostgreSQL, so its optional web GUI is **Adminer**, a browser-based database manager similar to phpMyAdmin. It lets you browse tables, inspect schema, view and edit rows, and run SQL queries.

## Start the graphical interface (server)
```bash
cd /root/ehrnow
bash scripts/db-admin.sh start
```
The Adminer container listens on **127.0.0.1:18080 on the server only**. It is deliberately not exposed over the Internet, and starts only when requested.

## Open the browser GUI from your computer

```bash
ssh -N -L 18080:127.0.0.1:18080 YOUR_USER@YOUR_SERVER_IP
```

Then visit `http://127.0.0.1:18080` in your web browser.

In Adminer enter:
- **System:** PostgreSQL
- **Server:** postgres
- **Username:** ehrdev
- **Password:** Read `EHR_DB_PASSWORD` privately from `/root/ehrnow/.env.private`; never send it over chat.
- **Database:** ehrnow

## Stop the database GUI

```bash
bash scripts/db-admin.sh stop
```

## Safety
Database administration bypasses EHRNow application permissions. Protect SSH, the local development credentials, and this web GUI. It is intended for synthetic development data only; not real patient data or PHI. Because the development account owns the database, manual updates can break clinical schemas and audit trails. Prefer application workflows over direct SQL changes. Back up the database before any mutation.
