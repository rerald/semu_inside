// 세무인사이드 시험 플랫폼 설정

// Supabase 설정
const SUPABASE_CONFIG = {
    url: 'https://skpvtqohyspfsmvwrgoc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrcHZ0cW9oeXNwZnNtdndyZ29jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNzU4ODUsImV4cCI6MjA3MTc1MTg4NX0.tMW3hiZR5JcXlbES2tKl1ZNOVRtYqGO04m-YSbqKUhY'
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
