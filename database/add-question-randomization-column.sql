-- exam_sessions 테이블에 question_randomization 컬럼 추가
-- 이 컬럼은 각 문제별 보기 랜덤화 정보를 JSONB 형태로 저장합니다.

ALTER TABLE public.exam_sessions 
ADD COLUMN question_randomization JSONB DEFAULT '{}';

-- 컬럼 설명 추가
COMMENT ON COLUMN public.exam_sessions.question_randomization IS 
'각 문제별 보기 랜덤화 정보를 저장하는 JSONB 필드. 
형식: {
  "question_id": {
    "randomizedChoices": [...],
    "originalToNewMapping": [...],
    "newCorrectIndices": [...],
    "isRandomized": true
  }
}';

-- 기존 데이터에 대해 빈 JSON 객체로 초기화
UPDATE public.exam_sessions 
SET question_randomization = '{}' 
WHERE question_randomization IS NULL;

-- NOT NULL 제약 조건 추가 (기본값이 있으므로 안전)
ALTER TABLE public.exam_sessions 
ALTER COLUMN question_randomization SET NOT NULL;
