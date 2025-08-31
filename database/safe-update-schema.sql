-- AI 채점 기능 안전한 스키마 업데이트 스크립트
-- 외래키 제약조건을 유지하면서 AI 채점 기능 추가
-- Supabase SQL 에디터에서 실행하세요

-- 1. 현재 테이블 구조 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    CASE 
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN 'FK: ' || ccu.table_name || '.' || ccu.column_name
        ELSE NULL 
    END as foreign_key_info
FROM information_schema.columns c
LEFT JOIN information_schema.table_constraints tc ON c.table_name = tc.table_name
LEFT JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE c.table_name = 'exam_answers' 
ORDER BY c.ordinal_position;

-- 2. AI 채점 전용 컬럼 추가 (기존 graded_by는 유지)
DO $$ 
BEGIN
    -- ai_graded 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'ai_graded 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'ai_graded 컬럼 이미 존재함';
    END IF;
    
    -- ai_graded_at 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_at') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'ai_graded_at 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'ai_graded_at 컬럼 이미 존재함';
    END IF;
    
    -- feedback 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'feedback') THEN
        ALTER TABLE exam_answers ADD COLUMN feedback TEXT;
        RAISE NOTICE 'feedback 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'feedback 컬럼 이미 존재함';
    END IF;
    
    -- ai_graded_by 컬럼 추가 (AI 채점 전용, TEXT 타입)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_by') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_by TEXT;
        RAISE NOTICE 'ai_graded_by 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'ai_graded_by 컬럼 이미 존재함';
    END IF;
END $$;

-- 3. points 컬럼 NULL 허용
ALTER TABLE exam_answers ALTER COLUMN points DROP NOT NULL;

-- 4. 기본값 설정
UPDATE exam_answers SET ai_graded = FALSE WHERE ai_graded IS NULL;

-- 5. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_graded ON exam_answers(ai_graded);
CREATE INDEX IF NOT EXISTS idx_exam_answers_question_id ON exam_answers(question_id);

-- 6. 컬럼 설명 추가
COMMENT ON COLUMN exam_answers.ai_graded IS 'AI 채점 여부';
COMMENT ON COLUMN exam_answers.ai_graded_at IS 'AI 채점 완료 시간';
COMMENT ON COLUMN exam_answers.feedback IS '채점 피드백 (AI 또는 수동)';
COMMENT ON COLUMN exam_answers.ai_graded_by IS 'AI 채점 시스템 구분 (ai: AI 채점, manual: 수동 채점)';
COMMENT ON COLUMN exam_answers.graded_by IS '수동 채점자 ID (profiles 테이블 참조, UUID)';

-- 7. 최종 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
AND column_name IN ('ai_graded', 'ai_graded_at', 'feedback', 'ai_graded_by', 'graded_by', 'points')
ORDER BY column_name;

-- 8. 테스트 데이터 확인
SELECT 
    id,
    points,
    ai_graded,
    ai_graded_at,
    feedback,
    ai_graded_by,
    graded_by,
    created_at
FROM exam_answers 
LIMIT 3;

-- 9. 외래키 제약조건 확인
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'exam_answers' AND tc.constraint_type = 'FOREIGN KEY';

