# Git Commit & Workflow Rules for boardgame-calc (Flutter Web)

> ## ⚠️ 에이전트는 작업 시작 전에 반드시 [`AGENTS.md`](./AGENTS.md) 를 먼저 읽는다
>
> 본 문서는 원본 프로젝트(`C:\Users\곽현기\Documents\pickban_smulator\GEMINI.md`)의 개발·Git·테스트·문서화 규칙을 인용하여 Flutter 웹앱(`boardgame-calc`) 프로젝트에 맞게 정비한 상세 규칙 원본입니다.
> 충돌 시 **더 엄격한 쪽**을 따릅니다.

## 0. 다중 세션 동시 작업 시 최우선 원칙

여러 AI 에이전트 세션이 동시에 작업할 수 있으므로 아래는 다른 모든 규칙보다 우선합니다.

1. **워크트리 없이 파일을 수정하지 않는다.**
   작업 시작 전 반드시 `.agents/worktrees/<브랜치명>` 워크트리를 만들고, 그 안에서만 작업한다.
2. **메인 체크아웃(저장소 루트)은 읽기 전용이다.**
   루트의 브랜치는 다른 세션이 언제든 바꿀 수 있으므로, 루트에서 수정하면 **남의 브랜치에 커밋이 들어간다.**
3. **커밋 전 브랜치를 확인한다.**
   `git rev-parse --abbrev-ref HEAD` 가 내 브랜치인지 매번 확인한다.
4. **파괴적 명령을 쓰지 않는다.**
   `git reset --hard`, `git checkout .`, `git clean -fd`, `git stash clear` 는 다른 세션의 작업을 소실시킨다.

> 상세 절차·금지 명령·사고 복구 순서는 [`AGENTS.md`](./AGENTS.md) 참조.

## 1. 브랜치 운영 전략 (Branching Strategy: `main` - `develop` - `feature/*`)

- 프로젝트는 **`main` - `develop` - `feature/*` (또는 `feat/*`)** 3단계 브랜치 전략을 엄격히 준수한다.
- **`main` 브랜치**:
  - 운영(Production) 최종 릴리즈 전용 브랜치.
  - **`main` 브랜치에 직접 커밋하거나 푸시하는 행위는 절대 금지**한다. (최초 저장소 초기화 제외)
  - `develop`에서 충분한 테스트와 검증이 완료된 안정화 버전만 릴리즈 시점에 병합(Merge)한다.
- **`develop` 브랜치**:
  - 개발의 중심이 되는 기본 통합 브랜치.
  - 모든 신규 작업 브랜치는 항상 최신 `develop`에서 분기(`checkout -b` 또는 `git worktree add`)한다.
- **`feature/*` (또는 `feat/*`, `fix/*`, `docs/*`, `refactor/*`) 브랜치**:
  - **신규 기능 개발, 버그 수정, UI 변경, 리팩토링 등 모든 작업은 반드시 전용 작업 브랜치에서 수행**한다.
  - **작업 워크플로우**:
    1. 작업 시작 전: 최신 `develop`에서 워크트리/브랜치 생성 (`git fetch origin` → `git worktree add .agents/worktrees/<브랜치명> -b <브랜치명> origin/develop`)
    2. 작업 진행: 해당 워크트리/브랜치 내에서 독립적으로 작업, 단위/위젯 테스트 및 원자적 커밋 수행.
    3. 작업 완료 및 검증: `git checkout develop` → `git merge --no-ff <브랜치명>` → `git push origin develop`
    4. 브랜치 정리: 병합 완료된 워크트리 및 브랜치 삭제 (`git worktree remove ...`, `git branch -d ...`).

## 2. 작업 단위별 자동 커밋 규칙 (Automatic Atomic Commits)

- 의미 있는 작업 단위가 완료되고 **테스트 및 빌드 검증이 완료되면 반드시 작업을 마칠 때 자동으로 Git 커밋을 수행**한다.
- 커밋 전 프로세스 (반드시 순서 준수):
  1. `git status`로 변경 사항 및 추적되지 않은 파일 확인.
  2. 불필요한 빌드 아티팩트(`.dart_tool/`, `build/` 등)나 임시 파일이 포함되지 않았는지 점검 (`.gitignore` 준수).
  3. **정적 분석(`flutter analyze`), 전체 테스트(`flutter test`), 웹 빌드(`flutter build web`)를 실행하여 100% 통과 여부 확인 (필수 게이트)**.
  4. 관련 파일만 선별하여 스테이징 (`git add <files>` — `git add -A` 금지).
  5. Conventional Commits 규칙에 맞추어 명확하고 구체적인 커밋 메시지로 커밋 (`git commit -m "..."`).
  6. 커밋 완료 후 사용자에게 커밋 내역(현재 브랜치, 워크트리 경로, 커밋 메시지, 해시)과 **테스트/빌드 검증 결과**를 응답에 안내한다.

## 3. 커밋 메시지 컨벤션 (Conventional Commits)

커밋 메시지는 `<type>(<scope>): <subject>` 형식을 기본으로 하며, 한글 또는 영어로 변경 내용을 명확히 기술한다.

- `feat`: 새로운 기능 추가 (예: `feat(auction): 실시간 경매 타이머 및 자동 연장 UI 구현`)
- `fix`: 버그 및 오류 수정 (예: `fix(socket): 재접속 시 sessionId 기반 방 복원 보완`)
- `refactor`: 동작 변경 없는 코드 구조 개선 / 리팩토링
- `style`: 코드 포맷팅, UI 스타일/레이아웃 조정
- `perf`: 성능 개선 (렌더링 최적화, 불필요한 리빌드 방지 등)
- `test`: 테스트 코드 추가 및 수정 (단위 테스트, 위젯 테스트)
- `docs`: README, 가이드 문서, 규칙 문서 작업
- `chore`: 패키지 의존성(`pubspec.yaml`), 빌드 설정 변경

