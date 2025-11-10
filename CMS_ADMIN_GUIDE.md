# CMS Admin Guide — Graduation Project (Flutter + Supabase)

This document maps the app’s data model to a Supabase‑backed CMS. It lists every table the app reads/writes, the JSON shapes used, and recommended admin workflows and RLS policies so you can build a web CMS confidently.

## Scope & Architecture

- Auth: Supabase Auth (users table), app stores profile in `user_identity`.
- Health: Reads from Apple Health/Google Fit on device. Optional daily snapshots stored in `habit`.
- Plans: AI/curated plans persisted in `workout_plan`, `relax_plan`, `meal_plan` per user.
- Relax: User breathing sessions logged in `relax_sessions`.
- Nutrition:
  - Photo analysis → user can add to `nutrition_intake`.
  - Goal changes tracked in `nutrition_goal_history`.
- Chat: Messages stored in `messages` (user + assistant), AI backend via `CHAT_SERVER`.

Use a service‑role key on the CMS server to bypass RLS for admin operations. End‑users in the app rely on owner‑based RLS.

## Entities & Tables

Below are the tables the app references, expected columns, and example policies. Use these to scaffold CMS CRUD.

### user_identity (per‑user profile)
- Purpose: Store profile and plan linkage; acts as “profile” row for a Supabase auth user.
- Columns (recommended):
  - `id` bigint PK
  - `user_id` uuid UNIQUE references `auth.users(id)` on delete cascade
  - `user_name` text
  - `email` text
  - `phone` text
  - `age` int
  - `gender` text
  - `height` double precision
  - `weight` double precision
  - `activity_level` text
  - `diet_type` text
  - `calories` int, `protein` int, `carbs` int, `fat` int, `sugar` int  (snapshot of target/macros)
  - `exercise_id` bigint  (first row id in `workout_plan` for linkage)
  - `relax_id` bigint     (first row id in `relax_plan` for linkage)
  - `created_at` timestamptz default now()
- RLS (owner‑based): select/insert/update/delete where `auth.uid() = user_id`.
- CMS: list/search by email, edit profile and macros, inspect linked plan IDs.

### workout_plan (per‑user plan; rows grouped by `day`)
- Purpose: Weekly workout items per day.
- Columns:
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade (nullable if you want global templates)
  - `exercise_name` text
  - `description` text
  - `difficulty_level` text
  - `exercise_category` text
  - `duration_minutes` int
  - `repetitions` text (e.g., `3x10`)
  - `day` text (e.g., `Day 1`)
  - `finished` boolean (optional; app reads it if present)
  - `created_at` timestamptz default now()
- RLS (owner‑based over `user_id`).
- CMS: create/edit rows per user/day; optional global rows with `user_id = null`.

### relax_plan (per‑user plan; rows grouped by `day`)
- Purpose: Recovery/relaxation sessions per day.
- Columns:
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `title` text
  - `description` text
  - `relaxation_type` text
  - `day` text (e.g., `Day 1`)
  - `created_at` timestamptz default now()
- RLS (owner‑based over `user_id`).
- CMS: curate per‑day relax items per user; may also add defaults (`user_id = null`).

### meal_plan (per‑user plan; 1 row per day)
- Purpose: Structured meals/snacks per day with flexible JSON.
- Columns:
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `day_index` int not null (1..7)
  - `day_label` text (e.g., `Day 1`)
  - `meals` jsonb not null (see shape below)
  - `snacks` jsonb (array of strings)
  - `created_at` timestamptz default now()
- RLS (owner‑based over `user_id`).
- JSON shapes used by the app:
  - `meals`: array where each item is either a map or a string. Recommended map keys:
    - `name` or `title` (string)
    - Optional: `calories` (number), `items` (string[]), `description` (string)
  - `snacks`: array of strings

### relax_sessions (user logs for breathing/relax)
- Purpose: Track per‑session relax data.
- Columns (from app error hints):
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `started_at` timestamptz default now()
  - `minutes` integer not null check (minutes >= 0)
  - `pattern` text (e.g., `4-7-8`, `Box`)
  - `mood` text
  - `created_at` timestamptz default now()
