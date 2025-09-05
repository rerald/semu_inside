-- 아바타 보유 현황 상세 확인
-- 1. 아바타 아이템별 보유자 수 확인
SELECT 
    ai.id,
    ai.name,
    ai.price,
    ai.is_limited,
    ai.total_supply,
    ai.remaining_stock,
    COUNT(ua.id) as owner_count
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id AND ua.is_active = true
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock
ORDER BY owner_count DESC;

-- 2. 실제 보유자 상세 정보 확인 (최대 10명)
SELECT 
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email,
    ua.purchased_at,
    ua.created_at,
    ua.is_active
FROM avatar_items ai
JOIN user_avatars ua ON ai.id = ua.avatar_item_id
JOIN profiles p ON ua.user_id = p.id
WHERE ua.is_active = true
ORDER BY ai.name, ua.purchased_at DESC
LIMIT 20;

-- 3. 센팍 아바타 보유자 확인
SELECT 
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email,
    ua.purchased_at,
    ua.created_at,
    ua.is_active
FROM avatar_items ai
JOIN user_avatars ua ON ai.id = ua.avatar_item_id
JOIN profiles p ON ua.user_id = p.id
WHERE ai.name = '센팍' AND ua.is_active = true
ORDER BY ua.purchased_at DESC;

-- 4. 전체 보유자 통계
SELECT 
    COUNT(DISTINCT ua.user_id) as total_unique_owners,
    COUNT(ua.id) as total_avatar_ownerships,
    COUNT(CASE WHEN ua.is_active = true THEN 1 END) as active_ownerships
FROM user_avatars ua;
