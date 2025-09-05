-- 포인트 관리를 위한 PostgreSQL 함수들

-- 사용자 포인트 추가 함수 (거래 내역 포함)
CREATE OR REPLACE FUNCTION add_user_points(
    user_id UUID, 
    points_to_add INTEGER, 
    description TEXT DEFAULT '포인트 획득',
    session_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- point_transactions 테이블에 거래 내역 추가
    INSERT INTO point_transactions (user_id, points, description, session_id, created_at)
    VALUES (user_id, points_to_add, description, session_id, NOW());
    
    -- user_points 테이블에 포인트 추가 (upsert)
    INSERT INTO user_points (user_id, total_points, updated_at)
    VALUES (user_id, points_to_add, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = user_points.total_points + points_to_add,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- 사용자 포인트 차감 함수
CREATE OR REPLACE FUNCTION subtract_user_points(target_user_id UUID, point_amount INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    current_points INTEGER;
BEGIN
    -- 현재 포인트 조회
    SELECT points INTO current_points 
    FROM user_points 
    WHERE user_id = target_user_id;
    
    -- 포인트가 부족한 경우
    IF current_points IS NULL OR current_points < point_amount THEN
        RETURN FALSE;
    END IF;
    
    -- 포인트 차감
    UPDATE user_points 
    SET 
        points = points - point_amount,
        updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 사용자 현재 포인트 조회 함수
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
$$ LANGUAGE plpgsql;

-- 포인트 거래 내역 조회 함수
CREATE OR REPLACE FUNCTION get_user_point_history(
    target_user_id UUID, 
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    transaction_id UUID,
    amount INTEGER,
    transaction_type VARCHAR,
    description TEXT,
    avatar_item_name VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.id,
        pt.amount,
        pt.transaction_type,
        pt.description,
        ai.name as avatar_item_name,
        pt.created_at
    FROM point_transactions pt
    LEFT JOIN avatar_items ai ON pt.avatar_item_id = ai.id
    WHERE pt.user_id = target_user_id
    ORDER BY pt.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 일일 포인트 획득량 조회 함수
CREATE OR REPLACE FUNCTION get_daily_points_earned(
    target_user_id UUID,
    target_date DATE DEFAULT CURRENT_DATE
)
RETURNS INTEGER AS $$
DECLARE
    daily_points INTEGER;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO daily_points
    FROM point_transactions
    WHERE 
        user_id = target_user_id 
        AND transaction_type = 'earn'
        AND DATE(created_at) = target_date;
    
    RETURN daily_points;
END;
$$ LANGUAGE plpgsql;

-- 포인트 랭킹 조회 함수 (상위 N명)
CREATE OR REPLACE FUNCTION get_points_leaderboard(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    rank INTEGER,
    user_id UUID,
    user_name VARCHAR,
    points INTEGER,
    department_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY up.points DESC)::INTEGER as rank,
        up.user_id,
        p.name as user_name,
        up.points,
        d.name as department_name
    FROM user_points up
    JOIN profiles p ON up.user_id = p.id
    LEFT JOIN departments d ON p.department_id = d.id
    ORDER BY up.points DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

