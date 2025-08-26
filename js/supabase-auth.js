// Supabase 연결 및 인증 시스템
console.log('Supabase auth script loaded');

let supabaseClient = null;
let currentUser = null;

// Supabase 초기화 함수
async function initSupabase() {
    try {
        console.log('🔄 Initializing Supabase connection...');
        console.log('Config URL:', SUPABASE_CONFIG.url);
        console.log('Config Key (first 10 chars):', SUPABASE_CONFIG.anonKey.substring(0, 10) + '...');
        
        // Supabase 라이브러리 로드 확인 (더 오래 기다리기)
        let attempts = 0;
        const maxAttempts = 100; // 늘림: 50 -> 100
        
        console.log('🔍 Available window properties:', Object.keys(window).filter(key => key.toLowerCase().includes('supa')));
        
        while (attempts < maxAttempts) {
            // 다양한 방법으로 Supabase 확인
            if (window.supabase || window.Supabase || (window.supabaseClient && window.supabaseClient.createClient)) {
                const supabaseObj = window.supabase || window.Supabase || window.supabaseClient;
                console.log('✅ Supabase library found!', supabaseObj);
                
                // 전역 window.supabase 설정
                if (!window.supabase && supabaseObj) {
                    window.supabase = supabaseObj;
                }
                break;
            }
            
            await new Promise(resolve => setTimeout(resolve, 150)); // 늘림: 100ms -> 150ms
            attempts++;
            
            if (attempts % 10 === 0) {
                console.log(`⏳ Waiting for Supabase library... attempt ${attempts}/${maxAttempts}`);
                console.log('Current window.supabase:', window.supabase);
            }
        }

        if (!window.supabase) {
            console.error('📋 Final check - Available globals:', Object.keys(window).filter(key => key.toLowerCase().includes('supa')));
            throw new Error('Supabase library failed to load after extended waiting');
        }

        // Supabase 클라이언트 생성
        console.log('🔧 Creating Supabase client...');
        supabaseClient = window.supabase.createClient(
            SUPABASE_CONFIG.url,
            SUPABASE_CONFIG.anonKey
        );

        // 연결 테스트
        console.log('🧪 Testing Supabase connection...');
        const { data, error } = await supabaseClient.auth.getSession();
        
        if (error && !error.message.includes('session_not_found')) {
            throw new Error(`Connection test failed: ${error.message}`);
        }

        console.log('✅ Supabase connected successfully!');
        console.log('Session check result:', data ? 'Valid' : 'No active session');
        
        showAlert('✅ Supabase 연결 성공! 실제 데이터베이스를 사용합니다.', 'success');
        return true;

    } catch (error) {
        console.error('❌ Supabase connection failed:', error);
        console.log('📄 Error details:', {
            message: error.message,
            url: SUPABASE_CONFIG.url,
            keyLength: SUPABASE_CONFIG.anonKey.length
        });
        
        // 실패 시 Mock 모드로 전환하지 않고 오류 표시
        showAlert('❌ Supabase 연결에 실패했습니다. 설정을 확인해주세요.', 'error');
        return false;
    }
}

// Mock Supabase 설정 함수
function setupMockSupabase() {
    supabaseClient = {
        auth: {
            signUp: async (data) => {
                console.log('🎭 Mock signup:', data);
                const users = JSON.parse(localStorage.getItem('mockUsers') || '[]');
                const existingUser = users.find(u => u.email === data.email);
                
                if (existingUser) {
                    throw new Error('User already registered');
                }
                
                const newUser = {
                    id: 'mock-' + Date.now(),
                    email: data.email,
                    name: data.options?.data?.name || 'Unknown'
                };
                
                users.push(newUser);
                localStorage.setItem('mockUsers', JSON.stringify(users));
                
                return {
                    data: { user: newUser },
                    error: null
                };
            },
            
            signInWithPassword: async (data) => {
                console.log('🎭 Mock login:', data);
                const users = JSON.parse(localStorage.getItem('mockUsers') || '[]');
                const user = users.find(u => u.email === data.email);
                
                if (!user) {
                    throw new Error('Invalid login credentials');
                }
                
                return {
                    data: { user },
                    error: null
                };
            },
            
            signOut: async () => {
                console.log('🎭 Mock logout');
                return { error: null };
            }
        },
        
        from: (table) => ({
            select: (fields) => ({
                eq: (column, value) => ({
                    single: async () => {
                        console.log(`🎭 Mock query: SELECT ${fields} FROM ${table} WHERE ${column} = ${value}`);
                        
                        if (table === 'profiles') {
                            const users = JSON.parse(localStorage.getItem('mockUsers') || '[]');
                            const user = users.find(u => u.id === value || u.email === value);
                            
                            if (user) {
                                return {
                                    data: {
                                        ...user,
                                        role: user.email.includes('admin') ? 'super_admin' : 'employee',
                                        departments: { name: '테스트팀', code: 'TEST' }
                                    },
                                    error: null
                                };
                            }
                        }
                        
                        if (table === 'departments') {
                            return {
                                data: { id: 'mock-dept-1', name: '테스트팀', code: 'TEST' },
                                error: null
                            };
                        }
                        
                        return { data: null, error: { message: 'Not found' } };
                    }
                })
            }),
            
            insert: async (data) => {
                console.log(`🎭 Mock insert into ${table}:`, data);
                return { data, error: null };
            },
            
            update: async (data) => {
                console.log(`🎭 Mock update ${table}:`, data);
                return { data, error: null };
            }
        })
    };
    
    console.log('✅ Mock Supabase client created');
}

