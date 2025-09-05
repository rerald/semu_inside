-- rerald293@gmail.com의 아바타 구매 기록 추가
-- 1. 사용자 ID 확인
SELECT id, name, email FROM profiles WHERE email = 'rerald293@gmail.com';

-- 2. 아바타 아이템 ID 확인
SELECT id, name, price FROM avatar_items WHERE name IN ('뷔', '트랄랄레로 트랄랄라');

-- 3. 뷔 아바타 구매 기록 추가 (착용 중)
INSERT INTO user_avatars (user_id, avatar_item_id, is_active, purchased_at, created_at)
SELECT 
    p.id,
    ai.id,
    true,  -- 착용 중
    NOW(),
    NOW()
FROM profiles p, avatar_items ai
WHERE p.email = 'rerald293@gmail.com' 
  AND ai.name = '뷔';

-- 4. 트랄랄레로 트랄랄라 아바타 구매 기록 추가 (보유 중)
INSERT INTO user_avatars (user_id, avatar_item_id, is_active, purchased_at, created_at)
SELECT 
    p.id,
    ai.id,
    false,  -- 보유 중 (착용하지 않음)
    NOW(),
    NOW()
FROM profiles p, avatar_items ai
WHERE p.email = 'rerald293@gmail.com' 
  AND ai.name = '트랄랄레로 트랄랄라';

-- 5. 재고 차감
UPDATE avatar_items 
SET remaining_stock = remaining_stock - 1
WHERE name = '뷔';

UPDATE avatar_items 
SET remaining_stock = remaining_stock - 1
WHERE name = '트랄랄레로 트랄랄라';

-- 6. 구매 후 상태 확인
SELECT 
    ai.name as avatar_name,
    ai.price,
    ai.is_limited,
    ai.total_supply,
    ai.remaining_stock,
    COUNT(ua.id) as owner_count
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id
WHERE ai.name IN ('뷔', '트랄랄레로 트랄랄라')
GROUP BY ai.id, ai.name, ai.price, ai.is_limited, ai.total_supply, ai.remaining_stock;

-- 7. rerald293@gmail.com의 구매 기록 확인
SELECT 
    ua.id,
    ua.user_id,
    ua.avatar_item_id,
    ua.is_active,
    ua.purchased_at,
    ai.name as avatar_name,
    ai.price,
    p.name as user_name,
    p.email
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE p.email = 'rerald293@gmail.com'
ORDER BY ua.created_at DESC;
