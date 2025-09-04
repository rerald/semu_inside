// 아바타 관리 시스템

class AvatarManager {
    constructor() {
        this.avatars = [];
        this.supabaseClient = null;
        this.currentEditingAvatar = null;
        console.log('🎨 아바타 관리 시스템 초기화 중...');
    }

    async init() {
        try {
            // Supabase 클라이언트 초기화
            await this.initSupabaseClient();
            
            // 사용자 인증 확인
            await this.checkAuth();
            
            // 아바타 목록 로드
            await this.loadAvatars();
            
            // 이벤트 리스너 설정
            this.setupEventListeners();
            
            console.log('✅ 아바타 관리 시스템 초기화 완료');
        } catch (error) {
            console.error('❌ 아바타 관리 시스템 초기화 실패:', error);
            this.showError('아바타 관리 시스템을 초기화하는데 실패했습니다.');
        }
    }

    async initSupabaseClient() {
        // 전역 SemuApp에서 Supabase 클라이언트 가져오기
        if (window.semuApp?.supabaseClient) {
            this.supabaseClient = window.semuApp.supabaseClient;
            console.log('✅ SemuApp에서 Supabase 클라이언트 가져옴');
            return;
        }

        // 직접 Supabase 클라이언트 생성
        if (typeof supabase !== 'undefined') {
            const supabaseUrl = 'https://skpvtqohyspfsmvwrgoc.supabase.co';
            const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrcHZ0cW9oeXNwZnNtdndyZ29jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQ2NDcyNzEsImV4cCI6MjA0MDIyMzI3MX0.VCVOGp8Et55b66O3hVhgxNPWvGEAk7N8X8TJyVTK8EA';
            
            this.supabaseClient = supabase.createClient(supabaseUrl, supabaseAnonKey);
            console.log('✅ 직접 Supabase 클라이언트 생성됨');
        } else {
            throw new Error('Supabase 라이브러리를 찾을 수 없습니다.');
        }
    }

    async checkAuth() {
        try {
            const { data: { user }, error } = await this.supabaseClient.auth.getUser();
            if (error) throw error;
            
            if (!user) {
                window.location.href = './admin-login.html';
                return;
            }

            // 사용자 권한 확인
            const { data: profile } = await this.supabaseClient
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single();

            if (!profile || !['admin', 'super_admin'].includes(profile.role)) {
                this.showError('관리자 권한이 필요합니다.');
                setTimeout(() => window.location.href = './dashboard.html', 2000);
                return;
            }

            console.log('✅ 관리자 인증 확인됨');
        } catch (error) {
            console.error('인증 확인 실패:', error);
            window.location.href = './admin-login.html';
        }
    }

