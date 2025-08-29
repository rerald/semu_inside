-- 시험지 삭제 시 연관 데이터 자동 삭제를 위한 CASCADE 설정
-- 이 스크립트는 기존 외래키 제약조건을 CASCADE 삭제로 변경합니다.

-- 1단계: 기존 외래키 제약조건 삭제
ALTER TABLE public.exam_sessions 
DROP CONSTRAINT IF EXISTS exam_sessions_exam_id_fkey;

ALTER TABLE public.exam_permissions 
DROP CONSTRAINT IF EXISTS exam_permissions_exam_id_fkey;

ALTER TABLE public.exam_questions 
DROP CONSTRAINT IF EXISTS exam_questions_exam_id_fkey;

-- 2단계: CASCADE 삭제가 포함된 새로운 외래키 제약조건 생성
ALTER TABLE public.exam_sessions 
ADD CONSTRAINT exam_sessions_exam_id_fkey 
FOREIGN KEY (exam_id) 
REFERENCES public.exams(id) 
ON DELETE CASCADE;

ALTER TABLE public.exam_permissions 
ADD CONSTRAINT exam_permissions_exam_id_fkey 
FOREIGN KEY (exam_id) 
REFERENCES public.exams(id) 
ON DELETE CASCADE;

ALTER TABLE public.exam_questions 
ADD CONSTRAINT exam_questions_exam_id_fkey 
FOREIGN KEY (exam_id) 
REFERENCES public.exams(id) 
ON DELETE CASCADE;

-- 3단계: 변경사항 확인
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name IN ('exam_sessions', 'exam_permissions', 'exam_questions')
    AND ccu.table_name = 'exams';

-- 4단계: CASCADE 삭제 테스트 (선택사항)
-- 실제 삭제를 원하지 않는다면 이 부분은 실행하지 마세요
-- DELETE FROM exams WHERE id = '7f4e33fd-3c9f-41ab-b51f-b82fb303ae8b';