- Index: `(user_id, started_at)`
- RLS (owner‑based over `user_id`).

### nutrition_intake (user’s intake entries)
- Purpose: Roll‑up of analyzed/manual entries; used to compute today totals.
- Columns (from service):
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `bucket_date` date not null (YYYY‑MM‑DD)
  - `energy_kcal` double precision not null default 0
  - `carbs_g` double precision, `protein_g` double precision, `fat_g` double precision, `sugar_g` double precision
  - `source` text default 'manual'
  - `metadata` jsonb (see “Analysis metadata” below)
  - `created_at` timestamptz default now()
- Index: `(user_id, bucket_date)`
- RLS (owner‑based over `user_id`).

### nutrition_goal_history (user’s goal/macros history)
- Purpose: Audit log of target changes set by user.
- Columns:
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `goal` text check in ('lose','maintain','gain')
  - `delta_percent` int check in (10,15,20)
  - `calories_target` int
  - `carbs_g` double precision, `protein_g` double precision, `fat_g` double precision, `sugar_g` double precision
  - `created_at` timestamptz default now()
- RLS (owner‑based over `user_id`).

### habit (per‑day health metrics snapshot)
- Purpose: Optional cache of daily metrics fetched from HealthKit/Google Fit.
- Columns (from service):
  - `id` bigint PK
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `bucket_date` date not null UNIQUE per user
  - `steps` int, `calories` int
  - `standing_time_minutes` int (legacy), `standing_minutes` int (canonical)
  - `sleep_hours` numeric(4,1)
  - `heart_rate_avg` int
  - `sleep_start_time` time
  - `created_at` timestamptz default now()
- Unique index: `(user_id, bucket_date)`
- RLS (owner‑based over `user_id`).

### messages (chat history)
- Purpose: Store user + assistant messages for in‑app chat.
- Columns (recommended):
  - `id` bigint PK (or `uuid`)
  - `user_id` uuid references `auth.users(id)` on delete cascade
  - `role` text default 'user'  -- 'user' | 'assistant'
  - `content` text not null
  - `created_at` timestamptz default now()
- RLS (owner‑based over `user_id`).

## Analysis Metadata (nutrition_intake.metadata)

The app stores AI analysis details as JSON for traceability. Suggested shape:

```json
{
  "reasoning": "string",
  "confidence_level": "low|medium|high",
  "meal_quality": { "balance_score": 0, "notes": "string" },
  "macros": {
    "protein_g": 0, "carbs_g": 0, "fat_g": 0,
    "sugar_g": 0, "fiber_g": 0, "saturated_fat_g": 0, "sodium_mg": 0
  },
  "items": [
    {
      "name": "string",
      "portion_size": "string",
      "calories": 0,
      "macros": {
        "protein_g": 0, "carbs_g": 0, "fat_g": 0,
        "sugar_g": 0, "fiber_g": 0, "saturated_fat_g": 0, "sodium_mg": 0
      }
    }
  ]
}
```

## Suggested RLS Policies (Owner‑Based)

For each user‑owned table above:

```sql
alter table public.<table> enable row level security;
create policy "Select own" on public.<table> for select using (auth.uid() = user_id);
create policy "Insert own" on public.<table> for insert with check (auth.uid() = user_id);
create policy "Update own" on public.<table> for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own" on public.<table> for delete using (auth.uid() = user_id);
```

Ensure `user_id` exists on the table (`uuid` referencing `auth.users(id)`), plus helpful indexes:

```sql
-- Common pattern
alter table public.<table> add column if not exists user_id uuid references auth.users(id) on delete cascade;
create index if not exists <table>_user_idx on public.<table>(user_id);
```

## Admin Workflows (What Your CMS Should Do)

### Users
- Search users by email; view `user_identity`.
- Edit profile details (name, age, gender, height, weight, activity_level, diet_type, macros).
- Link/unlink plan IDs (exercise_id, relax_id) if needed.

### Plans
- Workout Plan: CRUD rows per day; mark `finished` if supporting completion tracking.
- Relax Plan: CRUD rows per day (`title`, `description`, `relaxation_type`).
- Meal Plan: 1 row/day; edit `meals`/`snacks` JSON. Provide a JSON editor and form helpers.
- Optionally provide global templates (`user_id = null`) that the app can read as fallbacks.

