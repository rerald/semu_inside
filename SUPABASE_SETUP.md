# Supabase 설정 가이드

## 1단계: Supabase 프로젝트 생성

### 1.1 계정 생성 및 프로젝트 생성
1. [Supabase.com](https://supabase.com) 접속
2. "Start your project" 클릭
3. GitHub/Google 계정으로 로그인
4. "New Project" 클릭
5. 프로젝트 정보 입력:
   - **Name**: `semu-inside-exam-platform`
   - **Database Password**: 안전한 비밀번호 생성 (잘 기록해두세요!)
   - **Region**: `Northeast Asia (Seoul)` 선택
   - **Pricing Plan**: `Free tier` 선택
6. "Create new project" 클릭
7. 프로젝트 생성 완료까지 2-3분 대기

### 1.2 프로젝트 URL과 API Key 확인
1. 프로젝트 대시보드에서 `Settings` > `API` 메뉴 클릭
2. 다음 정보 복사해두기:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **anon public key**: `eyJ...` (긴 토큰)

## 2단계: 데이터베이스 스키마 설정

### 2.1 SQL 에디터 접속
1. 왼쪽 메뉴에서 `SQL Editor` 클릭
2. `New query` 버튼 클릭

### 2.2 스키마 실행
1. 아래 파일 내용을 복사하여 SQL 에디터에 붙여넣기:
   ```
   database/schema.sql 파일의 전체 내용
   ```

2. `Run` 버튼 클릭하여 실행
3. 성공 메시지 확인: "Success. No rows returned"

### 2.3 샘플 데이터 추가 (선택사항)
1. 새 쿼리 생성
2. `database/sample-data.sql` 파일 내용 붙여넣기
3. `Run` 버튼 클릭

## 3단계: 인증 설정

### 3.1 이메일 인증 설정
1. `Authentication` > `Settings` 메뉴 클릭
2. `Email Auth` 탭에서:
   - `Enable email confirmations`: **OFF** (개발/테스트용)
   - `Enable email change confirmations`: **OFF**
   - `Enable secure email change`: **OFF**

⚠️ **운영 환경에서는 이메일 인증을 켜는 것을 권장합니다**

### 3.2 URL 설정
1. `Site URL`: `http://localhost:8080` (개발용)
2. `Redirect URLs`: 
   ```
   http://localhost:8080
   https://your-domain.vercel.app
   ```

## 4단계: 애플리케이션 설정

### 4.1 설정 파일 업데이트
`js/config.js` 파일을 열어 다음 부분을 수정하세요:

```javascript
const SUPABASE_CONFIG = {
    url: 'https://your-project-id.supabase.co',  // 2단계에서 복사한 URL
    anonKey: 'eyJ...'  // 2단계에서 복사한 anon key
};
```

## 5단계: 테스트

### 5.1 로컬 서버 실행
```bash
# 프로젝트 폴더에서
python -m http.server 8080
# 또는
python3 -m http.server 8080
```

### 5.2 브라우저에서 테스트
1. `http://localhost:8080` 접속
2. 회원가입 테스트:
   - 이름, 이메일, 비밀번호, 부서 입력
   - 회원가입 완료 확인
3. 로그인 테스트
4. 대시보드 접속 확인

### 5.3 관리자 권한 부여
1. Supabase 대시보드 > `Table Editor` > `profiles` 테이블
2. 생성한 사용자 찾아서 `role` 컬럼을 `super_admin`으로 변경
3. 로그아웃 후 다시 로그인
4. "관리" 탭이 나타나는지 확인

## 6단계: 프로덕션 배포

### 6.1 Vercel 배포
```bash
npm install -g vercel
vercel login
vercel --prod
```

### 6.2 도메인 설정
1. Vercel에서 제공하는 도메인 복사
2. Supabase > Authentication > Settings에서 `Site URL` 업데이트
3. `Redirect URLs`에 새 도메인 추가

## 트러블슈팅

### 문제 1: "Invalid login credentials" 오류
- **원인**: 이메일 인증이 활성화되어 있거나 잘못된 비밀번호
- **해결**: 3.1 단계에서 이메일 인증 비활성화 확인

### 문제 2: "Failed to fetch" 오류
- **원인**: CORS 설정 또는 잘못된 URL/API Key
- **해결**: 4.1 단계에서 URL과 API Key 재확인

### 문제 3: 데이터베이스 연결 오류
- **원인**: 스키마가 제대로 실행되지 않음
- **해결**: 2.2 단계에서 SQL 실행 결과 재확인

### 문제 4: 권한 오류 ("permission denied")
- **원인**: RLS 정책 문제
- **해결**: 
  ```sql
  -- 임시로 RLS 비활성화 (디버깅용)
  ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
  ```

## 성공 확인 체크리스트

- [ ] Supabase 프로젝트 생성 완료
- [ ] 데이터베이스 스키마 실행 완료
- [ ] 애플리케이션 설정 완료
- [ ] 회원가입/로그인 테스트 성공
- [ ] 관리자 권한 부여 완료
- [ ] 시험 응시 테스트 성공
- [ ] 프로덕션 배포 완료

---

## 다음 단계

설정이 완료되면:
1. 샘플 문제 등록
2. 테스트 시험 생성
3. 직원들에게 계정 안내
4. 본격적인 운영 시작!

🎉 **축하합니다! 세무인사이드 시험 플랫폼이 준비되었습니다!**
