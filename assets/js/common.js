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
        await this.checkAuthState();
        
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

            // Supabase 라이브러리 로드 대기 (다양한 방법으로 확인)
            let attempts = 0;
            const maxAttempts = 100;
            
            console.log('🔍 Supabase 라이브러리 로딩 대기 중...');
            
            while (attempts < maxAttempts) {
                // 더 정확한 Supabase 확인
                let supabaseFound = false;
                let supabaseLib = null;
                
                // 1. window.supabase 직접 확인
                if (window.supabase && typeof window.supabase === 'object') {
                    console.log('🔍 window.supabase 발견:', typeof window.supabase, Object.keys(window.supabase));
                    
                    // createClient 함수 확인
                    if (window.supabase.createClient && typeof window.supabase.createClient === 'function') {
                        console.log('✅ window.supabase.createClient 함수 발견!');
                        supabaseLib = window.supabase;
                        supabaseFound = true;
                    } else {
                        console.log('⚠️ window.supabase는 있지만 createClient가 없음:', Object.keys(window.supabase));
                    }
                }
                
                // 2. window.Supabase 확인
                if (!supabaseFound && window.Supabase && typeof window.Supabase === 'object') {
                    console.log('🔍 window.Supabase 발견:', typeof window.Supabase, Object.keys(window.Supabase));
                    if (window.Supabase.createClient && typeof window.Supabase.createClient === 'function') {
                        console.log('✅ window.Supabase.createClient 함수 발견!');
                        supabaseLib = window.Supabase;
                        supabaseFound = true;
                    }
                }
                
                if (supabaseFound) {
                    console.log('✅ Supabase 라이브러리 발견!', supabaseLib);
                    break;
                }
                
                await new Promise(resolve => setTimeout(resolve, 100));
                attempts++;
                
                if (attempts % 20 === 0) {
                    console.log(`⏳ Supabase 라이브러리 대기 중... ${attempts}/${maxAttempts}`);
                    console.log('현재 window 객체의 supabase 관련 속성:', 
                        Object.keys(window).filter(key => key.toLowerCase().includes('supa')));
                    
                    // 상세 디버깅
                    if (window.supabase) {
                        console.log('📋 window.supabase 상세:', {
                            type: typeof window.supabase,
                            constructor: window.supabase.constructor?.name,
                            keys: Object.keys(window.supabase),
                            createClient: typeof window.supabase.createClient
                        });
                    }
                }
            }

            // Supabase 클라이언트 생성 시도
            const supabaseLib = window.supabase || window.Supabase;
            if (supabaseLib && supabaseLib.createClient) {
                try {
                    this.supabaseClient = supabaseLib.createClient(
                        SUPABASE_CONFIG.url,
                        SUPABASE_CONFIG.anonKey
                    );
                    
                    // 전역 변수로도 설정
                    window.supabaseClient = this.supabaseClient;
                    
                    // 연결 테스트
                    console.log('🧪 Supabase 연결 테스트 중...');
                    const testResult = await this.supabaseClient.from('profiles').select('count', { count: 'exact', head: true });
                    console.log('✅ Supabase 연결 및 테스트 성공!');
                    
                } catch (error) {
                    console.error('❌ Supabase 클라이언트 생성 실패:', error);
                    this.supabaseClient = null;
                }
            } else {
                console.warn('⚠️ Supabase 라이브러리를 찾을 수 없습니다.');
                console.log('사용 가능한 전역 객체:', Object.keys(window).filter(key => 
                    key.toLowerCase().includes('supa') || key.toLowerCase().includes('auth')
                ));
            }
        } catch (error) {
            console.error('❌ Supabase 초기화 실패:', error);
        }
    }

    async checkAuthState() {
        // Supabase 세션 확인
        try {
            if (this.supabaseClient) {
                const { data: { session }, error } = await this.supabaseClient.auth.getSession();
                
                if (error) {
                    console.error('세션 확인 오류:', error);
                    return;
                }

                if (session?.user) {
                    console.log('✅ Supabase 세션 발견:', session.user.email);
                    
                    // 프로필 정보 가져오기
                    const { data: profile } = await this.supabaseClient
                        .from('profiles')
                        .select('*, departments(name, code)')
                        .eq('id', session.user.id)
                        .single();

                    if (profile) {
                        this.currentUser = {
                            id: session.user.id,
                            email: session.user.email,
                            name: profile.name,
                            role: profile.role || 'employee',
                            department: profile.departments?.name || '미지정',
                            department_id: profile.department_id,
                            hire_date: profile.hire_date,
                            phone: profile.phone,
                            loginTime: new Date().toISOString()
                        };
                        
                        console.log('✅ 세션에서 사용자 정보 복원:', this.currentUser.email);
                    }
                } else {
                    console.log('📋 활성 세션 없음');
                    this.currentUser = null;
                }
            }
        } catch (error) {
            console.error('❌ 인증 상태 확인 실패:', error);
            this.currentUser = null;
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

    // 인증 관련 메서드 (Supabase 전용)
    async login(email, password) {
        try {
            console.log('🔐 로그인 시도:', email);

            if (!this.supabaseClient) {
                throw new Error('Supabase 클라이언트가 초기화되지 않았습니다. 데이터베이스 연결이 필요합니다.');
            }

            // Supabase 로그인 시도
            const { data, error } = await this.supabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });

            if (error) throw error;

            console.log('✅ Auth 로그인 성공:', data.user?.email);

            // 프로필 정보 가져오기
            const { data: profile, error: profileError } = await this.supabaseClient
                .from('profiles')
                .select('*, departments(name, code)')
                .eq('id', data.user.id)
                .single();

            if (profileError) {
                console.error('프로필 정보 조회 실패:', profileError);
                throw new Error('사용자 프로필 정보를 찾을 수 없습니다.');
            }

            this.currentUser = {
                id: data.user.id,
                email: data.user.email,
                name: profile?.name || data.user.user_metadata?.name || email.split('@')[0],
                role: profile?.role || 'employee',
                department: profile?.departments?.name || '미지정',
                department_id: profile?.department_id,
                hire_date: profile?.hire_date,
                phone: profile?.phone,
                loginTime: new Date().toISOString()
            };

            console.log('✅ 프로필 정보 로드 완료:', this.currentUser);
            
            console.log('✅ Supabase 로그인 성공:', this.currentUser);
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



    async logout() {
        try {
            if (this.supabaseClient) {
                const { error } = await this.supabaseClient.auth.signOut();
                if (error) throw error;
            }
            
            this.currentUser = null;
            
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

    // 회원가입 메서드 (Supabase 전용)
    async register(userData) {
        try {
            console.log('📝 회원가입 시도:', userData.email);

            if (!this.supabaseClient) {
                throw new Error('Supabase 클라이언트가 초기화되지 않았습니다. 데이터베이스 연결이 필요합니다.');
            }
                // Supabase 회원가입
                const { data, error } = await this.supabaseClient.auth.signUp({
                    email: userData.email,
                    password: userData.password,
                    options: {
                        data: {
                            name: userData.name,
                            department: userData.department,
                            hire_date: userData.hire_date,
                            phone: userData.phone || null
                        }
                    }
                });

                if (error) throw error;

                // 부서 ID 먼저 조회
                console.log('📋 부서 정보 조회 중...');
                let departmentId = null;
                
                try {
                    const { data: department, error: deptError } = await this.supabaseClient
                        .from('departments')
                        .select('id')
                        .eq('code', userData.department.toUpperCase())
                        .single();

                    if (deptError) {
                        console.warn('부서 조회 실패, 기본값 사용:', deptError.message);
                        // 기본 부서 (첫 번째 부서) 사용
                        const { data: defaultDept } = await this.supabaseClient
                            .from('departments')
                            .select('id')
                            .limit(1)
                            .single();
                        departmentId = defaultDept?.id;
                    } else {
                        departmentId = department.id;
                        console.log('✅ 부서 ID 찾음:', departmentId);
                    }
                } catch (error) {
                    console.warn('부서 조회 중 오류, 계속 진행:', error.message);
                }

                // 프로필 테이블에 사용자 정보 저장
                if (data.user) {
                    const profileData = {
                        id: data.user.id,
                        name: userData.name,
                        email: userData.email,
                        department_id: departmentId,
                        hire_date: userData.hire_date,
                        phone: userData.phone || null,
                        role: 'employee'
                    };

                    console.log('💾 프로필 데이터:', profileData);

                    const { data: profileResult, error: profileError } = await this.supabaseClient
                        .from('profiles')
                        .insert([profileData])
                        .select()
                        .single();

                    if (profileError) {
                        console.error('프로필 저장 실패:', profileError);
                        throw new Error(`프로필 저장 실패: ${profileError.message}`);
                    }

                    console.log('✅ 프로필 저장 완료:', profileResult);
                }

                console.log('✅ 회원가입 성공:', data.user);
                return { success: true, user: data.user };

        } catch (error) {
            console.error('❌ 회원가입 실패:', error);
            let message = '회원가입에 실패했습니다.';
            
            if (error.message.includes('User already registered')) {
                message = '이미 등록된 이메일입니다.';
            } else if (error.message.includes('Password should be at least 6 characters')) {
                message = '비밀번호는 최소 6자 이상이어야 합니다.';
            } else if (error.message.includes('Invalid email')) {
                message = '올바른 이메일 형식이 아닙니다.';
            }
            
            return { success: false, error: message };
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
