-- profiles 테이블에 last_login_at 컬럼 추가
-- 사용자의 최신 로그인 시간을 추적하기 위한 필드

-- 1. last_login_at 컬럼 추가
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;

-- 2. 컬럼 설명 추가
COMMENT ON COLUMN profiles.last_login_at IS '사용자의 최근 로그인 시간';

-- 3. 인덱스 추가 (성능 향상을 위해)
CREATE INDEX IF NOT EXISTS idx_profiles_last_login_at ON profiles(last_login_at) WHERE last_login_at IS NOT NULL;

-- 4. 현재 활성 사용자들의 last_login_at을 현재 시간으로 초기화 (선택사항)
-- UPDATE profiles SET last_login_at = NOW() WHERE last_login_at IS NULL;

-- 5. 확인 쿼리
SELECT 
    name, 
    email, 
    created_at,
    last_login_at,
    CASE 
        WHEN last_login_at IS NULL THEN '로그인 기록 없음'
        WHEN last_login_at > NOW() - INTERVAL '1 day' THEN '오늘'
        WHEN last_login_at > NOW() - INTERVAL '2 days' THEN '어제'
        WHEN last_login_at > NOW() - INTERVAL '7 days' THEN CONCAT(EXTRACT(DAY FROM NOW() - last_login_at), '일 전')
        ELSE TO_CHAR(last_login_at, 'YYYY-MM-DD')
    END as login_status
FROM profiles 
ORDER BY last_login_at DESC NULLS LAST
LIMIT 10;
