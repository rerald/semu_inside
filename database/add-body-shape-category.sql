-- 아바타 체형(body) 카테고리 추가
-- avatar_items 테이블의 category 체크 제약 조건 수정

-- 1. 기존 체크 제약 조건 삭제
ALTER TABLE avatar_items DROP CONSTRAINT IF EXISTS avatar_items_category_check;

-- 2. 새로운 체크 제약 조건 추가 (body 카테고리 포함)
ALTER TABLE avatar_items ADD CONSTRAINT avatar_items_category_check 
CHECK (category IN ('face', 'hair', 'top', 'bottom', 'accessory', 'background', 'body'));

-- 3. 기본 체형 아이템들 추가
INSERT INTO avatar_items (name, description, category, price, rarity, image_url, is_limited, is_active) VALUES
('기본 체형', '기본적인 체형입니다.', 'body', 0, 'common', NULL, FALSE, TRUE),
('마른 체형', '슬림한 체형입니다.', 'body', 500, 'common', NULL, FALSE, TRUE),
('건장한 체형', '근육이 발달한 체형입니다.', 'body', 1000, 'rare', NULL, FALSE, TRUE),
('통통한 체형', '둥글고 귀여운 체형입니다.', 'body', 800, 'common', NULL, FALSE, TRUE),
('키 큰 체형', '장신 체형입니다.', 'body', 1200, 'rare', NULL, FALSE, TRUE),
('키 작은 체형', '단신 체형입니다.', 'body', 600, 'common', NULL, FALSE, TRUE),
('운동선수 체형', '탄탄한 근육의 체형입니다.', 'body', 2000, 'epic', NULL, FALSE, TRUE),
('아이 체형', '어린이 같은 체형입니다.', 'body', 300, 'common', NULL, FALSE, TRUE);

-- 4. user_avatars 테이블에 body_item_id 컬럼 추가
ALTER TABLE user_avatars 
ADD COLUMN IF NOT EXISTS body_item_id UUID REFERENCES avatar_items(id) ON DELETE SET NULL;

-- 5. 확인 쿼리
SELECT category, COUNT(*) as count 
FROM avatar_items 
WHERE category = 'body' 
GROUP BY category;
