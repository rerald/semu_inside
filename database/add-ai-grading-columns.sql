-- AI 채점 기능을 위한 컬럼 추가
-- exam_answers 테이블에 AI 채점 관련 컬럼들 추가

-- 1. ai_graded 컬럼 추가 (AI 채점 여부)
ALTER TABLE exam_answers 
ADD COLUMN IF NOT EXISTS ai_graded BOOLEAN DEFAULT FALSE;

-- 2. ai_graded_at 컬럼 추가 (AI 채점 시간)
ALTER TABLE exam_answers 
ADD COLUMN IF NOT EXISTS ai_graded_at TIMESTAMP WITH TIME ZONE;

-- 3. feedback 컬럼 추가 (채점 피드백)
ALTER TABLE exam_answers 
ADD COLUMN IF NOT EXISTS feedback TEXT;

-- 4. 기존 컬럼들의 제약 조건 확인 및 수정
-- points 컬럼이 NULL을 허용하는지 확인
ALTER TABLE exam_answers 
ALTER COLUMN points DROP NOT NULL;

-- 5. 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_exam_answers_ai_graded 
ON exam_answers(ai_graded);

CREATE INDEX IF NOT EXISTS idx_exam_answers_question_id 
ON exam_answers(question_id);

-- 6. 기존 데이터에 대한 기본값 설정
UPDATE exam_answers 
SET ai_graded = FALSE 
WHERE ai_graded IS NULL;

-- 7. 컬럼 설명 추가 (선택사항)
COMMENT ON COLUMN exam_answers.ai_graded IS 'AI 채점 여부';
COMMENT ON COLUMN exam_answers.ai_graded_at IS 'AI 채점 완료 시간';
COMMENT ON COLUMN exam_answers.feedback IS '채점 피드백 (AI 또는 수동)';

-- 8. 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'exam_answers' 
AND column_name IN ('ai_graded', 'ai_graded_at', 'feedback', 'points')
ORDER BY column_name;