## 4. 원자적 커밋(Atomic Commit) 원칙

- 서로 연관 없는 두 개 이상의 변경을 하나의 커밋으로 묶지 않고 각각 분리하여 커밋한다.
- 각 커밋 시점의 코드는 `flutter analyze`와 `flutter test`를 모두 통과한 정상 동작 상태를 유지해야 한다.

## 5. 단위 테스트 및 위젯 테스트 의무화 규칙 (Mandatory Testing Policy)

모든 에이전트 세션은 기능 개발, 버그 수정, 리팩토링 시 **반드시 테스트를 작성하고 실행하여 통과를 검증한 후 커밋/머지**해야 한다. (임의로 테스트를 생략하는 행위 절대 금지)

### 5.1. 작업 유형별 테스트 요구사항
1. **단위 테스트 (Unit Test)**:
   - **대상**: 도메인 모델 직렬화/역직렬화(`fromJson`/`toJson`), 유틸리티(`formatCompactNumber`, `sortTopPlayers`, `getRoomUnits`), 오프라인/로컬 게임 엔진(`LocalBoardgameEngine`: 화폐/점수 증감, 수량 한도 차감·반환, P2P 송금 합의, 경매 입찰·낙찰·동시성 체크, 배팅·환불, 주사위 콤보, 비밀노트 마스킹·잠금·오픈).
   - **요구사항**: 정상 동작(Happy Path)과 예외/경계 상황(잔액 부족, 단위 소진, 권한 오류, 중복 닉네임, 자가 입찰 방지 등)을 검증한다.
2. **위젯 / UI 통합 테스트 (Widget Test)**:
   - **대상**: 로비(방 목록/방 생성/프로필 색상 선택), 인게임 3단 레이아웃(상단 타 플레이어, 중앙 보드/도구, 하단 내 프로필), 도구 전환(플레이어 보드/주사위/배팅/경매/비밀노트), 주요 모달(송금/합의/조율/설정/로그/프로필편집/햄버거 메뉴).

### 5.2. 커밋 및 머지 전 테스트 검증 게이트 (Test Verification Gate)
- **테스트 미통과 시 커밋/머지 절대 금지**:
  - `flutter analyze`, `flutter test`, `flutter build web` 이 모두 통과하기 전에는 `git commit`이나 `git merge`를 진행하지 않는다.
- **테스트 실행 결과 응답 보고 의무**:
  - 작업 완료 후 사용자에게 답변할 때 실행한 명령어와 결과(통과한 테스트 수, 분석/빌드 결과)를 커밋 내역과 함께 반드시 명시한다.

## 6. 단일 원본 테마 일관성 규칙 (Single Original Boardgame Tabletop Theme Policy)

- 원본(`pickban_smulator`)의 보드게임 계산기 기본 테마인 **Warm Walnut & Parchment Gold 단일 테마**만 일관되게 적용한다.
- 사이버펑크 테마나 별도의 다중 테마 분기를 추가하지 않는다.
- 주요 색상 팔레트:
  - 표면/배경: Parchment Cream (`#F4EBE1`, `#FDFAF5`, `#FFFDF9`), Border (`#C4A685`, `#E8D7C4`)
  - 강조/헤더/도구 패널: Walnut (`#2B160C`, `#3E2723`, `#1A0E08`, `#180D07`), Gold (`#C5A059`, `#D4AF37`, `#F3E5AB`)
  - 플레이어 8종 테마 컬러: Blue(`#3B82F6`), Red(`#EF4444`), Green(`#10B981`), Amber(`#F59E0B`), Purple(`#8B5CF6`), Pink(`#EC4899`), Cyan(`#06B6D4`), Orange(`#F97316`)

## 7. 기능적 변경 시 프로젝트 문서 동기화 의무화 규칙 (Mandatory Documentation Synchronization Policy)

프로젝트에 주요 도메인/프로토콜/화면 변경이 발생할 경우 코드 구현 및 테스트 완료 후 관련 문서를 최신화한다.
- **루트 `README.md`**: 주요 기능, 실행/테스트/빌드 명령, 디렉터리 구조 반영.
- **`docs/ARCHITECTURE.md`**: 상태 관리, 온라인(Socket.IO) 및 오프라인(`LocalBoardgameEngine`) 이중 어댑터 구조 다이어그램 동기화.
- **`docs/SOCKET_API.md`**: `boardgameCalc:*` Socket.IO 이벤트 명세 및 DTO 동기화.
- **Mermaid 다이어그램 문법 검증**: 링크 라벨 내 특수문자(`( ) /`) 사용 시 따옴표(`|"..."|`)로 감싸 파싱 에러를 방지한다.

## 8. 다중 에이전트 동시 작업 시 Git Worktree 격리 의무화 규칙 (Mandatory Git Worktree Isolation Policy)

- 워크트리는 저장소 루트의 `.agents/worktrees/<브랜치명>/` 아래에 생성한다.
- 모든 파일 편집·빌드·테스트·커밋은 워크트리 절대경로 안에서 수행하며, 메인 체크아웃에서는 `develop` 병합 및 워크트리 정리만 수행한다.
- 병합 완료 후 반드시 `git worktree remove .agents/worktrees/<브랜치명>`, `git branch -d <브랜치명>`, `git worktree prune` 으로 정리한다.
