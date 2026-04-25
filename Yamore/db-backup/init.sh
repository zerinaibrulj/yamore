#!/bin/bash
set -e

echo "Starting SQL Server initialization..."

/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Waiting for SQL Server to be ready..."

RETRY_COUNT=0
MAX_RETRIES=30

until /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" &>/dev/null; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: SQL Server failed to start within timeout!"
    kill $SQL_PID
    exit 1
  fi
  echo "Waiting for SQL Server... ($RETRY_COUNT/30)"
  sleep 2
done

echo "SQL Server is ready!"

# Provjera da li baza 220245 već postoji
DB_EXISTS=$(/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$SA_PASSWORD" -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '220245'" | tr -d ' \r\n')

if [ "$DB_EXISTS" = "0" ]; then
  echo "Database doesn't exist. Restoring from backup..."

  if [ ! -f "/var/opt/mssql/backup/220245.bak" ]; then
    echo "ERROR: Backup file 220245.bak not found!"
    kill $SQL_PID
    exit 1
  fi

  # Ovdje smo zamijenili 'yamore' sa '220245'
  /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$SA_PASSWORD" -Q "
  RESTORE DATABASE [220245]
  FROM DISK = '/var/opt/mssql/backup/220245.bak'
  WITH REPLACE,
  MOVE '220245' TO '/var/opt/mssql/data/220245.mdf',
  MOVE '220245_log' TO '/var/opt/mssql/data/220245_log.ldf'
  "

  echo "Database restored as 220245 successfully!"
else
  echo "Database already exists. Skipping restore."
fi

echo "Initialization complete. SQL Server is running..."

wait $SQL_PID