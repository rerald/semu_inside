-- Supabase Auth 사용자 생성 시 자동으로 profiles 테이블에 레코드 생성하는 트리거
-- 이 트리거가 없으면 Auth에는 사용자가 있지만 profiles 테이블에는 없는 상황이 발생

-- handle_new_user 함수 생성
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)), -- 이름이 없으면 이메일 앞부분 사용
    NEW.email,
    'employee', -- 기본 역할
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- auth.users 테이블에 트리거 설정
-- 새 사용자가 Auth에 생성될 때마다 자동으로 profiles 테이블에도 레코드 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 기존 profiles 테이블 정책 업데이트 (필요한 경우)
-- 관리자가 다른 사용자의 프로필을 조회할 수 있도록 허용
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 관리자가 다른 사용자의 프로필을 수정할 수 있도록 허용
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 관리자가 프로필을 삭제할 수 있도록 허용
DROP POLICY IF EXISTS "Admins can delete profiles" ON profiles;
CREATE POLICY "Admins can delete profiles" ON profiles
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 시스템이 새 사용자의 프로필을 생성할 수 있도록 허용 (트리거용)
DROP POLICY IF EXISTS "System can insert profiles" ON profiles;
CREATE POLICY "System can insert profiles" ON profiles
    FOR INSERT WITH CHECK (true);

COMMENT ON FUNCTION public.handle_new_user() IS 'Supabase Auth에서 새 사용자가 생성될 때 자동으로 profiles 테이블에 기본 프로필을 생성하는 함수';
COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 'Auth 사용자 생성 시 profiles 테이블에 자동으로 레코드 생성';
