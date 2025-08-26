// 시험 응시 관리

class ExamManager {
    constructor() {
        this.currentExam = null;
        this.currentSession = null;
        this.questions = [];
        this.answers = {};
        this.currentQuestionIndex = 0;
        this.timer = null;
        this.timeRemaining = 0;
        this.autoSaveInterval = null;
        this.isSubmitted = false;
    }

    // 시험 시작
    async startExam(examId, sessionId) {
        try {
            Utils.showLoading();

            // 시험 정보 조회
            const { data: exam, error: examError } = await window.supabase
                .from('exams')
                .select('*')
                .eq('id', examId)
                .single();

            if (examError) {
                throw examError;
            }

            // 세션 정보 조회
            const { data: session, error: sessionError } = await window.supabase
                .from('exam_sessions')
                .select('*')
                .eq('id', sessionId)
                .single();

            if (sessionError) {
                throw sessionError;
            }

            // 시험 문제 조회
            const { data: examQuestions, error: questionsError } = await window.supabase
                .from('exam_questions')
                .select(`
                    *,
                    questions (
                        *,
                        question_options (*),
                        question_groups (*)
                    )
                `)
                .eq('exam_id', examId)
                .order('order_index');

            if (questionsError) {
                throw questionsError;
            }

            // 기존 답안 조회 (재시작인 경우)
            const { data: existingAnswers, error: answersError } = await window.supabase
                .from('exam_answers')
                .select('*')
                .eq('session_id', sessionId);

            if (answersError && answersError.code !== 'PGRST116') {
                throw answersError;
            }

            // 데이터 설정
            this.currentExam = exam;
            this.currentSession = session;
            this.questions = examQuestions;
            this.answers = {};
            this.currentQuestionIndex = 0;

            // 기존 답안 복원
            if (existingAnswers) {
                existingAnswers.forEach(answer => {
                    this.answers[answer.question_id] = answer.answer;
                });
            }

            // 시간 계산
            const sessionStartTime = new Date(session.start_time);
            const now = new Date();
            const elapsedMinutes = Math.floor((now - sessionStartTime) / (1000 * 60));
            this.timeRemaining = Math.max(0, (exam.duration * 60) - (elapsedMinutes * 60));

            // 시험 화면 표시
            this.showExamPage();
            this.initializeExam();

        } catch (error) {
            console.error('Start exam error:', error);
            Utils.showAlert('시험을 시작할 수 없습니다.', 'error');
        } finally {
            Utils.hideLoading();
        }
    }

    // 시험 화면 표시
    showExamPage() {
        // 모든 페이지 숨기기
        document.querySelectorAll('.page').forEach(page => {
            page.classList.add('hidden');
        });

        // 시험 페이지 표시
        document.getElementById('exam-taking').classList.remove('hidden');
    }

    // 시험 초기화
    initializeExam() {
        // 시험 정보 표시
        document.getElementById('exam-title').textContent = this.currentExam.title;
        document.getElementById('exam-description').textContent = this.currentExam.description || '';

        // 문제 네비게이션 생성
        this.createQuestionNavigation();

        // 첫 번째 문제 표시
        this.displayQuestion(0);

        // 타이머 시작
        this.startTimer();

        // 자동저장 시작
        this.startAutoSave();

        // 이벤트 리스너 설정
        this.setupEventListeners();

        // 페이지 이탈 경고 설정
        this.setupBeforeUnload();
    }

    // 문제 네비게이션 생성
    createQuestionNavigation() {
        const container = document.getElementById('question-nav');
        container.innerHTML = '';

        this.questions.forEach((q, index) => {
            const button = document.createElement('button');
            button.className = 'question-nav-btn';
            button.textContent = index + 1;
            button.onclick = () => this.displayQuestion(index);
            
            // 답안 상태 표시
            if (this.answers[q.questions.id]) {
                button.classList.add('answered');
            }
            
            container.appendChild(button);
        });
    }

    // 문제 표시
    displayQuestion(index) {
        if (index < 0 || index >= this.questions.length) return;

        this.currentQuestionIndex = index;
        const examQuestion = this.questions[index];
        const question = examQuestion.questions;

        // 네비게이션 버튼 상태 업데이트
        document.querySelectorAll('.question-nav-btn').forEach((btn, i) => {
            btn.classList.toggle('current', i === index);
        });

        // 문제 표시
        const container = document.getElementById('current-question');
        container.innerHTML = this.renderQuestion(examQuestion, question);

        // 기존 답안 복원
        this.restoreAnswer(question.id);

        // 답안 변경 이벤트 설정
        this.setupAnswerEvents(question);

        // 이전/다음 버튼 상태 업데이트
        document.getElementById('prev-question').disabled = index === 0;
        document.getElementById('next-question').disabled = index === this.questions.length - 1;
    }

