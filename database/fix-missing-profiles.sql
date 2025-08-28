-- Auth에는 있지만 profiles 테이블에 없는 사용자들의 프로필을 생성하는 복구 스크립트

-- 1. 현재 상황 확인
-- Auth에 있지만 profiles에 없는 사용자들 찾기
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'name' as metadata_name,
    CASE WHEN p.id IS NULL THEN 'MISSING' ELSE 'EXISTS' END as profile_status
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ORDER BY au.created_at;

-- 2. 누락된 프로필들을 복구
-- Auth에는 있지만 profiles에 없는 사용자들의 기본 프로필 생성
INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
SELECT 
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'name', 
        split_part(au.email, '@', 1)
    ) as name,
    au.email,
    'employee' as role,
    au.created_at,
    NOW() as updated_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- 3. 복구 결과 확인
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN p.id IS NOT NULL THEN 1 END) as users_with_profiles,
    COUNT(CASE WHEN p.id IS NULL THEN 1 END) as users_missing_profiles
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id;

-- 4. 최근 생성된 프로필들 확인
SELECT 
    p.name,
    p.email,
    p.role,
    p.created_at,
    'RECOVERED' as status
FROM public.profiles p
WHERE p.updated_at > NOW() - INTERVAL '1 minute'
ORDER BY p.created_at DESC;
