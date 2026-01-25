//
//  LoginCoordinator.swift
//  Devvit
//
//  Created by 하다현 on 1/19/26.
//

import SwiftUI
import Combine

// 화면 전환 이벤트를 정의
enum LoginRoute {
    case home // 로그인 성공 시 홈으로
}

class LoginCoordinator: ObservableObject {
    
    var onFinish: (() -> Void)?
    
    func start() {
        // 초기화 로직 (필요 시)
    }
    
    func navigate(to route: LoginRoute) {
        switch route {
        case .home:
            // 실제 앱에서는 여기서 AppCoordinator에게 알리거나 RootView를 교체합니다.
            onFinish?()
        }
    }
}
