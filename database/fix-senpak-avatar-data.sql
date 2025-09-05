-- 센팍 아바타 데이터 수정
-- 1. 현재 센팍 아바타 상태 확인
SELECT 
    id, name, price, is_limited, total_supply, remaining_stock, created_at
FROM avatar_items 
WHERE name = '센팍';

-- 2. 센팍 아바타를 보유한 모든 사용자 확인
SELECT 
    ua.id,
    ua.user_id,
    ua.avatar_item_id,
    ua.purchased_at,
    ua.created_at,
    ua.is_active,
    p.name as user_name,
    p.email
FROM user_avatars ua
JOIN profiles p ON ua.user_id = p.id
JOIN avatar_items ai ON ua.avatar_item_id = ai.id
WHERE ai.name = '센팍'
ORDER BY ua.created_at;

-- 3. 센팍 아바타를 한정수량 1개로 설정
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 1,
    remaining_stock = 1
WHERE name = '센팍';

-- 4. 센팍 아바타의 모든 보유 기록 삭제 (실제 구매가 아니므로)
DELETE FROM user_avatars 
WHERE avatar_item_id = (
    SELECT id FROM avatar_items WHERE name = '센팍'
);

-- 5. 수정 후 센팍 아바타 상태 확인
SELECT 
    id, name, price, is_limited, total_supply, remaining_stock
FROM avatar_items 
WHERE name = '센팍';

-- 6. 센팍 아바타 보유자 수 확인 (0이어야 함)
SELECT 
    ai.name,
    COUNT(ua.id) as owner_count
FROM avatar_items ai
LEFT JOIN user_avatars ua ON ai.id = ua.avatar_item_id
WHERE ai.name = '센팍'
GROUP BY ai.id, ai.name;
