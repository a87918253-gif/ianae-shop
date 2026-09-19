-- =======================================================
-- 이안애(E-安愛) 장바구니 표 만들기
--
-- 로그인한 회원의 장바구니를 서버에 저장합니다.
-- 그래야 컴퓨터에서 담은 것을 휴대폰에서도 볼 수 있습니다.
--
-- 쓰는 방법
--   supabase.com -> SQL Editor -> 붙여넣기 -> RUN
--   여러 번 실행해도 안전합니다.
-- =======================================================


-- ===== 1. 장바구니 표 =====
create table if not exists public.cart_items (
  id            bigint generated always as identity primary key,

  -- 누구의 장바구니인지 (회원이 탈퇴하면 함께 지워집니다)
  user_id       uuid not null references auth.users(id) on delete cascade,

  product_name  text    not null,                  -- 담은 상품 이름
  price         integer not null,                  -- 담을 때의 가격
  qty           integer not null default 1,        -- 개수
  added_date    date    not null default current_date,  -- 담은 날짜

  created_at    timestamptz default now(),

  -- 같은 사람이 같은 날 같은 상품을 담으면 줄을 늘리지 않고 개수만 올립니다
  unique (user_id, product_name, added_date)
);

-- 내 장바구니를 빨리 찾기 위한 색인
create index if not exists cart_items_user_idx on public.cart_items (user_id, added_date desc);


-- ===== 2. 보안 설정 (RLS) =====
-- 이게 없으면 남의 장바구니를 들여다보거나 지울 수 있습니다.
alter table public.cart_items enable row level security;

drop policy if exists "내 장바구니만 봅니다"    on public.cart_items;
drop policy if exists "내 장바구니만 담습니다"  on public.cart_items;
drop policy if exists "내 장바구니만 고칩니다"  on public.cart_items;
drop policy if exists "내 장바구니만 지웁니다"  on public.cart_items;

-- 읽기: 내 것만
create policy "내 장바구니만 봅니다"
  on public.cart_items for select
  to authenticated
  using (auth.uid() = user_id);

-- 담기: 내 이름으로만
create policy "내 장바구니만 담습니다"
  on public.cart_items for insert
  to authenticated
  with check (auth.uid() = user_id);

-- 개수 바꾸기: 내 것만
create policy "내 장바구니만 고칩니다"
  on public.cart_items for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 빼기: 내 것만
create policy "내 장바구니만 지웁니다"
  on public.cart_items for delete
  to authenticated
  using (auth.uid() = user_id);


-- ===== 3. 확인 =====
select
  (select count(*) from public.cart_items) as 담긴줄수,
  (select count(*) from pg_policies where tablename = 'cart_items') as 보안규칙수;


-- =======================================================
-- 참고
--
-- 로그인하지 않은 손님의 장바구니는 서버에 담지 않습니다.
-- 그 경우에는 예전처럼 그 브라우저에만 저장됩니다.
--
-- 로그인하시면, 로그인 전에 담아둔 것이 서버로 함께 옮겨집니다.
-- =======================================================
