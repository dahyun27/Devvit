//
//  LoginViewModel.swift
//  Devvit
//
//  Created by 하다현 on 1/19/26.
//

import Foundation
import Combine
import AuthenticationServices

class LoginViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private let coordinator: LoginCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(coordinator: LoginCoordinator) {
        self.coordinator = coordinator
        bindAuthService()
    }
    
    // AuthService의 로그인 상태를 구독 (Combine)
    private func bindAuthService() {
        authService.$isUserLoggedIn
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoggedIn in
                if isLoggedIn {
                    self?.coordinator.navigate(to: .home)
                }
            }
            .store(in: &cancellables)
    }
    
    func handleAppleLoginSuccess(credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        authService.signInToFirebase(credential: credential)
        // 로딩 해제는 AuthService의 상태 변화나 완료 핸들러에서 처리 (여기서는 단순화)
        // 실제로는 AuthService에 completion handler를 추가하거나 상태를 더 세분화하는 것이 좋습니다.
    }
    
    func handleAppleLoginError(_ error: Error) {
        errorMessage = "애플 로그인 실패: \(error.localizedDescription)"
        isLoading = false
    }
    
    func tappedGithubLogin() {
        // 깃허브 로그인 로직 호출 (AuthService에 구현 필요)
        print("GitHub 로그인 시도")
    }
}
