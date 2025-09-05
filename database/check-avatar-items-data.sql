-- 🔍 아바타 아이템 실제 데이터 확인

-- 1. 모든 아바타 아이템의 재고 정보 확인
SELECT 
    id,
    name,
    price,
    is_limited,
    total_supply,
    remaining_stock,
    is_active,
    created_at
FROM avatar_items 
ORDER BY price ASC;

-- 2. 사용자가 보유한 아바타 확인
SELECT 
    ua.id,
    ua.user_id,
    ua.is_active,
    ua.purchased_at,
    ua.created_at,
    ai.name as avatar_name,
    ai.price,
    ai.is_limited,
    ai.remaining_stock
FROM user_avatars ua
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE ua.user_id = '886a8fc3-0a85-4c85-98d1-e89ca3967871'
ORDER BY ua.created_at DESC;

-- 3. 재고 정보가 있는 아이템만 확인
SELECT 
    name,
    price,
    is_limited,
    total_supply,
    remaining_stock
FROM avatar_items 
WHERE is_limited = true 
   OR total_supply IS NOT NULL 
   OR remaining_stock IS NOT NULL
ORDER BY price ASC;
