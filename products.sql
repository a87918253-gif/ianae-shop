-- =======================================================
-- 이안애(E-安愛) 상품 테이블 만들기 + 상품 6개 넣기
--
-- 쓰는 방법
--   1. supabase.com 에 로그인해서 프로젝트를 고릅니다
--   2. 왼쪽 메뉴에서 SQL Editor 를 누릅니다
--   3. 이 파일 내용을 통째로 붙여넣습니다
--   4. 오른쪽 아래 RUN 을 누릅니다
--
-- 여러 번 실행해도 안전합니다 (기존 내용을 덮어씁니다)
-- =======================================================


-- ===== 1. 상품 표 만들기 =====
create table if not exists public.products (
  id          bigint generated always as identity primary key,

  name        text    not null,          -- 상품 이름
  category    text    not null,          -- 'home'(주거용) 또는 'gym'(체육관용)
  cat_label   text,                      -- 카드에 작게 뜨는 글자 (예: 층간소음)

  old_price   integer not null,          -- 할인 전 가격
  price       integer not null,          -- 파는 가격
  unit        text    default '㎡',      -- 가격 단위

  benefit     text,                      -- 카드에 들어가는 한 줄 설명
  ship        text,                      -- 배송·시공 안내
  badge       text,                      -- 'BEST' / '인기' / 없으면 비움
  photo_url   text,                      -- 상품 사진 주소

  rating      numeric(2,1),              -- 별점 (예: 4.9)
  review_cnt  integer,                   -- 후기 수
  sort_order  integer default 0,         -- 화면에 보여줄 순서
  is_active   boolean default true,      -- false 로 바꾸면 화면에서 숨겨집니다

  created_at  timestamptz default now()
);

-- 같은 이름이 두 번 들어가지 않게 합니다 (다시 실행해도 안전하도록)
create unique index if not exists products_name_key on public.products (name);


-- ===== 2. 보안 설정 (RLS) =====
-- 이게 없으면 주소만 아는 사람이 상품을 지우거나 가격을 바꿀 수 있습니다.
alter table public.products enable row level security;

-- 누구나 '읽기'만 됩니다. 쓰기·수정·삭제 규칙은 만들지 않았으므로 전부 막힙니다.
drop policy if exists "상품은 누구나 볼 수 있습니다" on public.products;

create policy "상품은 누구나 볼 수 있습니다"
  on public.products
  for select
  to anon, authenticated
  using (is_active = true);


-- ===== 3. 상품 6개 넣기 =====
-- 이미 있는 이름이면 내용만 새로 덮어씁니다.
insert into public.products
  (name, category, cat_label, old_price, price, benefit, ship, badge, photo_url, rating, review_cnt, sort_order)
values
  ('EVA 고밀도 층간소음 매트 10mm', 'home', '층간소음',
   39000, 26900,
   '아이 발소리가 아랫집까지 가지 않게. 물걸레로 쓱 닦이는 표면입니다.',
   '무료배송 · 오늘 출발', '인기',
   'https://images.pexels.com/photos/17181935/pexels-photo-17181935.jpeg?auto=compress&cs=tinysrgb&w=900',
   4.9, 1284, 1),

  ('TPE 프리미엄 홈짐 매트 15mm', 'home', '홈트레이닝',
   68000, 47600,
   '덤벨을 내려놔도 조용합니다. 중량 충격음 최대 28dB 감소.',
   '무료배송 · 오늘 출발', null,
   'https://images.pexels.com/photos/6752163/pexels-photo-6752163.jpeg?auto=compress&cs=tinysrgb&w=900',
   4.8, 612, 2),

  ('체육관용 PVC 탄성 바닥재 4.5mm', 'gym', '체육관 전용',
   125000, 98000,
   '무릎에 부담이 적은 탄성층. 실내 코트에 쓰이는 등급입니다.',
   '무료 실측 · 전문 시공', null,
   'https://images.pexels.com/photos/5407033/pexels-photo-5407033.jpeg?auto=compress&cs=tinysrgb&w=900',
   4.7, 208, 3),

  ('오크 헤링본 강마루 7.5mm', 'home', '거실 마루',
   89000, 62300,
   '거실이 두 배로 넓어 보입니다. 긁힘에 강해 오래 씁니다.',
   '무료 실측 · 시공비 포함', 'BEST',
   'https://images.pexels.com/photos/129731/pexels-photo-129731.jpeg?auto=compress&cs=tinysrgb&w=900',
   5.0, 947, 4),

  ('아이 안심 친환경 장판 6mm', 'home', '아이 방',
   54000, 37800,
   '푹신해서 넘어져도 덜 아픕니다. 크레파스 자국도 잘 지워집니다.',
   '무료배송 · 오늘 출발', 'BEST',
   'https://images.pexels.com/photos/4544598/pexels-photo-4544598.jpeg?auto=compress&cs=tinysrgb&w=900',
   4.9, 1536, 5),

  ('태권도 퍼즐 매트 25mm (홍청)', 'gym', '도장 · 학원',
   32000, 23900,
   '끼워 맞추기만 하면 끝. 한 장씩 빼서 세척할 수 있습니다.',
   '무료배송 · 오늘 출발', null,
   'https://images.pexels.com/photos/7045594/pexels-photo-7045594.jpeg?auto=compress&cs=tinysrgb&w=900',
   4.7, 431, 6)

on conflict (name) do update set
  category   = excluded.category,
  cat_label  = excluded.cat_label,
  old_price  = excluded.old_price,
  price      = excluded.price,
  benefit    = excluded.benefit,
  ship       = excluded.ship,
  badge      = excluded.badge,
  photo_url  = excluded.photo_url,
  rating     = excluded.rating,
  review_cnt = excluded.review_cnt,
  sort_order = excluded.sort_order;


-- ===== 4. 잘 들어갔는지 확인 =====
select sort_order, name, category, old_price, price, badge
from public.products
order by sort_order;


-- =======================================================
-- 참고
--
-- 별점(rating)과 후기 수(review_cnt)는 지금 예시 값입니다.
-- 실제 후기를 받으시면 그 숫자로 바꿔 주세요.
--
-- 상품을 화면에서 잠시 내리고 싶으시면 지우지 마시고
-- is_active 를 false 로 바꾸세요.
--   update public.products set is_active = false where name = '상품이름';
-- =======================================================
