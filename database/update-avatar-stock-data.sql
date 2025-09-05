-- 🏷️ 기존 아바타 아이템에 한정판 재고 데이터 추가

-- 1. 기존 아바타 아이템에 한정판 정보 업데이트
UPDATE avatar_items 
SET 
    is_limited = CASE 
        WHEN name = '센팍' THEN false  -- 무료 아이템은 무제한
        WHEN name = '트랄랄레로 트랄랄라' THEN true
        WHEN name = '뷔' THEN true
        WHEN name = '봄바르디로 크로코딜로' THEN true
        WHEN name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르' THEN true
        ELSE false
    END,
    total_supply = CASE 
        WHEN name = '센팍' THEN null  -- 무제한
        WHEN name = '트랄랄레로 트랄랄라' THEN 50
        WHEN name = '뷔' THEN 30
        WHEN name = '봄바르디로 크로코딜로' THEN 20
        WHEN name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르' THEN 10  -- 고가 아이템은 적게
        ELSE null
    END,
    remaining_stock = CASE 
        WHEN name = '센팍' THEN null  -- 무제한
        WHEN name = '트랄랄레로 트랄랄라' THEN 50
        WHEN name = '뷔' THEN 30
        WHEN name = '봄바르디로 크로코딜로' THEN 20
        WHEN name = '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르' THEN 10
        ELSE null
    END
WHERE name IN ('센팍', '트랄랄레로 트랄랄라', '뷔', '봄바르디로 크로코딜로', '퉁퉁퉁퉁퉁퉁퉁퉁퉁 사후르');

-- 2. 재고 상태 확인
SELECT 
    name,
    price,
    is_limited,
    total_supply,
    remaining_stock,
    CASE 
        WHEN is_limited = false THEN '무제한'
        WHEN remaining_stock <= 0 THEN '품절'
        WHEN remaining_stock <= total_supply * 0.1 THEN '품절임박'
        WHEN remaining_stock <= total_supply * 0.3 THEN '재고부족'
        ELSE '재고충분'
    END as stock_status
FROM avatar_items 
WHERE is_active = true
ORDER BY price ASC;

-- 3. 재고 시스템 설정 완료 확인
SELECT 
    '재고 시스템 설정 완료' as status,
    COUNT(*) as total_items,
    COUNT(CASE WHEN is_limited = true THEN 1 END) as limited_items,
    COUNT(CASE WHEN is_limited = true AND remaining_stock <= 0 THEN 1 END) as sold_out_items
FROM avatar_items 
WHERE is_active = true;
