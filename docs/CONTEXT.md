# Fitie — 채팅용 컨텍스트 브리핑

> 폴더에 접근할 수 없는 Claude 채팅(claude.ai)에게 이 앱을 한 번에 이해시키기 위한 요약본입니다.
> 최종 갱신: 2026-08-04

---

## 1. 한 문단 요약

**Fitie**는 **HealthKit이 습관 완료를 자동으로 판정해주는** iOS 습관 트래커입니다.
대부분의 습관 앱은 사용자가 직접 "완료"를 누르지만, Fitie는 걸음·물·수면·운동·마음챙김 같은 실제 건강 데이터로 달성 여부를 스스로 판정합니다.

그리고 **같은 데이터를 두 번 씁니다** — (1) 습관 자동 판정, (2) 매일의 컨디션(기분·에너지)과의 상관 분석.
그래서 "어떤 습관이 내 컨디션을 좋게 하는가"라는 인사이트가 나옵니다. 기능 수는 적어도 깊이가 있는 구조예요.

- 저장소: https://github.com/mxvixxn/Fitie (브랜치 `main`)
- 로컬 경로: `~/Desktop/Fitie`
- 성격: **개인 포트폴리오 목적 공개**. 버전 0.1.0
- UI 문구는 한국어, 다정한 존댓말 톤

---

## 2. 기술 스택 / 제약

| 항목 | 값 |
|---|---|
| 타깃 OS | **iOS 26.0+** (Liquid Glass 세대) |
| 언어 | **Swift 6.0** |
| UI | SwiftUI |
| 영속성 | SwiftData |
| 건강 데이터 | HealthKit |
| AI | **Foundation Models (온디바이스)** — 문장 표현만 담당 |
| 차트 | Swift Charts |
| 라이브 액티비티 | ActivityKit |
| 알림 | UserNotifications |
| 테스트 | **Swift Testing** — 순수 로직 코어 중심 (테스트 있음!) |
| 프로젝트 생성 | **XcodeGen** — `project.yml`이 원본, `.xcodeproj`는 생성물 |
| 외부 의존성 | XcodeGen(빌드 도구)뿐, 런타임 라이브러리 **없음** |
| 서버 | **없음.** 계정·로그인·클라우드 동기화 전부 없음. 완전 온디바이스 |

### ★ 중요한 두 가지 제약

**1) `.xcodeproj`를 직접 고치지 마세요.** 타깃·capability·entitlements·Info.plist는 전부 **`project.yml`**에서 선언합니다.
```bash
brew install xcodegen     # 최초 1회
xcodegen generate         # project.yml → Fitie.xcodeproj
```

**2) 무료 Personal Team 기준으로 개발되어 시뮬레이터가 1순위입니다.**
그래서 App Groups가 필요한 **홈 화면 위젯은 v1 범위에서 제외**(자리만 설계)되어 있어요. HealthKit·Live Activity·로컬 알림·온디바이스 AI는 전부 시뮬레이터에서 동작합니다.

---

## 3. 아키텍처 — 이 프로젝트의 핵심

원칙: **각 유닛은 단일 목적 + 잘 정의된 인터페이스 + 독립 테스트 가능.**
프로토콜로 격리해서 *시뮬레이터/실기기*, *모델 가용성* 차이를 **구현체 교체**로 흡수합니다.

```
Fitie/
├─ Models/      SwiftData 모델 (Habit, DailyResult, ConditionEntry, InsightSnapshot, VerificationRule)
├─ Health/      HealthDataSource 프로토콜 + HealthKit / Mock 구현
├─ Logic/       순수 로직 코어 (HabitEvaluator, InsightEngine, StreakCalculator, HabitStatus)
├─ Insights/    InsightPhraser 프로토콜 + FoundationModels / Template 구현
├─ Services/    Store(SwiftData), RefreshService, RefreshController, NotificationService, SampleData
├─ Live/        Live Activity (FitieActivityAttributes, SessionController)
└─ Views/       SwiftUI 화면 (Today, Insights, Habits, Settings, Onboarding, Components)
FitieTests/     HabitEvaluator · InsightEngine · RefreshService · TemplatePhraser 테스트
FitieWidgets/   Live Activity 확장
```

