# 세무인사이드 시험 플랫폼

세무법인 세무인사이드의 사내 교육 및 평가를 위한 온라인 시험 플랫폼입니다.

## 🚀 라이브 데모

GitHub Pages에서 실행 중인 라이브 데모를 확인하세요:
**[https://YOUR_USERNAME.github.io/semu_inside/](https://YOUR_USERNAME.github.io/semu_inside/)**

### 📱 테스트 계정
- **관리자**: `admin@semu.com` / `123456`
- **일반 사용자**: `kjtsori@gmail.com` / `123456`
- **일반 사용자**: `rerald293@gmail.com` / `123456`

## 🎯 빠른 시작

로컬에서 실행하려면:
```bash
# 파일 다운로드
git clone https://github.com/YOUR_USERNAME/semu_inside.git
cd semu_inside

# 로컬 서버 실행 (Python 3)
python -m http.server 8080

# 브라우저에서 http://localhost:8080 접속
```

## 🎯 주요 기능

### 직원 기능
- **회원가입/로그인**: 부서별 직원 계정 관리
- **시험 응시**: 객관식, 주관식, 그룹형 문제 지원
- **실시간 타이머**: 시험 시간 관리 및 자동 제출
- **자동저장**: 답안 실시간 저장으로 데이터 손실 방지
- **결과 확인**: 상세한 시험 결과 및 해설 제공
- **모바일 지원**: 반응형 디자인으로 모든 디바이스 지원

### 관리자 기능
- **문제 관리**: 카테고리별 문제 등록 및 관리
- **시험지 생성**: 문항 구성 및 배점 설정
- **권한 관리**: 부서/개인별 시험 응시 권한 부여
- **수동 채점**: 주관식 문항 채점 시스템
- **통계 분석**: 응시율, 정답률, 점수 분포 등

## 🛠 기술 스택

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Database**: PostgreSQL with Row Level Security
- **Deployment**: Vercel/Netlify (정적 호스팅)

## 📦 설치 및 설정

### 1. 프로젝트 클론
```bash
git clone [repository-url]
cd semu_inside
```

### 2. Supabase 설정

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. `database/schema.sql` 파일의 내용을 Supabase SQL 에디터에서 실행
3. `js/config.js` 파일에서 Supabase 연결 정보 수정:

```javascript
const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY'
};
```

### 3. 배포

#### Vercel 배포
```bash
npm install -g vercel
vercel
```

#### Netlify 배포
1. [Netlify](https://netlify.com)에 로그인
2. 프로젝트 폴더를 드래그 앤 드롭으로 배포

## 📊 데이터베이스 구조

### 주요 테이블
- `profiles`: 직원 프로필 정보
- `departments`: 부서 정보
- `categories`: 문제 카테고리 (계층적 구조)
- `questions`: 문제 정보
- `question_options`: 객관식 선택지
- `exams`: 시험지 정보
- `exam_sessions`: 응시 세션
- `exam_answers`: 답안 기록

### 권한 관리
- Row Level Security (RLS) 적용
- 역할 기반 접근 제어 (직원/관리자/슈퍼관리자)

## 🚀 사용 방법

### 초기 설정

1. **관리자 계정 생성**
   ```sql
   -- Supabase에서 실행
   UPDATE profiles 
   SET role = 'super_admin' 
   WHERE email = 'admin@semu-inside.com';
   ```

2. **기본 카테고리 설정**
   - 부가가치세, 소득세, 법인세 등 세무 분야별 카테고리
   - 세무회계, 세무조사, 세무상담 등 업무 영역별 카테고리

3. **부서 설정**
   - 세무팀, 감사팀, 컨설팅팀, 관리팀 등

### 문제 등록

1. 관리자로 로그인
2. "관리" → "문제 관리" → "새 문제 등록"
3. 문제 유형, 카테고리, 난이도 설정
4. 객관식의 경우 선택지 및 정답 설정

### 시험 생성

1. "관리" → "시험지 관리" → "새 시험지 생성"
2. 시험 정보 입력 (제목, 설명, 시간, 일자)
3. 문항 추가 및 배점 설정
4. 응시 권한 부여 (부서별/개인별)
5. 시험 배포

### 시험 응시

1. 직원 로그인
2. 대시보드에서 응시 가능한 시험 확인
3. "시험 시작" 클릭
4. 실시간 타이머 확인하며 문제 해결
5. 답안 자동저장 기능 활용
6. 완료 후 "시험 제출"

## 🔧 주요 설정

### `js/config.js`에서 수정 가능한 설정들:

```javascript
const EXAM_CONFIG = {
    AUTO_SAVE_INTERVAL: 30000,    // 자동저장 간격 (30초)
    WARNING_TIME: 300,            // 경고 시간 (5분 전)
    GRACE_PERIOD: 60,             // 여유 시간 (1분)
    MAX_FILE_SIZE: 10 * 1024 * 1024,  // 최대 파일 크기 (10MB)
};
```

## 📱 모바일 지원

- 반응형 디자인으로 모든 디바이스 지원
- 터치 친화적 인터페이스
- 모바일 브라우저 최적화

## 🔒 보안 기능

- Supabase Row Level Security (RLS)
- JWT 토큰 기반 인증
- 역할 기반 접근 제어
- 시험 중 페이지 이탈 방지
- 자동 로그아웃 (비활성 상태 30분)

## 📈 통계 및 분석

- 시험별 응시율 및 평균 점수
- 문제별 정답률 분석
- 부서별/개인별 성적 통계
- 실시간 대시보드

## 🛟 문제 해결

### 일반적인 문제들

1. **로그인이 되지 않아요**
   - Supabase 연결 설정 확인
   - 이메일 인증 완료 여부 확인

2. **시험 중 페이지가 새로고침되었어요**
   - 자동저장 기능으로 답안은 보존됩니다
   - 다시 로그인하여 시험 계속 진행 가능

3. **모바일에서 화면이 깨져요**
   - 최신 브라우저 사용 권장
   - 가로 모드에서 더 나은 경험 제공

## 📞 지원

문제 발생 시 다음 정보와 함께 문의해주세요:
- 브라우저 종류 및 버전
- 발생한 오류 메시지
- 수행하려던 작업

## 📄 라이선스

이 프로젝트는 세무법인 세무인사이드의 내부 사용을 위해 개발되었습니다.

---

**세무법인 세무인사이드** | 전문성과 신뢰를 바탕으로 한 세무 서비스
