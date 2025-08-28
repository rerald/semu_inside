-- admin@semu.com 계정의 프로필 상태 확인 및 수정

-- 1. 현재 profiles 테이블에서 admin 계정 확인
SELECT 
    id, 
    email, 
    name, 
    role, 
    created_at,
    department_id
FROM profiles 
WHERE email = 'admin@semu.com';

-- 2. auth.users 테이블에서 admin 계정의 UUID 확인
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'admin@semu.com';

-- 3. admin 계정이 profiles에 없다면 추가
INSERT INTO profiles (id, email, name, role)
SELECT 
    au.id,
    'admin@semu.com',
    '시스템 관리자',
    'super_admin'
FROM auth.users au
WHERE au.email = 'admin@semu.com'
AND NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.email = 'admin@semu.com'
);

-- 4. admin 계정이 이미 있다면 role 업데이트
UPDATE profiles 
SET 
    role = 'super_admin',
    name = COALESCE(name, '시스템 관리자')
WHERE email = 'admin@semu.com';

-- 5. 최종 확인
SELECT 
    p.id,
    p.email,
    p.name,
    p.role,
    au.email_confirmed_at,
    au.last_sign_in_at
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE p.email = 'admin@semu.com';
