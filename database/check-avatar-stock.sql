-- 🔍 아바타 재고 상태 확인

-- 1. 현재 아바타 아이템의 재고 정보 확인
SELECT 
    name,
    price,
    is_limited,
    total_supply,
    remaining_stock,
    CASE 
        WHEN is_limited IS NULL THEN '재고정보 없음'
        WHEN is_limited = false THEN '무제한'
        WHEN remaining_stock IS NULL THEN '재고정보 없음'
        WHEN remaining_stock <= 0 THEN '품절'
        ELSE CONCAT('재고: ', remaining_stock, '/', total_supply)
    END as stock_status
FROM avatar_items 
WHERE is_active = true
ORDER BY price ASC;

-- 2. user_avatars 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_avatars'
ORDER BY ordinal_position;

-- 3. 사용자가 보유한 아바타 확인
SELECT 
    ua.id,
    ua.user_id,
    ua.is_active,
    ua.purchased_at,
    ua.created_at,
    ai.name as avatar_name,
    ai.price
FROM user_avatars ua
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE ua.user_id = '886a8fc3-0a85-4c85-98d1-e89ca3967871'
ORDER BY ua.created_at DESC;

-- 4. 재고 컬럼 존재 여부 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'avatar_items' 
AND column_name IN ('is_limited', 'total_supply', 'remaining_stock')
ORDER BY column_name;
