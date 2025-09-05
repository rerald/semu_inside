# 🚀 Quizbank 기능 개발 로드맵

> **세무인사이드 시험 플랫폼의 기능 확장 및 개발 계획서**

## 📋 목차
- [1. 개요](#1-개요)
- [2. 완료된 기능](#2-완료된-기능)
- [3. 포인트 관리 시스템 (진행중)](#3-포인트-관리-시스템-진행중)
- [4. 아바타 시스템](#4-아바타-시스템)
- [5. 향후 개발 계획](#5-향후-개발-계획)
- [6. 기술 스택 및 아키텍처](#6-기술-스택-및-아키텍처)
- [7. 개발 우선순위](#7-개발-우선순위)

---

## 1. 개요

### 📊 프로젝트 현황
- **기본 시험 플랫폼**: ✅ 완료
- **게이미피케이션 요소**: 🔄 진행중
- **포인트 시스템**: 🆕 신규 개발
- **아바타 시스템**: ✅ 완료

### 🎯 개발 목표
1. **모듈화된 시스템 구축** - 각 기능을 독립적으로 관리
2. **확장 가능한 아키텍처** - 다른 프로젝트에서 재사용 가능
3. **사용자 경험 향상** - 게이미피케이션을 통한 참여도 증진
4. **데이터 기반 의사결정** - 통계와 분석 기능 강화

---

## 2. 완료된 기능

### ✅ 기본 시험 플랫폼
- **사용자 인증 시스템** (Supabase Auth)
- **문제 관리 시스템** (객관식/주관식/서술형)
- **시험 생성 및 관리**
- **자동 채점 시스템**
- **실시간 타이머 및 자동 저장**
- **결과 분석 및 통계**

### ✅ 관리자 시스템
- **문제 관리** - CRUD, 카테고리 분류, 난이도 설정
- **시험지 관리** - 시험 생성, 문제 배정, 권한 관리
- **사용자 관리** - 프로필, 부서, 권한 관리
- **채점 관리** - 수동 채점, AI 채점 연동

### ✅ 아바타 시스템
- **아바타 아이템 관리** - CRUD, 이미지 업로드
- **한정판 시스템** - 재고 관리, 고유 번호 부여
- **AI 이미지 편집** - DALL-E 연동으로 이미지 생성/편집
- **구매 시스템** - 포인트 연동 준비 완료

---

## 3. 포인트 관리 시스템 (진행중)

### 🎯 개발 목표
포인트 시스템을 **독립적인 모듈**로 분리하여 확장성과 재사용성을 극대화

### 📋 시스템 설계

#### 🏗️ 아키텍처
```
┌─────────────────────────────────────────┐
│            Points Management            │
├─────────────────────────────────────────┤
│  • Independent Module                   │
│  • Configurable Rules                   │
│  • Multi-platform Ready                 │
│  • Advanced Analytics                   │
└─────────────────────────────────────────┘
          ↓ API Connections ↓
┌─────────────┬─────────────┬─────────────┐
│ Exam System │Avatar System│Future Systems│
└─────────────┴─────────────┴─────────────┘
```

#### 📁 파일 구조
```
/points-admin/
├── points-admin.html          # 포인트 관리 메인 페이지
├── js/
│   ├── points-admin.js       # 포인트 관리 로직
│   ├── points-config.js      # 포인트 설정 관리
│   ├── points-analytics.js   # 포인트 통계/분석
│   ├── points-policies.js    # 포인트 정책 관리
│   └── points-api.js         # API 통신 모듈
├── database/
│   ├── points-schema.sql     # 포인트 관련 테이블
│   ├── points-functions.sql  # 포인트 관련 함수
│   └── points-triggers.sql   # 자동화 트리거
└── styles/
    └── points-admin.css      # 포인트 관리 전용 스타일
```

### 🎛️ 주요 기능

#### 1️⃣ 포인트 정책 관리
```javascript
// 예시: 포인트 지급 규칙 설정
const pointPolicies = {
    examRewards: {
        perQuestion: { correct: 100, incorrect: 0 },
        completion: 200,
        passing: 300,
        difficultyBonus: { 1: 0, 2: 10, 3: 25, 4: 50, 5: 100 }
    },
    specialEvents: {
        doublePointsDays: ['2025-01-01', '2025-03-01'],
        seasonalBonus: { spring: 1.2, summer: 1.0, fall: 1.1, winter: 1.3 }
    }
}
```

#### 2️⃣ 사용자 포인트 관리
- **개별 포인트 조회/수정**
- **벌크 포인트 지급/차감**
- **거래 내역 상세 조회**
- **포인트 만료 관리**

#### 3️⃣ 통계 및 분석
- **실시간 포인트 현황 대시보드**
- **사용자별/부서별 포인트 분석**
- **포인트 발행/소모 추이**
- **아이템 구매 패턴 분석**

#### 4️⃣ 시스템 관리
- **포인트 정책 변경 이력**
- **자동화 규칙 설정**
- **데이터 백업/복원**
- **오류 로그 모니터링**

### 🔗 연동 시스템

#### 시험 시스템 연동
```javascript
// 시험 완료 시 자동 포인트 지급
await pointsAPI.awardExamPoints({
    userId: session.employee_id,
    sessionId: session.id,
    score: session.score,
    totalQuestions: session.total_questions,
    timeUsed: session.duration_minutes
});
```

#### 아바타 시스템 연동
```javascript
// 아바타 구매 시 포인트 차감
const purchaseResult = await pointsAPI.processAvatarPurchase({
    userId: buyer.id,
    avatarId: avatar.id,
    price: avatar.price
});
```

### 📊 데이터베이스 스키마

#### 기존 테이블 확장
```sql
-- 포인트 정책 테이블 추가
CREATE TABLE point_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR NOT NULL,
    policy_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 포인트 이벤트 테이블 추가
CREATE TABLE point_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name VARCHAR NOT NULL,
    event_type VARCHAR NOT NULL, -- 'bonus', 'penalty', 'transfer'
    multiplier DECIMAL DEFAULT 1.0,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- 포인트 만료 관리 테이블
CREATE TABLE point_expiry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    points_amount INTEGER NOT NULL,
    earned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR DEFAULT 'active' -- 'active', 'expired', 'used'
);
```

---

## 4. 아바타 시스템

### ✅ 완료된 기능
- **기본 CRUD 작업**
- **이미지 업로드 및 미리보기**
- **한정판 시스템** (재고 관리, 고유 번호)
- **AI 이미지 편집** (DALL-E 2/3 연동)
- **카드 인스턴스 시스템** (NFT-like 구조)

### 🎨 한정판 카드 시스템
```sql
-- 아바타 카드 인스턴스
CREATE TABLE avatar_card_instances (
    id UUID PRIMARY KEY,
    avatar_item_id UUID REFERENCES avatar_items(id),
    unique_card_number INTEGER, -- 고유 번호 (예: #001/100)
    current_owner_id UUID REFERENCES profiles(id),
    mint_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 거래 내역
CREATE TABLE avatar_card_transactions (
    id UUID PRIMARY KEY,
    card_instance_id UUID REFERENCES avatar_card_instances(id),
    transaction_type VARCHAR, -- 'mint', 'purchase', 'transfer'
    from_user_id UUID,
    to_user_id UUID,
    price INTEGER,
    transaction_hash VARCHAR UNIQUE
);
```

### 🔮 AI 이미지 편집 기능
- **DALL-E 2/3 연동**
- **이미지 분석 후 재생성**
- **실시간 이미지 비교**
- **통합 편집 워크플로우**

---

## 5. 향후 개발 계획

### 🎯 1단계: 포인트 시스템 완성 (우선순위: 높음)
#### 목표 기간: 2주
- [ ] 독립적인 포인트 관리 페이지 구축
- [ ] 포인트 정책 설정 인터페이스
- [ ] 실시간 통계 대시보드
- [ ] 시험-포인트 연동 완성
- [ ] 아바타-포인트 연동 완성

### 🛒 2단계: 마켓플레이스 시스템 (우선순위: 중간)
#### 목표 기간: 3주
- [ ] 사용자 간 아바타 거래 시스템
- [ ] 경매 시스템
- [ ] 거래 수수료 관리
- [ ] 거래 내역 추적
- [ ] 사기 방지 시스템

### 📈 3단계: 고급 분석 시스템 (우선순위: 중간)
#### 목표 기간: 2주
- [ ] 학습 진도 분석
- [ ] 개인별 성취도 추적
- [ ] 부서별 경쟁 시스템
- [ ] 예측 분석 (성과 예측)
- [ ] 맞춤형 학습 추천

### 🎮 4단계: 게이미피케이션 확장 (우선순위: 낮음)
#### 목표 기간: 4주
- [ ] 업적 시스템 (뱃지, 칭호)
- [ ] 레벨링 시스템
- [ ] 길드/팀 시스템
- [ ] 이벤트 시스템
- [ ] 소셜 기능 (친구, 랭킹)

### 🔧 5단계: 시스템 고도화 (우선순위: 낮음)
#### 목표 기간: 계속
- [ ] 모바일 앱 개발
- [ ] 오프라인 모드 지원
- [ ] 다국어 지원
- [ ] 접근성 개선
- [ ] 성능 최적화

---

## 6. 기술 스택 및 아키텍처

### 🛠️ 현재 기술 스택
```yaml
Frontend:
  - HTML5/CSS3/JavaScript (Vanilla)
  - Responsive Design
  - Progressive Web App

Backend:
  - Supabase (PostgreSQL + Auth + Storage)
  - Row Level Security (RLS)
  - Real-time Subscriptions

External APIs:
  - OpenAI (DALL-E 2/3, GPT-4)
  - Replicate (Alternative AI Models)

Development:
  - Git Version Control
  - GitHub Pages / Vercel Deployment
  - VS Code + Extensions
```

### 🏗️ 시스템 아키텍처
```
┌─────────────────────────────────────────────────┐
│                  Frontend Layer                 │
├─────────────────┬─────────────────┬─────────────┤
│   Exam System   │ Points System   │Avatar System│
├─────────────────┼─────────────────┼─────────────┤
│      Admin      │  Points Admin   │Avatar Admin │
└─────────────────┴─────────────────┴─────────────┘
                           ↓
┌─────────────────────────────────────────────────┐
│                 API Gateway Layer               │
├─────────────────────────────────────────────────┤
│              Supabase Backend                   │
│  • PostgreSQL Database                          │
│  • Authentication Service                       │
│  • Real-time Subscriptions                      │
│  • File Storage                                 │
└─────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────┐
│               External Services                 │
├─────────────────┬─────────────────┬─────────────┤
│   OpenAI API    │  Replicate API  │ Future APIs │
└─────────────────┴─────────────────┴─────────────┘
```

### 🔗 모듈 간 연동 방식
```javascript
// 이벤트 기반 통신
window.addEventListener('pointsAwarded', (event) => {
    const { userId, amount, source } = event.detail;
    updateUserInterface(userId, amount);
});

// API 기반 통신
const pointsAPI = {
    award: async (userId, amount, description) => { ... },
    deduct: async (userId, amount, description) => { ... },
    getBalance: async (userId) => { ... },
    getHistory: async (userId, options) => { ... }
};
```

---

## 7. 개발 우선순위

### 🔥 즉시 진행 (1-2주)
1. **포인트 관리 시스템 완성**
   - 독립적인 관리 페이지 구축
   - 정책 설정 인터페이스
   - 기본 통계 대시보드

2. **시험-포인트 연동 완성**
   - 자동 포인트 지급
   - 지급 결과 UI
   - 오류 처리 강화

### ⚡ 우선 진행 (3-4주)
1. **아바타 구매 시스템 완성**
   - 포인트 차감 로직
   - 구매 확인 프로세스
   - 재고 관리 연동

2. **사용자 포인트 대시보드**
   - 개인 포인트 현황
   - 거래 내역 조회
   - 랭킹 시스템

### 📅 중장기 계획 (1-3개월)
1. **마켓플레이스 시스템**
2. **고급 분석 기능**
3. **모바일 최적화**
4. **성능 최적화**

### 🚀 장기 비전 (3-6개월)
1. **다른 시스템 확장**
   - HR 시스템 연동
   - 전사 교육 플랫폼
   - 외부 API 제공

2. **AI 기능 확장**
   - 맞춤형 문제 생성
   - 학습 패턴 분석
   - 자동 커리큘럼 추천

---

## 📊 성과 지표 (KPI)

### 📈 정량적 지표
- **사용자 참여도**: 일일/월별 활성 사용자 수
- **학습 효과**: 평균 점수 향상률
- **포인트 활용도**: 포인트 적립/사용 비율
- **아바타 인기도**: 구매 및 거래량

### 🎯 정성적 지표
- **사용자 만족도**: 피드백 및 리뷰 점수
- **시스템 안정성**: 오류 발생률 및 처리 시간
- **기능 완성도**: 요구사항 충족률
- **확장성**: 새로운 기능 추가 용이성

---

## 📝 변경 이력

### v1.0 (2025-01-09)
- 초기 문서 작성
- 포인트 관리 시스템 설계 수립
- 기본 로드맵 수립

### 향후 업데이트 예정
- 포인트 시스템 구현 진행 상황
- 새로운 기능 요구사항
- 기술적 의사결정 사항
- 성과 분석 결과

---

**📞 문의 사항이나 제안사항이 있으시면 언제든 말씀해 주세요!**

*이 문서는 개발 진행 상황에 따라 지속적으로 업데이트됩니다.*

