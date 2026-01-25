//
//  AuthService.swift
//  Devvit
//
//  Created by 하다현 on 1/18/26.
//

import Foundation
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
    private var cancellables = Set<AnyCancellable>()
    
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
        } else {
            self.isUserLoggedIn = false
            print("❌ 로그인 필요")
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
            self.saveUserData(
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
            
            // UserDefaults 삭제
            UserDefaults.standard.removeObject(forKey: "userUID")
            UserDefaults.standard.removeObject(forKey: "appleUserID")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "userName")
            
            print("✅ 로그아웃 완료")
        } catch {
            print("❌ 로그아웃 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 사용자 데이터 저장
extension AuthService {
    
    /// Firestore와 UserDefaults에 사용자 정보 저장
    private func saveUserData(
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
        
        // 2) Firestore에 저장 (merge: true는 기존 데이터 유지)
        db.collection("users").document(firebaseUID).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 완료!")
            }
        }
        
        // 3) UserDefaults에도 저장 (빠른 접근용)
        UserDefaults.standard.set(firebaseUID, forKey: "userUID")
        UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(displayName.isEmpty ? "개발자" : displayName, forKey: "userName")
        
        print("💾 로컬 저장 완료!")
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
        
        // 에러를 ViewModel에 전달하려면 NotificationCenter나 Combine Subject 사용
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .appleLoginDidFail,
                object: nil,
                userInfo: ["error": error]
            )
        }
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

// MARK: - Notification Names
extension Notification.Name {
    static let appleLoginDidFail = Notification.Name("appleLoginDidFail")
}



