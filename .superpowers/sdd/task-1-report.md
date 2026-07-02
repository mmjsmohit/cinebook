# Task 1: Bootstrapping Report

## What I implemented
- Initialized the Node 22+ project (`cinebook-server`) with Typescript, Express, Prisma, Zod, Redis, etc.
- Created `docker-compose.yml` for `postgres:16` and `redis:7`. (Used host port 5433 for Postgres to avoid conflicts with any local installations).
- Defined the provided Prisma schema in `prisma/schema.prisma` and formatted it according to Prisma requirements. Fixed a missing back-relation for `Payment` to `Booking` which was preventing schema compilation.
- Downgraded Prisma temporarily to `5.22.0` to avoid new breaking configuration changes in Prisma 7, allowing us to keep `url` directly in the schema as per standard practice.
- Wrote a robust `prisma/seed.ts` script that produces a demoable world:
  - 3 theatre chains with 3 screens each (mix of IMAX and STANDARD).
  - Seat layouts per screen (Rows A-J) with mappings to `FRONT`, `STANDARD`, `PREMIUM`, and `RECLINER`.
  - 6 movies with genres, cast, and reviews.
  - Shows distributed across the next 7 days.
  - 3 promo codes.
  - Users created for each role (`CUSTOMER`, `HALL_MANAGER`, `ADMIN`).

## What I tested and test results
- Verified that `docker-compose up -d` successfully created and started the Postgres and Redis containers.
- Ran `npx prisma migrate dev --name init` which successfully compiled the schema, created the tables in the database, and generated the Prisma client.
- Executed `npx prisma db seed` which successfully ran and committed the seed data to the database without any errors.

## Files changed
- `cinebook-server/package.json`
- `cinebook-server/tsconfig.json`
- `cinebook-server/docker-compose.yml`
- `cinebook-server/.env`
- `cinebook-server/prisma/schema.prisma`
- `cinebook-server/prisma/seed.ts`

## Self-review findings
- Checked against requirements: Docker stack, schema, and comprehensive seed script are all implemented precisely.
- The schema provided in the plan required minor adjustments for Prisma compilation (e.g. enum declarations on separate lines, and adding the missing `booking` field in the `Payment` model).
- Over-engineering was avoided; focused purely on project initialization and database bootstrapping.

## Issues or concerns
- None. The schema is sound and the seed data properly models a realistic application state.
