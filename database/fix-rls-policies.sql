-- RLS 정책 문제 해결을 위한 SQL 스크립트
-- Supabase SQL 에디터에서 실행하세요

-- 1. 기존 RLS 정책 확인 및 삭제 (필요시)
-- DROP POLICY IF EXISTS "Users can view published exams" ON exams;
-- DROP POLICY IF EXISTS "Admins can manage exams" ON exams;

-- 2. exams 테이블에 대한 RLS 정책 재설정
-- 모든 사용자가 시험지를 조회할 수 있도록 허용 (개발 단계)
CREATE POLICY "Allow all operations on exams" ON exams
    FOR ALL USING (true);

-- 3. exam_questions 테이블에 대한 RLS 정책 설정
-- 이 테이블에 RLS가 활성화되어 있지 않다면 활성화
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;

-- exam_questions 테이블에 대한 정책 설정
CREATE POLICY "Allow all operations on exam_questions" ON exam_questions
    FOR ALL USING (true);

-- 4. exam_answers 테이블에 대한 RLS 정책 재설정
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can view own answers" ON exam_answers;
DROP POLICY IF EXISTS "Users can update own answers" ON exam_answers;

-- 새로운 정책 설정 (개발 단계에서는 모든 작업 허용)
CREATE POLICY "Allow all operations on exam_answers" ON exam_answers
    FOR ALL USING (true);

-- 5. exam_sessions 테이블에 대한 RLS 정책 재설정
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can view own sessions" ON exam_sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON exam_sessions;
DROP POLICY IF EXISTS "Admins can view all sessions" ON exam_sessions;

-- 새로운 정책 설정 (개발 단계에서는 모든 작업 허용)
CREATE POLICY "Allow all operations on exam_sessions" ON exam_sessions
    FOR ALL USING (true);

-- 6. profiles 테이블에 대한 RLS 정책 재설정 (선택사항)
-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 새로운 정책 설정 (개발 단계에서는 모든 작업 허용)
CREATE POLICY "Allow all operations on profiles" ON profiles
    FOR ALL USING (true);

-- 7. categories 테이블에 대한 RLS 정책 설정 (필요시)
-- 이 테이블에 RLS가 활성화되어 있지 않다면 활성화
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- categories 테이블에 대한 정책 설정
CREATE POLICY "Allow all operations on categories" ON categories
    FOR ALL USING (true);

-- 8. questions 테이블에 대한 RLS 정책 설정 (필요시)
-- 이 테이블에 RLS가 활성화되어 있지 않다면 활성화
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- questions 테이블에 대한 정책 설정
CREATE POLICY "Allow all operations on questions" ON questions
    FOR ALL USING (true);

-- 9. RLS 상태 확인
-- 다음 쿼리로 각 테이블의 RLS 상태를 확인할 수 있습니다:
/*
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('exams', 'exam_questions', 'exam_answers', 'exam_sessions', 'profiles', 'categories', 'questions')
ORDER BY tablename;
*/

-- 10. 정책 확인
-- 다음 쿼리로 각 테이블의 정책을 확인할 수 있습니다:
/*
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('exams', 'exam_questions', 'exam_answers', 'exam_sessions', 'profiles', 'categories', 'questions')
ORDER BY tablename, policyname;
*/

