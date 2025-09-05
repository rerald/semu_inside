-- 아바타 시스템 테이블 존재 확인
-- Supabase SQL Editor에서 실행하여 아바타 시스템이 제대로 설정되었는지 확인

-- 1. 필요한 테이블들이 존재하는지 확인
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('avatar_items', 'user_avatars', 'user_points', 'point_transactions') 
        THEN '✅ 존재'
        ELSE '❌ 누락'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('avatar_items', 'user_avatars', 'user_points', 'point_transactions')
ORDER BY table_name;

-- 2. avatar_items 테이블 구조 확인
SELECT 
    'avatar_items 테이블 구조' as info,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'avatar_items' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. 아바타 아이템 데이터 확인
SELECT 
    '현재 등록된 아바타 아이템' as info,
    count(*) as total_items,
    count(CASE WHEN is_active = true THEN 1 END) as active_items
FROM avatar_items;

-- 4. 샘플 아바타 아이템 목록
SELECT 
    name,
    price,
    rarity,
    is_active,
    CASE WHEN is_limited THEN CONCAT('한정판 ', remaining_stock, '/', total_supply) ELSE '일반' END as availability
FROM avatar_items 
ORDER BY 
    CASE rarity 
        WHEN 'common' THEN 1
        WHEN 'uncommon' THEN 2  
        WHEN 'rare' THEN 3
        WHEN 'epic' THEN 4
        WHEN 'legendary' THEN 5
    END,
    price
LIMIT 10;

-- 5. RLS 정책 확인
SELECT 
    'RLS 정책 확인' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('avatar_items', 'user_avatars', 'user_points', 'point_transactions')
AND schemaname = 'public';

-- 6. 사용자 포인트 테이블 확인
SELECT 
    'user_points 데이터 샘플' as info,
    p.name,
    up.points,
    up.created_at
FROM user_points up
JOIN profiles p ON up.user_id = p.id
ORDER BY up.points DESC
LIMIT 5;

-- 문제 진단용 쿼리들

-- 7. 아바타 시스템이 완전히 누락된 경우 확인
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'avatar_items') THEN
        RAISE NOTICE '⚠️  avatar_items 테이블이 없습니다. new-avatar-system.sql을 실행해주세요.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_points') THEN
        RAISE NOTICE '⚠️  user_points 테이블이 없습니다. create-point-tables.sql을 실행해주세요.';
    END IF;
END $$;

-- 8. 필요한 RPC 함수들 확인
SELECT 
    'RPC 함수 확인' as info,
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('add_user_points', 'subtract_user_points', 'get_user_points')
ORDER BY routine_name;

SELECT '🎯 아바타 시스템 검사 완료' as message;