    // 문제 렌더링
    renderQuestion(examQuestion, question) {
        let html = `
            <div class="question-header">
                <div class="question-number">문제 ${this.currentQuestionIndex + 1}</div>
                <div class="question-points">${examQuestion.points}점</div>
            </div>
        `;

        // 그룹 문제인 경우 공통 지문 표시
        if (question.question_groups) {
            html += `
                <div class="question-group-content">
                    <h4>${Utils.escapeHtml(question.question_groups.title || '')}</h4>
                    <div>${Utils.escapeHtml(question.question_groups.content)}</div>
                </div>
            `;
        }

        html += `<div class="question-content">${Utils.escapeHtml(question.content)}</div>`;

        // 문제 유형별 답안 입력 영역
        if (question.type === 'multiple_choice') {
            html += this.renderMultipleChoice(question);
        } else if (question.type === 'subjective') {
            html += this.renderSubjective(question);
        }

        return html;
    }

    // 객관식 문제 렌더링
    renderMultipleChoice(question) {
        const options = question.question_options || [];
        
        return `
            <div class="answer-options">
                ${options.map((option, index) => `
                    <label class="option" for="option-${option.id}">
                        <input type="radio" id="option-${option.id}" name="question-${question.id}" value="${option.id}">
                        <span class="option-text">${Utils.escapeHtml(option.content)}</span>
                    </label>
                `).join('')}
            </div>
        `;
    }

    // 주관식 문제 렌더링
    renderSubjective(question) {
        return `
            <div class="subjective-container">
                <textarea 
                    class="subjective-answer" 
                    id="subjective-${question.id}"
                    placeholder="답안을 입력하세요..."
                    data-question-id="${question.id}"
                ></textarea>
            </div>
        `;
    }

    // 기존 답안 복원
    restoreAnswer(questionId) {
        const savedAnswer = this.answers[questionId];
        if (!savedAnswer) return;

        // 객관식 답안 복원
        const radioInput = document.querySelector(`input[name="question-${questionId}"][value="${savedAnswer}"]`);
        if (radioInput) {
            radioInput.checked = true;
            radioInput.closest('.option').classList.add('selected');
        }

        // 주관식 답안 복원
        const textareaInput = document.getElementById(`subjective-${questionId}`);
        if (textareaInput) {
            textareaInput.value = savedAnswer;
        }
    }

    // 답안 이벤트 설정
    setupAnswerEvents(question) {
        if (question.type === 'multiple_choice') {
            // 객관식 이벤트
            document.querySelectorAll(`input[name="question-${question.id}"]`).forEach(radio => {
                radio.addEventListener('change', (e) => {
                    // 선택 상태 시각적 업데이트
                    document.querySelectorAll('.option').forEach(opt => opt.classList.remove('selected'));
                    e.target.closest('.option').classList.add('selected');
                    
                    // 답안 저장
                    this.saveAnswer(question.id, e.target.value);
                });
            });
        } else if (question.type === 'subjective') {
            // 주관식 이벤트 (디바운스 적용)
            const textarea = document.getElementById(`subjective-${question.id}`);
            if (textarea) {
                const debouncedSave = Utils.debounce((value) => {
                    this.saveAnswer(question.id, value);
                }, 1000);

                textarea.addEventListener('input', (e) => {
                    debouncedSave(e.target.value);
                });
            }
        }
    }

    // 답안 저장 (메모리)
    saveAnswer(questionId, answer) {
        this.answers[questionId] = answer;
        
        // 네비게이션 버튼 상태 업데이트
        const questionIndex = this.questions.findIndex(q => q.questions.id === questionId);
        if (questionIndex !== -1) {
            const navButton = document.querySelectorAll('.question-nav-btn')[questionIndex];
            if (navButton) {
                navButton.classList.add('answered');
            }
        }

        // 자동저장 상태 표시
        const autoSaveBtn = document.getElementById('auto-save-btn');
        if (autoSaveBtn) {
            autoSaveBtn.innerHTML = '<i class="fas fa-save"></i> 저장 중...';
            autoSaveBtn.disabled = true;
        }
    }

