---
name: database-migrations
description: Database migration best practices for schema changes, data migrations, rollbacks, and zero-downtime deployments across PostgreSQL, MySQL, and common ORMs (Prisma, Drizzle, Kysely, Django, TypeORM, golang-migrate).
origin: ECC
---

# Database Migration Patterns

本番システムのための安全でリバーシブルなデータベーススキーマ変更です。

## 起動条件

- データベーステーブルの作成または変更
- カラムやインデックスの追加/削除
- データマイグレーション（バックフィル、変換）の実行
- ゼロダウンタイムスキーマ変更の計画
- 新しいプロジェクトへのマイグレーションツールのセットアップ

## 基本原則

1. **すべての変更はマイグレーション** — 本番データベースを手動で変更しないでください
2. **本番環境ではマイグレーションは前方のみ** — ロールバックは新しい前方マイグレーションで行います
3. **スキーマとデータのマイグレーションは分離** — 1つのマイグレーションに DDL と DML を混在させないでください
4. **本番サイズのデータでマイグレーションをテスト** — 100行で動作するマイグレーションが1000万行ではロックする可能性があります
5. **デプロイ済みのマイグレーションはイミュータブル** — 本番で実行済みのマイグレーションは編集しないでください

## マイグレーション安全チェックリスト

マイグレーション適用前に：

- [ ] マイグレーションに UP と DOWN の両方がある（または明示的にイリバーシブルとマーク）
- [ ] 大きなテーブルでフルテーブルロックがない（コンカレント操作を使用）
- [ ] 新しいカラムにデフォルト値があるか nullable（デフォルトなしの NOT NULL を追加しない）
- [ ] インデックスはコンカレントに作成（既存テーブルの CREATE TABLE インラインではない）
- [ ] データバックフィルはスキーマ変更とは別のマイグレーション
- [ ] 本番データのコピーに対してテスト済み
- [ ] ロールバック計画がドキュメント化されている

## PostgreSQL パターン

### カラムの安全な追加

```sql
-- GOOD: Nullable column, no lock
ALTER TABLE users ADD COLUMN avatar_url TEXT;

-- GOOD: Column with default (Postgres 11+ is instant, no rewrite)
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- BAD: NOT NULL without default on existing table (requires full rewrite)
ALTER TABLE users ADD COLUMN role TEXT NOT NULL;
-- This locks the table and rewrites every row
```

### ダウンタイムなしのインデックス追加

```sql
-- BAD: Blocks writes on large tables
CREATE INDEX idx_users_email ON users (email);

-- GOOD: Non-blocking, allows concurrent writes
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- Note: CONCURRENTLY cannot run inside a transaction block
-- Most migration tools need special handling for this
```

### カラムのリネーム（ゼロダウンタイム）

本番環境では直接リネームしないでください。expand-contract パターンを使用します：

```sql
-- Step 1: Add new column (migration 001)
ALTER TABLE users ADD COLUMN display_name TEXT;

-- Step 2: Backfill data (migration 002, data migration)
UPDATE users SET display_name = username WHERE display_name IS NULL;

-- Step 3: Update application code to read/write both columns
-- Deploy application changes

-- Step 4: Stop writing to old column, drop it (migration 003)
ALTER TABLE users DROP COLUMN username;
```

### カラムの安全な削除

```sql
-- Step 1: Remove all application references to the column
-- Step 2: Deploy application without the column reference
-- Step 3: Drop column in next migration
ALTER TABLE orders DROP COLUMN legacy_status;

-- For Django: use SeparateDatabaseAndState to remove from model
-- without generating DROP COLUMN (then drop in next migration)
```

### 大規模データマイグレーション

```sql
-- BAD: Updates all rows in one transaction (locks table)
UPDATE users SET normalized_email = LOWER(email);

-- GOOD: Batch update with progress
DO $$
DECLARE
  batch_size INT := 10000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users
    SET normalized_email = LOWER(email)
    WHERE id IN (
      SELECT id FROM users
      WHERE normalized_email IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RAISE NOTICE 'Updated % rows', rows_updated;
    EXIT WHEN rows_updated = 0;
    COMMIT;
  END LOOP;
END $$;
```

## Prisma (TypeScript/Node.js)

### ワークフロー

```bash
# Create migration from schema changes
npx prisma migrate dev --name add_user_avatar

# Apply pending migrations in production
npx prisma migrate deploy

# Reset database (dev only)
npx prisma migrate reset

# Generate client after schema changes
npx prisma generate
```

### スキーマの例

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  avatarUrl String?  @map("avatar_url")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  orders    Order[]

  @@map("users")
  @@index([email])
}
```

### カスタム SQL マイグレーション

Prisma で表現できない操作（コンカレントインデックス、データバックフィル）の場合：

```bash
# Create empty migration, then edit the SQL manually
npx prisma migrate dev --create-only --name add_email_index
```

```sql
-- migrations/20240115_add_email_index/migration.sql
-- Prisma cannot generate CONCURRENTLY, so we write it manually
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users (email);
```

## Drizzle (TypeScript/Node.js)

### ワークフロー

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply migrations
npx drizzle-kit migrate

# Push schema directly (dev only, no migration file)
npx drizzle-kit push
```

### スキーマの例

```typescript
import { pgTable, text, timestamp, uuid, boolean } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  name: text("name"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});
```

## Kysely (TypeScript/Node.js)

### ワークフロー (kysely-ctl)

```bash
# Initialize config file (kysely.config.ts)
kysely init

# Create a new migration file
kysely migrate make add_user_avatar

# Apply all pending migrations
kysely migrate latest

# Rollback last migration
kysely migrate down

# Show migration status
kysely migrate list
```

