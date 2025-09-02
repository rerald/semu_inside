-- 문제 태그 시스템 구축
-- 기존 questions 테이블의 tags TEXT[] 컬럼을 정규화된 관계형 구조로 변경

-- 1) question_tags 테이블 생성 (문제-태그 다대다 관계)
create table if not exists public.question_tags (
  id uuid primary key default uuid_generate_v4(),
  question_id uuid not null references public.questions(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamp with time zone default now(),
  unique(question_id, tag_id)
);

create index if not exists idx_question_tags_question on public.question_tags (question_id);
create index if not exists idx_question_tags_tag on public.question_tags (tag_id);

-- 2) 기존 questions.tags 배열 데이터를 정규화된 구조로 마이그레이션
-- (선택사항: 기존 데이터가 있는 경우에만 실행)
/*
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
CROSS JOIN unnest(q.tags) as tag_name
JOIN tags t ON t.name = tag_name
ON CONFLICT (question_id, tag_id) DO NOTHING;
*/

-- 3) (선택사항) 마이그레이션 완료 후 기존 tags 컬럼 제거
-- ALTER TABLE questions DROP COLUMN IF EXISTS tags;

-- 4) RLS 정책 (필요시)
-- alter table public.question_tags enable row level security;
-- create policy "Allow authenticated read question_tags" on public.question_tags for select using (auth.role() = 'authenticated');
-- create policy "Allow admin manage question_tags" on public.question_tags for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','super_admin')));
