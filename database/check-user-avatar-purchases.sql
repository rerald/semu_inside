-- rerald293@gmail.com의 아바타 구매 기록 확인
-- 1. 사용자 ID 확인
SELECT id, name, email FROM profiles WHERE email = 'rerald293@gmail.com';

-- 2. 해당 사용자의 아바타 구매 기록
SELECT 
    ua.id as user_avatar_id,
    ua.user_id,
    ua.avatar_item_id,
    ua.purchased_at,
    ua.created_at,
    ua.is_active,
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE p.email = 'rerald293@gmail.com'
ORDER BY ua.created_at DESC;

-- 3. 전체 user_avatars 테이블 상태 확인
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_records
FROM user_avatars;

-- 4. 최근 구매 기록 (상위 10개)
SELECT 
    ua.id,
    ua.user_id,
    ua.avatar_item_id,
    ua.purchased_at,
    ua.created_at,
    ua.is_active,
    ai.name as avatar_name,
    p.name as user_name,
    p.email
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
ORDER BY ua.created_at DESC
LIMIT 10;
