-- 기존 아바타 구매 기록 확인 및 수정
-- 1. rerald293@gmail.com의 현재 아바타 보유 현황
SELECT 
    ua.id,
    ua.user_id,
    ua.avatar_item_id,
    ua.is_active,
    ua.purchased_at,
    ua.created_at,
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE p.email = 'rerald293@gmail.com'
ORDER BY ua.created_at DESC;

-- 2. 뷔 아바타의 현재 상태 (착용 중으로 변경)
UPDATE user_avatars 
SET is_active = true
WHERE user_id = (
    SELECT id FROM profiles WHERE email = 'rerald293@gmail.com'
) AND avatar_item_id = (
    SELECT id FROM avatar_items WHERE name = '뷔'
);

-- 3. 트랄랄레로 트랄랄라 아바타의 현재 상태 (보유 중으로 유지)
UPDATE user_avatars 
SET is_active = false
WHERE user_id = (
    SELECT id FROM profiles WHERE email = 'rerald293@gmail.com'
) AND avatar_item_id = (
    SELECT id FROM avatar_items WHERE name = '트랄랄레로 트랄랄라'
);

-- 4. 재고 상태 확인 및 수정
SELECT 
    ai.name,
    ai.price,
    ai.is_limited,
    ai.total_supply,
    ai.remaining_stock,
    COUNT(ua.id) as owner_count
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id
WHERE ai.name IN ('뷔', '트랄랄레로 트랄랄라')
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock;

-- 5. 재고 수정 (실제 보유자 수에 맞게)
UPDATE avatar_items 
SET remaining_stock = total_supply - (
    SELECT COUNT(*) 
    FROM user_avatars ua 
    WHERE ua.avatar_item_id = avatar_items.id
)
WHERE name IN ('뷔', '트랄랄레로 트랄랄라');

-- 6. 수정 후 최종 상태 확인
SELECT 
    ai.name as avatar_name,
    ai.price,
    ai.is_limited,
    ai.total_supply,
    ai.remaining_stock,
    COUNT(ua.id) as owner_count,
    COUNT(CASE WHEN ua.is_active = true THEN 1 END) as active_owners
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id
WHERE ai.name IN ('뷔', '트랄랄레로 트랄랄라')
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock;

-- 7. rerald293@gmail.com의 최종 보유 현황
SELECT 
    ua.id,
    ua.avatar_item_id,
    ua.is_active,
    ua.purchased_at,
    ai.name as avatar_name,
    ai.price,
    CASE 
        WHEN ua.is_active = true THEN '착용중'
        ELSE '보유중'
    END as status
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE p.email = 'rerald293@gmail.com'
ORDER BY ua.created_at DESC;
