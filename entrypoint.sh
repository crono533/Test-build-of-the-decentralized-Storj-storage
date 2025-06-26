#!/usr/bin/env bash
set -euo pipefail


# 0. Настройки
STORAGE_NODES=10
PG_DB="teststorj"
PG_PWD="mysecret"
CONFIG_DIR="/root/.local/share/storj/local-network"


# 1. PostgreSQL  ─ старт и чистая БД
echo "▶ Starting PostgreSQL"
pg_ctlcluster 17 main start

for i in {1..10}; do
  if su - postgres -c "psql -qAt -c 'SELECT 1'" >/dev/null 2>&1; then break; fi
  echo "  ↪ waiting for Postgres…"; sleep 1
done

echo "▶ Resetting ${PG_DB} database"
su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '${PG_PWD}';\""
su - postgres -c "dropdb  --if-exists ${PG_DB}"
su - postgres -c "createdb          ${PG_DB}"

export PGPASSWORD="${PG_PWD}"
PG_URL="postgres://postgres:${PG_PWD}@localhost/${PG_DB}?sslmode=disable"


# 2. Ganache (Ethereum test chain)
echo "▶ Starting Ganache"
nohup npx --yes ganache --host 0.0.0.0 --port 8545 --chainId 1337 --networkId 1337 \
      >/var/log/ganache.log 2>&1 &
sleep 3

# 3. Storj-sim: wipe + fresh setup
echo "▶ Destroying previous Storj-sim network"
storj-sim network destroy --config-dir "${CONFIG_DIR}" || true
rm -rf "${CONFIG_DIR}"

echo "▶ Setting up fresh Storj-sim network (${STORAGE_NODES} storage nodes)"
storj-sim network setup \
  --storage-nodes "${STORAGE_NODES}" \
  --config-dir    "${CONFIG_DIR}"    \
  --postgres      "${PG_URL}"        \
  --host          "0.0.0.0"

# 4. Запуск сети
echo "▶ Launching Storj-sim network (${STORAGE_NODES} storage nodes)"
exec storj-sim network run \
  --storage-nodes "${STORAGE_NODES}" \
  --config-dir    "${CONFIG_DIR}"    \
  --postgres      "${PG_URL}"