    // 서버에 답안 저장
    async saveAnswersToServer() {
        try {
            const answerArray = Object.entries(this.answers).map(([questionId, answer]) => ({
                session_id: this.currentSession.id,
                question_id: questionId,
                answer: answer,
                auto_saved_at: new Date().toISOString()
            }));

            // upsert를 사용하여 기존 답안 업데이트 또는 새 답안 삽입
            const { error } = await window.supabase
                .from('exam_answers')
                .upsert(answerArray, {
                    onConflict: 'session_id,question_id'
                });

            if (error) {
                throw error;
            }

            // 자동저장 완료 표시
            const autoSaveBtn = document.getElementById('auto-save-btn');
            if (autoSaveBtn) {
                autoSaveBtn.innerHTML = '<i class="fas fa-check"></i> 자동저장됨';
                autoSaveBtn.disabled = true;
                
                setTimeout(() => {
                    autoSaveBtn.innerHTML = '<i class="fas fa-save"></i> 자동저장됨';
                }, 2000);
            }

        } catch (error) {
            console.error('Auto save error:', error);
            
            // 자동저장 실패 표시
            const autoSaveBtn = document.getElementById('auto-save-btn');
            if (autoSaveBtn) {
                autoSaveBtn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> 저장 실패';
                autoSaveBtn.classList.add('btn-warning');
                
                setTimeout(() => {
                    autoSaveBtn.innerHTML = '<i class="fas fa-save"></i> 자동저장됨';
                    autoSaveBtn.classList.remove('btn-warning');
                }, 3000);
            }
        }
    }

    // 타이머 시작
    startTimer() {
        this.updateTimerDisplay();
        
        this.timer = setInterval(() => {
            this.timeRemaining--;
            this.updateTimerDisplay();
            
            // 경고 시간 체크
            if (this.timeRemaining === EXAM_CONFIG.WARNING_TIME) {
                Utils.showAlert(`시험 종료 ${Math.floor(EXAM_CONFIG.WARNING_TIME / 60)}분 전입니다!`, 'warning');
            }
            
            // 시간 종료
            if (this.timeRemaining <= 0) {
                this.timeUp();
            }
        }, 1000);
    }

    // 타이머 표시 업데이트
    updateTimerDisplay() {
        const display = document.getElementById('timer-display');
        if (display) {
            display.textContent = Utils.formatTime(this.timeRemaining);
            
            // 시간이 부족하면 빨간색으로 표시
            if (this.timeRemaining <= EXAM_CONFIG.WARNING_TIME) {
                display.style.color = 'var(--danger-color)';
            }
        }
    }

    // 자동저장 시작
    startAutoSave() {
        this.autoSaveInterval = setInterval(() => {
            this.saveAnswersToServer();
        }, EXAM_CONFIG.AUTO_SAVE_INTERVAL);
    }

    // 이벤트 리스너 설정
    setupEventListeners() {
        // 이전 문제
        document.getElementById('prev-question').onclick = () => {
            this.displayQuestion(this.currentQuestionIndex - 1);
        };

        // 다음 문제
        document.getElementById('next-question').onclick = () => {
            this.displayQuestion(this.currentQuestionIndex + 1);
        };

        // 시험 제출
        document.getElementById('submit-exam-btn').onclick = () => {
            this.confirmSubmit();
        };
    }

    // 페이지 이탈 경고 설정
    setupBeforeUnload() {
        window.addEventListener('beforeunload', (e) => {
            if (!this.isSubmitted) {
                const message = '시험이 진행 중입니다. 페이지를 나가면 답안이 손실될 수 있습니다.';
                e.preventDefault();
                e.returnValue = message;
                return message;
            }
        });
    }

    // 시간 종료 처리
    async timeUp() {
        this.stopTimer();
        this.stopAutoSave();
        
        Utils.showAlert('시험 시간이 종료되었습니다. 자동으로 제출됩니다.', 'warning');
        
        // 자동 제출
        await this.submitExam(true);
    }

    // 제출 확인
    confirmSubmit() {
        const unansweredCount = this.questions.length - Object.keys(this.answers).length;
        
        let message = '시험을 제출하시겠습니까?';
        if (unansweredCount > 0) {
            message += `\n\n답하지 않은 문제가 ${unansweredCount}개 있습니다.`;
        }
        
        if (confirm(message)) {
            this.submitExam(false);
        }
    }

