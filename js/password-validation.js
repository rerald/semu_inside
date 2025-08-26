// 🔐 비밀번호 검증 시스템
console.log('Password validation system loaded');

class PasswordValidator {
    constructor() {
        this.passwordInput = null;
        this.confirmInput = null;
        this.isValid = false;
        this.rules = {
            length: false,
            uppercase: false,
            lowercase: false,
            number: false,
            special: false,
            match: false
        };
        
        this.init();
    }
    
    init() {
        // DOM 로드 후 초기화
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setupEventListeners());
        } else {
            this.setupEventListeners();
        }
    }
    
    setupEventListeners() {
        this.passwordInput = document.getElementById('reg-password');
        this.confirmInput = document.getElementById('reg-password-confirm');
        
        if (this.passwordInput) {
            this.passwordInput.addEventListener('input', (e) => this.validatePassword(e.target.value));
            this.passwordInput.addEventListener('focus', () => this.showPasswordRules());
        }
        
        if (this.confirmInput) {
            this.confirmInput.addEventListener('input', (e) => this.validatePasswordMatch());
            this.confirmInput.addEventListener('focus', () => this.showPasswordRules());
        }
        
        console.log('✅ Password validation listeners attached');
    }
    
    validatePassword(password) {
        if (!password) {
            this.resetValidation();
            return;
        }
        
        // 각 규칙 검증
        this.rules.length = password.length >= 8;
        this.rules.uppercase = /[A-Z]/.test(password);
        this.rules.lowercase = /[a-z]/.test(password);
        this.rules.number = /[0-9]/.test(password);
        this.rules.special = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
        
        // UI 업데이트
        this.updateRuleDisplay();
        this.updatePasswordStrength(password);
        this.validatePasswordMatch(); // 확인 비밀번호도 다시 검증
        
        // 전체 검증 상태 업데이트
        this.updateValidationState();
    }
    
    validatePasswordMatch() {
        if (!this.passwordInput || !this.confirmInput) return;
        
        const password = this.passwordInput.value;
        const confirm = this.confirmInput.value;
        
        if (!confirm) {
            this.rules.match = false;
            this.updateMatchDisplay('empty', '비밀번호 확인을 입력하세요');
            return;
        }
        
        if (password === confirm) {
            this.rules.match = true;
            this.updateMatchDisplay('match', '✓ 비밀번호가 일치합니다');
        } else {
            this.rules.match = false;
            this.updateMatchDisplay('no-match', '✗ 비밀번호가 일치하지 않습니다');
        }
        
        this.updateRuleDisplay();
        this.updateValidationState();
    }
    
    updateRuleDisplay() {
        const rules = [
            { id: 'rule-length', valid: this.rules.length },
            { id: 'rule-uppercase', valid: this.rules.uppercase },
            { id: 'rule-lowercase', valid: this.rules.lowercase },
            { id: 'rule-number', valid: this.rules.number },
            { id: 'rule-special', valid: this.rules.special },
            { id: 'rule-match', valid: this.rules.match }
        ];
        
        rules.forEach(rule => {
            const element = document.getElementById(rule.id);
            if (element) {
                const icon = element.querySelector('i');
                if (rule.valid) {
                    element.classList.add('valid');
                    if (icon) icon.className = 'fas fa-check-circle';
                } else {
                    element.classList.remove('valid');
                    if (icon) icon.className = 'fas fa-times-circle';
                }
            }
        });
    }
    
    updatePasswordStrength(password) {
        const strengthElement = document.getElementById('password-strength');
        const fillElement = document.getElementById('strength-fill');
        const textElement = document.getElementById('strength-text');
        
        if (!strengthElement || !fillElement || !textElement) return;
        
        // 강도 계산 (0-100)
        let strength = 0;
        let strengthText = '';
        let strengthClass = '';
        
        if (password.length === 0) {
            strength = 0;
            strengthText = '비밀번호를 입력하세요';
            strengthClass = '';
        } else {
            // 각 조건당 20점
            if (this.rules.length) strength += 20;
            if (this.rules.uppercase) strength += 20;
            if (this.rules.lowercase) strength += 20;
            if (this.rules.number) strength += 20;
            if (this.rules.special) strength += 20;
            
            // 강도 레벨 결정
            if (strength < 40) {
                strengthText = '약함';
                strengthClass = 'strength-weak';
            } else if (strength < 60) {
                strengthText = '보통';
                strengthClass = 'strength-fair';
            } else if (strength < 80) {
                strengthText = '좋음';
                strengthClass = 'strength-good';
            } else {
                strengthText = '강함';
                strengthClass = 'strength-strong';
            }
        }
        
        // UI 업데이트
        fillElement.style.width = `${strength}%`;
        textElement.textContent = strengthText;
        
        // 클래스 제거 후 새로운 클래스 추가
        strengthElement.className = 'password-strength';
        if (strengthClass) {
            strengthElement.classList.add(strengthClass);
        }
    }
    
    updateMatchDisplay(type, message) {
        const matchElement = document.getElementById('password-match');
        if (!matchElement) return;
        
        matchElement.textContent = message;
        matchElement.className = `password-match ${type}`;
    }
    
    showPasswordRules() {
        const rulesElement = document.querySelector('.password-rules');
        if (rulesElement) {
            rulesElement.style.display = 'block';
        }
    }
    
    updateValidationState() {
        // 모든 규칙이 통과했는지 확인
        this.isValid = Object.values(this.rules).every(rule => rule);
        
        // 입력 필드 스타일 업데이트
        if (this.passwordInput) {
            this.passwordInput.classList.remove('valid', 'invalid');
            if (this.passwordInput.value) {
                const basicRulesValid = this.rules.length && this.rules.uppercase && 
                                      this.rules.lowercase && this.rules.number && this.rules.special;
                this.passwordInput.classList.add(basicRulesValid ? 'valid' : 'invalid');
            }
        }
        
        if (this.confirmInput) {
            this.confirmInput.classList.remove('valid', 'invalid');
            if (this.confirmInput.value) {
                this.confirmInput.classList.add(this.rules.match ? 'valid' : 'invalid');
            }
        }
        
        // 제출 버튼 상태 업데이트
        this.updateSubmitButton();
    }
    
    updateSubmitButton() {
        const submitButton = document.querySelector('#register-form button[type="submit"]');
        if (submitButton) {
            if (this.isValid) {
                submitButton.disabled = false;
                submitButton.style.opacity = '1';
                submitButton.style.cursor = 'pointer';
            } else {
                // 비밀번호가 입력되었지만 조건을 만족하지 않는 경우에만 비활성화
                if (this.passwordInput && this.passwordInput.value) {
                    submitButton.disabled = true;
                    submitButton.style.opacity = '0.6';
                    submitButton.style.cursor = 'not-allowed';
                } else {
                    submitButton.disabled = false;
                    submitButton.style.opacity = '1';
                    submitButton.style.cursor = 'pointer';
                }
            }
        }
    }
    
    resetValidation() {
        this.rules = {
            length: false,
            uppercase: false,
            lowercase: false,
            number: false,
            special: false,
            match: false
        };
        
        this.updateRuleDisplay();
        this.updatePasswordStrength('');
        this.updateMatchDisplay('empty', '');
        this.updateValidationState();
    }
    
    // 외부에서 호출할 수 있는 검증 함수
    isPasswordValid() {
        return this.isValid;
    }
    
    getValidationErrors() {
        const errors = [];
        
        if (!this.rules.length) errors.push('비밀번호는 8자 이상이어야 합니다');
        if (!this.rules.uppercase) errors.push('대문자를 포함해야 합니다');
        if (!this.rules.lowercase) errors.push('소문자를 포함해야 합니다');
        if (!this.rules.number) errors.push('숫자를 포함해야 합니다');
        if (!this.rules.special) errors.push('특수문자를 포함해야 합니다');
        if (!this.rules.match) errors.push('비밀번호 확인이 일치하지 않습니다');
        
        return errors;
    }
}

// 전역 인스턴스 생성
const passwordValidator = new PasswordValidator();

// 전역 함수로 내보내기
window.passwordValidator = passwordValidator;

console.log('✅ Password validation system initialized');
