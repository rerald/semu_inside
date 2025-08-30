-- exam_answers 테이블에 feedback 컬럼 추가
ALTER TABLE exam_answers ADD COLUMN IF NOT EXISTS feedback text;

-- feedback 컬럼에 대한 설명 추가
COMMENT ON COLUMN exam_answers.feedback IS '주관식 답안에 대한 평가 의견 (수동 채점 시 사용)';

-- graded_by 컬럼이 없다면 추가 (AI 채점과 수동 채점을 구분하기 위해)
ALTER TABLE exam_answers ADD COLUMN IF NOT EXISTS graded_by text DEFAULT 'ai';

-- graded_by 컬럼에 대한 설명 추가
COMMENT ON COLUMN exam_answers.graded_by IS '채점자 구분 (ai: AI 채점, manual: 수동 채점, UUID: 특정 사용자 ID)';
