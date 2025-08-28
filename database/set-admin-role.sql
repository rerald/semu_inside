-- 기존 사용자를 관리자로 승격시키는 SQL
-- Supabase SQL 에디터에서 실행하세요

-- rerald293@gmail.com를 슈퍼 관리자로 승격
UPDATE profiles 
SET role = 'super_admin'
WHERE email = 'rerald293@gmail.com';

-- 또는 새로운 관리자 계정이 profiles 테이블에 있다면
UPDATE profiles 
SET role = 'super_admin'
WHERE email = 'admin@semu.com';

-- 현재 profiles 테이블의 모든 사용자 확인
SELECT id, email, name, role, created_at 
FROM profiles 
ORDER BY created_at DESC;
