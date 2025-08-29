-- 세무인사이드 시험 플랫폼 샘플 데이터
-- 개발 및 테스트용 데이터

-- 샘플 카테고리 추가 (기본 데이터 외 추가)
INSERT INTO categories (name, code, description) VALUES 
('부가가치세 신고', 'VAT_FILING', '부가가치세 신고 관련 업무'),
('소득세 계산', 'INCOME_CALC', '소득세 계산 및 절세'),
('법인세 조정', 'CORP_ADJ', '법인세 세무조정'),
('1장 총칙', 'CHAPTER_1', '부가가치세법 1장'),
('2장 과세거래', 'CHAPTER_2', '부가가치세법 2장'),
('3장 납세의무자', 'CHAPTER_3', '부가가치세법 3장');

-- 샘플 문제 그룹 (지문)
INSERT INTO question_groups (title, content, created_by) VALUES 
('부가가치세 사례 1', 
'(주)세무인사이드는 소프트웨어 개발업을 영위하는 법인으로 다음과 같은 거래를 하였다.

1. 2024년 1월: 고객 A에게 소프트웨어 라이선스 공급 - 11,000천원(부가세 포함)
2. 2024년 2월: 사무용품 구입 - 1,100천원(부가세 포함) 
3. 2024년 3월: 직원 교육비 지급 - 550천원(부가세 포함)

위 거래를 바탕으로 다음 문제에 답하시오.',
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1));

-- 샘플 문제들
INSERT INTO questions (type, content, explanation, difficulty, group_id, category_id, tags, created_by) VALUES 

