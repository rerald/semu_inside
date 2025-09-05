-- 김효진님의 데이터 분석
-- 1. 김효진님의 사용자 정보
SELECT id, name, email FROM profiles WHERE email = 'kkotbun.kim@gmail.com';

-- 2. 김효진님의 모든 시험 세션 정보
SELECT 
    es.id as session_id,
    es.exam_id,
    e.title as exam_title,
    es.score,
    es.total_points,
    es.status,
    es.start_time,
    es.submit_time
FROM exam_sessions es
JOIN exams e ON es.exam_id = e.id
JOIN profiles p ON es.employee_id = p.id
WHERE p.email = 'kkotbun.kim@gmail.com'
ORDER BY es.start_time DESC;

-- 3. 김효진님의 모든 답안 분석 (맞힌 문제 vs 틀린 문제)
SELECT 
    es.id as session_id,
    e.title as exam_title,
    COUNT(*) as total_questions,
    COUNT(CASE WHEN ea.is_correct = true THEN 1 END) as correct_answers,
    COUNT(CASE WHEN ea.is_correct = false THEN 1 END) as wrong_answers,
    COUNT(CASE WHEN ea.is_correct IS NULL THEN 1 END) as unanswered,
    ROUND(
        (COUNT(CASE WHEN ea.is_correct = true THEN 1 END)::numeric / COUNT(*)::numeric) * 100, 2
    ) as accuracy_percentage
FROM exam_sessions es
JOIN exams e ON es.exam_id = e.id
JOIN profiles p ON es.employee_id = p.id
LEFT JOIN exam_answers ea ON es.id = ea.session_id
WHERE p.email = 'kkotbun.kim@gmail.com'
  AND es.status = 'submitted'
GROUP BY es.id, e.title
ORDER BY es.start_time DESC;

-- 4. 김효진님의 답안 상세 내역 (최근 시험 1개만)
SELECT 
    ea.question_id,
    q.content as question_content,
    ea.answer,
    ea.is_correct,
    ea.points,
    q.type as question_type
FROM exam_answers ea
JOIN questions q ON ea.question_id = q.id
JOIN exam_sessions es ON ea.session_id = es.id
JOIN profiles p ON es.employee_id = p.id
WHERE p.email = 'kkotbun.kim@gmail.com'
  AND es.status = 'submitted'
ORDER BY es.start_time DESC, ea.created_at
LIMIT 20;
