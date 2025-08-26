-- 세무인사이드 시험 플랫폼 데이터베이스 스키마
-- Supabase PostgreSQL용

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 부서 테이블
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    parent_id UUID REFERENCES departments(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 직원 프로필 테이블 (Supabase Auth 확장)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department_id UUID REFERENCES departments(id),
    hire_date DATE,
    phone VARCHAR(20),
    role VARCHAR(20) DEFAULT 'employee' CHECK (role IN ('employee', 'admin', 'super_admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 카테고리 테이블 (세목, 과목, 영역 분류)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('subject', 'area', 'chapter')), -- 세목, 영역, 장
    code VARCHAR(50),
    parent_id UUID REFERENCES categories(id),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 문제 그룹 테이블 (공통 지문)
CREATE TABLE question_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200),
    content TEXT NOT NULL, -- 공통 지문
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 문제 테이블
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('multiple_choice', 'subjective', 'group')),
    content TEXT NOT NULL,
    explanation TEXT, -- 해설
    difficulty INTEGER DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    group_id UUID REFERENCES question_groups(id), -- 그룹형 문제인 경우
    category_id UUID REFERENCES categories(id),
    tags TEXT[], -- 태그 배열
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 객관식 선택지 테이블
CREATE TABLE question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 시험지 테이블
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    duration INTEGER NOT NULL, -- 분 단위
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'closed')),
    passing_score INTEGER DEFAULT 60, -- 합격 점수
    show_results BOOLEAN DEFAULT TRUE, -- 결과 공개 여부
    randomize_questions BOOLEAN DEFAULT FALSE, -- 문제 순서 랜덤화
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 시험-문제 매핑 테이블
CREATE TABLE exam_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    order_index INTEGER DEFAULT 0,
    points INTEGER DEFAULT 1, -- 배점
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(exam_id, question_id)
);

-- 시험 권한 부여 테이블
CREATE TABLE exam_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES profiles(id),
    department_id UUID REFERENCES departments(id),
    granted_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK ((employee_id IS NOT NULL AND department_id IS NULL) OR 
           (employee_id IS NULL AND department_id IS NOT NULL))
);

-- 시험 세션 테이블 (응시 기록)
CREATE TABLE exam_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id),
    employee_id UUID REFERENCES profiles(id),
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submit_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER, -- 실제 응시 시간
    score INTEGER,
    total_points INTEGER,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'graded')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(exam_id, employee_id) -- 한 시험당 한 번만 응시 가능
);

-- 답안 기록 테이블
CREATE TABLE exam_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES exam_sessions(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id),
    answer TEXT, -- 객관식: 선택지 ID, 주관식: 텍스트 답안
    is_correct BOOLEAN,
    points INTEGER DEFAULT 0, -- 획득 점수
    graded_by UUID REFERENCES profiles(id), -- 주관식 채점자
    graded_at TIMESTAMP WITH TIME ZONE,
    auto_saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_id, question_id)
);

-- 통계 뷰 생성
CREATE OR REPLACE VIEW exam_statistics AS
SELECT 
    e.id as exam_id,
    e.title as exam_title,
    COUNT(es.id) as total_participants,
    AVG(es.score) as average_score,
    MAX(es.score) as highest_score,
    MIN(es.score) as lowest_score,
    COUNT(CASE WHEN es.score >= e.passing_score THEN 1 END) as passed_count,
    COUNT(CASE WHEN es.status = 'submitted' OR es.status = 'graded' THEN 1 END) as completed_count
FROM exams e
LEFT JOIN exam_sessions es ON e.id = es.exam_id
GROUP BY e.id, e.title, e.passing_score;

-- 문제별 정답률 뷰
CREATE OR REPLACE VIEW question_statistics AS
SELECT 
    q.id as question_id,
    q.content as question_content,
    q.type as question_type,
    c.name as category_name,
    COUNT(ea.id) as total_answers,
    COUNT(CASE WHEN ea.is_correct = true THEN 1 END) as correct_answers,
    CASE 
        WHEN COUNT(ea.id) > 0 
        THEN ROUND((COUNT(CASE WHEN ea.is_correct = true THEN 1 END)::float / COUNT(ea.id)::float) * 100, 2)
        ELSE 0 
    END as correct_rate
FROM questions q
LEFT JOIN categories c ON q.category_id = c.id
LEFT JOIN exam_answers ea ON q.id = ea.question_id
GROUP BY q.id, q.content, q.type, c.name;

-- 인덱스 생성
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_department ON profiles(department_id);
CREATE INDEX idx_questions_category ON questions(category_id);
CREATE INDEX idx_questions_type ON questions(type);
CREATE INDEX idx_exam_sessions_employee ON exam_sessions(employee_id);
CREATE INDEX idx_exam_sessions_exam ON exam_sessions(exam_id);
CREATE INDEX idx_exam_answers_session ON exam_answers(session_id);
CREATE INDEX idx_exam_answers_question ON exam_answers(question_id);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_answers ENABLE ROW LEVEL SECURITY;

-- 프로필 정책: 사용자는 자신의 프로필만 조회/수정 가능
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- 시험 정책: 모든 사용자가 공개된 시험 조회 가능
CREATE POLICY "Users can view published exams" ON exams
    FOR SELECT USING (status = 'published');

-- 관리자는 모든 시험 관리 가능
CREATE POLICY "Admins can manage exams" ON exams
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 시험 세션 정책: 사용자는 자신의 세션만 조회/수정 가능
CREATE POLICY "Users can view own sessions" ON exam_sessions
    FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "Users can update own sessions" ON exam_sessions
    FOR UPDATE USING (employee_id = auth.uid());

-- 관리자는 모든 세션 조회 가능
CREATE POLICY "Admins can view all sessions" ON exam_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- 답안 정책: 사용자는 자신의 답안만 조회/수정 가능
CREATE POLICY "Users can view own answers" ON exam_answers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM exam_sessions 
            WHERE id = session_id 
            AND employee_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own answers" ON exam_answers
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM exam_sessions 
            WHERE id = session_id 
            AND employee_id = auth.uid()
        )
    );

-- 기본 데이터 삽입
INSERT INTO departments (name, code) VALUES 
('세무팀', 'TAX'),
('감사팀', 'AUDIT'),
('컨설팅팀', 'CONSULTING'),
('관리팀', 'ADMIN');

INSERT INTO categories (name, type, code) VALUES 
('부가가치세', 'subject', 'VAT'),
('소득세', 'subject', 'INCOME'),
('법인세', 'subject', 'CORPORATE'),
('상속증여세', 'subject', 'INHERITANCE'),
('국세기본법', 'subject', 'BASIC'),
('세무회계', 'area', 'ACCOUNTING'),
('세무조사', 'area', 'AUDIT'),
('세무상담', 'area', 'CONSULTING');

-- 함수: 자동 업데이트 타임스탬프
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_sessions_updated_at BEFORE UPDATE ON exam_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_answers_updated_at BEFORE UPDATE ON exam_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
