-- Supabase에서 관리자 비밀번호를 재설정하는 방법

-- 참고: 이 SQL은 Supabase에서 직접 실행할 수 없습니다.
-- 대신 다음 방법들을 사용하세요:

/*
방법 1: Supabase 대시보드에서
1. Authentication > Users 메뉴 이동
2. admin@semu.com 사용자 클릭
3. "Reset password" 또는 "Send recovery email" 클릭
4. 새 비밀번호 설정: Admin123!

방법 2: SQL로 비밀번호 해시 확인
*/

-- auth.users 테이블에서 현재 상태 확인
SELECT 
    id,
    email,
    encrypted_password IS NOT NULL as has_password,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    updated_at
FROM auth.users 
WHERE email = 'admin@semu.com';

-- 이메일 확인 상태 업데이트 (필요한 경우)
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'admin@semu.com' 
AND email_confirmed_at IS NULL;
