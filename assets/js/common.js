// 세무인사이드 공통 JavaScript 유틸리티

class SemuApp {
    constructor() {
        this.currentUser = null;
        this.supabaseClient = null;
        this.init();
    }

    async init() {
        console.log('🚀 세무인사이드 앱 초기화');
        
        // Supabase 초기화
        await this.initSupabase();
        
        // 인증 상태 확인
        this.checkAuthState();
        
        // 공통 이벤트 리스너 설정
        this.setupCommonEventListeners();
    }

    async initSupabase() {
        try {
            // Supabase 설정
            const SUPABASE_CONFIG = {
                url: 'https://skpvtqohyspfsmvwrgoc.supabase.co',
                anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrcHZ0cW9oeXNwZnNtdndyZ29jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNzU4ODUsImV4cCI6MjA3MTc1MTg4NX0.tMW3hiZR5JcXlbES2tKl1ZNOVRtYqGO04m-YSbqKUhY'
            };

            // Supabase 라이브러리 로드 대기
            let attempts = 0;
            while (!window.supabase && attempts < 50) {
                await new Promise(resolve => setTimeout(resolve, 100));
                attempts++;
            }

            if (window.supabase) {
                this.supabaseClient = window.supabase.createClient(
                    SUPABASE_CONFIG.url,
                    SUPABASE_CONFIG.anonKey
                );
                console.log('✅ Supabase 연결 성공');
            } else {
                console.warn('⚠️ Supabase 라이브러리를 찾을 수 없습니다. Mock 모드로 실행합니다.');
            }
        } catch (error) {
            console.error('❌ Supabase 초기화 실패:', error);
        }
    }

    checkAuthState() {
        // 로컬 저장소에서 사용자 정보 확인
        const savedUser = localStorage.getItem('semu_user');
        if (savedUser) {
            try {
                this.currentUser = JSON.parse(savedUser);
                console.log('✅ 저장된 사용자 세션 복원:', this.currentUser.email);
            } catch (error) {
                console.error('❌ 사용자 세션 복원 실패:', error);
                localStorage.removeItem('semu_user');
            }
        }
    }

