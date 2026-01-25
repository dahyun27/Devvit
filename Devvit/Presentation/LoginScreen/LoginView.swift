//
//  LoginView.swift
//  Devvit
//
//  Created by 하다현 on 1/18/26.
//

import SwiftUI
import AuthenticationServices


struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @ObservedObject var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color(hex: "111814")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 15) {
                    Image(.logoGrass)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding()
                    
                    Image(.logoLogin)
                        .scaledToFit()
                }

                Spacer()
                
                VStack(spacing: 15) {
                    
                    // GitHub 로그인 버튼
                    Button(action: {
//                        viewModel.handleGitHubLogin()
                    }) {
                        Image(.loginGithub)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                    
                    // Apple 로그인 버튼
                    Button(action: {
                        viewModel.handleAppleLogin()
                    }) {
                        Image(.loginApple)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            // 로딩 인디케이터
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        
        if let errorMessage = viewModel.errorMessage {
            VStack {
                Spacer()
                
                Text(errorMessage)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: viewModel.errorMessage)
        }
    }
}


#Preview {
    LoginView(viewModel: LoginViewModel(coordinator: LoginCoordinator()))
}
