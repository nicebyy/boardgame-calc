# 🎲 보드게임 계산기 (Boardgame Calculator) — Flutter Web

원본 프로젝트(`pickban_smulator`의 `/minigames/boardgame-calc`)의 **모든 기능과 Warm Walnut & Parchment Gold 테이블탑 UI/UX**를 **Flutter Web**으로 이식·확장한 실시간 보드게임 자산·점수·도구 계산기 웹앱입니다.

---

## ✨ 주요 핵심 기능 (원본 100% 호환 + 오프라인 병행 지원)

1. **이중 실행 모드 (온라인 멀티플레이어 + 오프라인 로컬 테이블)**
   - **온라인 모드 (Socket.IO)**: 기존 NestJS `BoardgameCalcGateway`(`boardgameCalc:*` 이벤트)와 100% 프로토콜 호환. 서버 URL 설정 및 세션 자동 재접속 지원.
   - **오프라인 모드 (Local Engine)**: 서버 연결 없이 브라우저 단독으로 모든 보드게임 계산기 기능을 즉시 사용 가능(Pass & Play 플레이어 전환 및 `SharedPreferences` 로컬 상태 저장/복원 지원).
2. **공개방 로비 & 프로필 관리**
   - 공개방 목록 검색/새로고침, 방 생성/입장/삭제, 닉네임(최대 15자) 및 8종 플레이어 테마 컬러 선택.
3. **화폐(포인트) & 점수(VP) 듀얼 트래커**
   - 화면 표기 모드(`화폐 & 점수` / `화폐만` / `점수만`), 1만 이상 `k` 단위 자동 압축(`10k`, `10.5k`), 천 단위 콤마 툴팁.
   - 빠른 증감 단위(음수 단위 포함) 및 **단위별 수량 한도(`remainingCount / maxCount`)** 차감·반환·소진 제어.
   - 권한 분리(`자율 모드` vs `엄격 뱅커 모드`) — 화폐 권한/점수 권한 독립 설정.
4. **P2P 상호 합의 송금**
   - 송금 모달(잔액 초과 및 경매 최고입찰 예약액 보호) + 수신자 **P2P 합의 요청 모달(수락/거절)**.
5. **중앙 보드판 도구 4종 (방장 일괄 전환)**
   - **플레이어 보드 (기본)**: 카드형/리스트형 뷰 전환 및 5종 정렬(기본순, 화폐 ↓/↑, 점수 ↓/↑).
   - **🎲 주사위 롤러**: 개수(`1~12`)·면수(`2~1000`) 직접 입력, D6 눈금/다면체 렌더링, 텀블링 애니메이션, 콤보 판정(더블/트리플/퍼펙트 매치/내추럴 20/펌블 1), 전역 알림 토스트.
   - **💰 배팅 판돈 & 모인 돈**: 경매와 독립된 테이블 팟, 플레이어별 누적 배팅 집계·점유율, 4분할 빠른 배팅, 승자 지급 및 전액 환불/초기화.
   - **🔨 실시간 경매**: 최소 입찰단위, 카운트다운 타이머 & 입찰 시 자동 시간 연장, 낙관적 동시성 충돌 감지, 자가 중복 입찰 방지, 즉시 낙찰(대금 차감/팟 지급).
   - **📝 비밀노트**: 라운드/주제/제한시간(`30/60/90/120/무제한`) 및 자동 오픈 설정, 개인 화면 가리기(덮기/펼치기), 방장 `✋ 손떼`(잠금) / `📖 오픈`(공개) / `새 라운드`, 미오픈 시 타인 내용 마스킹.
6. **실시간 게임 로그 & Web·Android 효과음 / 로비 BGM**
   - 8종 카테고리 필터(`전체`, `화폐`, `승점`, `경매`, `배팅`, `주사위`, `비밀노트`, `기타/설정`) 로그 모달.
   - Web Audio API 및 순수 Dart PCM WAV 합성 기반 **버튼 클릭·탭·모달·인게임 효과음 11종** (Web/Android 공용 `ON/OFF` 토글).
   - **로비 BGM 플레이어**: 내장 `assets/audio/lobby_bgm.mp3` 웹·Android 로비 자동 루프 재생(ON/OFF·볼륨 조절, 인게임 진입 시 자동 정지 및 로비 복귀 시 재개).

