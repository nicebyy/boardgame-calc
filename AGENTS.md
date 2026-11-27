# 에이전트 작업 지침 (AGENTS.md)

> 이 파일은 **이 저장소(`boardgame-calc`)에서 작업하는 모든 AI 에이전트 세션**이 작업 시작 전에 읽어야 하는 공용 지침입니다.
> 본 규칙은 원본 프로젝트(`C:\Users\곽현기\Documents\pickban_smulator\AGENTS.md` 및 `GEMINI.md`)의 검증된 워크플로우와 품질 게이트를 Flutter 웹앱 개발 환경에 맞추어 인용·적용한 것입니다.
> 상세 규칙은 [`GEMINI.md`](./GEMINI.md) 가 원본이며, 이 문서는 **가장 자주 위반되는 항목**을 압축한 요약입니다.

---

## 🚨 최우선: 브랜치 / 워크트리 (위반 시 다른 세션 작업 파괴)

여러 세션이 **같은 저장소에서 동시에** 작업할 수 있습니다. 아래 4단계를 **예외 없이** 지킵니다.

### 1️⃣ 작업 시작 전 — 워크트리 생성

```bash
git fetch origin
git worktree add .agents/worktrees/<브랜치명> -b <브랜치명> origin/develop
git worktree list   # 생성 확인
```

- 브랜치명: `feature/*`, `feat/*`, `fix/*`, `docs/*`, `perf/*`, `refactor/*` (`GEMINI.md` 규칙 1)
- 위치: 저장소 루트의 `.agents/worktrees/<브랜치명>` (`.gitignore` 대상)

### 2️⃣ 작업 중 — 워크트리 밖으로 나가지 않는다

```bash
pwd                              # .agents/worktrees/<브랜치명> 이어야 함
git rev-parse --abbrev-ref HEAD  # 내 브랜치여야 함
```

- 모든 파일 편집·빌드·테스트·커밋을 **워크트리 절대경로 안에서** 수행합니다.
- 저장소 루트(메인 체크아웃)는 **읽기 전용**으로 유지합니다.
- ⚠️ **메인 체크아웃의 브랜치를 다른 세션이 언제든 바꿀 수 있으므로**, 루트에서 수정하면 커밋이 남의 브랜치로 들어갑니다.

### 3️⃣ 커밋 직전 — 범위 확인

```bash
git diff --name-only --cached   # 의도한 파일만?
git status --short              # 다른 세션 파일 섞이지 않았나?
```

- `git add -A`, `git commit -a` **금지** — 파일을 하나씩 명시적으로 스테이징합니다.
- 커밋 후 `git rev-parse --abbrev-ref HEAD` 로 브랜치를 재확인합니다.

### 4️⃣ 작업 완료 후 — 병합 및 정리

```bash
# 메인 체크아웃에서
git checkout develop && git merge --no-ff <브랜치명>
git worktree remove .agents/worktrees/<브랜치명>
git branch -d <브랜치명>
git worktree prune
```

---

## 🛑 절대 금지 명령

| 명령 | 이유 |
|---|---|
| `git reset --hard` | 다른 세션의 미커밋 작업이 **소실**됨 |
| `git checkout .` / `git restore .` | 다른 세션 변경분까지 되돌림 |
| `git clean -fd` | 추적 안 된 다른 세션 파일 삭제 |
| `git stash clear` | 모든 세션의 stash 삭제 |
| 메인 체크아웃에서 파일 수정 | 커밋이 남의 브랜치로 감 |
| `git add -A` / `git commit -a` | 무관한 파일·타 세션 WIP 포함 |
| `main` 브랜치 직접 커밋/푸시 | 검증된 `develop` 병합만 허용 (`GEMINI.md` 규칙 1) |

---

## 📋 작업 종료 전 필수 게이트 (`GEMINI.md` 규칙 2·5·6·8)

1. **정적 분석 통과**: `flutter analyze` (경고/에러 0건)
2. **테스트 100% 통과**: `flutter test` (단위 테스트 및 위젯 테스트 전부 통과)
3. **웹 빌드 통과**: `flutter build web` (프로덕션 웹 번들 빌드 성공 확인)
4. **단일 원본 테마 준수 (규칙 6)**: 원본 보드게임 계산기의 기본 **Warm Walnut & Parchment Gold 단일 테마** 일관 유지
5. **프로토콜 호환성 유지**: 온라인 멀티플레이어 모드는 `pickban_smulator` NestJS 백엔드(`boardgameCalc:*` Socket.IO 이벤트)와 100% 호환 유지, 오프라인 엔진은 동일 규칙 적용
6. **문서 동기화 (규칙 8)**: 기능·구조·프로토콜 변경 시 `README.md`, `docs/*.md` 갱신
7. **원자적 커밋 (규칙 4)**: 무관한 변경을 한 커밋에 묶지 않음
8. 응답에 **브랜치명 / 워크트리 경로 / 커밋 해시 / 테스트 및 빌드 결과**를 반드시 명시

---

## 🎨 테마 지원 정책 (단일 원본 테마 유지)

- 본 프로젝트는 사용자 요구사항에 따라 원본(`pickban_smulator`)의 기본 테마인 **보드게임 테이블탑(Warm Parchment `#F4EBE1`/`#FDFAF5`, Walnut `#2B160C`/`#3E2723`, Gold `#C5A059`/`#D4AF37`) 단일 테마**만을 사용합니다.
- 플레이어 개별 카드 및 아바타는 원본 `PLAYER_THEME_PALETTE` 8종 색상(`blue`, `red`, `green`, `amber`, `purple`, `pink`, `cyan`, `orange`)을 그대로 지원합니다.

---

## 📚 참고 문서

| 문서 | 내용 |
|---|---|
| [`GEMINI.md`](./GEMINI.md) | 전체 규칙 원본 (브랜치·커밋·테스트·문서·워크트리) |
| [`README.md`](./README.md) | 프로젝트 개요, 기능 목록, 실행 방법 |
| [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) | Flutter 앱 아키텍처 및 데이터 흐름 |
| [`docs/SOCKET_API.md`](./docs/SOCKET_API.md) | `boardgameCalc:*` Socket.IO 이벤트 명세 |
