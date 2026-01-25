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
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // 파이어베이스 시동 걸기
        print("🔥 Firebase 초기화 완료")
        return true
    }
}

@main
struct DevvitApp: App {
    // 앱 델리게이트 연결
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            // 로그인 상태에 따라 화면을 교체합니다.
            if authService.isUserLoggedIn {
                HomeView() // 로그인 되면 보여줄 메인 화면
                    .environmentObject(authService) // 필요하다면 서비스 주입
            } else {
                createLoginView()
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

// (임시) 홈 뷰 - 로그인이 잘 되었는지 확인용
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 환영합니다!")
                .font(.largeTitle)
                .bold()
            
            Text("Devvit 홈 화면")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("로그인 정보")
                    .font(.headline)
                
                Text("UID: \(authService.currentUser?.uid ?? "Unknown")")
                    .font(.caption)
                
                Text("Email: \(authService.currentUser?.email ?? "Unknown")")
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button(action: {
                authService.signOut()
            }) {
                Text("로그아웃")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
