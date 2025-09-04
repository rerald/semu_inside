-- 아바타 시스템 데이터베이스 스키마
-- Supabase SQL Editor에서 실행하세요

-- 1. 사용자 포인트 테이블
CREATE TABLE IF NOT EXISTS user_points (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) UNIQUE,
    points INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 아바타 아이템 테이블 (한정판 기능 포함)
CREATE TABLE IF NOT EXISTS avatar_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    price INTEGER NOT NULL DEFAULT 0,
    rarity VARCHAR NOT NULL DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    image_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- 한정판 관련 컬럼들
    is_limited BOOLEAN DEFAULT FALSE,
    total_supply INTEGER,
    remaining_stock INTEGER,
    release_date TIMESTAMPTZ DEFAULT NOW(),
    sale_end_date TIMESTAMPTZ,
    creator_id UUID REFERENCES profiles(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 사용자 아바타 (구매한 아바타)
CREATE TABLE IF NOT EXISTS user_avatars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id),
    avatar_item_id UUID REFERENCES avatar_items(id),
    is_active BOOLEAN DEFAULT TRUE,
    purchased_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 포인트 거래 내역
CREATE TABLE IF NOT EXISTS point_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id),
    amount INTEGER NOT NULL,
    transaction_type VARCHAR NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'refund')),
    description TEXT,
    avatar_item_id UUID REFERENCES avatar_items(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_points_user_id ON user_points(user_id);
CREATE INDEX IF NOT EXISTS idx_avatar_items_rarity ON avatar_items(rarity);
CREATE INDEX IF NOT EXISTS idx_avatar_items_is_active ON avatar_items(is_active);
CREATE INDEX IF NOT EXISTS idx_avatar_items_is_limited ON avatar_items(is_limited);
CREATE INDEX IF NOT EXISTS idx_user_avatars_user_id ON user_avatars(user_id);
CREATE INDEX IF NOT EXISTS idx_user_avatars_avatar_item_id ON user_avatars(avatar_item_id);
CREATE INDEX IF NOT EXISTS idx_point_transactions_user_id ON point_transactions(user_id);

-- RLS (Row Level Security) 정책 설정

-- user_points 테이블
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "사용자는 자신의 포인트만 조회 가능" ON user_points
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "관리자는 모든 포인트 조회 가능" ON user_points
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- avatar_items 테이블  
ALTER TABLE avatar_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "모든 사용자가 활성 아바타 아이템 조회 가능" ON avatar_items
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY "관리자는 아바타 아이템 관리 가능" ON avatar_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- user_avatars 테이블
ALTER TABLE user_avatars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "사용자는 자신의 아바타만 조회 가능" ON user_avatars
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "사용자는 자신의 아바타만 관리 가능" ON user_avatars
    FOR ALL USING (auth.uid() = user_id);

-- point_transactions 테이블
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "사용자는 자신의 거래 내역만 조회 가능" ON point_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "관리자는 모든 거래 내역 조회 가능" ON point_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 샘플 아바타 데이터 삽입
INSERT INTO avatar_items (name, description, price, rarity, image_url) VALUES
    ('기본 아바타', '기본 제공되는 아바타입니다.', 0, 'common', 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iMzUiIGZpbGw9IiNGRkQ3QjciLz4KPGNpcmNsZSBjeD0iMzAiIGN5PSIzNSIgcj0iMyIgZmlsbD0iIzMzMzMzMyIvPgo8Y2lyY2xlIGN4PSI1MCIgY3k9IjM1IiByPSIzIiBmaWxsPSIjMzMzMzMzIi8+CjxwYXRoIGQ9Ik0yNSA1MEM1NSA1MCA1NSA1MCA1NSA1MCIgc3Ryb2tlPSIjMzMzMzMzIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K'),
    ('귀여운 아바타', '귀여운 스타일의 아바타입니다.', 100, 'uncommon', 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iMzUiIGZpbGw9IiNGRkQ3QjciLz4KPGNpcmNsZSBjeD0iMzAiIGN5PSIzNSIgcj0iMyIgZmlsbD0iIzMzMzMzMyIvPgo8Y2lyY2xlIGN4PSI1MCIgY3k9IjM1IiByPSIzIiBmaWxsPSIjMzMzMzMzIi8+CjxwYXRoIGQ9Ik0yNSA1MEM1NSA1MCA1NSA1MCA1NSA1MCIgc3Ryb2tlPSIjMzMzMzMzIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K'),
    ('멋진 아바타', '멋진 스타일의 아바타입니다.', 500, 'rare', 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iMzUiIGZpbGw9IiNGRkQ3QjciLz4KPGNpcmNsZSBjeD0iMzAiIGN5PSIzNSIgcj0iMyIgZmlsbD0iIzMzMzMzMyIvPgo8Y2lyY2xlIGN4PSI1MCIgY3k9IjM1IiByPSIzIiBmaWxsPSIjMzMzMzMzIi8+CjxwYXRoIGQ9Ik0yNSA1MEM1NSA1MCA1NSA1MCA1NSA1MCIgc3Ryb2tlPSIjMzMzMzMzIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K'),
    ('전설의 아바타', '매우 희귀한 전설급 아바타입니다.', 2000, 'legendary', 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iMzUiIGZpbGw9IiNGRkQ3QjciLz4KPGNpcmNsZSBjeD0iMzAiIGN5PSIzNSIgcj0iMyIgZmlsbD0iIzMzMzMzMyIvPgo8Y2lyY2xlIGN4PSI1MCIgY3k9IjM1IiByPSIzIiBmaWxsPSIjMzMzMzMzIi8+CjxwYXRoIGQ9Ik0yNSA1MEM1NSA1MCA1NSA1MCA1NSA1MCIgc3Ryb2tlPSIjMzMzMzMzIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K');

-- 성공 메시지
SELECT '✅ 아바타 시스템 데이터베이스가 성공적으로 설정되었습니다!' as message;
