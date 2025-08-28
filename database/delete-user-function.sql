-- 사용자 및 관련 데이터를 안전하게 삭제하는 PostgreSQL 함수
-- Supabase SQL Editor에서 실행

CREATE OR REPLACE FUNCTION delete_user_completely(user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    session_count INTEGER;
    answer_count INTEGER;
    permission_count INTEGER;
BEGIN
    -- 삭제할 데이터 개수 확인
    SELECT COUNT(*) INTO session_count FROM exam_sessions WHERE employee_id = user_id;
    SELECT COUNT(*) INTO permission_count FROM exam_permissions WHERE employee_id = user_id;
    
    -- 답안 개수 확인
    SELECT COUNT(*) INTO answer_count 
    FROM exam_answers 
    WHERE session_id IN (SELECT id FROM exam_sessions WHERE employee_id = user_id);
    
    -- 1단계: 답안 삭제
    DELETE FROM exam_answers 
    WHERE session_id IN (SELECT id FROM exam_sessions WHERE employee_id = user_id);
    
    -- 2단계: 시험 세션 삭제
    DELETE FROM exam_sessions WHERE employee_id = user_id;
    
    -- 3단계: 시험 권한 삭제
    DELETE FROM exam_permissions WHERE employee_id = user_id;
    
    -- 4단계: 프로필 삭제
    DELETE FROM profiles WHERE id = user_id;
    
    -- 결과 반환
    result := json_build_object(
        'success', true,
        'deleted_answers', answer_count,
        'deleted_sessions', session_count,
        'deleted_permissions', permission_count,
        'user_id', user_id
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- 오류 발생 시 롤백되고 오류 정보 반환
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'user_id', user_id
        );
        RETURN result;
END;
$$;

-- 함수 사용 예시:
-- SELECT delete_user_completely('6606057f-8c77-48a4-bf3b-dca72160d801');

-- 권한 설정 (필요한 경우)
-- GRANT EXECUTE ON FUNCTION delete_user_completely TO authenticated;
