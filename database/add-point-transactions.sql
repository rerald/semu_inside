-- rerald293@gmail.com의 포인트 거래 기록 추가
-- 1. 현재 포인트 확인
SELECT 
    p.name,
    p.email,
    up.points
FROM profiles p
JOIN user_points up ON p.id = up.user_id
WHERE p.email = 'rerald293@gmail.com';

-- 2. 포인트 차감 (뷔: 500P, 트랄랄레로 트랄랄라: 300P, 총 800P)
UPDATE user_points 
SET points = points - 800
WHERE user_id = (
    SELECT id FROM profiles WHERE email = 'rerald293@gmail.com'
);

-- 3. 포인트 거래 기록 추가
INSERT INTO point_transactions (user_id, amount, transaction_type, description, created_at)
SELECT 
    p.id,
    -500,
    'spend',
    '아바타 구매: 뷔',
    NOW()
FROM profiles p
WHERE p.email = 'rerald293@gmail.com';

INSERT INTO point_transactions (user_id, amount, transaction_type, description, created_at)
SELECT 
    p.id,
    -300,
    'spend',
    '아바타 구매: 트랄랄레로 트랄랄라',
    NOW()
FROM profiles p
WHERE p.email = 'rerald293@gmail.com';

-- 4. 거래 후 포인트 확인
SELECT 
    p.name,
    p.email,
    up.points
FROM profiles p
JOIN user_points up ON p.id = up.user_id
WHERE p.email = 'rerald293@gmail.com';

-- 5. 최근 포인트 거래 기록 확인
SELECT 
    pt.id,
    pt.amount,
    pt.transaction_type,
    pt.description,
    pt.created_at,
    p.name as user_name,
    p.email
FROM point_transactions pt
JOIN profiles p ON pt.user_id = p.id
WHERE p.email = 'rerald293@gmail.com'
ORDER BY pt.created_at DESC
LIMIT 5;
