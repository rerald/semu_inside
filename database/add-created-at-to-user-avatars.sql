-- 🔧 user_avatars 테이블에 created_at 컬럼 추가

-- 1. created_at 컬럼 추가
ALTER TABLE user_avatars 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. 기존 데이터에 created_at 값 설정 (현재 시간으로)
UPDATE user_avatars 
SET created_at = NOW() 
WHERE created_at IS NULL;

-- 3. 컬럼을 NOT NULL로 설정
ALTER TABLE user_avatars 
ALTER COLUMN created_at SET NOT NULL;

-- 4. 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_user_avatars_created_at 
ON user_avatars(created_at);

-- 5. 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_avatars'
ORDER BY ordinal_position;
