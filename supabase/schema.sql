-- SoleTrade — schemat bazy danych Supabase (Postgres) + RLS
-- Uruchom w SQL Editor projektu Supabase (lub przez `supabase db push`).

create extension if not exists "uuid-ossp";

-- =========================================================
-- PROFILES
-- =========================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  avatar_url text,
  rating_score numeric(3, 2) not null default 0,
  total_sold integer not null default 0,
  bio text,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles są publicznie widoczne"
  on public.profiles for select
  using (true);

create policy "Użytkownik edytuje tylko swój profil"
  on public.profiles for update
  using (auth.uid() = id);

-- Trigger: automatycznie tworzy profil po rejestracji nowego użytkownika.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =========================================================
-- CATEGORIES
-- =========================================================
create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  icon_url text
);

alter table public.categories enable row level security;

create policy "Kategorie są publicznie widoczne"
  on public.categories for select
  using (true);

insert into public.categories (name, icon_url) values
  ('Stopki', null),
  ('Skarpetki', null),
  ('Zakolanówki', null),
  ('Sportowe', null),
  ('Rajstopy', null)
on conflict (name) do nothing;

-- =========================================================
-- PRODUCTS
-- =========================================================
create table if not exists public.products (
  id uuid primary key default uuid_generate_v4(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid references public.categories (id) on delete set null,
  title text not null,
  description text not null default '',
  price numeric(10, 2) not null check (price >= 0),
  condition_days integer not null default 0,
  size text not null default '',
  material text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'active', 'sold', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "Aktywne oferty są publicznie widoczne, sprzedawca widzi swoje"
  on public.products for select
  using (status = 'active' or seller_id = auth.uid());

create policy "Zalogowany użytkownik może dodać ofertę"
  on public.products for insert
  with check (seller_id = auth.uid());

create policy "Sprzedawca edytuje tylko swoje oferty"
  on public.products for update
  using (seller_id = auth.uid());

create policy "Sprzedawca usuwa tylko swoje oferty"
  on public.products for delete
  using (seller_id = auth.uid());

create policy "Moderator widzi wszystkie oferty"
  on public.products for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('moderator', 'admin')
    )
  );

create policy "Moderator aktualizuje status dowolnej oferty"
  on public.products for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('moderator', 'admin')
    )
  );

-- =========================================================
-- PRODUCT IMAGES
-- =========================================================
create table if not exists public.product_images (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references public.products (id) on delete cascade,
  image_url text not null,
  is_main boolean not null default false
);

alter table public.product_images enable row level security;

create policy "Zdjęcia widoczne razem z produktem"
  on public.product_images for select
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and (p.status = 'active' or p.seller_id = auth.uid())
    )
  );

create policy "Sprzedawca zarządza zdjęciami swoich ofert"
  on public.product_images for all
  using (
    exists (select 1 from public.products p where p.id = product_id and p.seller_id = auth.uid())
  )
  with check (
    exists (select 1 from public.products p where p.id = product_id and p.seller_id = auth.uid())
  );

-- =========================================================
-- CHATS
-- =========================================================
create table if not exists public.chats (
  id uuid primary key default uuid_generate_v4(),
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (buyer_id, seller_id, product_id)
);

alter table public.chats enable row level security;

create policy "Użytkownik widzi tylko swoje czaty"
  on public.chats for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "Kupujący zakłada czat ze sprzedawcą"
  on public.chats for insert
  with check (auth.uid() = buyer_id);

-- =========================================================
-- MESSAGES
-- =========================================================
create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  chat_id uuid not null references public.chats (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  text text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "Wiadomości widoczne tylko w swoich czatach"
  on public.messages for select
  using (
    exists (
      select 1 from public.chats c
      where c.id = chat_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

create policy "Wysyłanie wiadomości tylko we własnym czacie"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.chats c
      where c.id = chat_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

create policy "Odbiorca może oznaczyć wiadomość jako przeczytaną"
  on public.messages for update
  using (
    exists (
      select 1 from public.chats c
      where c.id = chat_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

alter publication supabase_realtime add table public.messages;

-- =========================================================
-- TRANSACTIONS
-- =========================================================
create table if not exists public.transactions (
  id uuid primary key default uuid_generate_v4(),
  buyer_id uuid not null references public.profiles (id),
  seller_id uuid not null references public.profiles (id),
  product_id uuid not null references public.products (id),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'shipped', 'completed', 'cancelled')),
  stripe_payment_id text,
  created_at timestamptz not null default now()
);

alter table public.transactions enable row level security;

create policy "Strony transakcji widzą tylko swoje transakcje"
  on public.transactions for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "Kupujący tworzy transakcję"
  on public.transactions for insert
  with check (auth.uid() = buyer_id);

-- =========================================================
-- USER DEVICES (FCM)
-- =========================================================
create table if not exists public.user_devices (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  fcm_token text not null,
  device_type text not null check (device_type in ('ios', 'android', 'web')),
  created_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

alter table public.user_devices enable row level security;

create policy "Użytkownik zarządza tylko swoimi urządzeniami"
  on public.user_devices for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =========================================================
-- FOLLOWS — obserwowani sprzedający
-- =========================================================
create table if not exists public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followed_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

alter table public.follows enable row level security;

create policy "Użytkownik widzi kogo obserwuje i kto go obserwuje"
  on public.follows for select
  using (auth.uid() = follower_id or auth.uid() = followed_id);

create policy "Użytkownik zaczyna obserwować"
  on public.follows for insert
  with check (auth.uid() = follower_id);

create policy "Użytkownik przestaje obserwować"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- =========================================================
-- STORAGE — bucket na zdjęcia produktów i avatary
-- =========================================================
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "Zdjęcia produktów są publicznie widoczne"
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy "Zalogowany użytkownik może wgrywać zdjęcia"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and auth.role() = 'authenticated');

create policy "Właściciel pliku może go usunąć"
  on storage.objects for delete
  using (bucket_id = 'product-images' and owner = auth.uid());
