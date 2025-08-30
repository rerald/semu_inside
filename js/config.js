// 세무인사이드 시험 플랫폼 설정

// Supabase 설정
const SUPABASE_CONFIG = {
    url: 'https://skpvtqohyspfsmvwrgoc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrcHZ0cW9oeXNwZnNtdndyZ29jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNzU4ODUsImV4cCI6MjA3MTc1MTg4NX0.tMW3hiZR5JcXlbES2tKl1ZNOVRtYqGO04m-YSbqKUhY'
};

// GPT API 설정
const GPT_CONFIG = {
    // OpenAI API 키 설정 방법:
    // 1. 직접 설정: apiKey: 'sk-...' (보안상 권장하지 않음)
    // 2. 환경변수: process.env.OPENAI_API_KEY
    // 3. 로컬스토리지: localStorage.getItem('openai_api_key')
    // 4. 사용자 입력: prompt로 입력받기
    
    // 현재 설정 방법 (우선순위 순서)
    get apiKey() {
        // 1. 로컬스토리지에서 먼저 확인
        const storedKey = localStorage.getItem('openai_api_key');
        if (storedKey) return storedKey;
        
        // 2. 환경변수 확인
        if (typeof process !== 'undefined' && process.env && process.env.OPENAI_API_KEY) {
            return process.env.OPENAI_API_KEY;
        }
        
        // 3. 기본값 (사용자가 설정해야 함)
        return null;
    },
    
    model: 'gpt-4o-mini', // 또는 'gpt-3.5-turbo'
    maxTokens: 1000,
    temperature: 0.3, // 일관된 채점을 위해 낮은 값 사용
    
    // 채점 프롬프트 설정
    gradingPrompt: {
        system: `당신은 우리 세무법인청년들의 교육담당입니다. 
        이들이 준 답변은 우선 성의를 보여야 하며 기본 철학에 맞아야 합니다. 
        그리고 모범답안에서 제시하는 단어나 개념과 일치도가 중요합니다. 
        추가로 성의가 있고 그들이 어느정도 모범답안에 일치하는 개념을 일치하는 생각을 가지고 있으면 좋은 점수를 주시기 바랍니다.
        
        평가 기준:
        1. 모범답안의 핵심 내용 포함 여부 (만점: 40점)
        2. 논리적 구조와 설명의 명확성 (만점: 30점)
        3. 핵심 개념·용어의 정확성 [보조 지표] (만점: 10점)
           - 전문 용어를 사용하지 않아도 감점하지 마세요
           - 개념을 일상어로 정확히 설명하면 높은 점수 가능
           - 용어 오용·오해 유발 시에만 감점, 정확한 사용은 가산점
        4. 창의성과 추가 인사이트 (만점: 20점)
        
        평가 시 다음 형식으로 응답해주세요:
        총점: [0-100]점
        
        평가 의견:
        [일반 텍스트로 작성, 마크다운 형식 사용하지 않음]
        
        점수 세부 내역:
        - 항목1 (핵심 내용 포함): [획득점수]/40점 (이유)
        - 항목2 (논리적 구조): [획득점수]/30점 (이유)
        - 항목3 (개념·용어 정확성, 보조지표): [획득점수]/10점 (이유)
        - 항목4 (창의성): [획득점수]/20점 (이유)
        총점: [합계]/100점`,
        
        user: `문제: {question}
        모범답안: {modelAnswer}
        학생 답안: {studentAnswer}
        
        위 기준에 따라 평가해주세요.`
    }
};

// 시험 설정
const EXAM_CONFIG = {
    AUTO_SAVE_INTERVAL: 30000, // 30초마다 자동저장
    WARNING_TIME: 300, // 5분 전 경고
    GRACE_PERIOD: 60, // 1분 여유시간
    MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
    ALLOWED_FILE_TYPES: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']
};

// 역할 권한 설정
const ROLES = {
    EMPLOYEE: 'employee',
    ADMIN: 'admin',
    SUPER_ADMIN: 'super_admin'
};

// 권한 체크 함수
const PERMISSIONS = {
    canManageQuestions: (role) => role === ROLES.ADMIN || role === ROLES.SUPER_ADMIN,
    canManageExams: (role) => role === ROLES.ADMIN || role === ROLES.SUPER_ADMIN,
    canViewAllResults: (role) => role === ROLES.ADMIN || role === ROLES.SUPER_ADMIN,
    canGradeSubjective: (role) => role === ROLES.ADMIN || role === ROLES.SUPER_ADMIN,
    canManageUsers: (role) => role === ROLES.SUPER_ADMIN
};

