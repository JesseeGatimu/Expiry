-- Run this file once in the Supabase SQL Editor for this project.
-- It creates a password-free, shared-shop model protected by Row Level Security.

create extension if not exists pgcrypto with schema extensions;

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 80),
  join_code_hash text not null,
  created_at timestamptz not null default now()
);

create table public.shop_members (
  shop_id uuid not null references public.shops(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 40),
  joined_at timestamptz not null default now(),
  primary key (shop_id, user_id),
  unique (user_id)
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 60),
  removal_days integer not null check (removal_days >= 0 and removal_days <= 365),
  created_at timestamptz not null default now(),
  unique (shop_id, name)
);

create type public.product_status as enum ('active', 'sold', 'removed', 'expired');

create table public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  name text not null check (char_length(trim(name)) between 1 and 120),
  size text not null check (char_length(trim(size)) between 1 and 40),
  expiry_date date not null,
  original_removal_date date not null,
  current_removal_date date not null,
  extension_days integer not null default 0 check (extension_days >= 0),
  status public.product_status not null default 'active',
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_events (
  id bigint generated always as identity primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  actor_id uuid not null default auth.uid() references auth.users(id),
  event_type text not null check (event_type in ('created', 'sold', 'removed', 'extended')),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index products_shop_status_removal_idx
  on public.products (shop_id, status, current_removal_date);

alter table public.shops enable row level security;
alter table public.shop_members enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_events enable row level security;

create policy "Members can read their membership"
  on public.shop_members for select to authenticated
  using (user_id = auth.uid());

create policy "Members can read their shop"
  on public.shops for select to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = shops.id and m.user_id = auth.uid()));

create policy "Shop members can read categories"
  on public.categories for select to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = categories.shop_id and m.user_id = auth.uid()));
create policy "Shop members can add categories"
  on public.categories for insert to authenticated
  with check (exists (select 1 from public.shop_members m
    where m.shop_id = categories.shop_id and m.user_id = auth.uid()));
create policy "Shop members can update categories"
  on public.categories for update to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = categories.shop_id and m.user_id = auth.uid()))
  with check (exists (select 1 from public.shop_members m
    where m.shop_id = categories.shop_id and m.user_id = auth.uid()));
create policy "Shop members can delete categories"
  on public.categories for delete to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = categories.shop_id and m.user_id = auth.uid()));

create policy "Shop members can read products"
  on public.products for select to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = products.shop_id and m.user_id = auth.uid()));
create policy "Shop members can add products"
  on public.products for insert to authenticated
  with check (exists (select 1 from public.shop_members m
    where m.shop_id = products.shop_id and m.user_id = auth.uid()));
create policy "Shop members can update products"
  on public.products for update to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = products.shop_id and m.user_id = auth.uid()))
  with check (exists (select 1 from public.shop_members m
    where m.shop_id = products.shop_id and m.user_id = auth.uid()));

create policy "Shop members can read product events"
  on public.product_events for select to authenticated
  using (exists (select 1 from public.shop_members m
    where m.shop_id = product_events.shop_id and m.user_id = auth.uid()));
create policy "Shop members can write product events"
  on public.product_events for insert to authenticated
  with check (actor_id = auth.uid() and exists (select 1 from public.shop_members m
    where m.shop_id = product_events.shop_id and m.user_id = auth.uid()));

create or replace function public.create_shop(
  p_shop_name text, p_join_code text, p_display_name text
) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare v_shop_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  if char_length(trim(p_join_code)) < 6 then
    raise exception 'The shop code must be at least 6 characters';
  end if;
  insert into public.shops (name, join_code_hash)
  values (trim(p_shop_name), extensions.crypt(p_join_code, extensions.gen_salt('bf')))
  returning id into v_shop_id;
  insert into public.shop_members (shop_id, user_id, display_name)
  values (v_shop_id, auth.uid(), trim(p_display_name));
  return v_shop_id;
end;
$$;

create or replace function public.join_shop(
  p_join_code text, p_display_name text
) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare v_shop_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in is required'; end if;
  select id into v_shop_id from public.shops
  where extensions.crypt(p_join_code, join_code_hash) = join_code_hash;
  if v_shop_id is null then raise exception 'That shop code is not valid'; end if;
  insert into public.shop_members (shop_id, user_id, display_name)
  values (v_shop_id, auth.uid(), trim(p_display_name));
  return v_shop_id;
end;
$$;

grant execute on function public.create_shop(text, text, text) to authenticated;
grant execute on function public.join_shop(text, text) to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update on public.products to authenticated;
grant select, insert on public.product_events to authenticated;

alter publication supabase_realtime add table public.categories, public.products;