    async loadAvatars() {
        try {
            console.log('🔄 아바타 목록 로딩 중...');
            
            const { data: avatars, error } = await this.supabaseClient
                .from('avatar_items')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) {
                if (error.code === 'PGRST205') {
                    // 테이블이 존재하지 않는 경우
                    this.showDatabaseSetupMessage();
                    return;
                }
                throw error;
            }

            this.avatars = avatars || [];
            console.log(`✅ 아바타 ${this.avatars.length}개 로드됨`);
            
            this.renderAvatars();
            this.updateSummary();
            
            // 로딩 상태 숨기기
            document.getElementById('avatars-loading').style.display = 'none';
            document.getElementById('avatars-content').style.display = 'block';
            
        } catch (error) {
            console.error('아바타 목록 로드 실패:', error);
            this.showError('아바타 목록을 불러오는데 실패했습니다: ' + error.message);
        }
    }

    showDatabaseSetupMessage() {
        const loadingElement = document.getElementById('avatars-loading');
        loadingElement.innerHTML = `
            <div style="text-align: center; padding: 40px; background: white; border-radius: 12px; margin: 20px;">
                <i class="fas fa-database" style="font-size: 3rem; color: #ffc107; margin-bottom: 20px;"></i>
                <h3 style="color: #856404; margin-bottom: 15px;">데이터베이스 설정이 필요합니다</h3>
                <p style="color: #6c757d; margin-bottom: 20px;">아바타 시스템을 사용하려면 먼저 데이터베이스 테이블을 생성해야 합니다.</p>
                <p style="color: #6c757d; font-size: 0.9rem;">
                    Supabase 대시보드의 SQL Editor에서 <code>database/new-avatar-system.sql</code> 파일을 실행해주세요.
                </p>
            </div>
        `;
    }

    renderAvatars(avatars = this.avatars) {
        const grid = document.getElementById('avatars-grid');
        
        if (!avatars || avatars.length === 0) {
            grid.innerHTML = `
                <div class="no-data">
                    <i class="fas fa-user-circle"></i>
                    <h4>아바타가 없습니다</h4>
                    <p>새로운 아바타를 추가해보세요.</p>
                </div>
            `;
            return;
        }

        // 재고 정보가 포함된 카드 렌더링
        grid.innerHTML = avatars.map(avatar => this.createAvatarCard(avatar)).join('');
        
        // 렌더링 완료 후 이미지 비율 적용
        setTimeout(() => {
            this.applyImageAspectRatios();
        }, 100);
    }

    createAvatarCard(avatar) {
        const stockBadge = this.getStockBadge(avatar);
        
        return `
            <div class="avatar-card" data-id="${avatar.id}">
                <div class="avatar-preview">
                    <div class="avatar-image" 
                         style="background-image: url('${avatar.image_url}')"
                         onload="avatarManager.setImageAspectRatio(this, '${avatar.image_url}')"></div>
                    ${stockBadge}
                </div>
                <div class="avatar-info">
                    <div class="avatar-name">${avatar.name}</div>
                    <div class="avatar-description">${avatar.description || '설명이 없습니다.'}</div>
                    <div class="avatar-meta">
                        <div class="avatar-price">${avatar.price.toLocaleString()} 포인트</div>
                        <div class="avatar-rarity rarity-${avatar.rarity}">${this.getRarityText(avatar.rarity)}</div>
                    </div>
                    <div class="avatar-actions">
                        <button class="btn btn-primary btn-sm" onclick="avatarManager.editAvatar('${avatar.id}')">
                            <i class="fas fa-edit"></i> 수정
                        </button>
                        <button class="btn btn-danger btn-sm" onclick="avatarManager.showDeleteModal('${avatar.id}')">
                            <i class="fas fa-trash"></i> 삭제
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    getStockBadge(avatar) {
        // 한정판이 아닌 경우 재고 표시 안 함
        if (!avatar.is_limited) {
            return '';
        }
        
        const remaining = avatar.remaining_stock || 0;
        const total = avatar.total_supply || 0;
        
        let badge = '';
        
        if (remaining === 0) {
            badge = '<span class="stock-badge stock-sold-out">💨 품절</span>';
        } else if (total === 1) {
            // 한정수량이 1장인 경우 특별 처리
            badge = `<span class="stock-badge stock-unique">⭐ ${remaining}/${total}</span>`;
        } else if (remaining <= total * 0.1) { // 10% 이하 - 매우 적음
            badge = `<span class="stock-badge stock-low">🔥 ${remaining}/${total}</span>`;
        } else if (remaining <= total * 0.3) { // 30% 이하 - 보통
            badge = `<span class="stock-badge stock-medium">⚡ ${remaining}/${total}</span>`;
        } else { // 30% 초과 - 충분함
            badge = `<span class="stock-badge stock-high">✅ ${remaining}/${total}</span>`;
        }
        
        return badge;
    }

    getRarityText(rarity) {
        const rarityMap = {
            'common': '일반',
            'uncommon': '고급',
            'rare': '희귀',
            'epic': '영웅',
            'legendary': '전설'
        };
        return rarityMap[rarity] || rarity;
    }

    updateSummary() {
        const totalAvatars = this.avatars.length;
        const legendaryCount = this.avatars.filter(a => a.rarity === 'legendary').length;
        
        // TODO: 실제 판매 수 계산
        const totalSales = 0;

        document.getElementById('total-avatars').textContent = totalAvatars;
        document.getElementById('legendary-avatars').textContent = legendaryCount;
        document.getElementById('total-sales').textContent = totalSales;
    }

    setupEventListeners() {
        // 검색
        document.getElementById('search-avatars').addEventListener('input', (e) => {
            this.filterAvatars();
        });

        // 필터링
        document.getElementById('filter-rarity').addEventListener('change', (e) => {
            this.filterAvatars();
        });

        // 정렬
        document.getElementById('sort-avatars').addEventListener('change', (e) => {
            this.sortAvatars();
        });

        // 이미지 파일 선택
        document.getElementById('avatar-image').addEventListener('change', (e) => {
            this.handleImagePreview(e);
        });
    }

    filterAvatars() {
        const searchTerm = document.getElementById('search-avatars').value.toLowerCase();
        const rarityFilter = document.getElementById('filter-rarity').value;

        let filteredAvatars = this.avatars.filter(avatar => {
            const matchesSearch = avatar.name.toLowerCase().includes(searchTerm) ||
                                 (avatar.description && avatar.description.toLowerCase().includes(searchTerm));
            const matchesRarity = !rarityFilter || avatar.rarity === rarityFilter;
            
            return matchesSearch && matchesRarity;
        });

        this.renderAvatars(filteredAvatars);
    }

    sortAvatars() {
        const sortBy = document.getElementById('sort-avatars').value;
        
        let sortedAvatars = [...this.avatars];
        
        switch (sortBy) {
            case 'name':
                sortedAvatars.sort((a, b) => a.name.localeCompare(b.name));
                break;
            case 'price':
                sortedAvatars.sort((a, b) => a.price - b.price);
                break;
            case 'rarity':
                const rarityOrder = { 'common': 1, 'uncommon': 2, 'rare': 3, 'epic': 4, 'legendary': 5 };
                sortedAvatars.sort((a, b) => rarityOrder[a.rarity] - rarityOrder[b.rarity]);
                break;
            default: // created_at
                sortedAvatars.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
                break;
        }

        this.renderAvatars(sortedAvatars);
    }

    showAddAvatarModal() {
        this.currentEditingAvatar = null;
        document.getElementById('avatar-modal-title').textContent = '새 아바타 추가';
        document.getElementById('avatar-form').reset();
        document.getElementById('image-preview').style.display = 'none';
        
        // 한정판 설정 초기화
        const isLimitedCheckbox = document.getElementById('is-limited');
        const limitedSettings = document.getElementById('limited-settings');
        
        isLimitedCheckbox.checked = false;
        limitedSettings.style.display = 'none';
        
        // 한정판 필드들 초기화
        document.getElementById('total-supply').value = '';
        document.getElementById('remaining-stock').value = '';
        document.getElementById('release-date').value = '';
        document.getElementById('sale-end-date').value = '';
        
        console.log('➕ 새 아바타 추가 모달 - 한정판 설정 초기화됨');
        
        document.getElementById('avatar-modal').style.display = 'block';
    }

    async editAvatar(avatarId) {
        try {
            const avatar = this.avatars.find(a => a.id === avatarId);
            if (!avatar) {
                this.showError('아바타를 찾을 수 없습니다.');
                return;
            }

            this.currentEditingAvatar = avatar;
            document.getElementById('avatar-modal-title').textContent = '아바타 수정';
            
            // 폼에 데이터 채우기
            document.getElementById('avatar-name').value = avatar.name;
            document.getElementById('avatar-description').value = avatar.description || '';
            document.getElementById('avatar-price').value = avatar.price;
            document.getElementById('avatar-rarity').value = avatar.rarity;
            
            // 한정판 설정 로드
            const isLimitedCheckbox = document.getElementById('is-limited');
            const limitedSettings = document.getElementById('limited-settings');
            
            console.log('🔄 수정 모드 - 아바타 데이터:', {
                name: avatar.name,
                is_limited: avatar.is_limited,
                total_supply: avatar.total_supply,
                remaining_stock: avatar.remaining_stock,
                release_date: avatar.release_date,
                sale_end_date: avatar.sale_end_date
            });
            
            if (avatar.is_limited) {
                isLimitedCheckbox.checked = true;
                limitedSettings.style.display = 'block';
                
                // 한정판 상세 정보 설정
                document.getElementById('total-supply').value = avatar.total_supply || '';
                document.getElementById('remaining-stock').value = avatar.remaining_stock || '';
                
                // 날짜 필드 설정 (ISO 문자열을 date input 형식으로 변환)
                if (avatar.release_date) {
                    const releaseDate = new Date(avatar.release_date);
                    document.getElementById('release-date').value = releaseDate.toISOString().split('T')[0];
                }
                
                if (avatar.sale_end_date) {
                    const saleEndDate = new Date(avatar.sale_end_date);
                    document.getElementById('sale-end-date').value = saleEndDate.toISOString().split('T')[0];
                }
            } else {
                isLimitedCheckbox.checked = false;
                limitedSettings.style.display = 'none';
                
                // 한정판이 아닌 경우 필드 초기화
                document.getElementById('total-supply').value = '';
                document.getElementById('remaining-stock').value = '';
                document.getElementById('release-date').value = '';
                document.getElementById('sale-end-date').value = '';
            }
            
            // 이미지 미리보기
            const preview = document.getElementById('image-preview');
            preview.src = avatar.image_url;
            preview.style.display = 'block';
            
            document.getElementById('avatar-modal').style.display = 'block';
        } catch (error) {
            console.error('아바타 수정 모달 열기 실패:', error);
            this.showError('아바타 수정 모달을 열 수 없습니다.');
        }
    }

    async saveAvatar() {
        try {
            const avatarData = {
                name: document.getElementById('avatar-name').value.trim(),
                description: document.getElementById('avatar-description').value.trim(),
                price: parseInt(document.getElementById('avatar-price').value) || 0,
                rarity: document.getElementById('avatar-rarity').value
            };

            // 기본 유효성 검사
            if (!avatarData.name) {
                this.showError('아바타 이름을 입력해주세요.');
                return;
            }

            // 한정판 설정 처리
            const isLimited = document.getElementById('is-limited').checked;
            console.log('🔍 한정판 설정 확인:', { isLimited });
            
            if (isLimited) {
                const totalSupply = parseInt(document.getElementById('total-supply').value);
                const remainingStock = document.getElementById('remaining-stock').value;
                const releaseDate = document.getElementById('release-date').value;
                const saleEndDate = document.getElementById('sale-end-date').value;

                console.log('🔍 한정판 입력값:', {
                    totalSupply,
                    remainingStock,
                    releaseDate,
                    saleEndDate
                });

                if (!totalSupply || totalSupply < 1) {
                    this.showError('한정판 설정 시 총 발행량을 입력해주세요.');
                    return;
                }

                avatarData.is_limited = true;
                avatarData.total_supply = totalSupply;
                avatarData.remaining_stock = remainingStock ? parseInt(remainingStock) : totalSupply;
                
                if (releaseDate) {
                    avatarData.release_date = new Date(releaseDate).toISOString();
                }
                
                if (saleEndDate) {
                    avatarData.sale_end_date = new Date(saleEndDate).toISOString();
                }
            } else {
                avatarData.is_limited = false;
                avatarData.total_supply = null;
                avatarData.remaining_stock = null;
                avatarData.release_date = null;
                avatarData.sale_end_date = null;
            }

            // 이미지 처리
            const imageInput = document.getElementById('avatar-image');
            if (imageInput.files && imageInput.files[0]) {
                avatarData.image_url = await this.uploadImage(imageInput.files[0]);
            } else if (!this.currentEditingAvatar) {
                this.showError('아바타 이미지를 선택해주세요.');
                return;
            }

            console.log('💾 최종 저장 데이터:', avatarData);

            let result;
            if (this.currentEditingAvatar) {
                // 수정
                console.log('🔄 아바타 수정 중...');
                result = await this.supabaseClient
                    .from('avatar_items')
                    .update(avatarData)
                    .eq('id', this.currentEditingAvatar.id);
            } else {
                // 추가
                console.log('➕ 새 아바타 추가 중...');
                result = await this.supabaseClient
                    .from('avatar_items')
                    .insert([avatarData]);
            }

            if (result.error) throw result.error;
            
            console.log('✅ 저장 완료:', result);

            this.hideAvatarModal();
            await this.loadAvatars();
            this.showSuccess(this.currentEditingAvatar ? '아바타가 수정되었습니다.' : '아바타가 추가되었습니다.');
            
        } catch (error) {
            console.error('아바타 저장 실패:', error);
            this.showError('아바타 저장에 실패했습니다.');
        }
    }

    async uploadImage(file) {
        try {
            // 파일을 Base64로 변환
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => resolve(reader.result);
                reader.onerror = reject;
                reader.readAsDataURL(file);
            });
        } catch (error) {
            console.error('이미지 업로드 실패:', error);
            throw new Error('이미지 업로드에 실패했습니다.');
        }
    }

    handleImagePreview(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const preview = document.getElementById('image-preview');
                preview.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        }
    }

    showDeleteModal(avatarId) {
        const avatar = this.avatars.find(a => a.id === avatarId);
        if (!avatar) {
            this.showError('아바타를 찾을 수 없습니다.');
            return;
        }

        document.getElementById('delete-avatar-info').innerHTML = `
            <div style="text-align: center; padding: 20px;">
                <img src="${avatar.image_url}" style="max-width: 100px; border-radius: 8px; margin-bottom: 15px;">
                <h4>${avatar.name}</h4>
                <small>${avatar.price} 포인트 • ${this.getRarityText(avatar.rarity)}</small>
            </div>
        `;
        
        document.getElementById('delete-avatar-modal').style.display = 'block';
        this.currentEditingAvatar = avatar;
    }

    async confirmDeleteAvatar() {
        try {
            if (!this.currentEditingAvatar) return;

            const { error } = await this.supabaseClient
                .from('avatar_items')
                .delete()
                .eq('id', this.currentEditingAvatar.id);

            if (error) throw error;

            this.hideDeleteModal();
            await this.loadAvatars();
            this.showSuccess('아바타가 삭제되었습니다.');
            
        } catch (error) {
            console.error('아바타 삭제 실패:', error);
            this.showError('아바타 삭제에 실패했습니다.');
        }
    }

    async refreshAvatars() {
        await this.loadAvatars();
        this.showSuccess('아바타 목록이 새로고침되었습니다.');
    }

    // 이미지 비율에 따른 클래스 설정 (원본 비율 유지)
    setImageAspectRatio(element, imageUrl) {
        const img = new Image();
        img.onload = () => {
            const aspectRatio = img.width / img.height;
            
            // 기존 클래스 제거
            element.classList.remove('landscape', 'portrait', 'square');
            
            // 비율에 따른 클래스 추가
            if (aspectRatio > 1.2) {
                // 가로가 긴 이미지
                element.classList.add('landscape');
                console.log(`📐 ${imageUrl}: 가로형 (${img.width}x${img.height}, 비율: ${aspectRatio.toFixed(2)})`);
            } else if (aspectRatio < 0.8) {
                // 세로가 긴 이미지
                element.classList.add('portrait');
                console.log(`📐 ${imageUrl}: 세로형 (${img.width}x${img.height}, 비율: ${aspectRatio.toFixed(2)})`);
            } else {
                // 정사각형에 가까운 이미지
                element.classList.add('square');
                console.log(`📐 ${imageUrl}: 정사각형 (${img.width}x${img.height}, 비율: ${aspectRatio.toFixed(2)})`);
            }
        };
        
        img.onerror = () => {
            console.warn(`⚠️ 이미지 로드 실패: ${imageUrl}`);
            element.classList.add('square'); // 기본값으로 정사각형 적용
        };
        
        img.src = imageUrl;
    }

    // 렌더링 후 모든 이미지의 비율 설정
    applyImageAspectRatios() {
        const imageElements = document.querySelectorAll('.avatar-image');
        imageElements.forEach(element => {
            const backgroundImage = element.style.backgroundImage;
            if (backgroundImage) {
                // url("...") 형태에서 URL 추출
                const imageUrl = backgroundImage.slice(5, -2); // 'url("' 와 '")' 제거
                this.setImageAspectRatio(element, imageUrl);
            }
        });
    }

    hideAvatarModal() {
        document.getElementById('avatar-modal').style.display = 'none';
        this.currentEditingAvatar = null;
    }

    hideDeleteModal() {
        document.getElementById('delete-avatar-modal').style.display = 'none';
        this.currentEditingAvatar = null;
    }

    showSuccess(message) {
        this.showNotification(message, 'success');
    }

    showError(message) {
        this.showNotification(message, 'error');
    }

    showNotification(message, type = 'info') {
        // 기존 알림 제거
        const existingAlert = document.querySelector('.alert');
        if (existingAlert) {
            existingAlert.remove();
        }

        // 새 알림 생성
        const alert = document.createElement('div');
        alert.className = `alert alert-${type === 'error' ? 'error' : 'success'}`;
        alert.textContent = message;
        
        // 첫 번째 자식 요소 앞에 삽입
        const container = document.querySelector('.admin-content');
        container.insertBefore(alert, container.firstChild);

        // 3초 후 자동 제거
        setTimeout(() => {
            alert.remove();
        }, 3000);
    }
}

// 전역 함수들 (HTML에서 호출)
function showAddAvatarModal() {
    if (avatarManager) {
        avatarManager.showAddAvatarModal();
    }
}

function refreshAvatars() {
    if (avatarManager) {
        avatarManager.refreshAvatars();
    }
}

function saveAvatar() {
    if (avatarManager) {
        avatarManager.saveAvatar();
    }
}

function hideAvatarModal() {
    if (avatarManager) {
        avatarManager.hideAvatarModal();
    }
}

function hideDeleteModal() {
    if (avatarManager) {
        avatarManager.hideDeleteModal();
    }
}

function confirmDeleteAvatar() {
    if (avatarManager) {
        avatarManager.confirmDeleteAvatar();
    }
}

// 한정판 설정 토글
function toggleLimitedSettings() {
    const isLimited = document.getElementById('is-limited').checked;
    const limitedSettings = document.getElementById('limited-settings');
    const totalSupplyInput = document.getElementById('total-supply');
    const remainingStockInput = document.getElementById('remaining-stock');
    
    if (isLimited) {
        limitedSettings.style.display = 'block';
        totalSupplyInput.required = true;
        
        // 총 발행량 변경 시 재고 자동 설정
        totalSupplyInput.addEventListener('input', function() {
            if (!remainingStockInput.value || remainingStockInput.value === '0') {
                remainingStockInput.value = this.value;
            }
        });
        
        console.log('🎯 한정판 모드 활성화');
    } else {
        limitedSettings.style.display = 'none';
        totalSupplyInput.required = false;
        
        // 필드 초기화
        document.getElementById('total-supply').value = '';
        document.getElementById('remaining-stock').value = '';
        document.getElementById('release-date').value = '';
        document.getElementById('sale-end-date').value = '';
        
        console.log('🎯 무제한 모드 활성화');
    }
}

// 전역 avatarManager 인스턴스
let avatarManager = null;

// 페이지 로드 시 초기화
document.addEventListener('DOMContentLoaded', async () => {
    try {
        // 약간의 지연을 두어 다른 스크립트들이 로드되기를 기다림
        setTimeout(async () => {
            avatarManager = new AvatarManager();
            await avatarManager.init();
        }, 100);
    } catch (error) {
        console.error('아바타 관리 시스템 초기화 오류:', error);
    }
});