### マイグレーションファイル

```typescript
// migrations/2024_01_15_001_create_user_profile.ts
import { type Kysely, sql } from 'kysely'

// IMPORTANT: Always use Kysely<any>, not your typed DB interface.
// Migrations are frozen in time and must not depend on current schema types.
export async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .createTable('user_profile')
    .addColumn('id', 'serial', (col) => col.primaryKey())
    .addColumn('email', 'varchar(255)', (col) => col.notNull().unique())
    .addColumn('avatar_url', 'text')
    .addColumn('created_at', 'timestamp', (col) =>
      col.defaultTo(sql`now()`).notNull()
    )
    .execute()

  await db.schema
    .createIndex('idx_user_profile_avatar')
    .on('user_profile')
    .column('avatar_url')
    .execute()
}

export async function down(db: Kysely<any>): Promise<void> {
  await db.schema.dropTable('user_profile').execute()
}
```

### プログラマティック Migrator

```typescript
import { Migrator, FileMigrationProvider } from 'kysely'
import { promises as fs } from 'fs'
import * as path from 'path'
// ESM only — CJS can use __dirname directly
import { fileURLToPath } from 'url'
const migrationFolder = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  './migrations',
)

// `db` is your Kysely<any> database instance
const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder,
  }),
  // WARNING: Only enable in development. Disables timestamp-ordering
  // validation, which can cause schema drift between environments.
  // allowUnorderedMigrations: true,
})

const { error, results } = await migrator.migrateToLatest()

results?.forEach((it) => {
  if (it.status === 'Success') {
    console.log(`migration "${it.migrationName}" executed successfully`)
  } else if (it.status === 'Error') {
    console.error(`failed to execute migration "${it.migrationName}"`)
  }
})

if (error) {
  console.error('migration failed', error)
  process.exit(1)
}
```

## Django (Python)

### ワークフロー

```bash
# Generate migration from model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations

# Generate empty migration for custom SQL
python manage.py makemigrations --empty app_name -n description
```

### データマイグレーション

```python
from django.db import migrations

def backfill_display_names(apps, schema_editor):
    User = apps.get_model("accounts", "User")
    batch_size = 5000
    users = User.objects.filter(display_name="")
    while users.exists():
        batch = list(users[:batch_size])
        for user in batch:
            user.display_name = user.username
        User.objects.bulk_update(batch, ["display_name"], batch_size=batch_size)

def reverse_backfill(apps, schema_editor):
    pass  # Data migration, no reverse needed

class Migration(migrations.Migration):
    dependencies = [("accounts", "0015_add_display_name")]

    operations = [
        migrations.RunPython(backfill_display_names, reverse_backfill),
    ]
```

### SeparateDatabaseAndState

データベースから即座にドロップせずに Django モデルからカラムを削除します：

```python
class Migration(migrations.Migration):
    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.RemoveField(model_name="user", name="legacy_field"),
            ],
            database_operations=[],  # Don't touch the DB yet
        ),
    ]
```

## golang-migrate (Go)

### ワークフロー

```bash
# Create migration pair
migrate create -ext sql -dir migrations -seq add_user_avatar

# Apply all pending migrations
migrate -path migrations -database "$DATABASE_URL" up

# Rollback last migration
migrate -path migrations -database "$DATABASE_URL" down 1

# Force version (fix dirty state)
migrate -path migrations -database "$DATABASE_URL" force VERSION
```

### マイグレーションファイル

```sql
-- migrations/000003_add_user_avatar.up.sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
CREATE INDEX CONCURRENTLY idx_users_avatar ON users (avatar_url) WHERE avatar_url IS NOT NULL;

-- migrations/000003_add_user_avatar.down.sql
DROP INDEX IF EXISTS idx_users_avatar;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
```

## ゼロダウンタイムマイグレーション戦略

重要な本番変更には、expand-contract パターンに従います：

```
Phase 1: EXPAND
  - 新しいカラム/テーブルを追加（nullable またはデフォルト値付き）
  - デプロイ：アプリケーションが旧と新の両方に書き込み
  - 既存データをバックフィル

Phase 2: MIGRATE
  - デプロイ：アプリケーションが新から読み取り、両方に書き込み
  - データの整合性を検証

Phase 3: CONTRACT
  - デプロイ：アプリケーションが新のみ使用
  - 別のマイグレーションで旧カラム/テーブルをドロップ
```

### タイムラインの例

```
Day 1: マイグレーションで new_status カラムを追加（nullable）
Day 1: アプリ v2 をデプロイ — status と new_status の両方に書き込み
Day 2: 既存行のバックフィルマイグレーションを実行
Day 3: アプリ v3 をデプロイ — new_status のみから読み取り
Day 7: マイグレーションで旧 status カラムをドロップ
```

## アンチパターン

| アンチパターン | 失敗する理由 | より良いアプローチ |
|-------------|-------------|-----------------|
| 本番での手動 SQL | 監査証跡がなく再現不可能 | 常にマイグレーションファイルを使用 |
| デプロイ済みマイグレーションの編集 | 環境間でドリフトが発生 | 代わりに新しいマイグレーションを作成 |
| デフォルトなしの NOT NULL | テーブルをロックし全行を書き換え | nullable で追加、バックフィル後に制約を追加 |
| 大きなテーブルでのインラインインデックス | ビルド中に書き込みをブロック | CREATE INDEX CONCURRENTLY |
| 1つのマイグレーションにスキーマ + データ | ロールバックが困難で長いトランザクション | マイグレーションを分離 |
| コード削除前のカラムドロップ | 欠落カラムでアプリケーションエラー | まずコードを削除、次のデプロイでカラムをドロップ |
