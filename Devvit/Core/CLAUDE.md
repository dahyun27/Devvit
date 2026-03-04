# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Facts
- 역할: 인프라 / 공통 모듈 (앱 전반에서 사용하는 싱글톤 유틸리티)
- 이 폴더 파일들은 특정 Scene에 종속되면 안 됨

## 파일 구성

| 파일 | 역할 |
|------|------|
| `Extensions/Color.swift` | `Color(hex:)` 이니셜라이저 (3·6·8자리 hex 지원) |
| `Protocols/Coordinator.swift` | `Coordinator` 프로토콜 — 모든 Coordinator의 기반 |
| `Utils/Configuration.swift` | xcconfig 값을 `Bundle.main.infoDictionary`를 통해 노출 |
| `Utils/KeychainHelper.swift` | Keychain CRUD 래퍼 (`save`, `read`, `delete`) |

### 데이터 저장 기준
- 민감한 토큰/자격증명 → `KeychainHelper`
- 일반 사용자 설정·상태 → `UserDefaults` (TokenStorageService)

### Configuration 패턴
새 xcconfig 키 추가 시:
1. `Config/Secrets.xcconfig`에 키 추가
2. `Info.plist`에 항목 추가
3. `Configuration.swift`에 `static var` 추가

## Conventions
- 싱글톤 패턴: `static let shared` 사용
- 에러는 커스텀 `Error` enum으로 정의해서 `throw` *(현재 KeychainHelper 미적용 — 추후 개선 대상)*
- Combine 퍼블리셔 반환 시 `AnyPublisher`로 타입 지우기 필수
- Firebase / GitHub API 등 외부 의존성 처리는 `Network/` 레이어에서 담당 *(Core는 순수 유틸리티만)*

## DO NOT
- `import SwiftUI` 금지
- View / ViewModel import 금지
- 특정 Scene 로직 포함 금지
