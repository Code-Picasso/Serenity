#!/bin/sh
set -e

echo "Syncing chat database schema..."
npx prisma db push --skip-generate

echo "Starting chat service..."
exec node dist/index.js
