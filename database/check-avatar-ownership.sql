-- 🔍 아바타 보유 현황 조회

-- 1. 모든 아바타 아이템의 보유 현황
SELECT 
    ai.id as avatar_item_id,
    ai.name as avatar_name,
    ai.price,
    ai.is_limited,
    ai.total_supply,
    ai.remaining_stock,
    COUNT(ua.id) as owned_count,
    CASE 
        WHEN ai.is_limited = false THEN '무제한'
        WHEN ai.total_supply IS NULL THEN '재고정보 없음'
        WHEN ai.remaining_stock IS NULL THEN '재고정보 없음'
        ELSE CONCAT('재고: ', ai.remaining_stock, '/', ai.total_supply)
    END as stock_status
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id AND ua.is_active = true
WHERE ai.is_active = true
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock
ORDER BY ai.price ASC;

-- 2. 특정 아바타를 보유한 사용자 목록
SELECT 
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email,
    ua.purchased_at,
    ua.created_at
FROM avatar_items ai
JOIN user_avatars ua ON ai.id = ua.avatar_item_id
JOIN profiles p ON ua.user_id = p.id
WHERE ai.is_active = true 
  AND ua.is_active = true
ORDER BY ai.name, ua.purchased_at DESC;

-- 3. 사용자별 보유 아바타 목록
SELECT 
    p.name as user_name,
    p.email,
    COUNT(ua.id) as total_avatars,
    STRING_AGG(ai.name, ', ' ORDER BY ai.price) as owned_avatars
FROM profiles p
LEFT JOIN user_avatars ua ON p.id = ua.user_id AND ua.is_active = true
LEFT JOIN avatar_items ai ON ua.avatar_item_id = ai.id
GROUP BY p.id, p.name, p.email
HAVING COUNT(ua.id) > 0
ORDER BY total_avatars DESC, p.name;

-- 4. 인기 아바타 순위 (보유자 수 기준)
SELECT 
    ai.name as avatar_name,
    ai.price,
    COUNT(ua.id) as owner_count,
    CASE 
        WHEN ai.is_limited = false THEN '무제한'
        WHEN ai.total_supply IS NULL THEN '재고정보 없음'
        WHEN ai.remaining_stock IS NULL THEN '재고정보 없음'
        ELSE CONCAT('재고: ', ai.remaining_stock, '/', ai.total_supply)
    END as stock_status
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id AND ua.is_active = true
WHERE ai.is_active = true
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock
ORDER BY owner_count DESC, ai.price ASC;
