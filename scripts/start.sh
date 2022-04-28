#!/bin/sh
set -x

scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"
npx prisma migrate deploy --schema /cal.com/packages/prisma/schema.prisma
yarn start