---

## 🛠️ 기술 스택 및 요구사항

- **Framework**: Flutter 3.50+ (Web / Android) / Dart 3.14+
- **State & Storage**: `provider`, `shared_preferences`
- **Realtime**: `socket_io_client` (NestJS Socket.IO v4 호환)
- **Web Audio & BGM**: `package:web` (`AudioContext` 경량 신디사이저) + `audioplayers` (`assets/audio/lobby_bgm.mp3` 크로스 플랫폼 루프)

---

## 🚀 실행 및 검증 명령

```bash
# 의존성 설치
flutter pub get

# 정적 분석
flutter analyze

# 단위 및 위젯 테스트
flutter test

# 웹 개발 서버 실행
flutter run -d chrome

# 프로덕션 웹 빌드
flutter build web

# Android APK 릴리즈 빌드 (Android SDK 환경 또는 GitHub Actions)
flutter build apk --release
# 산출물: build/app/outputs/flutter-apk/app-release.apk
```

> **Windows 한글 계정 경로 참고**: Windows 사용자 경로(예: `C:\Users\<한글명>`)에 비ASCII 문자가 포함된 경우 Flutter의 `impellerc.exe` 셰이더 컴파일러가 테스트/웹 에셋 번들링 중 종료될 수 있습니다. 이 경우 임시 ASCII 드라이브(`subst W: <경로>`, `subst P: <PubCache경로>` 및 `$env:PUB_CACHE="P:\"`)에서 실행하면 정상 빌드/테스트됩니다.
>
> **Android APK 간편 다운로드 (GitHub Actions & Releases)**:
> - **`main` 병합 시 자동 릴리즈**: [`.github/workflows/build-apk.yml`](./.github/workflows/build-apk.yml) 워크플로우가 실행되어 **GitHub Releases (`releases/latest`)** 에 `boardgame-calc.apk` 를 자동 발행합니다.
> - **`develop` / PR 빌드**: GitHub 저장소의 **Actions → Artifacts** 에서 `boardgame-calc-release-apk` 를 내려받아 테스트할 수 있습니다.

---

## 📁 디렉터리 구조

- `lib/main.dart`: 앱 진입점(`BoardgameCalcApp`) 및 3단 테이블탑 레이아웃
- `lib/theme/boardgame_theme.dart`: Warm Walnut & Parchment Gold 단일 테마 및 8색 플레이어 팔레트
- `lib/models/boardgame_models.dart`: 도메인 모델, Enum, 숫자 포맷터 및 정렬 유틸
- `lib/services/local_boardgame_engine.dart`: 순수 Dart 오프라인/Pass & Play 게임 엔진
- `lib/services/boardgame_socket_client.dart`: NestJS `boardgameCalc:*` Socket.IO 클라이언트
- `lib/services/boardgame_audio*.dart`: Web Audio API 0KB 합성 효과음 및 플랫폼 스텁
- `lib/services/lobby_bgm_service.dart`: `audioplayers` 기반 Web/Android 로비 BGM 플레이어
- `lib/state/boardgame_calc_controller.dart`: 온/오프라인 통합 컨트롤러(`ChangeNotifier`)
- `lib/widgets/`: 로비, 상단/중앙/하단 패널, 비밀노트, 햄버거 드로어, 모달 7종
- `assets/audio/`: 로비 배경음악 배치 폴더 (`lobby_bgm.mp3`)
- `assets/icon/`: Android Adaptive 아이콘 및 Web PWA 아이콘 원본(`app_icon.png`, `app_icon_foreground.png`)
- `test/`: `local_engine_test.dart`(단위 10건), `lobby_bgm_test.dart`(BGM·효과음 단위 6건), `widget_test.dart`(위젯 8건)

---

## 📚 문서 및 규칙

- [`AGENTS.md`](./AGENTS.md) — 에이전트 작업 지침 및 필수 검증 게이트
- [`GEMINI.md`](./GEMINI.md) — 브랜치 전략(`main`-`develop`-`feature/*`), 워크트리 격리, 커밋·테스트 규칙
- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — 아키텍처 및 상태/어댑터 구조
- [`docs/SOCKET_API.md`](./docs/SOCKET_API.md) — Socket.IO 프로토콜 명세
