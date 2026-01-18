//
//  AuthService.swift
//  Devvit
//
//  Created by 하다현 on 1/18/26.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    var currentNonce: String?
    
    // 로그인 성공 여부를 알리는 변수 (뷰가 이걸 보고 화면을 바꿈)
    @Published var isUserLoggedIn: Bool = false
    
    init() {
        // 앱 켤 때 이미 로그인된 상태인지 확인
        if Auth.auth().currentUser != nil {
            self.isUserLoggedIn = true
        }
    }
    // 2. 애플 로그인 성공 후, 받은 데이터로 Firebase에 로그인 요청하는 함수
    func signInToFirebase(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            print("Error: Nonce가 없습니다.")
            return
        }
        
        // 애플이 준 ID 토큰을 가져옴
        guard let appleIDToken = credential.identityToken else {
            print("Error: 애플 토큰을 가져오지 못했습니다.")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Error: 토큰 문자열 변환 실패")
            return
        }
        
        let userIdentifier = credential.user  // 고유 ID
        let email = credential.email  // 이메일 (첫 로그인 때만)
        let fullName = credential.fullName  // 이름 (첫 로그인 때만)
        
        let displayName = [fullName?.familyName, fullName?.givenName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        print("애플 로그인 정보:")
        print("User ID: \(userIdentifier)")
        print("Email: \(email ?? "없음")")
        print("Name: \(displayName.isEmpty ? "없음" : displayName)")
        
        // 3. Firebase용 인증 정보(Credential) 생성
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: fullName
            )
        
        // 4. Firebase에 로그인
        Auth.auth().signIn(with: firebaseCredential) { (authResult, error) in
            if let error = error {
                print("Firebase 로그인 실패: \(error.localizedDescription)")
                return
            }
            
            // 로그인 성공!
            print("🎉 Firebase 로그인 성공! User ID: \(authResult?.user.uid ?? "")")
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                self.isUserLoggedIn = true
            }
        }
    }
}

// MARK: - 애플 로그인 보안(Nonce) 관련 헬퍼 함수
extension AuthService {
    // 랜덤 문자열(Nonce) 생성 함수
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { charset[Int($0) % charset.count] }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