| 유닛 | 역할 |
|---|---|
| `HealthDataSource` *(프로토콜)* | HealthKit 추상화. `HealthKitDataSource`(실제) / `MockHealthDataSource`(테스트·프리뷰). **시뮬/실기기 차이를 흡수하는 핵심 seam** |
| `HabitEvaluator` | 순수 로직: 규칙 + 측정값 → 달성 상태. **프레임워크 의존 0** |
| `InsightEngine` | 순수 통계: DailyResult + ConditionEntry → 구조화 인사이트. **프레임워크 의존 0** |
| `InsightPhraser` *(프로토콜)* | 인사이트 → 문장. `FoundationModelsPhraser` / `TemplatePhraser`(폴백), 가용성으로 자동 선택 |

### ★★ AI에 대한 원칙 (가장 중요)

**숫자는 전부 Swift가 계산하고, 온디바이스 모델은 문장만 표현합니다.**
LLM에게 통계를 계산시키지 않습니다. 모델을 못 쓰는 상황에서는 `TemplatePhraser`로 자동 폴백해서 앱이 그대로 동작합니다.
→ **"AI에게 데이터를 분석시키자"는 방향의 제안은 이 설계와 정면으로 어긋납니다.**

---

## 4. 구현된 기능

- 🩺 **자동 판정 습관** — HealthKit 규칙 연결 시 매일 자동 판정. 데이터 없는 습관(독서 등)은 수동 체크
- 🔥 **정직한 스트릭** — 앱 실행 시 지나간 날을 확정(finalize). 미달성 날이 조용히 스트릭을 끊지 않음. 하루치 결과를 스냅샷 캐싱
- 💚 **컨디션 체크인** — 하루 한 번 기분·에너지(1–5) + 한 줄 메모, 30초
- 🧠 **주간 AI 인사이트** — "X한 날 컨디션이 평균 N점 높았어요" 형태의 **관찰형** 인사이트
- 📅 **기록 캘린더** — 과거 특정 날 재판정, 컨디션 나중에 기록 가능
- 📊 **차트** — 컨디션 추세, 습관별 30일 달성률, 습관↔컨디션 상관
- 🔔 **스마트 리마인더** — 반복 트리거 대신 **7일 롤링 재예약**. 오늘 달성한 습관은 오늘 알림 건너뜀
- 📲 **Live Activity** — 사용자가 시작하는 걷기/스트레칭 세션의 진행 링을 잠금화면에
- 🔒 **완전 로컬** + JSON 백업 내보내기
- ✨ iOS 26 Liquid Glass 앱 아이콘(Icon Composer), 스크롤 시 탭바 축소

## 5. 로드맵 (v2 이후, 미구현)

- [ ] 홈 화면 데이터 위젯 (App Groups 필요)
- [ ] Apple Watch 동반 앱
- [ ] 원격 푸시 기반 Live Activity 갱신

---

## 6. 빌드 & 실행

```bash
DEST='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
xcodegen generate
xcodebuild -project Fitie.xcodeproj -scheme Fitie -destination "$DEST" build
xcodebuild test -project Fitie.xcodeproj -scheme Fitie -destination "$DEST"
```

시드 데이터로 실행: 환경변수 **`FITIE_SEED=1`**

---

## 7. 채팅에게 부탁하고 싶은 것

1. **한국어 존댓말**로 답해 주세요.
2. **런타임 외부 라이브러리를 도입하는 제안은 하지 마세요.** 애플 순정 프레임워크만 씁니다.
3. **AI에게 숫자를 계산시키는 제안을 하지 마세요.** 계산은 Swift, 모델은 문장만 (위 3절 참고).
4. 프로젝트 설정 변경은 `.xcodeproj`가 아니라 **`project.yml`** 을 고치는 것으로 제안해 주세요.
5. 새 로직을 넣을 땐 `Logic/`의 순수 코어에 넣고 테스트를 함께 제안해 주세요 — 이 프로젝트는 **테스트가 있는 유일한 앱**입니다.
6. 파일 내용이 필요하면 추측하지 말고 붙여 달라고 요청해 주세요.
