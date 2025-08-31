-- AI 채점 세부점수 및 계산 과정 저장을 위한 확장 스키마
-- Supabase SQL 에디터에서 실행하세요

-- 1. 기존 AI 채점 컬럼 추가 (이미 있다면 건너뜀)
DO $$ 
BEGIN
    -- ai_graded 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'ai_graded 컬럼 추가됨';
    END IF;
    
    -- ai_graded_at 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_at') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'ai_graded_at 컬럼 추가됨';
    END IF;
    
    -- feedback 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'feedback') THEN
        ALTER TABLE exam_answers ADD COLUMN feedback TEXT;
        RAISE NOTICE 'feedback 컬UMN 추가됨';
    END IF;
    
    -- ai_graded_by 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_by') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_graded_by TEXT;
        RAISE NOTICE 'ai_graded_by 컬럼 추가됨';
    END IF;
END $$;

-- 2. 세부점수 및 계산 과정 저장을 위한 새로운 컬럼들
DO $$ 
BEGIN
    -- ai_detailed_scores 컬럼 (JSON 형태로 세부점수 저장)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_detailed_scores') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_detailed_scores JSONB;
        RAISE NOTICE 'ai_detailed_scores 컬럼 추가됨';
    END IF;
    
    -- ai_calculation_process 컬럼 (총점 계산 과정 설명)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_calculation_process') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_calculation_process TEXT;
        RAISE NOTICE 'ai_calculation_process 컬럼 추가됨';
    END IF;
    
    -- ai_grading_criteria 컬럼 (평가 기준)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_grading_criteria') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_grading_criteria TEXT;
        RAISE NOTICE 'ai_grading_criteria 컬럼 추가됨';
    END IF;
    
    -- ai_grading_version 컬럼 (AI 채점 시스템 버전)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'exam_answers' AND column_name = 'ai_grading_version') THEN
        ALTER TABLE exam_answers ADD COLUMN ai_grading_version TEXT DEFAULT 'v1.0';
        RAISE NOTICE 'ai_grading_version 컬럼 추가됨';
    END IF;
END $$;

-- 3. points 컬럼 NULL 허용
ALTER TABLE exam_answers ALTER COLUMN points DROP NOT NULL;

-- 4. 기본값 설정
UPDATE exam_answers SET ai_graded = FALSE WHERE ai_graded IS NULL;

-- 5. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_graded ON exam_answers(ai_graded);
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_detailed_scores ON exam_answers USING GIN (ai_detailed_scores);

-- 6. 컬럼 설명 추가
COMMENT ON COLUMN exam_answers.ai_graded IS 'AI 채점 여부';
COMMENT ON COLUMN exam_answers.ai_graded_at IS 'AI 채점 완료 시간';
COMMENT ON COLUMN exam_answers.feedback IS '채점 피드백 (AI 또는 수동)';
COMMENT ON COLUMN exam_answers.ai_graded_by IS 'AI 채점 시스템 구분';
COMMENT ON COLUMN exam_answers.ai_detailed_scores IS 'AI 채점 세부점수 (JSON 형태)';
COMMENT ON COLUMN exam_answers.ai_calculation_process IS 'AI 채점 총점 계산 과정';
COMMENT ON COLUMN exam_answers.ai_grading_criteria IS 'AI 채점 평가 기준';
COMMENT ON COLUMN exam_answers.ai_grading_version IS 'AI 채점 시스템 버전';

-- 7. 최종 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
AND column_name LIKE 'ai_%'
ORDER BY column_name;

-- 8. 테스트 데이터 확인
SELECT 
    id,
    points,
    ai_graded,
    ai_graded_at,
    ai_detailed_scores,
    ai_calculation_process,
    ai_grading_criteria,
    ai_grading_version,
    created_at
FROM exam_answers 
LIMIT 3;

