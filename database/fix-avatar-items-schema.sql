-- avatar_items 테이블에 created_by 컬럼 추가
-- 사용자가 생성한 아이템을 추적하기 위한 컬럼

-- 1. created_by 컬럼 추가
ALTER TABLE avatar_items 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- 2. 기존 데이터에 대한 기본값 설정 (관리자 계정으로 설정)
-- admin@semu.com 계정의 ID를 찾아서 설정
UPDATE avatar_items 
SET created_by = (
    SELECT id FROM profiles 
    WHERE email = 'admin@semu.com' 
    LIMIT 1
)
WHERE created_by IS NULL;

-- 3. created_by 컬럼을 NOT NULL로 변경 (기본값 설정 후)
ALTER TABLE avatar_items 
ALTER COLUMN created_by SET NOT NULL;

-- 4. 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_avatar_items_created_by ON avatar_items(created_by);
CREATE INDEX IF NOT EXISTS idx_avatar_items_category ON avatar_items(category);
CREATE INDEX IF NOT EXISTS idx_avatar_items_rarity ON avatar_items(rarity);

-- 5. RLS 정책 추가 (사용자는 자신이 생성한 아이템만 수정/삭제 가능)
ALTER TABLE avatar_items ENABLE ROW LEVEL SECURITY;

-- 사용자가 자신이 생성한 아이템을 조회할 수 있는 정책
CREATE POLICY "Users can view all active avatar items" ON avatar_items
    FOR SELECT USING (is_active = true);

-- 사용자가 자신이 생성한 아이템을 수정할 수 있는 정책
CREATE POLICY "Users can update their own avatar items" ON avatar_items
    FOR UPDATE USING (auth.uid() = created_by);

-- 사용자가 자신이 생성한 아이템을 삭제할 수 있는 정책
CREATE POLICY "Users can delete their own avatar items" ON avatar_items
    FOR DELETE USING (auth.uid() = created_by);

-- 사용자가 새 아이템을 생성할 수 있는 정책
CREATE POLICY "Users can create avatar items" ON avatar_items
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- 6. 확인 쿼리
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'avatar_items' 
ORDER BY ordinal_position;