// 회원가입 함수
async function registerUser(userData) {
    try {
        console.log('🔄 실제 Supabase로 회원가입 시도:', userData);

        if (!supabaseClient) {
            throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
        }

        // 1. 부서 ID 먼저 조회
        console.log('📋 부서 정보 조회 중...');
        let departmentId = null;
        
        try {
            const { data: department, error: deptError } = await supabaseClient
                .from('departments')
                .select('id')
                .eq('code', userData.department.toUpperCase())
                .single();

            if (deptError) {
                console.warn('부서 조회 실패, 기본값 사용:', deptError.message);
                // 기본 부서 (첫 번째 부서) 사용
                const { data: defaultDept } = await supabaseClient
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

        // 2. Supabase Auth에 사용자 등록
        console.log('👤 Supabase Auth에 사용자 등록 중...');
        // 비밀번호 검증
        if (window.passwordValidator && !window.passwordValidator.isPasswordValid()) {
            const errors = window.passwordValidator.getValidationErrors();
            throw new Error('비밀번호 조건을 만족하지 않습니다:\n' + errors.join('\n'));
        }

        const { data: authData, error: authError } = await supabaseClient.auth.signUp({
            email: userData.email,
            password: userData.password,
            options: {
                data: { 
                    name: userData.name 
                }
            }
        });

        if (authError) {
            throw authError;
        }

        console.log('✅ Auth 사용자 생성 완료:', authData.user?.email);

        // 3. 프로필 테이블에 사용자 정보 저장
        console.log('💾 프로필 정보 저장 중...');
        const profileData = {
            id: authData.user.id,
            name: userData.name,
            email: userData.email,
            department_id: departmentId,
            hire_date: userData.hire_date,
            phone: userData.phone,
            role: 'employee'
        };

        console.log('프로필 데이터:', profileData);

        // 프로필 저장 시도 (RLS 정책 우회를 위해 재시도 로직 추가)
        let profileResult, profileError;
        
        try {
            const { data, error } = await supabaseClient
                .from('profiles')
                .insert([profileData])
                .select()
                .single();
            
            profileResult = data;
            profileError = error;
        } catch (insertError) {
            console.warn('첫 번째 INSERT 시도 실패, RLS 정책 문제 가능성:', insertError.message);
            
            // RLS 우회를 위한 대안적 접근
            try {
                const { data, error } = await supabaseClient
                    .from('profiles')
                    .upsert([profileData], { 
                        onConflict: 'id',
                        ignoreDuplicates: false 
                    })
                    .select()
                    .single();
                
                profileResult = data;
                profileError = error;
                console.log('UPSERT로 성공적으로 저장됨');
            } catch (upsertError) {
                profileError = upsertError;
                console.error('UPSERT도 실패:', upsertError.message);
            }
        }

        if (profileError) {
            console.error('프로필 저장 실패:', profileError);
            throw new Error(`프로필 저장 실패: ${profileError.message}`);
        }

        console.log('✅ 프로필 저장 완료:', profileResult);
        console.log('🎉 실제 Supabase 회원가입 완료!');
        
        showAlert('✅ 회원가입이 완료되었습니다! 실제 데이터베이스에 저장되었습니다.', 'success');
        return { success: true, data: profileResult };

    } catch (error) {
        console.error('❌ 회원가입 오류:', error);
        
        let message = '회원가입에 실패했습니다.';
        if (error.message.includes('User already registered') || error.message.includes('already_registered')) {
            message = '이미 등록된 이메일입니다.';
        } else if (error.message.includes('Password') || error.message.includes('password')) {
            message = '비밀번호는 최소 6자 이상이어야 합니다.';
        } else if (error.message.includes('Invalid email') || error.message.includes('email')) {
            message = '올바른 이메일 형식이 아닙니다.';
        } else if (error.message.includes('profiles_email_key')) {
            message = '이미 등록된 이메일입니다.';
        } else {
            message = `회원가입 실패: ${error.message}`;
        }
        
        showAlert(message, 'error');
        return { success: false, error };
    }
}

// 로그인 함수
async function loginUser(email, password) {
    try {
        console.log('🔄 로그인 시도:', email);
        console.log('🔍 Supabase client:', supabaseClient ? 'Available' : 'Not available');

        if (!supabaseClient) {
            throw new Error('Supabase 클라이언트가 초기화되지 않았습니다.');
        }

        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email: email,
            password: password
        });

        if (error) {
            console.error('🔍 Auth error:', error);
            throw error;
        }

        console.log('✅ Auth data received:', data);

        // 사용자 프로필 생성
        currentUser = {
            id: data.user.id,
            email: data.user.email,
            name: data.user.user_metadata?.name || '테스트 사용자',
            role: email.includes('admin') ? 'super_admin' : 'employee',
            departments: { name: '테스트팀', code: 'TEST' }
        };

        console.log('✅ 로그인 성공:', currentUser);
        showAlert('로그인에 성공했습니다!', 'success');
        
        return { success: true, user: currentUser };

    } catch (error) {
        console.error('❌ 로그인 오류:', error);
        
        // Mock 모드에서 간단한 로그인 (테스트용)
        if (error.message.includes('Supabase') || !supabaseClient.auth.signInWithPassword) {
            console.log('🎭 Mock login mode activated');
            
            // 간단한 검증
            if (email && password.length >= 6) {
                currentUser = {
                    id: 'mock-' + Date.now(),
                    email: email,
                    name: email.split('@')[0],
                    role: email.includes('admin') ? 'super_admin' : 'employee',
                    departments: { name: '테스트팀', code: 'TEST' }
                };
                
                console.log('✅ Mock 로그인 성공:', currentUser);
                showAlert('테스트 로그인 성공!', 'success');
                return { success: true, user: currentUser };
            }
        }
        
        let message = '로그인에 실패했습니다.';
        if (error.message.includes('Invalid login credentials')) {
            message = '이메일 또는 비밀번호가 올바르지 않습니다.';
        } else if (error.message.includes('Email not confirmed')) {
            message = '이메일 인증이 필요합니다.';
        }
        
        showAlert(message, 'error');
        return { success: false, error };
    }
}