//import Foundation
//import FirebaseAuth
//import FirebaseFirestore
//import AuthenticationServices
//import CryptoKit
//import Combine
//
//class AuthService: NSObject, ObservableObject {
//    static let shared = AuthService()
//    var currentNonce: String?
//    
//    // 로그인 성공 여부를 알리는 변수 (뷰가 이걸 보고 화면을 바꿈)
//    @Published var isUserLoggedIn: Bool = false
//    @Published var currentUser: User?
//    
//    override init() {
//        // 앱 켤 때 이미 로그인된 상태인지 확인
//        if let user = Auth.auth().currentUser {
//            self.currentUser = user
//            self.isUserLoggedIn = true
//            print("✅ 기존 로그인 유저 확인: \(user.uid)")
//        }
//    }
//    // 2. 애플 로그인 성공 후, 받은 데이터로 Firebase에 로그인 요청하는 함수
//    func signInToFirebase(credential: ASAuthorizationAppleIDCredential) {
//        guard let nonce = currentNonce else {
//            print("Error: Nonce가 없습니다.")
//            return
//        }
//        
//        // 애플이 준 ID 토큰을 가져옴
//        guard let appleIDToken = credential.identityToken else {
//            print("Error: 애플 토큰을 가져오지 못했습니다.")
//            return
//        }
//        
//        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//            print("Error: 토큰 문자열 변환 실패")
//            return
//        }
//        
//        let userIdentifier = credential.user  // 고유 ID
//        let email = credential.email  // 이메일 (첫 로그인 때만)
//        let fullName = credential.fullName  // 이름 (첫 로그인 때만)
//        
//        let displayName = [fullName?.familyName, fullName?.givenName]
//            .compactMap { $0 }
//            .joined(separator: " ")
//        
//        print("애플 로그인 정보:")
//        print("User ID: \(userIdentifier)")
//        print("Email: \(email ?? "없음")")
//        print("Name: \(displayName.isEmpty ? "없음" : displayName)")
//        
//        // 3. Firebase용 인증 정보(Credential) 생성
//        let firebaseCredential = OAuthProvider.appleCredential(
//            withIDToken: idTokenString,
//            rawNonce: nonce,
//            fullName: fullName
//        )
//        
//        // 4. Firebase에 로그인
//        Auth.auth().signIn(with: firebaseCredential) { [weak self] (authResult, error) in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("❌ Firebase 로그인 실패: \(error.localizedDescription)")
//                return
//            }
//            guard let user = authResult?.user else {
//                print("❌ 사용자 정보를 가져올 수 없습니다.")
//                return
//            }
//            
//            // 로그인 성공!
//            print("🎉 Firebase 로그인 성공! User ID: \(user.uid)")
//            
//            self.saveUserData(
//                firebaseUID: user.uid,
//                email: email ?? user.email ?? "",
//                displayName: displayName,
//                appleUserID: userIdentifier
//            )
//            
//            // 메인 스레드에서 UI 업데이트
//            DispatchQueue.main.async {
//                self.currentUser = user
//                self.isUserLoggedIn = true
//            }
//        }
//    }
//    
//    // 로그아웃 기능 (테스트용)
//    func signOut() {
//        do {
//            try Auth.auth().signOut()
//            DispatchQueue.main.async {
//                self.isUserLoggedIn = false
//                self.currentUser = nil
//            }
//        } catch {
//            print("로그아웃 에러: \(error)")
//        }
//    }
//}
//
//// MARK: - 사용자 데이터 저장
//extension AuthService {
//    
//    // Firestore와 UserDefaults에 사용자 정보 저장
//    private func saveUserData(
//        firebaseUID: String,
//        email: String,
//        displayName: String,
//        appleUserID: String
//    ) {
//        let db = Firestore.firestore()
//        
//        // 1) Firestore에 저장할 데이터 구조
//        let userData: [String: Any] = [
//            "uid": firebaseUID,
//            "email": email,
//            "name": displayName.isEmpty ? "개발자" : displayName,
//            "appleUserID": appleUserID,
//            "createdAt": FieldValue.serverTimestamp(),
//            "lastLoginAt": FieldValue.serverTimestamp()
//        ]
//        
//        // 2) Firestore에 저장 (merge: true는 기존 데이터 유지)
//        db.collection("users").document(firebaseUID).setData(userData, merge: true) { error in
//            if let error = error {
//                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
//            } else {
//                print("✅ Firestore 저장 완료!")
//            }
//        }
//        
//        // 3) UserDefaults에도 저장 (빠른 접근용)
//        UserDefaults.standard.set(firebaseUID, forKey: "userUID")
//        UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
//        UserDefaults.standard.set(email, forKey: "userEmail")
//        UserDefaults.standard.set(displayName.isEmpty ? "개발자" : displayName, forKey: "userName")
//        
//        print("💾 로컬 저장 완료!")
//    }
//}
//
//// MARK: - 애플 로그인 보안(Nonce) 관련 헬퍼 함수
//extension AuthService {
//    // 랜덤 문자열(Nonce) 생성 함수
//    func startSignInWithAppleFlow() -> String {
//        let nonce = randomNonceString()
//        currentNonce = nonce
//        return sha256(nonce)
//    }
//    
//    private func randomNonceString(length: Int = 32) -> String {
//        precondition(length > 0)
//        var randomBytes = [UInt8](repeating: 0, count: length)
//        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
//        if errorCode != errSecSuccess {
//            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
//        }
//        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        let nonce = randomBytes.map { charset[Int($0) % charset.count] }
//        return String(nonce)
//    }
//    
//    private func sha256(_ input: String) -> String {
//        let inputData = Data(input.utf8)
//        let hashedData = SHA256.hash(data: inputData)
//        let hashString = hashedData.compactMap {
//            return String(format: "%02x", $0)
//        }.joined()
//        return hashString
//    }
//}
//
//
//extension AuthService: ASAuthorizationControllerDelegate {
//    func authorizationController(
//        controller: ASAuthorizationController,
//        didCompleteWithAuthorization authorization: ASAuthorization
//    ) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            signInToFirebase(credential: appleIDCredential)
//        }
//    }
//    
//    func authorizationController(
//        controller: ASAuthorizationController,
//        didCompleteWithError error: Error
//    ) {
//        print("❌ 애플 로그인 실패: \(error.localizedDescription)")
//    }
//}


