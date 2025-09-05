-- 포인트 관리 테이블들 생성
-- 세무인사이드 시험 플랫폼용

-- 사용자 포인트 테이블 (총 포인트 보관)
CREATE TABLE IF NOT EXISTS user_points (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 포인트 거래 내역 테이블
CREATE TABLE IF NOT EXISTS point_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    points INTEGER NOT NULL, -- 양수는 획득, 음수는 사용
    description TEXT NOT NULL,
    session_id UUID, -- 시험 세션 ID (있는 경우)
    exam_id UUID, -- 시험 ID (있는 경우)
    transaction_type VARCHAR(20) DEFAULT 'earn' CHECK (transaction_type IN ('earn', 'spend', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_point_transactions_user_id ON point_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_point_transactions_created_at ON point_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_point_transactions_session_id ON point_transactions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_points_total_points ON user_points(total_points DESC);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 포인트만 볼 수 있음
CREATE POLICY "Users can view own points" ON user_points
    FOR SELECT USING (auth.uid() = user_id);

-- 사용자는 자신의 거래 내역만 볼 수 있음
CREATE POLICY "Users can view own transactions" ON point_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- 관리자는 모든 데이터를 볼 수 있음
CREATE POLICY "Admins can view all points" ON user_points
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Admins can view all transactions" ON point_transactions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- 시스템이 포인트를 추가/수정할 수 있음 (서비스 키 사용 시)
CREATE POLICY "Service role can manage points" ON user_points
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage transactions" ON point_transactions
    FOR ALL USING (auth.role() = 'service_role');
