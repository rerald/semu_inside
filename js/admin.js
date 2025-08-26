// 관리자 패널 관리

class AdminManager {
    constructor() {
        this.currentSection = null;
        this.categories = [];
        this.questions = [];
        this.exams = [];
        this.departments = [];
    }

    // 관리자 패널 초기화
    async init() {
        if (!window.authManager.isAdmin()) {
            Utils.showAlert('관리자 권한이 필요합니다.', 'error');
            return;
        }

        await this.loadBaseData();
        this.setupAdminNavigation();
    }

    // 기본 데이터 로드
    async loadBaseData() {
        try {
            // 카테고리 로드
            const { data: categories, error: catError } = await window.supabase
                .from('categories')
                .select('*')
                .order('name');

            if (catError) throw catError;
            this.categories = categories || [];

            // 부서 로드
            const { data: departments, error: deptError } = await window.supabase
                .from('departments')
                .select('*')
                .order('name');

            if (deptError) throw deptError;
            this.departments = departments || [];

        } catch (error) {
            console.error('Load base data error:', error);
            Utils.showAlert('기본 데이터 로드에 실패했습니다.', 'error');
        }
    }

    // 관리자 네비게이션 설정
    setupAdminNavigation() {
        const adminMenuButtons = document.querySelectorAll('.admin-menu-btn');
        
        adminMenuButtons.forEach(button => {
            button.addEventListener('click', () => {
                const section = button.getAttribute('data-admin-section');
                this.showAdminSection(section);
            });
        });
    }

    // 관리자 섹션 표시
    async showAdminSection(section) {
        this.currentSection = section;
        const contentContainer = document.getElementById('admin-content');
        
        if (!contentContainer) return;

        try {
            Utils.showLoading();

            switch (section) {
                case 'questions':
                    await this.showQuestionManagement();
                    break;
                case 'exams':
                    await this.showExamManagement();
                    break;
                case 'grading':
                    await this.showGradingManagement();
                    break;
                case 'stats':
                    await this.showStatistics();
                    break;
                default:
                    contentContainer.innerHTML = '<p>섹션을 선택해주세요.</p>';
            }

        } catch (error) {
            console.error('Show admin section error:', error);
            Utils.showAlert('섹션을 로드할 수 없습니다.', 'error');
        } finally {
            Utils.hideLoading();
        }
    }

    // 문제 관리 화면
    async showQuestionManagement() {
        await this.loadQuestions();
        
        const contentContainer = document.getElementById('admin-content');
        contentContainer.innerHTML = `
            <div class="admin-section-header">
                <h4>문제 관리</h4>
                <button class="btn btn-primary" onclick="adminManager.showCreateQuestionModal()">
                    <i class="fas fa-plus"></i> 새 문제 등록
                </button>
            </div>
            
            <div class="question-filters">
                <select id="category-filter" onchange="adminManager.filterQuestions()">
                    <option value="">전체 카테고리</option>
                    ${this.categories.map(cat => 
                        `<option value="${cat.id}">${cat.name}</option>`
                    ).join('')}
                </select>
                
                <select id="type-filter" onchange="adminManager.filterQuestions()">
                    <option value="">전체 유형</option>
                    <option value="multiple_choice">객관식</option>
                    <option value="subjective">주관식</option>
                    <option value="group">그룹형</option>
                </select>
                
                <input type="text" id="search-input" placeholder="문제 내용 검색..." 
                       oninput="adminManager.searchQuestions(this.value)">
            </div>
            
            <div id="questions-list" class="questions-container">
                ${this.renderQuestionsList()}
            </div>
        `;
    }

    // 문제 목록 로드
    async loadQuestions() {
        try {
            const { data: questions, error } = await window.supabase
                .from('questions')
                .select(`
                    *,
                    categories (name),
                    question_groups (title),
                    question_options (*)
                `)
                .order('created_at', { ascending: false });

            if (error) throw error;
            this.questions = questions || [];

        } catch (error) {
            console.error('Load questions error:', error);
            Utils.showAlert('문제 목록을 불러올 수 없습니다.', 'error');
        }
    }

