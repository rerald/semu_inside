-- Adds tagging capability for users
-- Run this once in your Supabase (or psql) environment

-- 1) tags master table
create table if not exists public.tags (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  created_at timestamp with time zone default now()
);

create index if not exists idx_tags_name on public.tags (lower(name));

-- 2) user_tags: many-to-many between profiles and tags
create table if not exists public.user_tags (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamp with time zone default now(),
  unique(user_id, tag_id)
);

create index if not exists idx_user_tags_user on public.user_tags (user_id);
create index if not exists idx_user_tags_tag on public.user_tags (tag_id);

-- 3) (optional) RLS policies can be added according to your security model.
-- For example, allow admins to manage tags; read access for authenticated users:
-- alter table public.tags enable row level security;
-- alter table public.user_tags enable row level security;
-- create policy "Allow read tags" on public.tags for select using (auth.role() = 'authenticated');
-- create policy "Allow admin manage tags" on public.tags for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','super_admin')));
-- Repeat similar policies for public.user_tags.

