-- AI 채점 기능을 위한 RLS 정책 수정
-- exam_answers 테이블의 AI 채점 관련 업데이트 권한 확보

-- 기존 RLS 정책 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'exam_answers';

-- AI 채점을 위한 업데이트 정책 추가/수정
DROP POLICY IF EXISTS "AI grading can update exam answers" ON exam_answers;

CREATE POLICY "AI grading can update exam answers"
ON exam_answers
FOR UPDATE
USING (
    -- 기존 조건: 자신의 답안이거나 관리자
    auth.uid() = (SELECT employee_id FROM exam_sessions WHERE id = session_id)
    OR 
    auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin', 'super_admin'))
    OR
    -- AI 채점 시스템을 위한 조건 (서비스 역할)
    current_setting('role') = 'service_role'
)
WITH CHECK (
    -- 업데이트 후에도 동일한 조건 적용
    auth.uid() = (SELECT employee_id FROM exam_sessions WHERE id = session_id)
    OR 
    auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin', 'super_admin'))
    OR
    current_setting('role') = 'service_role'
);

-- AI 채점 전용 함수 생성 (선택사항)
CREATE OR REPLACE FUNCTION apply_ai_grading(
    answer_id UUID,
    grading_score INTEGER,
    grading_feedback TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    result BOOLEAN := FALSE;
BEGIN
    -- AI 채점 결과 업데이트
    UPDATE exam_answers 
    SET 
        points = grading_score,
        feedback = grading_feedback,
        ai_graded = TRUE,
        ai_graded_at = NOW(),
        graded_by = 'ai',
        graded_at = NOW(),
        updated_at = NOW()
    WHERE id = answer_id;
    
    -- 업데이트 성공 여부 확인
    GET DIAGNOSTICS result = FOUND;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION apply_ai_grading(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION apply_ai_grading(UUID, INTEGER, TEXT) TO anon;

-- 테이블 컬럼 존재 여부 확인 함수
CREATE OR REPLACE FUNCTION check_ai_grading_columns() RETURNS TABLE(
    has_ai_graded BOOLEAN,
    has_ai_graded_at BOOLEAN,
    has_feedback BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXISTS(SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'exam_answers' AND column_name = 'ai_graded') as has_ai_graded,
        EXISTS(SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'exam_answers' AND column_name = 'ai_graded_at') as has_ai_graded_at,
        EXISTS(SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'exam_answers' AND column_name = 'feedback') as has_feedback;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 컬럼 확인 함수 실행 권한
GRANT EXECUTE ON FUNCTION check_ai_grading_columns() TO authenticated;
GRANT EXECUTE ON FUNCTION check_ai_grading_columns() TO anon;

-- 현재 상태 확인
SELECT * FROM check_ai_grading_columns();

