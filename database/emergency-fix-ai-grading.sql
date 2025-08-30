-- AI 채점 문제 긴급 수정 스크립트
-- Supabase SQL 에디터에서 실행하세요

-- 1. AI 채점 관련 컬럼 추가 (IF NOT EXISTS로 안전하게)
DO $$ 
BEGIN
    -- ai_graded 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'ai_graded 컬럼이 추가되었습니다.';
    ELSE
        RAISE NOTICE 'ai_graded 컬럼이 이미 존재합니다.';
    END IF;
    
    -- ai_graded_at 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_at') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'ai_graded_at 컬럼이 추가되었습니다.';
    ELSE
        RAISE NOTICE 'ai_graded_at 컬럼이 이미 존재합니다.';
    END IF;
    
    -- feedback 컬럼 추가
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'feedback') THEN
        ALTER TABLE exam_answers ADD COLUMN feedback TEXT;
        RAISE NOTICE 'feedback 컬럼이 추가되었습니다.';
    ELSE
        RAISE NOTICE 'feedback 컬럼이 이미 존재합니다.';
    END IF;
    
    -- graded_by 컬럼 타입 확인 및 수정
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'exam_answers' AND column_name = 'graded_by') THEN
        -- graded_by 컬럼이 UUID 타입인지 확인
        IF (SELECT data_type FROM information_schema.columns 
            WHERE table_name = 'exam_answers' AND column_name = 'graded_by') = 'uuid' THEN
            -- UUID 타입이면 TEXT로 변경 (AI 채점을 위해)
            ALTER TABLE exam_answers ALTER COLUMN graded_by TYPE TEXT;
            RAISE NOTICE 'graded_by 컬럼을 TEXT 타입으로 변경했습니다.';
        ELSE
            RAISE NOTICE 'graded_by 컬럼이 이미 TEXT 타입입니다.';
        END IF;
    ELSE
        -- graded_by 컬럼이 없으면 추가
        ALTER TABLE exam_answers ADD COLUMN graded_by TEXT;
        RAISE NOTICE 'graded_by 컬럼을 TEXT 타입으로 추가했습니다.';
    END IF;
    
END $$;

-- 2. 기존 데이터에 대한 기본값 설정
UPDATE exam_answers 
SET ai_graded = FALSE 
WHERE ai_graded IS NULL;

-- 3. 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_graded 
ON exam_answers(ai_graded);

CREATE INDEX IF NOT EXISTS idx_exam_answers_question_id 
ON exam_answers(question_id);

-- 4. 컬럼 설명 추가
COMMENT ON COLUMN exam_answers.ai_graded IS 'AI 채점 여부';
COMMENT ON COLUMN exam_answers.ai_graded_at IS 'AI 채점 완료 시간';
COMMENT ON COLUMN exam_answers.feedback IS '채점 피드백 (AI 또는 수동)';
COMMENT ON COLUMN exam_answers.graded_by IS '채점자 구분 (ai: AI 채점, manual: 수동 채점, UUID: 특정 사용자 ID)';

-- 5. 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
AND column_name IN ('ai_graded', 'ai_graded_at', 'feedback', 'graded_by', 'points')
ORDER BY column_name;

-- 6. 테스트 데이터 확인
SELECT 
    id,
    points,
    ai_graded,
    ai_graded_at,
    feedback,
    graded_by,
    created_at
FROM exam_answers 
LIMIT 5;
