-- 부정확한 로그인 시간 데이터 정리
-- 모든 사용자의 last_login_at을 NULL로 초기화하여 정확한 추적 시작

-- 1. 모든 사용자의 로그인 시간을 NULL로 초기화
UPDATE public.profiles SET last_login_at = NULL;

-- 2. 확인 쿼리
SELECT 
    name, 
    email, 
    created_at,
    last_login_at,
    CASE 
        WHEN last_login_at IS NULL THEN '로그인 기록 없음'
        ELSE TO_CHAR(last_login_at, 'YYYY-MM-DD HH24:MI:SS')
    END as login_status
FROM profiles 
ORDER BY name;

-- 3. 통계 확인
SELECT 
    COUNT(*) as total_users,
    COUNT(last_login_at) as users_with_login_records,
    COUNT(*) - COUNT(last_login_at) as users_without_login_records
FROM profiles;

-- 이제 사용자가 실제로 로그인할 때마다 정확한 시간이 기록됩니다.
