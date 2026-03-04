# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Facts
- App: Devvit
- Stack: Swift, SwiftUI, Combine
- Architecture: MVVM-C (Model-View-ViewModel-Coordinator)
- iOS: 17+

## Build & Run

Xcode에서 ⌘R (빌드/실행), ⌘U (테스트 실행).

CLI build:
```bash
xcodebuild -project Devvit.xcodeproj -scheme Devvit -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Secret Management

`Config/Secrets.xcconfig` (gitignored)를 로컬에서 직접 생성해야 함:
```
GITHUB_TOKEN = your_token_here
```

값 흐름: `Secrets.xcconfig` → `Config/Config.xcconfig` → `Info.plist` → `Configuration.swift`

`GoogleService-Info.plist`도 gitignored — 클론 후 수동으로 추가 필요.

## Architecture: MVVM-C

### 앱 플로우

`AppCoordinator`가 루트 코디네이터. `AuthService.shared.$isUserLoggedIn`을 Combine으로 구독해 `currentFlow`를 전환. `DevvitApp.swift`가 이를 관찰해 화면을 렌더링.

```
DevvitApp
  └── AppCoordinator (ObservableObject, @StateObject)
        ├── .login → LoginView(viewModel: LoginViewModel(coordinator: LoginCoordinator))
        └── .home  → MainTabView → HomeView(viewModel: HomeViewModel(coordinator: HomeCoordinator))
```

### 레이어 책임

- **View**: UI 렌더링만 담당, 비즈니스 로직 금지
- **ViewModel**: 상태 관리 (@Published + Input/Output 패턴), SwiftUI import 금지
- **UseCase** *(계획된 구조, 미구현)*: 비즈니스 로직은 UseCase에만 작성
- **Coordinator**: 화면 전환만 처리. `Core/Protocols/Coordinator.swift`의 `Coordinator` 프로토콜 준수, 각 피처마다 `Route` enum과 `navigate(to:)` 정의

### Services (Singletons)

- **`AuthService.shared`** (`Network/Service/`) — Firebase Auth + Apple Sign In. `isUserLoggedIn`, `currentUser` publish. 로그인 시 Firestore에 유저 데이터 동기화.
- **`TokenStorageService.shared`** (`Network/Service/`) — UserDefaults 기반 로컬 퍼시스턴스. 로그아웃 → `clearForLogout()`, 회원탈퇴 → `clearForWithdraw()`.
- **`KeychainHelper`** (`Core/Utils/`) — 민감한 토큰 저장용 Keychain 래퍼.
- **`Configuration`** (`Core/Utils/`) — `Bundle.main.infoDictionary`를 통해 xcconfig 값 노출 (e.g. `Configuration.githubToken`).

## Conventions

- ViewModel: `ObservableObject` 채택, 상태는 `@Published`로 관리
- View: `@StateObject` (소유), `@ObservedObject` (전달받음) 구분 필수
- Combine: UI 바인딩 → `receive(on: DispatchQueue.main)` 명시, `AnyCancellable` Set 필수
- 네트워크 → `AnyPublisher<T, Error>` 반환
- 상태관리 → `CurrentValueSubject` (현재 값 필요) / `PassthroughSubject` (이벤트성) 용도 구분

## Naming

- `~View`, `~ViewModel`, `~Coordinator`, `~UseCase`, `~Model`

## Current Feature State

- **Login**: Apple Sign In 완성. GitHub 로그인은 UI만 존재, `AuthService` 로직 미구현.
- **Home**: 4탭 구조 (홈, 친구, 랭킹, 프로필). 홈 탭만 실제 View 구현. 활동 캘린더·오늘 기록은 **mock data** 사용 중 — GitHub API 연동 예정.
- **Onboarding**: `AppCoordinator`에 주석 처리된 stub 존재. `TokenStorageService`에 관련 메서드는 준비됨.

## Design System

- Background: `#0D1117` (메인), `#161B22` (카드), `#1C2128` (요소)
- Accent: `#3DDC84` (초록)
- Border: `#30363D` / Muted text: `#8B949E`
- `Color(hex:)` extension → `Core/Extensions/Color.swift`
- 앱 전체 다크모드 강제: `.preferredColorScheme(.dark)`

## DO NOT

- `AnyCancellable` Set 없이 `sink` 사용 금지
- View에서 직접 화면 전환 금지 (Coordinator 사용)
- ViewModel에서 `import SwiftUI` 금지
- API 토큰 하드코딩 금지 (Keychain 또는 xcconfig 사용)
