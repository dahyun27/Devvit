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
    
    // AuthService의 로그인 상태를 구독
    private func bindAuthService() {
        authService.$isUserLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if isLoggedIn {
                    print("✅ 로그인 성공 → 홈 화면 이동")
                    self.coordinator.navigate(to: .home)
                }
            }
            .store(in: &cancellables)
    }
    
    func handleAppleLogin() {
        print("🍎 Apple 로그인 시작")
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = authService.startSignInWithAppleFlow()
        request.nonce = nonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = authService
        authorizationController.performRequests()
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