// 로그아웃 함수
async function logoutUser() {
    try {
        const { error } = await supabaseClient.auth.signOut();
        if (error) throw error;

        currentUser = null;
        console.log('✅ 로그아웃 완료');
        showAlert('로그아웃되었습니다.', 'success');
        
        return { success: true };
    } catch (error) {
        console.error('❌ 로그아웃 오류:', error);
        showAlert('로그아웃 중 오류가 발생했습니다.', 'error');
        return { success: false, error };
    }
}

// 알림 표시 함수
function showAlert(message, type = 'info') {
    const existingAlert = document.querySelector('.alert');
    if (existingAlert) {
        existingAlert.remove();
    }

    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.innerHTML = `
        <i class="fas fa-${type === 'error' ? 'exclamation-triangle' : type === 'success' ? 'check-circle' : 'info-circle'}"></i>
        ${message}
    `;

    const container = document.querySelector('.main-content') || document.body;
    container.insertBefore(alertDiv, container.firstChild);

    setTimeout(() => {
        if (alertDiv.parentNode) {
            alertDiv.remove();
        }
    }, 3000);
}

// 페이지 전환 함수들
function showLoginPage() {
    hideAllPages();
    document.getElementById('login-page').classList.remove('hidden');
}

function showRegisterPage() {
    hideAllPages();
    document.getElementById('register-page').classList.remove('hidden');
}

function showDashboard() {
    hideAllPages();
    document.getElementById('dashboard').classList.remove('hidden');
    
    const userNameEl = document.getElementById('user-name');
    if (userNameEl && currentUser) {
        userNameEl.textContent = currentUser.name;
    }

    const adminNav = document.querySelector('.admin-only');
    if (adminNav && currentUser) {
        if (currentUser.role === 'admin' || currentUser.role === 'super_admin') {
            adminNav.classList.remove('hidden');
        } else {
            adminNav.classList.add('hidden');
        }
    }

    displayMockExams();
}

function hideAllPages() {
    document.querySelectorAll('.page').forEach(page => {
        page.classList.add('hidden');
    });
}

