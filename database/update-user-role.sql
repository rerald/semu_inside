-- rerald293@gmail.com 사용자의 역할을 admin으로 변경
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'rerald293@gmail.com';

-- 변경 결과 확인
SELECT id, email, name, role, created_at 
FROM profiles 
WHERE email = 'rerald293@gmail.com';
