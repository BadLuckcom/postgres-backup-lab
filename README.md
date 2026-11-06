# PostgreSQL Automated Backup with Docker

## Project Overview

This project demonstrates automated PostgreSQL database backups using Docker Compose, Bash, and Linux cron.

The backup script creates PostgreSQL backups, validates them, performs a test restore, and removes old backup files.

## Technologies

- Ubuntu Server / Linux
- Docker
- Docker Compose
- PostgreSQL 16
- Bash scripting
- pg_dump and pg_restore
- Cron

## Project Structure

```text
postgres-backup-lab/
├── compose.yaml
├── .env.example
├── .gitignore
├── README.md
├── init/
│   └── 01-init.sql
├── scripts/
│   └── backup.sh
├── backups/
└── logs/
```

## Features

- PostgreSQL runs inside Docker.
- Sample database is initialized with dummy data.
- Automated PostgreSQL backups in custom format.
- Backup archive validation using pg_restore.
- Test restore into a temporary database.
- Employee record count verification.
- Automatic cleanup of old backups.
- Logging and lock-file protection.
- Scheduled execution using Linux cron.

## Installation

### 1. Clone the repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd postgres-backup-lab
```

### 2. Configure environment

```bash
cp .env.example .env
nano .env
chmod 600 .env
```

Set a strong PostgreSQL password in `.env`.

### 3. Start PostgreSQL

```bash
docker compose up -d
docker compose ps
```

### 4. Run backup manually

```bash
chmod +x scripts/backup.sh
./scripts/backup.sh
```

### 5. Check backup files and logs

```bash
ls -lh backups/
tail -n 30 logs/backup.log
```

## Cron Configuration

Open the user's crontab:

```bash
crontab -e
```

Example: run backup every day at 02:00:

```cron
0 2 * * * /bin/bash /FULL/PATH/TO/postgres-backup-lab/scripts/backup.sh
```

Replace the path with the actual project path.

## Restore

List the contents of a backup:

```bash
docker compose exec -T db sh -c \
'pg_restore --list /backups/BACKUP_FILE.dump'
```

A restore should be tested in a separate database before using it in production.

## Security

- `.env` must never be committed to Git.
- Backup files and logs are excluded from Git.
- PostgreSQL should not be exposed publicly.
- Production backups should also be copied to separate storage.

## Learning Objectives

This project demonstrates practical skills in:

- Linux administration
- Docker and Docker Compose
- PostgreSQL administration
- Bash scripting
- Database backup and restore
- Cron job scheduling
- Git and GitHub

## Author

Mashhurbek

DevOps Learning Project
