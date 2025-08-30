-- questions 테이블에 model_answer 컬럼 추가
-- 주관식 문제의 모범답안을 명확하게 저장하기 위한 필드

-- 1. model_answer 컬럼 추가
ALTER TABLE questions ADD COLUMN IF NOT EXISTS model_answer text;

-- 2. 기존 주관식 문제의 explanation을 model_answer로 마이그레이션
UPDATE questions 
SET model_answer = explanation 
WHERE type = 'subjective' 
  AND explanation IS NOT NULL 
  AND explanation != '';

-- 3. 주관식 문제의 explanation을 NULL로 설정 (선택사항)
-- UPDATE questions 
-- SET explanation = NULL 
-- WHERE type = 'subjective' 
--   AND model_answer IS NOT NULL;

-- 4. 컬럼 설명 추가 (PostgreSQL 9.4+)
COMMENT ON COLUMN questions.model_answer IS '주관식 문제의 모범답안 (explanation과 구분)';
COMMENT ON COLUMN questions.explanation IS '문제 해설 (객관식 문제용)';

-- 5. 인덱스 추가 (선택사항 - 검색 성능 향상)
CREATE INDEX IF NOT EXISTS idx_questions_model_answer ON questions(model_answer) WHERE model_answer IS NOT NULL;

-- 6. 확인 쿼리
SELECT 
    id,
    title,
    type,
    CASE 
        WHEN type = 'subjective' THEN '주관식'
        WHEN type = 'multiple_choice' THEN '객관식'
        ELSE type
    END as question_type,
    CASE 
        WHEN type = 'subjective' AND model_answer IS NOT NULL THEN '✅ 모범답안 있음'
        WHEN type = 'subjective' AND model_answer IS NULL THEN '❌ 모범답안 없음'
        ELSE '해당없음'
    END as model_answer_status,
    CASE 
        WHEN type = 'subjective' AND explanation IS NOT NULL THEN '⚠️ explanation에 모범답안 저장됨'
        WHEN type = 'subjective' AND explanation IS NULL THEN '✅ explanation 비어있음'
        ELSE '해당없음'
    END as explanation_status
FROM questions 
WHERE type = 'subjective'
ORDER BY created_at DESC;
