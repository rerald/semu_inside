// 🔍 아바타 카드 표시 문제 진단 및 수정
console.log('🔍 아바타 카드 표시 상태 진단 시작...');

// 1. DOM 요소 상태 확인
const container = document.getElementById('shop-items');
const loading = document.getElementById('shop-loading');

console.log('📦 DOM 요소 상태:');
console.log('- container 존재:', !!container);
console.log('- loading 존재:', !!loading);

if (container) {
    console.log('- container display:', getComputedStyle(container).display);
    console.log('- container visibility:', getComputedStyle(container).visibility);
    console.log('- container opacity:', getComputedStyle(container).opacity);
    console.log('- container width:', getComputedStyle(container).width);
    console.log('- container height:', getComputedStyle(container).height);
    console.log('- 자식 요소 수:', container.children.length);
    
    // 각 아바타 카드 상태 확인
    Array.from(container.children).forEach((card, index) => {
        console.log(`🎴 카드 ${index + 1}:`, {
            display: getComputedStyle(card).display,
            visibility: getComputedStyle(card).visibility,
            opacity: getComputedStyle(card).opacity,
            width: getComputedStyle(card).width,
            height: getComputedStyle(card).height,
            className: card.className
        });
    });
}

// 2. CSS 스타일 강제 적용
if (container) {
    console.log('🔧 CSS 스타일 강제 적용 중...');
    
    // 컨테이너 스타일 강제 설정
    container.style.display = 'grid';
    container.style.visibility = 'visible';
    container.style.opacity = '1';
    container.style.gridTemplateColumns = 'repeat(auto-fill, minmax(300px, 1fr))';
    container.style.gap = '20px';
    container.style.padding = '20px';
    container.style.minHeight = '400px';
    
    // 각 카드 스타일 강제 설정
    Array.from(container.children).forEach((card, index) => {
        card.style.display = 'block';
        card.style.visibility = 'visible';
        card.style.opacity = '1';
        card.style.minHeight = '350px';
        card.style.backgroundColor = '#fff';
        card.style.border = '2px solid #e0e0e0';
        card.style.borderRadius = '12px';
        card.style.padding = '16px';
        card.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
        
        console.log(`✅ 카드 ${index + 1} 스타일 강제 적용 완료`);
    });
    
    console.log('✅ 모든 스타일 강제 적용 완료');
}

// 3. 로딩 요소 숨김
if (loading) {
    loading.style.display = 'none';
    console.log('✅ 로딩 요소 숨김 완료');
}

// 4. 스크롤 위치 조정
const tabContent = document.querySelector('.tab-content.active');
if (tabContent) {
    tabContent.scrollTop = 0;
    console.log('✅ 스크롤 위치 초기화 완료');
}

console.log('🎯 진단 및 수정 완료! 이제 아바타 카드가 보여야 합니다.');