    // 문제 목록 렌더링
    renderQuestionsList() {
        if (this.questions.length === 0) {
            return '<p class="text-center">등록된 문제가 없습니다.</p>';
        }

        return `
            <div class="questions-grid">
                ${this.questions.map(question => `
                    <div class="question-card">
                        <div class="question-card-header">
                            <span class="question-type ${question.type}">${this.getQuestionTypeText(question.type)}</span>
                            <span class="question-difficulty">난이도 ${question.difficulty}</span>
                        </div>
                        
                        <div class="question-content-preview">
                            ${Utils.escapeHtml(question.content.substring(0, 100))}
                            ${question.content.length > 100 ? '...' : ''}
                        </div>
                        
                        <div class="question-meta">
                            <span class="category">${question.categories?.name || '미분류'}</span>
                            ${question.tags ? question.tags.map(tag => `<span class="tag">${tag}</span>`).join('') : ''}
                        </div>
                        
                        <div class="question-actions">
                            <button class="btn btn-sm btn-outline" onclick="adminManager.editQuestion('${question.id}')">
                                <i class="fas fa-edit"></i> 수정
                            </button>
                            <button class="btn btn-sm btn-danger" onclick="adminManager.deleteQuestion('${question.id}')">
                                <i class="fas fa-trash"></i> 삭제
                            </button>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    // 문제 유형 텍스트
    getQuestionTypeText(type) {
        const typeMap = {
            'multiple_choice': '객관식',
            'subjective': '주관식',
            'group': '그룹형'
        };
        return typeMap[type] || type;
    }

    // 문제 생성 모달 표시
    showCreateQuestionModal() {
        const modalHtml = `
            <div class="modal-overlay" id="question-modal">
                <div class="modal-content" style="max-width: 800px;">
                    <div class="modal-header">
                        <h3>새 문제 등록</h3>
                        <button class="modal-close" onclick="document.getElementById('question-modal').remove()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div class="modal-body">
                        <form id="question-form" onsubmit="adminManager.saveQuestion(event)">
                            <div class="form-group">
                                <label for="question-type">문제 유형</label>
                                <select id="question-type" name="type" required onchange="adminManager.toggleQuestionOptions()">
                                    <option value="">선택하세요</option>
                                    <option value="multiple_choice">객관식</option>
                                    <option value="subjective">주관식</option>
                                    <option value="group">그룹형</option>
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="question-category">카테고리</label>
                                <select id="question-category" name="category_id">
                                    <option value="">선택하세요</option>
                                    ${this.categories.map(cat => 
                                        `<option value="${cat.id}">${cat.name}</option>`
                                    ).join('')}
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="question-difficulty">난이도</label>
                                <select id="question-difficulty" name="difficulty">
                                    <option value="1">1 (쉬움)</option>
                                    <option value="2">2</option>
                                    <option value="3" selected>3 (보통)</option>
                                    <option value="4">4</option>
                                    <option value="5">5 (어려움)</option>
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="question-content">문제 내용</label>
                                <textarea id="question-content" name="content" rows="5" required></textarea>
                            </div>
                            
                            <div class="form-group">
                                <label for="question-explanation">해설 (선택사항)</label>
                                <textarea id="question-explanation" name="explanation" rows="3"></textarea>
                            </div>
                            
                            <div class="form-group">
                                <label for="question-tags">태그 (쉼표로 구분)</label>
                                <input type="text" id="question-tags" name="tags" placeholder="예: 부가세, 신고, 과세표준">
                            </div>
                            
                            <div id="options-container" class="hidden">
                                <h4>선택지</h4>
                                <div id="options-list">
                                    <div class="option-item">
                                        <input type="text" placeholder="선택지 1" class="option-text">
                                        <label><input type="radio" name="correct-option" value="0"> 정답</label>
                                    </div>
                                    <div class="option-item">
                                        <input type="text" placeholder="선택지 2" class="option-text">
                                        <label><input type="radio" name="correct-option" value="1"> 정답</label>
                                    </div>
                                    <div class="option-item">
                                        <input type="text" placeholder="선택지 3" class="option-text">
                                        <label><input type="radio" name="correct-option" value="2"> 정답</label>
                                    </div>
                                    <div class="option-item">
                                        <input type="text" placeholder="선택지 4" class="option-text">
                                        <label><input type="radio" name="correct-option" value="3"> 정답</label>
                                    </div>
                                </div>
                                <button type="button" onclick="adminManager.addOption()" class="btn btn-outline">
                                    <i class="fas fa-plus"></i> 선택지 추가
                                </button>
                            </div>
                            
                            <div class="modal-actions">
                                <button type="button" onclick="document.getElementById('question-modal').remove()" 
                                        class="btn btn-outline">취소</button>
                                <button type="submit" class="btn btn-primary">저장</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHtml);
    }

    // 문제 옵션 토글
    toggleQuestionOptions() {
        const type = document.getElementById('question-type').value;
        const optionsContainer = document.getElementById('options-container');
        
        if (type === 'multiple_choice') {
            optionsContainer.classList.remove('hidden');
        } else {
            optionsContainer.classList.add('hidden');
        }
    }

    // 선택지 추가
    addOption() {
        const optionsList = document.getElementById('options-list');
        const optionCount = optionsList.children.length;
        
        const optionHtml = `
            <div class="option-item">
                <input type="text" placeholder="선택지 ${optionCount + 1}" class="option-text">
                <label><input type="radio" name="correct-option" value="${optionCount}"> 정답</label>
                <button type="button" onclick="this.parentNode.remove()" class="btn btn-sm btn-danger">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;
        
        optionsList.insertAdjacentHTML('beforeend', optionHtml);
    }

    // 문제 저장
    async saveQuestion(event) {
        event.preventDefault();
        
        try {
            Utils.showLoading();
            
            const formData = new FormData(event.target);
            const questionData = {
                type: formData.get('type'),
                content: formData.get('content'),
                explanation: formData.get('explanation'),
                difficulty: parseInt(formData.get('difficulty')),
                category_id: formData.get('category_id') || null,
                tags: formData.get('tags') ? formData.get('tags').split(',').map(tag => tag.trim()) : null,
                created_by: window.currentUser.id
            };

            // 문제 저장
            const { data: question, error: questionError } = await window.supabase
                .from('questions')
                .insert([questionData])
                .select()
                .single();

            if (questionError) throw questionError;

            // 객관식인 경우 선택지 저장
            if (questionData.type === 'multiple_choice') {
                const optionItems = document.querySelectorAll('.option-item');
                const correctOptionIndex = parseInt(document.querySelector('input[name="correct-option"]:checked')?.value);
                const options = [];

                optionItems.forEach((item, index) => {
                    const text = item.querySelector('.option-text').value.trim();
                    if (text) {
                        options.push({
                            question_id: question.id,
                            content: text,
                            is_correct: index === correctOptionIndex,
                            order_index: index
                        });
                    }
                });

                if (options.length > 0) {
                    const { error: optionsError } = await window.supabase
                        .from('question_options')
                        .insert(options);

                    if (optionsError) throw optionsError;
                }
            }

            Utils.showAlert('문제가 등록되었습니다.', 'success');
            document.getElementById('question-modal').remove();
            await this.showQuestionManagement(); // 목록 새로고침

        } catch (error) {
            console.error('Save question error:', error);
            Utils.showAlert('문제 등록에 실패했습니다.', 'error');
        } finally {
            Utils.hideLoading();
        }
    }

    // 시험 관리 화면
    async showExamManagement() {
        await this.loadExams();
        
        const contentContainer = document.getElementById('admin-content');
        contentContainer.innerHTML = `
            <div class="admin-section-header">
                <h4>시험지 관리</h4>
                <button class="btn btn-primary" onclick="adminManager.showCreateExamModal()">
                    <i class="fas fa-plus"></i> 새 시험지 생성
                </button>
            </div>
            
            <div id="exams-list" class="exams-admin-container">
                ${this.renderExamsList()}
            </div>
        `;
    }

    // 시험 목록 로드
    async loadExams() {
        try {
            const { data: exams, error } = await window.supabase
                .from('exams')
                .select(`
                    *,
                    exam_questions (count),
                    exam_sessions (count)
                `)
                .order('created_at', { ascending: false });

            if (error) throw error;
            this.exams = exams || [];

        } catch (error) {
            console.error('Load exams error:', error);
            Utils.showAlert('시험 목록을 불러올 수 없습니다.', 'error');
        }
    }

    // 시험 목록 렌더링
    renderExamsList() {
        if (this.exams.length === 0) {
            return '<p class="text-center">등록된 시험이 없습니다.</p>';
        }

        return `
            <div class="exams-admin-grid">
                ${this.exams.map(exam => `
                    <div class="exam-admin-card">
                        <div class="exam-admin-header">
                            <h5>${Utils.escapeHtml(exam.title)}</h5>
                            <span class="exam-status ${exam.status}">${this.getExamStatusText(exam.status)}</span>
                        </div>
                        
                        <div class="exam-admin-meta">
                            <span><i class="fas fa-clock"></i> ${exam.duration}분</span>
                            <span><i class="fas fa-question-circle"></i> ${exam.exam_questions?.length || 0}문항</span>
                            <span><i class="fas fa-users"></i> ${exam.exam_sessions?.length || 0}명 응시</span>
                        </div>
                        
                        <div class="exam-admin-actions">
                            <button class="btn btn-sm btn-outline" onclick="adminManager.editExam('${exam.id}')">
                                <i class="fas fa-edit"></i> 수정
                            </button>
                            <button class="btn btn-sm btn-primary" onclick="adminManager.manageExamQuestions('${exam.id}')">
                                <i class="fas fa-list"></i> 문항 관리
                            </button>
                            <button class="btn btn-sm btn-success" onclick="adminManager.manageExamPermissions('${exam.id}')">
                                <i class="fas fa-users"></i> 권한 관리
                            </button>
                            ${exam.status === 'draft' ? 
                                `<button class="btn btn-sm btn-warning" onclick="adminManager.publishExam('${exam.id}')">
                                    <i class="fas fa-paper-plane"></i> 배포
                                </button>` : ''
                            }
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    // 시험 상태 텍스트
    getExamStatusText(status) {
        const statusMap = {
            'draft': '초안',
            'published': '배포됨',
            'closed': '종료됨'
        };
        return statusMap[status] || status;
    }

    // 채점 관리 화면
    async showGradingManagement() {
        const contentContainer = document.getElementById('admin-content');
        contentContainer.innerHTML = `
            <div class="admin-section-header">
                <h4>채점 관리</h4>
                <p>주관식 문항의 수동 채점을 진행합니다.</p>
            </div>
            
            <div id="grading-list" class="grading-container">
                <div class="text-center">
                    <i class="fas fa-spinner fa-spin"></i> 채점 대기 목록을 불러오는 중...
                </div>
            </div>
        `;

        await this.loadPendingGrading();
    }

    // 채점 대기 목록 로드
    async loadPendingGrading() {
        try {
            const { data: pendingAnswers, error } = await window.supabase
                .from('exam_answers')
                .select(`
                    *,
                    exam_sessions (
                        id,
                        exams (title),
                        profiles (name)
                    ),
                    questions (content, type)
                `)
                .eq('questions.type', 'subjective')
                .is('is_correct', null)
                .order('created_at');

            if (error) throw error;

            const container = document.getElementById('grading-list');
            
            if (!pendingAnswers || pendingAnswers.length === 0) {
                container.innerHTML = '<p class="text-center">채점할 주관식 답안이 없습니다.</p>';
                return;
            }

            container.innerHTML = pendingAnswers.map(answer => `
                <div class="grading-item">
                    <div class="grading-header">
                        <h5>${Utils.escapeHtml(answer.exam_sessions.exams.title)}</h5>
                        <span>응시자: ${Utils.escapeHtml(answer.exam_sessions.profiles.name)}</span>
                    </div>
                    
                    <div class="question-content">
                        <strong>문제:</strong> ${Utils.escapeHtml(answer.questions.content)}
                    </div>
                    
                    <div class="answer-content">
                        <strong>답안:</strong> ${Utils.escapeHtml(answer.answer || '답안 없음')}
                    </div>
                    
                    <div class="grading-actions">
                        <input type="number" min="0" max="10" placeholder="점수" class="score-input" id="score-${answer.id}">
                        <button class="btn btn-success" onclick="adminManager.gradeAnswer('${answer.id}', true)">
                            <i class="fas fa-check"></i> 정답
                        </button>
                        <button class="btn btn-danger" onclick="adminManager.gradeAnswer('${answer.id}', false)">
                            <i class="fas fa-times"></i> 오답
                        </button>
                    </div>
                </div>
            `).join('');

        } catch (error) {
            console.error('Load pending grading error:', error);
            Utils.showAlert('채점 목록을 불러올 수 없습니다.', 'error');
        }
    }

    // 답안 채점
    async gradeAnswer(answerId, isCorrect) {
        try {
            const scoreInput = document.getElementById(`score-${answerId}`);
            const points = parseInt(scoreInput.value) || (isCorrect ? 1 : 0);

            const { error } = await window.supabase
                .from('exam_answers')
                .update({
                    is_correct: isCorrect,
                    points: points,
                    graded_by: window.currentUser.id,
                    graded_at: new Date().toISOString()
                })
                .eq('id', answerId);

            if (error) throw error;

            Utils.showAlert('채점이 완료되었습니다.', 'success');
            await this.loadPendingGrading(); // 목록 새로고침

        } catch (error) {
            console.error('Grade answer error:', error);
            Utils.showAlert('채점에 실패했습니다.', 'error');
        }
    }

    // 통계 화면
    async showStatistics() {
        const contentContainer = document.getElementById('admin-content');
        contentContainer.innerHTML = `
            <div class="admin-section-header">
                <h4>통계 분석</h4>
            </div>
            
            <div id="statistics-content" class="statistics-container">
                <div class="text-center">
                    <i class="fas fa-spinner fa-spin"></i> 통계를 생성하는 중...
                </div>
            </div>
        `;

        await this.loadStatistics();
    }

    // 통계 데이터 로드
    async loadStatistics() {
        try {
            // 시험 통계
            const { data: examStats, error: examError } = await window.supabase
                .from('exam_statistics')
                .select('*');

            if (examError) throw examError;

            // 문제 통계
            const { data: questionStats, error: questionError } = await window.supabase
                .from('question_statistics')
                .select('*')
                .order('correct_rate', { ascending: false });

            if (questionError) throw questionError;

            const container = document.getElementById('statistics-content');
            container.innerHTML = `
                <div class="stats-section">
                    <h5>시험별 통계</h5>
                    <div class="stats-table">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>시험명</th>
                                    <th>응시자 수</th>
                                    <th>평균 점수</th>
                                    <th>합격률</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${examStats.map(stat => `
                                    <tr>
                                        <td>${Utils.escapeHtml(stat.exam_title)}</td>
                                        <td>${stat.total_participants}</td>
                                        <td>${stat.average_score ? Math.round(stat.average_score) : 0}점</td>
                                        <td>${stat.completed_count > 0 ? Math.round((stat.passed_count / stat.completed_count) * 100) : 0}%</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <div class="stats-section">
                    <h5>문제별 정답률</h5>
                    <div class="stats-table">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>문제</th>
                                    <th>카테고리</th>
                                    <th>유형</th>
                                    <th>정답률</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${questionStats.slice(0, 20).map(stat => `
                                    <tr>
                                        <td>${Utils.escapeHtml(stat.question_content.substring(0, 50))}...</td>
                                        <td>${Utils.escapeHtml(stat.category_name || '미분류')}</td>
                                        <td>${this.getQuestionTypeText(stat.question_type)}</td>
                                        <td>${stat.correct_rate}%</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            `;

        } catch (error) {
            console.error('Load statistics error:', error);
            Utils.showAlert('통계를 불러올 수 없습니다.', 'error');
        }
    }
}

// AdminManager 인스턴스 생성
const adminManager = new AdminManager();

// 전역으로 노출
window.adminManager = adminManager;