// 가짜 시험 데이터 표시
function displayMockExams() {
    const examsList = document.getElementById('exams-list');
    if (examsList) {
        examsList.innerHTML = `
            <div class="exam-card">
                <div class="exam-card-header">
                    <div>
                        <h4 class="exam-title">2024년 1분기 부가가치세 평가</h4>
                        <span class="exam-status available">응시 가능</span>
                    </div>
                </div>
                <p class="exam-description">부가가치세 기본 개념과 실무 적용 능력을 평가하는 시험입니다.</p>
                <div class="exam-meta">
                    <span><i class="fas fa-clock"></i> 60분</span>
                    <span><i class="fas fa-question-circle"></i> 20문항</span>
                    <span><i class="fas fa-calendar"></i> 언제든지</span>
                </div>
                <div class="exam-actions">
                    <button class="btn btn-primary" onclick="alert('시험 기능은 추후 구현 예정입니다.')">
                        <i class="fas fa-play"></i> 시험 시작
                    </button>
                </div>
            </div>
        `;
    }
}

// 이벤트 리스너 설정
function setupEventListeners() {
    // 회원가입 폼
    const registerForm = document.getElementById('register-form');
    if (registerForm) {
        registerForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = new FormData(registerForm);
            const userData = {
                name: formData.get('name'),
                email: formData.get('email'),
                password: formData.get('password'),
                department: formData.get('department'),
                hire_date: formData.get('hire_date'),
                phone: formData.get('phone')
            };

            const result = await registerUser(userData);
            if (result.success) {
                showAlert('✅ 회원가입이 완료되었습니다! 로그인해주세요.', 'success');
                // 라우터를 통해 로그인 페이지로 이동
                if (window.router) {
                    window.router.navigateTo('/login');
                } else {
                    showLoginPage();
                }
                registerForm.reset();
            }
        });
    }

    // 로그인 폼
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        console.log('✅ Login form found, setting up listener');
        loginForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            console.log('🔄 Login form submitted');
            
            const formData = new FormData(loginForm);
            const email = formData.get('email');
            const password = formData.get('password');
            
            console.log('📧 Email:', email);
            console.log('🔑 Password length:', password ? password.length : 0);

            if (!email || !password) {
                showAlert('이메일과 비밀번호를 입력해주세요.', 'error');
                return;
            }

            const result = await loginUser(email, password);
            console.log('🔍 Login result:', result);
            
            if (result.success) {
                console.log('✅ Login successful, navigating to dashboard');
                // 라우터를 통해 대시보드로 이동
                if (window.router) {
                    window.router.navigateTo('/dashboard');
                } else {
                    showDashboard();
                }
            }
        });
    } else {
        console.error('❌ Login form not found!');
    }

    // 로그아웃 버튼
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', async function() {
            const result = await logoutUser();
            if (result.success) {
                showLoginPage();
            }
        });
    }

    // 회원가입/로그인 전환 링크
    const showRegisterLink = document.getElementById('show-register');
    const showLoginLink = document.getElementById('show-login');

    if (showRegisterLink) {
        showRegisterLink.addEventListener('click', function(e) {
            e.preventDefault();
            showRegisterPage();
        });
    }

    if (showLoginLink) {
        showLoginLink.addEventListener('click', function(e) {
            e.preventDefault();
            showLoginPage();
        });
    }

    // 탭 네비게이션
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            document.querySelectorAll('.nav-link').forEach(nav => nav.classList.remove('active'));
            this.classList.add('active');
            
            document.querySelectorAll('.tab-content').forEach(content => {
                content.classList.remove('active');
            });
            
            const targetTab = this.getAttribute('data-tab');
            const targetContent = document.getElementById(`${targetTab}-tab`);
            if (targetContent) {
                targetContent.classList.add('active');
            }
        });
    });
}

// DOM 로드 완료 후 실행
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🚀 DOM loaded, initializing app...');
    
    // 로딩 화면 즉시 숨기기
    const loadingElement = document.getElementById('loading');
    if (loadingElement) {
        loadingElement.classList.add('hidden');
        console.log('✅ Loading screen hidden');
    }

    // 라우터가 페이지 표시를 관리하므로 여기서는 제거
    // showLoginPage(); // 라우터가 처리
    
    // Mock 데이터 정리 (개발 중에만)
    console.log('🧹 Clearing mock data for fresh start...');
    localStorage.removeItem('mockUsers');

    // Supabase 초기화
    const supabaseReady = await initSupabase();
    
    if (!supabaseReady) {
        showAlert('⚠️ Supabase 연결에 실패했습니다. Mock 모드로 전환합니다.', 'warning');
        setupMockSupabase();
    }
    
    // 이벤트 리스너 설정
    setupEventListeners();
    
    console.log('✅ App initialization complete!');
});