    setupCommonEventListeners() {
        // 로그아웃 버튼들
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('logout-btn') || e.target.closest('.logout-btn')) {
                e.preventDefault();
                this.logout();
            }
        });

        // 네비게이션 링크들
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('nav-link')) {
                const href = e.target.getAttribute('href');
                if (href && href.startsWith('./')) {
                    // 상대 경로 네비게이션은 그대로 진행
                    return;
                }
            }
        });
    }

    // 인증 관련 메서드
    async login(email, password) {
        try {
            console.log('🔐 로그인 시도:', email);

            if (this.supabaseClient) {
                // Supabase 로그인
                const { data, error } = await this.supabaseClient.auth.signInWithPassword({
                    email: email,
                    password: password
                });

                if (error) throw error;

                // 프로필 정보 가져오기
                const { data: profile } = await this.supabaseClient
                    .from('profiles')
                    .select('*, departments(name, code)')
                    .eq('id', data.user.id)
                    .single();

                this.currentUser = {
                    id: data.user.id,
                    email: data.user.email,
                    name: profile?.name || data.user.user_metadata?.name || email.split('@')[0],
                    role: profile?.role || 'employee',
                    department: profile?.departments?.name || '미지정',
                    loginTime: new Date().toISOString()
                };
            } else {
                // Mock 로그인
                if (this.validateMockLogin(email, password)) {
                    this.currentUser = {
                        id: 'mock-' + Date.now(),
                        email: email,
                        name: email.split('@')[0],
                        role: email.includes('admin') ? 'admin' : 'employee',
                        department: '테스트팀',
                        loginTime: new Date().toISOString()
                    };
                } else {
                    throw new Error('Invalid credentials');
                }
            }

            // 세션 저장
            localStorage.setItem('semu_user', JSON.stringify(this.currentUser));
            
            console.log('✅ 로그인 성공:', this.currentUser);
            return { success: true, user: this.currentUser };

        } catch (error) {
            console.error('❌ 로그인 실패:', error);
            let message = '로그인에 실패했습니다.';
            
            if (error.message.includes('Invalid login credentials') || error.message === 'Invalid credentials') {
                message = '이메일 또는 비밀번호가 올바르지 않습니다.';
            } else if (error.message.includes('Email not confirmed')) {
                message = '이메일 인증이 필요합니다.';
            }
            
            return { success: false, error: message };
        }
    }

    validateMockLogin(email, password) {
        const validAccounts = [
            { email: 'admin@semu.com', password: '123456' },
            { email: 'kjtsori@gmail.com', password: '123456' },
            { email: 'rerald293@gmail.com', password: '123456' },
            { email: 'test@test.com', password: '123456' }
        ];

        return validAccounts.some(account => 
            account.email === email && account.password === password
        );
    }

    async logout() {
        try {
            if (this.supabaseClient) {
                await this.supabaseClient.auth.signOut();
            }
            
            this.currentUser = null;
            localStorage.removeItem('semu_user');
            
            console.log('✅ 로그아웃 완료');
            
            // 로그인 페이지로 리다이렉트
            this.showAlert('로그아웃 되었습니다.', 'success');
            
            setTimeout(() => {
                window.location.href = './login.html';
            }, 1000);
            
        } catch (error) {
            console.error('❌ 로그아웃 실패:', error);
            this.showAlert('로그아웃 중 오류가 발생했습니다.', 'error');
        }
    }

    // 네비게이션 메서드
    navigateTo(page) {
        const pages = {
            'login': './login.html',
            'dashboard': './dashboard.html',
            'exam': './exam.html',
            'results': './results.html',
            'profile': './profile.html',
            'admin': './admin.html'
        };

        const url = pages[page];
        if (url) {
            window.location.href = url;
        } else {
            console.error('❌ 알 수 없는 페이지:', page);
        }
    }

    // 인증 확인
    requireAuth() {
        if (!this.currentUser) {
            this.showAlert('로그인이 필요합니다.', 'warning');
            setTimeout(() => {
                window.location.href = './login.html';
            }, 1500);
            return false;
        }
        return true;
    }

    // 관리자 권한 확인
    requireAdmin() {
        if (!this.requireAuth()) return false;
        
        if (this.currentUser.role !== 'admin' && this.currentUser.role !== 'super_admin') {
            this.showAlert('관리자 권한이 필요합니다.', 'error');
            return false;
        }
        return true;
    }

    // UI 유틸리티
    showAlert(message, type = 'info') {
        // 기존 알림 제거
        const existingAlerts = document.querySelectorAll('.alert');
        existingAlerts.forEach(alert => alert.remove());

        const alert = document.createElement('div');
        alert.className = `alert ${type}`;
        alert.textContent = message;
        
        document.body.appendChild(alert);
        
        // 자동 제거
        setTimeout(() => {
            if (alert.parentNode) {
                alert.remove();
            }
        }, 4000);
    }

    showLoading(element) {
        const loader = document.createElement('div');
        loader.className = 'loading-spinner';
        loader.innerHTML = '<div class="loading-spinner"></div>';
        element.appendChild(loader);
        return loader;
    }

    hideLoading(loader) {
        if (loader && loader.parentNode) {
            loader.remove();
        }
    }

    // 폼 유틸리티
    validateForm(formElement) {
        const inputs = formElement.querySelectorAll('input[required], select[required], textarea[required]');
        let isValid = true;

        inputs.forEach(input => {
            const value = input.value.trim();
            
            if (!value) {
                this.setFieldError(input, '필수 입력 항목입니다.');
                isValid = false;
            } else if (input.type === 'email' && !this.isValidEmail(value)) {
                this.setFieldError(input, '올바른 이메일 형식이 아닙니다.');
                isValid = false;
            } else {
                this.clearFieldError(input);
            }
        });

        return isValid;
    }

    setFieldError(input, message) {
        input.classList.add('error');
        
        // 기존 에러 메시지 제거
        const existingError = input.parentNode.querySelector('.error-message');
        if (existingError) {
            existingError.remove();
        }

        // 새 에러 메시지 추가
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        errorDiv.style.color = 'var(--error-color)';
        errorDiv.style.fontSize = '12px';
        errorDiv.style.marginTop = '4px';
        errorDiv.textContent = message;
        
        input.parentNode.appendChild(errorDiv);
    }

    clearFieldError(input) {
        input.classList.remove('error');
        const errorMessage = input.parentNode.querySelector('.error-message');
        if (errorMessage) {
            errorMessage.remove();
        }
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // 데이터 포맷팅
    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('ko-KR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;

        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        } else {
            return `${minutes}:${secs.toString().padStart(2, '0')}`;
        }
    }
}

// 전역 앱 인스턴스
let app;

// DOM 로드 완료 시 앱 초기화
document.addEventListener('DOMContentLoaded', () => {
    app = new SemuApp();
    window.semuApp = app; // 전역 접근 가능
});

// 공통 유틸리티 함수들
window.showAlert = (message, type) => {
    if (window.semuApp) {
        window.semuApp.showAlert(message, type);
    }
};

window.navigateTo = (page) => {
    if (window.semuApp) {
        window.semuApp.navigateTo(page);
    }
};
