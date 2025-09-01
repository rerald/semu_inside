-- 미라클모닝팀 추가
INSERT INTO departments (id, name, code, parent_id, created_at, updated_at)
VALUES (
    uuid_generate_v4(),
    '미라클모닝팀 (Miracle Morning Team)',
    'MIRACLE_MORNING',
    NULL,
    NOW(),
    NOW()
);

-- 추가된 팀 확인
SELECT * FROM departments WHERE code = 'MIRACLE_MORNING';
