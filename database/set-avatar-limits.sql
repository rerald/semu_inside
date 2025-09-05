-- 모든 아바타 아이템에 한정수량 설정
-- 1. 현재 아바타 아이템 상태 확인
SELECT 
    id, name, price, is_limited, total_supply, remaining_stock
FROM avatar_items 
ORDER BY price;

-- 2. 각 아바타별 한정수량 설정
-- 센팍: 1개 (무료, 특별)
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 1,
    remaining_stock = 1
WHERE name = '센팍';

-- 트랄랄레로 트랄랄라: 10개 (일반)
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 10,
    remaining_stock = 10
WHERE name = '트랄랄레로 트랄랄라';

-- 뷔: 5개 (전설)
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 5,
    remaining_stock = 5
WHERE name = '뷔';

-- 봄바르디로 크로코딜로: 3개 (고급)
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 3,
    remaining_stock = 3
WHERE name = '봄바르디로 크로코딜로';

-- 퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르: 2개 (희귀)
UPDATE avatar_items 
SET 
    is_limited = true,
    total_supply = 2,
    remaining_stock = 2
WHERE name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르';

-- 3. 수정 후 전체 아바타 상태 확인
SELECT 
    id, name, price, is_limited, total_supply, remaining_stock
FROM avatar_items 
ORDER BY price;