    // 시험 제출
    async submitExam(isAutoSubmit = false) {
        try {
            Utils.showLoading();
            
            // 마지막 자동저장
            await this.saveAnswersToServer();
            
            // 세션 상태 업데이트
            const submitTime = new Date().toISOString();
            const durationMinutes = Math.ceil((new Date(submitTime) - new Date(this.currentSession.start_time)) / (1000 * 60));
            
            const { error: sessionError } = await window.supabase
                .from('exam_sessions')
                .update({
                    submit_time: submitTime,
                    duration_minutes: durationMinutes,
                    status: 'submitted'
                })
                .eq('id', this.currentSession.id);

            if (sessionError) {
                throw sessionError;
            }

            // 객관식 자동 채점
            await this.autoGradeMultipleChoice();

            this.isSubmitted = true;
            this.stopTimer();
            this.stopAutoSave();

            // 제출 완료 메시지
            Utils.showAlert(
                isAutoSubmit ? 
                '시간 종료로 시험이 자동 제출되었습니다.' : 
                '시험이 성공적으로 제출되었습니다!', 
                'success'
            );

            // 결과 페이지로 이동
            setTimeout(() => {
                this.returnToDashboard();
            }, 2000);

        } catch (error) {
            console.error('Submit exam error:', error);
            Utils.showAlert('시험 제출 중 오류가 발생했습니다.', 'error');
        } finally {
            Utils.hideLoading();
        }
    }

    // 객관식 자동 채점
    async autoGradeMultipleChoice() {
        try {
            const multipleChoiceAnswers = [];
            
            for (const examQuestion of this.questions) {
                const question = examQuestion.questions;
                const userAnswer = this.answers[question.id];
                
                if (question.type === 'multiple_choice' && userAnswer) {
                    const correctOption = question.question_options?.find(opt => opt.is_correct);
                    const isCorrect = correctOption && correctOption.id === userAnswer;
                    const points = isCorrect ? examQuestion.points : 0;
                    
                    multipleChoiceAnswers.push({
                        session_id: this.currentSession.id,
                        question_id: question.id,
                        is_correct: isCorrect,
                        points: points
                    });
                }
            }

            if (multipleChoiceAnswers.length > 0) {
                const { error } = await window.supabase
                    .from('exam_answers')
                    .upsert(multipleChoiceAnswers, {
                        onConflict: 'session_id,question_id'
                    });

                if (error) {
                    throw error;
                }
            }

            // 총점 계산 및 업데이트
            await this.calculateTotalScore();

        } catch (error) {
            console.error('Auto grading error:', error);
        }
    }

    // 총점 계산
    async calculateTotalScore() {
        try {
            // 현재 세션의 모든 답안 조회
            const { data: answers, error } = await window.supabase
                .from('exam_answers')
                .select('points')
                .eq('session_id', this.currentSession.id);

            if (error) {
                throw error;
            }

            const totalScore = answers.reduce((sum, answer) => sum + (answer.points || 0), 0);
            const totalPoints = this.questions.reduce((sum, q) => sum + q.points, 0);

            // 세션에 점수 업데이트
            const { error: updateError } = await window.supabase
                .from('exam_sessions')
                .update({
                    score: totalScore,
                    total_points: totalPoints,
                    status: 'graded' // 객관식만 있는 경우 자동으로 채점 완료
                })
                .eq('id', this.currentSession.id);

            if (updateError) {
                throw updateError;
            }

        } catch (error) {
            console.error('Calculate total score error:', error);
        }
    }

    // 타이머 중지
    stopTimer() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
    }

    // 자동저장 중지
    stopAutoSave() {
        if (this.autoSaveInterval) {
            clearInterval(this.autoSaveInterval);
            this.autoSaveInterval = null;
        }
    }

    // 대시보드로 돌아가기
    returnToDashboard() {
        // 페이지 이탈 경고 제거
        window.removeEventListener('beforeunload', this.beforeUnloadHandler);
        
        // 상태 초기화
        this.currentExam = null;
        this.currentSession = null;
        this.questions = [];
        this.answers = {};
        this.currentQuestionIndex = 0;
        this.isSubmitted = false;

        // 대시보드 표시
        if (window.authManager) {
            window.authManager.showDashboard();
        }

        // 결과 탭으로 이동
        setTimeout(() => {
            const resultsTab = document.querySelector('[data-tab="results"]');
            if (resultsTab) {
                resultsTab.click();
            }
        }, 500);
    }
}

// ExamManager 인스턴스 생성
const examManager = new ExamManager();

// 전역으로 노출
window.examManager = examManager;
