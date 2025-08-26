-- profiles 테이블에 누락된 INSERT 정책 추가

-- 사용자가 자신의 프로필을 생성할 수 있도록 허용
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 또는 더 안전한 방법: 서비스 역할로만 INSERT 허용 (회원가입 시에만)
-- 이미 위 정책이 있다면 이걸로 대체할 수도 있습니다:
-- DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
-- CREATE POLICY "Service role can insert profiles" ON profiles
--     FOR INSERT TO service_role WITH CHECK (true);

-- 기존 정책들 확인
-- SELECT * FROM pg_policies WHERE tablename = 'profiles';