-- 그룹형 문제 (객관식)
('group', 
'1월 소프트웨어 라이선스 공급에 대한 부가가치세 매출세액은?',
'공급가액 10,000천원 × 10% = 1,000천원',
2,
(SELECT id FROM question_groups WHERE title = '부가가치세 사례 1'),
(SELECT id FROM categories WHERE code = 'VAT'),
ARRAY['매출세액', '부가가치세', '라이선스'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

('group',
'2월 사무용품 구입에 대한 부가가치세 매입세액은?',
'공급가액 1,000천원 × 10% = 100천원',
2,
(SELECT id FROM question_groups WHERE title = '부가가치세 사례 1'),
(SELECT id FROM categories WHERE code = 'VAT'),
ARRAY['매입세액', '부가가치세', '사무용품'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

-- 일반 객관식 문제
('multiple_choice',
'부가가치세법상 과세기간은 다음 중 어느 것인가?',
'부가가치세법 제8조에 의하면 과세기간은 1월 1일부터 6월 30일까지, 7월 1일부터 12월 31일까지로 6개월이다.',
1,
NULL,
(SELECT id FROM categories WHERE code = 'VAT'),
ARRAY['과세기간', '부가가치세법'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

('multiple_choice',
'소득세법상 종합소득에 포함되지 않는 것은?',
'양도소득은 종합소득에 합산하지 않고 분리과세한다.',
3,
NULL,
(SELECT id FROM categories WHERE code = 'INCOME'),
ARRAY['종합소득', '소득세', '분류'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

-- 주관식 문제
('subjective',
'법인세법상 손금불산입의 개념과 주요 항목 3가지를 설명하시오.',
'손금불산입은 회계상 비용이지만 세법상 손금으로 인정하지 않는 항목이다. 주요 항목: 1) 접대비 한도초과액, 2) 기부금 한도초과액, 3) 각종 충당금 등',
4,
NULL,
(SELECT id FROM categories WHERE code = 'CORPORATE'),
ARRAY['손금불산입', '법인세', '세무조정'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

('subjective',
'부가가치세 면세사업자의 요건과 장단점을 서술하시오.',
'면세사업자는 직전연도 공급가액이 4,800만원 미만인 사업자로서 부가가치세 납부의무가 없다. 장점: 세금 부담 없음, 간편한 신고. 단점: 매입세액 공제 불가, 신용도 문제',
3,
NULL,
(SELECT id FROM categories WHERE code = 'VAT'),
ARRAY['면세사업자', '부가가치세', '요건'],
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1));

-- 객관식 선택지 추가
INSERT INTO question_options (question_id, content, is_correct, order_index) VALUES 
-- 그룹형 문제 1의 선택지
((SELECT id FROM questions WHERE content LIKE '1월 소프트웨어 라이선스%'), '900천원', false, 1),
((SELECT id FROM questions WHERE content LIKE '1월 소프트웨어 라이선스%'), '1,000천원', true, 2),
((SELECT id FROM questions WHERE content LIKE '1월 소프트웨어 라이선스%'), '1,100천원', false, 3),
((SELECT id FROM questions WHERE content LIKE '1월 소프트웨어 라이선스%'), '1,200천원', false, 4),

-- 그룹형 문제 2의 선택지
((SELECT id FROM questions WHERE content LIKE '2월 사무용품%'), '90천원', false, 1),
((SELECT id FROM questions WHERE content LIKE '2월 사무용품%'), '100천원', true, 2),
((SELECT id FROM questions WHERE content LIKE '2월 사무용품%'), '110천원', false, 3),
((SELECT id FROM questions WHERE content LIKE '2월 사무용품%'), '120천원', false, 4),

-- 과세기간 문제의 선택지
((SELECT id FROM questions WHERE content LIKE '부가가치세법상 과세기간%'), '3개월', false, 1),
((SELECT id FROM questions WHERE content LIKE '부가가치세법상 과세기간%'), '6개월', true, 2),
((SELECT id FROM questions WHERE content LIKE '부가가치세법상 과세기간%'), '12개월', false, 3),
((SELECT id FROM questions WHERE content LIKE '부가가치세법상 과세기간%'), '18개월', false, 4),

-- 종합소득 문제의 선택지
((SELECT id FROM questions WHERE content LIKE '소득세법상 종합소득에%'), '이자소득', false, 1),
((SELECT id FROM questions WHERE content LIKE '소득세법상 종합소득에%'), '배당소득', false, 2),
((SELECT id FROM questions WHERE content LIKE '소득세법상 종합소득에%'), '사업소득', false, 3),
((SELECT id FROM questions WHERE content LIKE '소득세법상 종합소득에%'), '양도소득', true, 4);

-- 샘플 시험지 생성
INSERT INTO exams (title, description, duration, start_time, end_time, status, passing_score, show_results, randomize_questions, created_by) VALUES 
('2024년 1분기 부가가치세 평가',
'부가가치세 기본 개념과 실무 적용 능력을 평가하는 시험입니다.',
60,
NOW() - INTERVAL '1 day',
NOW() + INTERVAL '30 days',
'published',
70,
true,
false,
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

('소득세 기초 이론 시험',
'소득세법의 기본 이론과 계산 능력을 평가합니다.',
45,
NOW() - INTERVAL '1 day',
NOW() + INTERVAL '15 days', 
'published',
60,
true,
false,
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)),

('법인세 실무 응용 시험',
'법인세 실무 처리 능력과 세무조정 이해도를 평가합니다.',
90,
NOW() + INTERVAL '1 day',
NOW() + INTERVAL '7 days',
'draft',
80,
false,
false,
(SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1));

-- 시험-문제 매핑
INSERT INTO exam_questions (exam_id, question_id, order_index, points) VALUES 
-- 부가가치세 평가 (첫 번째 시험)
((SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'), 
 (SELECT id FROM questions WHERE content LIKE '부가가치세법상 과세기간%'), 1, 10),
((SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'), 
 (SELECT id FROM questions WHERE content LIKE '1월 소프트웨어 라이선스%'), 2, 15),
((SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'), 
 (SELECT id FROM questions WHERE content LIKE '2월 사무용품%'), 3, 15),
((SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'), 
 (SELECT id FROM questions WHERE content LIKE '부가가치세 면세사업자%'), 4, 20),

-- 소득세 기초 이론 시험 (두 번째 시험)
((SELECT id FROM exams WHERE title LIKE '소득세 기초 이론%'), 
 (SELECT id FROM questions WHERE content LIKE '소득세법상 종합소득에%'), 1, 20),

-- 법인세 실무 응용 시험 (세 번째 시험)
((SELECT id FROM exams WHERE title LIKE '법인세 실무 응용%'), 
 (SELECT id FROM questions WHERE content LIKE '법인세법상 손금불산입%'), 1, 30);

-- 시험 권한 부여 (모든 부서에 부가가치세 시험 권한)
INSERT INTO exam_permissions (exam_id, department_id, granted_by) 
SELECT 
    (SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'),
    d.id,
    (SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1)
FROM departments d;

-- 소득세 시험은 세무팀만
INSERT INTO exam_permissions (exam_id, department_id, granted_by) VALUES 
((SELECT id FROM exams WHERE title LIKE '소득세 기초 이론%'),
 (SELECT id FROM departments WHERE code = 'TAX'),
 (SELECT id FROM profiles WHERE email LIKE '%admin%' LIMIT 1));

-- 샘플 응시 기록 (테스트용)
-- 주의: 실제 운영에서는 이 부분을 제거하세요
/*
INSERT INTO exam_sessions (exam_id, employee_id, start_time, submit_time, duration_minutes, score, total_points, status) VALUES 
((SELECT id FROM exams WHERE title LIKE '2024년 1분기 부가가치세%'),
 (SELECT id FROM profiles WHERE role = 'employee' LIMIT 1),
 NOW() - INTERVAL '2 hours',
 NOW() - INTERVAL '1 hours',
 55,
 45,
 60,
 'graded');
*/

-- 데이터 확인 쿼리 (개발자용)
-- SELECT 'Categories' as table_name, COUNT(*) as count FROM categories
-- UNION ALL
-- SELECT 'Questions', COUNT(*) FROM questions  
-- UNION ALL
-- SELECT 'Question Options', COUNT(*) FROM question_options
-- UNION ALL 
-- SELECT 'Exams', COUNT(*) FROM exams
-- UNION ALL
-- SELECT 'Exam Questions', COUNT(*) FROM exam_questions;
