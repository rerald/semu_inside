-- 사용자-부서 매핑 테이블 생성 (다대다 관계)
CREATE TABLE user_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE, -- 주 부서 여부
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, department_id)
);

-- 기존 profiles 테이블의 department_id를 매핑 테이블로 마이그레이션
INSERT INTO user_departments (user_id, department_id, is_primary)
SELECT id, department_id, TRUE
FROM profiles 
WHERE department_id IS NOT NULL;

-- profiles 테이블에서 department_id 컬럼 제거 (선택사항)
-- ALTER TABLE profiles DROP COLUMN department_id;

-- 인덱스 생성
CREATE INDEX idx_user_departments_user_id ON user_departments(user_id);
CREATE INDEX idx_user_departments_department_id ON user_departments(department_id);

-- 사용자별 부서 조회 뷰 생성
CREATE VIEW user_departments_view AS
SELECT 
    p.id as user_id,
    p.name as user_name,
    p.email,
    array_agg(d.name) as department_names,
    array_agg(d.code) as department_codes,
    array_agg(ud.department_id) as department_ids,
    array_agg(ud.is_primary) as is_primary_flags
FROM profiles p
LEFT JOIN user_departments ud ON p.id = ud.user_id
LEFT JOIN departments d ON ud.department_id = d.id
GROUP BY p.id, p.name, p.email;

-- 사용자에게 부서 추가하는 함수
CREATE OR REPLACE FUNCTION add_user_to_department(
    p_user_id UUID,
    p_department_id UUID,
    p_is_primary BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
BEGIN
    -- 이미 해당 부서에 속해있는지 확인
    IF EXISTS (SELECT 1 FROM user_departments WHERE user_id = p_user_id AND department_id = p_department_id) THEN
        RAISE EXCEPTION 'User is already a member of this department';
    END IF;
    
    -- 주 부서로 설정하는 경우, 기존 주 부서를 해제
    IF p_is_primary THEN
        UPDATE user_departments 
        SET is_primary = FALSE 
        WHERE user_id = p_user_id AND is_primary = TRUE;
    END IF;
    
    -- 새 부서 추가
    INSERT INTO user_departments (user_id, department_id, is_primary)
    VALUES (p_user_id, p_department_id, p_is_primary);
END;
$$ LANGUAGE plpgsql;

-- 사용자에게 부서 제거하는 함수
CREATE OR REPLACE FUNCTION remove_user_from_department(
    p_user_id UUID,
    p_department_id UUID
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM user_departments 
    WHERE user_id = p_user_id AND department_id = p_department_id;
    
    -- 삭제된 부서가 주 부서였고, 다른 부서가 있다면 첫 번째를 주 부서로 설정
    IF NOT EXISTS (SELECT 1 FROM user_departments WHERE user_id = p_user_id AND is_primary = TRUE) THEN
        UPDATE user_departments 
        SET is_primary = TRUE 
        WHERE user_id = p_user_id 
        AND id = (SELECT id FROM user_departments WHERE user_id = p_user_id LIMIT 1);
    END IF;
END;
$$ LANGUAGE plpgsql;
