//
//  AuthService.swift
//  Devvit
//
//  Created by 하다현 on 1/18/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import Combine

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    @Published var isUserLoggedIn: Bool = false
    @Published var currentUser: User?
    
    // MARK: - Private Properties
    var currentNonce: String?
    private let tokenStorage = TokenStorageService.shared
    let loginErrorSubject = PassthroughSubject<String, Never>()
    
    // MARK: - Init
    override init() {
        super.init()
        checkCurrentUser()
    }
    
    // MARK: - Check Current User
    private func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isUserLoggedIn = true
            print("✅ 기존 로그인 유저 확인: \(user.uid)")
            syncUserDataFromFirebase(user: user)
        } else {
            self.isUserLoggedIn = false
            print("❌ 로그인 필요")
        }
    }
    
    // MARK: - Sync User Data from Firebase
    private func syncUserDataFromFirebase(user: User) {
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Firestore 데이터 불러오기 실패: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                print("⚠️ Firestore에 사용자 데이터 없음")
                return
            }
            
            print("📥 Firebase에서 사용자 데이터 동기화")
            
            // Firebase UID 저장
            self.tokenStorage.saveFirebaseUID(user.uid)
            
            // Apple 정보 복원
            if let appleUserID = data["appleUserID"] as? String {
                let email = data["email"] as? String
                let name = data["name"] as? String
                
                self.tokenStorage.saveAppleUserInfo(
                    userId: appleUserID,
                    email: email,
                    fullName: name
                )
            }
            
            // 프로필 정보 복원
            if let name = data["name"] as? String {
                self.tokenStorage.saveProfile(nickname: name)
            }
            
            // 온보딩 상태 확인
            self.tokenStorage.clearOnboardingIfDifferentUser(currentUserId: user.uid)
            
            print("✅ 로컬 데이터 동기화 완료")
            self.tokenStorage.printCurrentStatus()
        }
    }
    
    // MARK: - Apple Sign In
    func signInToFirebase(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            print("❌ Error: Nonce가 없습니다.")
            return
        }
        
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("❌ Error: 애플 토큰을 가져오지 못했습니다.")
            return
        }
        
        // 사용자 정보 추출
        let userIdentifier = credential.user
        let email = credential.email
        let fullName = credential.fullName
        
        let displayName = [fullName?.familyName, fullName?.givenName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        print("📌 애플 로그인 정보:")
        print("  - User ID: \(userIdentifier)")
        print("  - Email: \(email ?? "없음")")
        print("  - Name: \(displayName.isEmpty ? "없음" : displayName)")
        
        // Firebase 인증
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: fullName
        )
        
        // Firebase 로그인
        Auth.auth().signIn(with: firebaseCredential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Firebase 로그인 실패: \(error.localizedDescription)")
                return
            }
            
            guard let user = authResult?.user else {
                print("❌ 사용자 정보를 가져올 수 없습니다.")
                return
            }
            
            print("🎉 Firebase 로그인 성공!")
            print("  - Firebase UID: \(user.uid)")
            
            // 사용자 정보 저장
            self.saveUserToFirestoreAndLocal(
                firebaseUID: user.uid,
                email: email ?? user.email ?? "",
                displayName: displayName,
                appleUserID: userIdentifier
            )
            
            // 상태 업데이트 (메인 스레드)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isUserLoggedIn = true
            }
        }
    }
    
    // MARK: - Logout
    func signOut() {
        do {
            try Auth.auth().signOut()
            
            // 상태 초기화
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isUserLoggedIn = false
            }
            tokenStorage.clearForLogout()
            print("✅ 로그아웃 완료")
        } catch {
            print("❌ 로그아웃 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 사용자 데이터 저장
extension AuthService {
    
    /// Firestore와 UserDefaults에 사용자 정보 저장
    private func saveUserToFirestoreAndLocal(
        firebaseUID: String,
        email: String,
        displayName: String,
        appleUserID: String
    ) {
        let db = Firestore.firestore()
        
        // 1) Firestore에 저장할 데이터 구조
        let userData: [String: Any] = [
            "uid": firebaseUID,
            "email": email,
            "name": displayName.isEmpty ? "개발자" : displayName,
            "appleUserID": appleUserID,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        var mergeData = userData
        if !email.isEmpty { mergeData["email"] = email }
        if !displayName.isEmpty { mergeData["name"] = displayName }
        
        // 2) Firestore에 저장 (merge: true는 기존 데이터 유지)
        db.collection("users").document(firebaseUID).setData(mergeData, merge: true) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 완료!")
            }
        }
        
        tokenStorage.saveFirebaseUID(firebaseUID)
        tokenStorage.saveAppleUserInfo(userId: appleUserID, email: email, fullName: displayName)
        if !displayName.isEmpty {
            tokenStorage.saveProfile(nickname: displayName)
        }
        
        print("💾 유저 데이터 동기화 완료 (Firestore + Local)")

    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 현재 앱의 가장 위에 있는 윈도우를 찾아서 반환
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            signInToFirebase(credential: appleIDCredential)
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("❌ 애플 로그인 실패: \(error.localizedDescription)")
        loginErrorSubject.send("Apple 로그인 취소 또는 실패")
    }
}

// MARK: - Nonce Generation
extension AuthService {
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
