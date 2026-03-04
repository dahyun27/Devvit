//
//  DevvitApp.swift
//  Devvit
//
//  Created by 하다현 on 1/13/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure() // 파이어베이스 시동 걸기
        print("🔥 Firebase 초기화 완료")
        return true
    }
}

@main
struct DevvitApp: App {
    // 앱 델리게이트 연결
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch appCoordinator.currentFlow {
                case .login:
                    // LoginCoordinator 주입
                    let loginCoordinator = LoginCoordinator()
                    LoginView(viewModel: LoginViewModel(coordinator: loginCoordinator))
                    
                case .home:
                    MainTabView()
                }
            }
            .onAppear {
                appCoordinator.start()
                TokenStorageService.shared.checkFirstLaunch()
            }
        }
    }
    
    private func createLoginView() -> some View {
        let coordinator = LoginCoordinator()
        
        // Coordinator의 onFinish는 AuthService가 자동으로 처리
        // (AuthService.$isUserLoggedIn 변경 → DevvitApp이 자동으로 HomeView로 전환)
        coordinator.start()
        
        let viewModel = LoginViewModel(coordinator: coordinator)
        return LoginView(viewModel: viewModel)
    }
}
