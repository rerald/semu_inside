-- 데이터베이스 스키마 강제 업데이트 스크립트
-- Supabase SQL 에디터에서 실행하세요

-- 1. 현재 테이블 구조 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
ORDER BY ordinal_position;

-- 2. AI 채점 관련 컬럼 강제 추가/수정
-- ai_graded 컬럼
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'ai_graded 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'ai_graded 컬럼 이미 존재함';
    END IF;
END $$;

-- ai_graded_at 컬럼
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_at') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'ai_graded_at 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'ai_graded_at 컬럼 이미 존재함';
    END IF;
END $$;

-- feedback 컬럼
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'feedback') THEN
        ALTER TABLE exam_answers ADD COLUMN feedback TEXT;
        RAISE NOTICE 'feedback 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'feedback 컬럼 이미 존재함';
    END IF;
END $$;

-- 3. graded_by 컬럼 타입 강제 변경
DO $$ 
BEGIN
    -- graded_by 컬럼이 UUID 타입이면 TEXT로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'exam_answers' 
               AND column_name = 'graded_by' 
               AND data_type = 'uuid') THEN
        
        -- 기존 데이터 백업 (필요시)
        -- CREATE TABLE exam_answers_backup AS SELECT * FROM exam_answers;
        
        -- 컬럼 타입 변경
        ALTER TABLE exam_answers ALTER COLUMN graded_by TYPE TEXT USING graded_by::text;
        RAISE NOTICE 'graded_by 컬럼을 UUID에서 TEXT로 변경함';
        
    ELSE
        RAISE NOTICE 'graded_by 컬럼이 이미 TEXT 타입이거나 존재하지 않음';
    END IF;
END $$;

-- 4. graded_by 컬럼이 없으면 추가
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'graded_by') THEN
        ALTER TABLE exam_answers ADD COLUMN graded_by TEXT;
        RAISE NOTICE 'graded_by 컬럼 추가됨';
    ELSE
        RAISE NOTICE 'graded_by 컬럼 이미 존재함';
    END IF;
END $$;

-- 5. points 컬럼 NULL 허용
ALTER TABLE exam_answers ALTER COLUMN points DROP NOT NULL;

-- 6. 기본값 설정
UPDATE exam_answers SET ai_graded = FALSE WHERE ai_graded IS NULL;

-- 7. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_graded ON exam_answers(ai_graded);
CREATE INDEX IF NOT EXISTS idx_exam_answers_question_id ON exam_answers(question_id);

-- 8. 최종 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
AND column_name IN ('ai_graded', 'ai_graded_at', 'feedback', 'graded_by', 'points')
ORDER BY column_name;

-- 9. 테스트 데이터 확인
SELECT 
    id,
    points,
    ai_graded,
    ai_graded_at,
    feedback,
    graded_by,
    created_at
FROM exam_answers 
LIMIT 3;
