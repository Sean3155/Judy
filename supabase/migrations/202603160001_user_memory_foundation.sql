-- User-scoped long-term memory foundation for Judy

create table if not exists public.user_memory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  key text not null,
  value jsonb not null,
  confidence numeric(4,3) not null default 0.50 check (confidence >= 0 and confidence <= 1),
  status text not null default 'tentative' check (status in ('confirmed_memory', 'tentative_memory', 'session_only', 'discard')),
  source_type text not null default 'inferred_episode',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_reinforced_at timestamptz not null default now(),
  expires_at timestamptz,
  sensitivity_level text,
  constraint user_memory_items_unique_user_fact unique (user_id, category, key, value)
);

create table if not exists public.user_memory_profile (
  user_id uuid primary key references auth.users(id) on delete cascade,
  style_summary text,
  wardrobe_summary text,
  weather_behavior_summary text,
  outing_context_summary text,
  updated_at timestamptz not null default now()
);

create index if not exists user_memory_items_user_status_idx
  on public.user_memory_items (user_id, status, last_reinforced_at desc);

create index if not exists user_memory_items_expires_idx
  on public.user_memory_items (expires_at)
  where expires_at is not null;

create index if not exists user_memory_items_user_category_idx
  on public.user_memory_items (user_id, category);

create or replace function public.set_current_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_memory_items_updated_at on public.user_memory_items;
create trigger set_user_memory_items_updated_at
before update on public.user_memory_items
for each row
execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_user_memory_profile_updated_at on public.user_memory_profile;
create trigger set_user_memory_profile_updated_at
before update on public.user_memory_profile
for each row
execute function public.set_current_timestamp_updated_at();

alter table public.user_memory_items enable row level security;
alter table public.user_memory_profile enable row level security;

drop policy if exists "Users can select own memory items" on public.user_memory_items;

create policy "Users can select own memory items"
on public.user_memory_items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own memory items" on public.user_memory_items;

create policy "Users can insert own memory items"
on public.user_memory_items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own memory items" on public.user_memory_items;

create policy "Users can update own memory items"
on public.user_memory_items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own memory items" on public.user_memory_items;

create policy "Users can delete own memory items"
on public.user_memory_items
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can select own memory profile" on public.user_memory_profile;

create policy "Users can select own memory profile"
on public.user_memory_profile
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own memory profile" on public.user_memory_profile;

create policy "Users can insert own memory profile"
on public.user_memory_profile
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own memory profile" on public.user_memory_profile;

create policy "Users can update own memory profile"
on public.user_memory_profile
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
