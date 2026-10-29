# 공통 Pretendard 등록 회귀

- 2026-10-28 iPhone17e iOS26.4.1, 기본 글자 크기. FullScreenAuditUITests8건 통과, 실제 화면100개 및 접근성 트리100개 확보.
- 7개 축소 모음에서 Calendar/Home/Guide/Login/List/Memo/MyPage/Notice/Notification/Share/Typing/Theme/탈퇴 상태를 확인했다. 캡처 원본과 촬영 시각은 font-audit/manifest.json에 있다.
- 기존 Oct25 실제 캡처와 Home Light/Dark, Login Light, Notification Light를 나란히 비교했다(font-regression-comparison.png). 글꼴 무게·자폭 변경은 보이며 해당 대표 화면에서 새 겹침·버튼 소실은 발견하지 못했다.
- 기존 Figma 차이(가이드 단계별 내용, 공유 Dark 텍스트 색상, 공용 토글 크기, 결과 팝업 배경 안내, 공지사항 구조)는 유지된다. 이번 공통 등록을 전 화면 Figma 최종 통과로 판정하지 않는다. 기준은 docs/design-qa/2026-10-25-full-screen-audit-qa.md 및 해당 Figma 원본을 참조한다.
- Home 이미지 fixture의 빨간 면은 테스트 이미지다. Calendar March2025의 흐린 날짜는 기존 날짜 범위 fixture 상태다. 새 글꼴 문제로 단정하지 않는다.
- 본문 스크롤 추가 직전 캡처다. 이후 변경은 TypingQuoteView 내부 본문 스크롤에 한정되며 입력 화면의 최신 증거는 round2 및 scroll-compact/scroll-large에 분리한다.
