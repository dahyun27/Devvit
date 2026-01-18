//
//  LoginView.swift
//  Devvit
//
//  Created by 하다현 on 1/18/26.
//

import SwiftUI
import AuthenticationServices


struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 15) {
                    Image(systemName: "hare.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    
                    Text("Devvit")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Text("개발자의 성장을 기록하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    
                    // ✨ 진짜 애플 로그인 버튼
                    SignInWithAppleButton(
                        onRequest: { request in
                            // 1. 요청을 보낼 때 보안 암호(Nonce)를 같이 실어 보냄
                            let nonce = authService.startSignInWithAppleFlow()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = nonce
                        },
                        onCompletion: { result in
                            // 2. 결과가 돌아왔을 때 처리
                            switch result {
                            case .success(let authorization):
                                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    // 3. AuthService에게 Firebase 로그인 처리를 맡김
                                    authService.signInToFirebase(credential: appleIDCredential)
                                }
                            case .failure(let error):
                                print("애플 로그인 실패: \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black) // 버튼 스타일 (검정)
                    .frame(height: 50) // 높이 설정
                    .cornerRadius(12)
                    
                    // 깃허브 버튼 (아직은 껍데기)
                    Button(action: {
                        print("깃허브 로그인 클릭")
                    }) {
                        HStack {
                            Text("GH")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .clipShape(Circle())
                            Text("GitHub로 계속하기")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}


#Preview {
    LoginView()
}
