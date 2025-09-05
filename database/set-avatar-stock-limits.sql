-- 🏷️ 아바타 아이템에 재고 한정 설정

-- 1. 무료 아이템 (센팍)은 무제한으로 유지
UPDATE avatar_items 
SET 
    is_limited = FALSE,
    total_supply = NULL,
    remaining_stock = NULL
WHERE name = '센팍' AND price = 0;

-- 2. 유료 아이템들을 한정판으로 설정
UPDATE avatar_items 
SET 
    is_limited = TRUE,
    total_supply = CASE 
        WHEN name = '트랄랄레로 트랄랄라' THEN 50
        WHEN name = '뷔' THEN 30
        WHEN name = '봄바르디로 크로코딜로' THEN 20
        WHEN name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르' THEN 10
        ELSE 100 -- 기본값
    END,
    remaining_stock = CASE 
        WHEN name = '트랄랄레로 트랄랄라' THEN 50
        WHEN name = '뷔' THEN 30
        WHEN name = '봄바르디로 크로코딜로' THEN 20
        WHEN name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르' THEN 10
        ELSE 100 -- 기본값
    END
WHERE name IN ('트랄랄레로 트랄랄라', '뷔', '봄바르디로 크로코딜로', '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르');

-- 3. 업데이트 결과 확인
SELECT 
    name,
    price,
    is_limited,
    total_supply,
    remaining_stock,
    CASE 
        WHEN is_limited = FALSE THEN '무제한'
        WHEN remaining_stock IS NULL THEN '재고정보 없음'
        WHEN remaining_stock <= 0 THEN '품절'
        ELSE CONCAT('재고: ', remaining_stock, '/', total_supply)
    END as stock_status
FROM avatar_items 
WHERE is_active = true
ORDER BY price ASC;
