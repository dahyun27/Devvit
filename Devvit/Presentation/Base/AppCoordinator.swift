//
//  AppCoordinator.swift
//  Devvit
//
//  Created by 하다현 on 1/25/26.
//

import SwiftUI
import Combine

enum AppFlow {
//    case splash
//    case onboarding  // 온보딩 화면
    case login       // 로그인 화면
    case home       // 메인 화면
}

class AppCoordinator: Coordinator {
    // MARK: - Published Properties
    
    /// 현재 보여줄 화면 상태
    /// SwiftUI가 이 값을 관찰하고, 변경되면 자동으로 화면 전환
    @Published var currentFlow: AppFlow = .login
    
    // MARK: - Properties
    @Published var childCoordinators: [any Coordinator] = []
    
    private let authService = AuthService.shared
    private let tokenStorageService = TokenStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        bindAuthService()
    }
    
    func start() {
        // 앱 시작 시 초기 상태 결정
        if authService.isUserLoggedIn {
            showHome()
        } else {
            showLogin()
        }
    }
    
    // MARK: - Bindings
    private func bindAuthService() {
        // 로그인 상태 변화 감지
        authService.$isUserLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in  // 값 변화 감지
                guard let self = self else { return }
                
                isLoggedIn ? self.showHome() : self.showLogin()
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation
    
    /// 온보딩 완료 여부 확인 후 적절한 화면으로 이동
    private func checkOnboardingAndNavigate() {
        let tokenStorage = TokenStorageService.shared
        
        if tokenStorage.isOnboardingCompleted() {
            // 온보딩 완료 → 메인 화면
            print("✅ [AppCoordinator] 온보딩 완료됨 → 메인 화면")
            currentFlow = .home
        } else {
            // 온보딩 미완료 → 온보딩 화면
            print("⚠️ [AppCoordinator] 온보딩 미완료 → 온보딩 화면")
//            showOnboarding()
        }
    }
    
    /// 로그인 화면 표시
    func showLogin() {
        print("🔐 [AppCoordinator] 로그인 화면 표시")
        currentFlow = .login
        
        // 홈 관련 코디네이터가 있다면 정리
        childCoordinators.removeAll()
        
        let loginCoordinator = LoginCoordinator()
        loginCoordinator.start()
    }
    
    /// 온보딩 화면 표시
//    func showOnboarding() {
//        print("📋 [AppCoordinator] 온보딩 화면 표시")
//        
//        // 기존 child coordinator 정리
//        childCoordinators.removeAll()
//        
//        // OnboardingCoordinator 생성
//        let onboardingCoordinator = OnboardingCoordinator()
//        
//        // 온보딩 완료 시 호출될 클로저 설정
//        onboardingCoordinator.onFinish = { [weak self] in
//            guard let self = self else { return }
//            print("✅ [OnboardingCoordinator] 온보딩 완료 → 메인 화면")
//            
//            // 사용 완료된 Coordinator 제거
//            self.removeChild(onboardingCoordinator)
//            
//            // 메인 화면으로 전환
//            self.showMain()
//        }
//        
//        // childCoordinators 배열에 추가
//        childCoordinators.append(onboardingCoordinator)
//        
//        // Coordinator 시작
//        onboardingCoordinator.start()
//        
//        // 화면 상태 변경 → SwiftUI가 자동으로 OnboardingView 표시
//        currentFlow = .onboarding
//    }
//    
    /// 메인 화면 표시
    func showHome() {
        print("🏠 [AppCoordinator] 메인 화면 표시")
        
        // 기존 child coordinator 정리
        // (메인 화면은 별도 Coordinator 없이 직접 관리)
        childCoordinators.removeAll()
        
        // 화면 상태 변경 → SwiftUI가 자동으로 MainTab View 표시
        currentFlow = .home
    }
}
