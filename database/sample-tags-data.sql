-- 샘플 태그 데이터 및 사용자-태그 연결
-- database/add-user-tags.sql 실행 후 이 파일을 실행하세요

-- 1) 샘플 태그 생성
INSERT INTO public.tags (name, description) VALUES
('수원시청점', '수원시청 지점 소속'),
('팀장', '팀장급 직급'),
('본사', '본사 소속'),
('계약직', '계약직 직원'),
('정규직', '정규직 직원'),
('신입', '신입 직원'),
('경력', '경력직 직원'),
('관리자', '관리자 권한 보유'),
('개발팀', '개발팀 소속'),
('교육팀', '교육팀 소속'),
('세무팀', '세무팀 소속'),
('영업팀', '영업팀 소속')
ON CONFLICT (name) DO NOTHING;

-- 2) 사용자-태그 연결 예시 (실제 사용자 ID로 수정 필요)
-- 먼저 profiles 테이블에서 사용자 ID를 확인하세요
-- SELECT id, name, email FROM profiles LIMIT 10;

-- 예시: 특정 사용자들에게 태그 연결
-- INSERT INTO public.user_tags (user_id, tag_id) 
-- SELECT 
--     p.id as user_id,
--     t.id as tag_id
-- FROM profiles p, tags t
-- WHERE p.name = '이규상' AND t.name = '관리자'
-- ON CONFLICT (user_id, tag_id) DO NOTHING;

-- 3) 부서별 태그 자동 연결 (부서명과 태그명이 일치하는 경우)
INSERT INTO public.user_tags (user_id, tag_id)
SELECT 
    p.id as user_id,
    t.id as tag_id
FROM profiles p
JOIN departments d ON p.department_id = d.id
JOIN tags t ON d.name = t.name
ON CONFLICT (user_id, tag_id) DO NOTHING;

-- 4) 권한별 태그 자동 연결
INSERT INTO public.user_tags (user_id, tag_id)
SELECT 
    p.id as user_id,
    t.id as tag_id
FROM profiles p
JOIN tags t ON (
    (p.role = 'super_admin' AND t.name = '관리자') OR
    (p.role = 'admin' AND t.name = '관리자')
)
ON CONFLICT (user_id, tag_id) DO NOTHING;

-- 5) 확인 쿼리
-- 사용자별 태그 확인
SELECT 
    p.name as 사용자명,
    p.email as 이메일,
    d.name as 부서,
    p.role as 권한,
    array_agg(t.name) as 태그목록
FROM profiles p
LEFT JOIN departments d ON p.department_id = d.id
LEFT JOIN user_tags ut ON p.id = ut.user_id
LEFT JOIN tags t ON ut.tag_id = t.id
GROUP BY p.id, p.name, p.email, d.name, p.role
ORDER BY p.name;
