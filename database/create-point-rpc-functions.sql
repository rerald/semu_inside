-- 포인트 관리 RPC 함수들
-- 기존 테이블 구조에 맞게 작성

-- 1. 사용자 포인트 추가 함수
CREATE OR REPLACE FUNCTION add_user_points(
    user_id UUID, 
    points_to_add INTEGER, 
    description TEXT DEFAULT '포인트 획득',
    session_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- point_transactions 테이블에 거래 내역 추가
    INSERT INTO point_transactions (user_id, amount, transaction_type, description, created_at)
    VALUES (user_id, points_to_add, 'earn', description, NOW());
    
    -- user_points 테이블에 포인트 추가 (upsert)  
    INSERT INTO user_points (user_id, points, created_at, updated_at)
    VALUES (user_id, points_to_add, NOW(), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        points = user_points.points + points_to_add,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 사용자 포인트 차감 함수
CREATE OR REPLACE FUNCTION subtract_user_points(
    user_id UUID, 
    points_to_subtract INTEGER, 
    description TEXT DEFAULT '포인트 사용',
    avatar_item_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_points INTEGER;
BEGIN
    -- 현재 포인트 조회
    SELECT points INTO current_points 
    FROM user_points 
    WHERE user_points.user_id = subtract_user_points.user_id;
    
    -- 포인트가 부족한 경우
    IF current_points IS NULL OR current_points < points_to_subtract THEN
        RETURN FALSE;
    END IF;
    
    -- point_transactions 테이블에 거래 내역 추가
    INSERT INTO point_transactions (user_id, amount, transaction_type, description, avatar_item_id, created_at)
    VALUES (user_id, -points_to_subtract, 'spend', description, avatar_item_id, NOW());
    
    -- user_points 테이블에서 포인트 차감
    UPDATE user_points 
    SET 
        points = points - points_to_subtract,
        updated_at = NOW()
    WHERE user_points.user_id = subtract_user_points.user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 사용자 현재 포인트 조회 함수
CREATE OR REPLACE FUNCTION get_user_points(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_points INTEGER;
BEGIN
    SELECT points INTO current_points 
    FROM user_points 
    WHERE user_id = target_user_id;
    
    RETURN COALESCE(current_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 포인트 리더보드 조회 함수
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
        ROW_NUMBER() OVER (ORDER BY up.points DESC)::INTEGER as rank,
        up.user_id,
        p.name as user_name,
        up.points as total_points,
        d.name as department_name
    FROM user_points up
    JOIN profiles p ON up.user_id = p.id
    LEFT JOIN departments d ON p.department_id = d.id
    ORDER BY up.points DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 최근 포인트 거래 내역 조회 함수
CREATE OR REPLACE FUNCTION get_recent_point_transactions(limit_count INTEGER DEFAULT 50)
RETURNS TABLE (
    transaction_id UUID,
    user_id UUID,
    user_name VARCHAR,
    amount INTEGER,
    transaction_type VARCHAR,
    description TEXT,
    avatar_item_name VARCHAR,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.id as transaction_id,
        pt.user_id,
        p.name as user_name,
        pt.amount,
        pt.transaction_type,
        pt.description,
        ai.name as avatar_item_name,
        pt.created_at
    FROM point_transactions pt
    JOIN profiles p ON pt.user_id = p.id
    LEFT JOIN avatar_items ai ON pt.avatar_item_id = ai.id
    ORDER BY pt.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
