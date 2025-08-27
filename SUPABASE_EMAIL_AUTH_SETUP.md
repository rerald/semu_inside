# Supabase Email 인증 활성화 가이드

## 문제 상황
- "Email logins are disabled" 오류 발생
- 회원가입 및 로그인이 작동하지 않음

## 해결 방법

### 1. Supabase 대시보드 접속
1. https://supabase.com/dashboard 접속
2. 프로젝트 선택: `skpvtqohyspfsmvwrgoc`

### 2. Authentication 설정 확인
1. 좌측 메뉴에서 **Authentication** 클릭
2. **Settings** → **Auth** 탭 선택

### 3. Email Provider 활성화
다음 설정들을 확인하고 활성화:

```
✅ Enable email confirmations: 체크 해제 (개발 환경)
✅ Enable email sign-ups: 체크
✅ Enable custom SMTP: 필요시 설정
```

### 4. Redirect URLs 설정
**Site URL** 및 **Redirect URLs** 설정:
```
Site URL: http://localhost:3000 (또는 배포 URL)
Redirect URLs: 
- http://localhost:3000
- http://localhost:3000/dashboard.html
- https://your-domain.com (배포 시)
```

### 5. RLS (Row Level Security) 정책 확인
profiles 테이블의 RLS 정책이 올바른지 확인:

```sql
-- 프로필 INSERT 정책 (회원가입 시 필요)
CREATE POLICY "Enable insert for authenticated users only" ON "public"."profiles"
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 프로필 SELECT 정책
CREATE POLICY "Users can view own profile" ON profiles
FOR SELECT USING (auth.uid() = id);
```

### 6. 테스트 계정으로 확인
1. 회원가입 시도
2. 콘솔에서 오류 메시지 확인
3. Supabase 대시보드의 Auth → Users에서 사용자 생성 확인

## 추가 참고사항

### Email 확인 비활성화 (개발 환경)
개발 중에는 이메일 확인을 비활성화할 수 있습니다:
- **Enable email confirmations** 체크 해제

### SMTP 설정 (프로덕션 환경)
실제 서비스에서는 SMTP 설정이 필요합니다:
- Gmail, SendGrid, Mailgun 등 설정 가능

### 디버깅 팁
1. 브라우저 Network 탭에서 Auth API 호출 확인
2. Supabase 대시보드의 Logs 섹션 확인
3. 콘솔 오류 메시지 분석