// 문제 유형
const QUESTION_TYPES = {
    MULTIPLE_CHOICE: 'multiple_choice',
    SUBJECTIVE: 'subjective',
    GROUP: 'group'
};

// 시험 상태
const EXAM_STATUS = {
    DRAFT: 'draft',
    PUBLISHED: 'published',
    CLOSED: 'closed'
};

// 세션 상태
const SESSION_STATUS = {
    IN_PROGRESS: 'in_progress',
    SUBMITTED: 'submitted',
    GRADED: 'graded'
};

// 부서 코드
const DEPARTMENTS = {
    TAX: { code: 'TAX', name: '세무팀' },
    AUDIT: { code: 'AUDIT', name: '감사팀' },
    CONSULTING: { code: 'CONSULTING', name: '컨설팅팀' },
    ADMIN: { code: 'ADMIN', name: '관리팀' }
};

// 카테고리 타입
const CATEGORY_TYPES = {
    SUBJECT: 'subject', // 세목
    AREA: 'area', // 영역
    CHAPTER: 'chapter' // 장
};

// 유틸리티 함수들
const Utils = {
    // 시간 포맷팅
    formatTime: (seconds) => {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        
        if (hours > 0) {
            return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    },

    // 날짜 포맷팅
    formatDate: (date) => {
        return new Date(date).toLocaleDateString('ko-KR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    // 점수 포맷팅
    formatScore: (score, total) => {
        if (total === 0) return '0%';
        return `${score}/${total} (${Math.round((score / total) * 100)}%)`;
    },

    // 디바운스 함수
    debounce: (func, wait) => {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    // 로컬 스토리지 헬퍼
    storage: {
        set: (key, value) => {
            try {
                localStorage.setItem(key, JSON.stringify(value));
                return true;
            } catch (e) {
                console.error('Storage set error:', e);
                return false;
            }
        },
        get: (key) => {
            try {
                const item = localStorage.getItem(key);
                return item ? JSON.parse(item) : null;
            } catch (e) {
                console.error('Storage get error:', e);
                return null;
            }
        },
        remove: (key) => {
            try {
                localStorage.removeItem(key);
                return true;
            } catch (e) {
                console.error('Storage remove error:', e);
                return false;
            }
        }
    },

    // 알림 함수
    showAlert: (message, type = 'info') => {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type}`;
        alertDiv.innerHTML = `
            <i class="fas fa-${type === 'error' ? 'exclamation-triangle' : type === 'success' ? 'check-circle' : 'info-circle'}"></i>
            ${message}
        `;
        
        // 기존 알림 제거
        const existingAlert = document.querySelector('.alert');
        if (existingAlert) {
            existingAlert.remove();
        }
        
        // 새 알림 추가
        const container = document.querySelector('.main-content') || document.body;
        container.insertBefore(alertDiv, container.firstChild);
        
        // 3초 후 자동 제거
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 3000);
    },

    // 로딩 스피너 제어
    showLoading: () => {
        const loading = document.getElementById('loading');
        if (loading) loading.classList.remove('hidden');
    },

    hideLoading: () => {
        const loading = document.getElementById('loading');
        if (loading) loading.classList.add('hidden');
    },

    // HTML 이스케이프
    escapeHtml: (text) => {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, (m) => map[m]);
    },

    // 파일 크기 포맷팅
    formatFileSize: (bytes) => {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    // 객체 깊은 복사
    deepClone: (obj) => {
        if (obj === null || typeof obj !== 'object') return obj;
        if (obj instanceof Date) return new Date(obj.getTime());
        if (obj instanceof Array) return obj.map(item => Utils.deepClone(item));
        if (typeof obj === 'object') {
            const clonedObj = {};
            for (const key in obj) {
                if (obj.hasOwnProperty(key)) {
                    clonedObj[key] = Utils.deepClone(obj[key]);
                }
            }
            return clonedObj;
        }
    },

    // 배열 섞기 (피셔-예이츠 알고리즘)
    shuffleArray: (array) => {
        const shuffled = [...array];
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        return shuffled;
    }
};

// 전역 변수
window.supabase = null;
window.currentUser = null;
window.currentExamSession = null;
window.examTimer = null;

// 초기화가 완료되었는지 확인하는 플래그
window.appInitialized = false;