### Nutrition
- Goal History: review audit trail; optionally add admin adjustments.
- Intake: view and correct `nutrition_intake` rows; inspect `metadata` (AI analysis).

### Habits
- Read/adjust daily snapshots in `habit` for support cases (e.g., device sync issues).

### Relax Sessions
- Read user logs; aggregate minutes by day/week.

### Chat
- List messages by user; filter by `role`; allow delete for moderation.

## JSON Field Guidance

- `meal_plan.meals`: keep a consistent structure. For a simple text list, strings are accepted; for richer display use a map with `name`, optional `calories`, `items` (array), `description`.
- `nutrition_intake.metadata`: keep keys stable; the app gracefully ignores unknown keys.

## Environment & Config

- App .env (mobile):
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`
  - `CHAT_SERVER` (full URL for chat API)
  - `FOOD_SERVER` (full URL for calorie analyzer)
- CMS (server): use Supabase service‑role key to bypass RLS; do not expose it client‑side.
- Supabase Auth: whitelist CMS origin for OAuth if needed.

## Minimal SQL Snippets (from app hints)

Relax Sessions
```sql
create table if not exists public.relax_sessions (
  id bigint generated by default as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  minutes integer not null check (minutes >= 0),
  pattern text,
  mood text,
  created_at timestamptz not null default now()
);
create index if not exists relax_sessions_user_date on public.relax_sessions(user_id, started_at);
```

Meal Plan
```sql
create table if not exists public.meal_plan (
  id bigint generated by default as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  day_index int not null,
  day_label text,
  meals jsonb not null,
  snacks jsonb,
  created_at timestamptz not null default now()
);
```

Habit
```sql
create table if not exists public.habit (
  id bigint generated by default as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  bucket_date date not null,
  steps integer,
  calories integer,
  standing_time_minutes integer,
  sleep_hours numeric(4,1),
  standing_minutes integer,
  heart_rate_avg integer,
  sleep_start_time time,
  created_at timestamptz not null default now()
);
create unique index if not exists habit_unique_user_date on public.habit (user_id, bucket_date);
```

Nutrition Intake
```sql
create table if not exists public.nutrition_intake (
  id bigint generated by default as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  bucket_date date not null,
  energy_kcal double precision not null default 0,
  carbs_g double precision,
  protein_g double precision,
  fat_g double precision,
  sugar_g double precision,
  source text default 'manual',
  metadata jsonb,
  created_at timestamptz not null default now()
);
create index if not exists nutrition_intake_user_date on public.nutrition_intake(user_id, bucket_date);
```

Nutrition Goal History
```sql
create table if not exists public.nutrition_goal_history (
  id bigint generated by default as identity primary key,
  user_id uuid references auth.users(id) on delete cascade,
  goal text not null check (goal in ('lose','maintain','gain')),
  delta_percent int not null check (delta_percent in (10,15,20)),
  calories_target int,
  carbs_g double precision,
  protein_g double precision,
  fat_g double precision,
  sugar_g double precision,
  created_at timestamptz not null default now()
);
```

Messages (suggested)
```sql
create table if not exists public.messages (
  id bigint generated by default as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'user',
  content text not null,
  created_at timestamptz not null default now()
);
create index if not exists messages_user_created on public.messages(user_id, created_at);
```

> Note: `workout_plan` and `relax_plan` schemas should include `user_id` and the columns the app reads above. Add owner‑based RLS.

## Building the CMS UI

- Entities: Users, Workout Plan, Relax Plan, Meal Plan, Nutrition Intake, Nutrition Goals, Habits, Relax Sessions, Chat Messages.
- UX tips:
  - Provide JSON editors with validation for `meals`, `snacks`, and `metadata`.
  - Show “as user” previews (e.g., how a day renders in app).
  - Batch operations: clone a week’s plan to another user; mark all day items finished.
  - Safeguards: confirm destructive actions; show RLS state.

If you need a seed SQL or want me to generate migrations for your Supabase project, let me know your preferences and I can tailor a `supabase` migration set from this spec.

