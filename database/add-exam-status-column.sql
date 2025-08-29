-- exams 테이블에 status 컬럼 추가
-- 이 컬럼은 시험지의 상태를 관리하여 비활성화 기능을 구현합니다.

-- 1. status 컬럼 추가 (기본값: 'active')
ALTER TABLE public.exams 
ADD COLUMN status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 2. status 컬럼에 대한 제약 조건 추가
ALTER TABLE public.exams 
ADD CONSTRAINT exams_status_check 
CHECK (status IN ('active', 'inactive', 'deleted'));

-- 3. 기존 데이터에 대해 status 설정
UPDATE public.exams 
SET status = 'active' 
WHERE status IS NULL OR status NOT IN ('active', 'inactive', 'deleted');

-- 4. 컬럼 설명 추가
COMMENT ON COLUMN public.exams.status IS 
'시험지 상태를 관리하는 필드.
- active: 활성 상태 (정상 사용 가능)
- inactive: 비활성 상태 (응시 불가, 데이터 보존)
- deleted: 삭제 상태 (완전 제거 예정)';

-- 5. 인덱스 추가 (성능 향상)
CREATE INDEX idx_exams_status ON public.exams(status);

-- 6. 기존 시험지들의 상태 확인
SELECT 
    id,
    title,
    status,
    created_at,
    updated_at
FROM public.exams 
ORDER BY created_at DESC;
