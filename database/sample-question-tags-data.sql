-- 문제 태그 샘플 데이터
-- database/add-question-tags.sql 실행 후 이 파일을 실행하세요

-- 1) 문제용 샘플 태그 생성 (기존 tags 테이블 활용)
INSERT INTO public.tags (name, description) VALUES
('세법', '세무 관련 법령'),
('소득세', '소득세 관련 문제'),
('법인세', '법인세 관련 문제'),
('부가가치세', '부가가치세 관련 문제'),
('상속세', '상속세 관련 문제'),
('증여세', '증여세 관련 문제'),
('지방세', '지방세 관련 문제'),
('기초', '기초 수준 문제'),
('중급', '중급 수준 문제'),
('고급', '고급 수준 문제'),
('실무', '실무 적용 문제'),
('이론', '이론 중심 문제'),
('계산', '계산 문제'),
('서술', '서술형 문제'),
('최신법령', '최신 개정 법령'),
('판례', '판례 관련 문제'),
('신고', '신고 관련 문제'),
('환급', '환급 관련 문제'),
('과세표준', '과세표준 계산'),
('세율', '세율 적용 문제')
ON CONFLICT (name) DO NOTHING;

-- 2) 문제별 태그 자동 연결 예시
-- 문제 제목이나 내용에 따라 자동으로 태그 연결
-- (실제 데이터에 맞게 수정 필요)

-- 소득세 관련 문제에 소득세 태그 연결
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '소득세'
WHERE q.content ILIKE '%소득세%' OR q.title ILIKE '%소득세%'
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 법인세 관련 문제에 법인세 태그 연결
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '법인세'
WHERE q.content ILIKE '%법인세%' OR q.title ILIKE '%법인세%'
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 부가가치세 관련 문제에 부가가치세 태그 연결
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '부가가치세'
WHERE q.content ILIKE '%부가가치세%' OR q.title ILIKE '%부가가치세%'
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 난이도별 태그 자동 연결
-- 난이도 1-2: 기초
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '기초'
WHERE q.difficulty IN (1, 2)
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 난이도 3: 중급
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '중급'
WHERE q.difficulty = 3
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 난이도 4-5: 고급
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '고급'
WHERE q.difficulty IN (4, 5)
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 문제 유형별 태그 연결
-- 객관식 문제
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '이론'
WHERE q.type = 'multiple_choice'
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 주관식 문제 
INSERT INTO public.question_tags (question_id, tag_id)
SELECT 
    q.id as question_id,
    t.id as tag_id
FROM questions q
JOIN tags t ON t.name = '서술'
WHERE q.type = 'subjective'
ON CONFLICT (question_id, tag_id) DO NOTHING;

-- 3) 확인 쿼리
-- 문제별 태그 현황 확인
/*
SELECT 
    q.title as 문제제목,
    q.type as 유형,
    q.difficulty as 난이도,
    array_agg(t.name) as 태그목록
FROM questions q
LEFT JOIN question_tags qt ON q.id = qt.question_id
LEFT JOIN tags t ON qt.tag_id = t.id
GROUP BY q.id, q.title, q.type, q.difficulty
ORDER BY q.created_at DESC
LIMIT 20;
*/

