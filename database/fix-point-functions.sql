-- 수정된 포인트 관리 RPC 함수들
-- 올바른 컬럼명 사용: total_points, points

-- 1. 사용자 포인트 추가 함수 (수정됨)
CREATE OR REPLACE FUNCTION add_user_points(
    target_user_id UUID, 
    points_to_add INTEGER, 
    description TEXT DEFAULT '포인트 획득',
    target_session_id UUID DEFAULT NULL,
    target_exam_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- point_transactions 테이블에 거래 내역 추가
    INSERT INTO point_transactions (user_id, points, transaction_type, description, session_id, exam_id, created_at)
    VALUES (target_user_id, points_to_add, 'earn', description, target_session_id, target_exam_id, NOW());
    
    -- user_points 테이블에 포인트 추가 (upsert)  
    INSERT INTO user_points (user_id, total_points, created_at, updated_at)
    VALUES (target_user_id, points_to_add, NOW(), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = user_points.total_points + points_to_add,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 사용자 포인트 차감 함수 (수정됨)
CREATE OR REPLACE FUNCTION subtract_user_points(
    target_user_id UUID, 
    points_to_subtract INTEGER, 
    description TEXT DEFAULT '포인트 사용'
)
RETURNS BOOLEAN AS $$
DECLARE
    current_points INTEGER;
BEGIN
    -- 현재 포인트 조회
    SELECT total_points INTO current_points 
    FROM user_points 
    WHERE user_id = target_user_id;
    
    -- 포인트가 부족한 경우
    IF current_points IS NULL OR current_points < points_to_subtract THEN
        RETURN FALSE;
    END IF;
    
    -- point_transactions 테이블에 거래 내역 추가
    INSERT INTO point_transactions (user_id, points, transaction_type, description, created_at)
    VALUES (target_user_id, -points_to_subtract, 'spend', description, NOW());
    
    -- user_points 테이블에서 포인트 차감
    UPDATE user_points 
    SET 
        total_points = total_points - points_to_subtract,
        updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 사용자 현재 포인트 조회 함수 (수정됨)
CREATE OR REPLACE FUNCTION get_user_points(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_points INTEGER;
BEGIN
    SELECT total_points INTO current_points 
    FROM user_points 
    WHERE user_id = target_user_id;
    
    RETURN COALESCE(current_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 포인트 리더보드 조회 함수 (수정됨)
CREATE OR REPLACE FUNCTION get_points_leaderboard(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    rank INTEGER,
    user_id UUID,
    user_name VARCHAR,
    total_points INTEGER,
    department_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY up.total_points DESC)::INTEGER as rank,
        up.user_id,
        p.name as user_name,
        up.total_points,
        d.name as department_name
    FROM user_points up
    JOIN profiles p ON up.user_id = p.id
    LEFT JOIN departments d ON p.department_id = d.id
    ORDER BY up.total_points DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 최근 포인트 거래 내역 조회 함수 (수정됨)
CREATE OR REPLACE FUNCTION get_recent_point_transactions(limit_count INTEGER DEFAULT 50)
RETURNS TABLE (
    transaction_id UUID,
    user_id UUID,
    user_name VARCHAR,
    points INTEGER,
    transaction_type VARCHAR,
    description TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.id as transaction_id,
        pt.user_id,
        p.name as user_name,
        pt.points,
        pt.transaction_type,
        pt.description,
        pt.created_at
    FROM point_transactions pt
    JOIN profiles p ON pt.user_id = p.id
    ORDER BY pt.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 시험 완료 포인트 지급 함수 (새로 추가)
CREATE OR REPLACE FUNCTION award_exam_completion_points(
    target_user_id UUID,
    target_session_id UUID,
    target_exam_id UUID,
    score INTEGER,
    total_questions INTEGER,
    passed BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
    question_points INTEGER := score * 10; -- 문제당 10점
    completion_bonus INTEGER := 200; -- 완료 보너스
    passing_bonus INTEGER := 0; -- 합격 보너스
    total_awarded INTEGER := 0;
    result JSON;
BEGIN
    -- 합격한 경우 보너스 추가
    IF passed THEN
        passing_bonus := 300;
    END IF;
    
    total_awarded := question_points + completion_bonus + passing_bonus;
    
    -- 포인트 지급
    PERFORM add_user_points(
        target_user_id, 
        total_awarded, 
        format('시험 완료 보너스 (문제: %s점, 완료: %s점, 합격: %s점)', 
               question_points, completion_bonus, passing_bonus),
        target_session_id,
        target_exam_id
    );
    
    -- 결과 반환
    result := json_build_object(
        'success', true,
        'total_points', total_awarded,
        'question_points', question_points,
        'completion_bonus', completion_bonus,
        'passing_bonus', passing_bonus,
        'message', '포인트가 성공적으로 지급되었습니다.'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
