//
//  TokenStorageService.swift
//  Devvit
//
//  Created by 하다현 on 1/25/26.
//

import Foundation

final class TokenStorageService {
    static let shared = TokenStorageService()
    
    // MARK: - Keys
    private let launchedKey = "Devvit_Launched"
    
    // Firebase 관련
    private let firebaseUIDKey = "Devvit_FirebaseUID"
    
    // Apple 로그인 관련
    private let appleUserIdKey = "Devvit_AppleUserId"
    private let appleEmailKey = "Devvit_AppleEmail"
    private let appleFullNameKey = "Devvit_AppleFullName"
    
    // GitHub 로그인 관련
    private let githubUserIdKey = "Devvit_GitHubUserId"
    private let githubUsernameKey = "Devvit_GitHubUsername"
    private let githubEmailKey = "Devvit_GitHubEmail"
    
    // 프로필 관련
    private let userNicknameKey = "Devvit_UserNickname"
    private let userBioKey = "Devvit_UserBio"
    
    // 온보딩 관련
    private let onboardingCompletedKey = "Devvit_OnboardingCompleted"
    private let onboardingCompletedUserIdKey = "Devvit_OnboardingCompletedUserId"
    
    // 활동 관련
    private let lastActivityDateKey = "Devvit_LastActivityDate"
    private let currentStreakKey = "Devvit_CurrentStreak"
    
    private init() {}
    
    // MARK: - First Launch Check
    func checkFirstLaunch() {
        let isFirstLaunch = UserDefaults.standard.bool(forKey: launchedKey) == false
        
        print("📱 첫 실행 여부: \(isFirstLaunch)")
        
        if isFirstLaunch {
            clearAllData()
            UserDefaults.standard.set(true, forKey: launchedKey)
            print("✅ 첫 실행 초기화 완료")
        }
    }
    
    // MARK: - Firebase UID
    func saveFirebaseUID(_ uid: String) {
        UserDefaults.standard.set(uid, forKey: firebaseUIDKey)
        print("💾 Firebase UID 저장: \(uid)")
    }
    
    func getFirebaseUID() -> String? {
        return UserDefaults.standard.string(forKey: firebaseUIDKey)
    }
    
    private func clearFirebaseUID() {
        UserDefaults.standard.removeObject(forKey: firebaseUIDKey)
    }
    
    // MARK: - Apple Login Info
    func saveAppleUserInfo(userId: String, email: String?, fullName: String?) {
        UserDefaults.standard.set(userId, forKey: appleUserIdKey)
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: appleEmailKey)
        }
        
        if let fullName = fullName {
            UserDefaults.standard.set(fullName, forKey: appleFullNameKey)
        }
        
        print("💾 Apple 로그인 정보 저장")
        print("  - User ID: \(userId)")
        print("  - Email: \(email ?? "없음")")
        print("  - Name: \(fullName ?? "없음")")
    }
    
    func getAppleUserId() -> String? {
        return UserDefaults.standard.string(forKey: appleUserIdKey)
    }
    
    func getAppleEmail() -> String? {
        return UserDefaults.standard.string(forKey: appleEmailKey)
    }
    
    func getAppleFullName() -> String? {
        return UserDefaults.standard.string(forKey: appleFullNameKey)
    }
    
    private func clearAppleLoginInfo() {
        UserDefaults.standard.removeObject(forKey: appleUserIdKey)
        UserDefaults.standard.removeObject(forKey: appleEmailKey)
        UserDefaults.standard.removeObject(forKey: appleFullNameKey)
        print("🗑️ Apple 로그인 정보 삭제")
    }
    
    // MARK: - GitHub Login Info
    func saveGitHubUserInfo(userId: String, username: String?, email: String?) {
        UserDefaults.standard.set(userId, forKey: githubUserIdKey)
        
        if let username = username {
            UserDefaults.standard.set(username, forKey: githubUsernameKey)
        }
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: githubEmailKey)
        }
        
        print("💾 GitHub 로그인 정보 저장")
        print("  - User ID: \(userId)")
        print("  - Username: \(username ?? "없음")")
        print("  - Email: \(email ?? "없음")")
    }
    
    func getGitHubUserId() -> String? {
        return UserDefaults.standard.string(forKey: githubUserIdKey)
    }
    
    func getGitHubUsername() -> String? {
        return UserDefaults.standard.string(forKey: githubUsernameKey)
    }
    
    func getGitHubEmail() -> String? {
        return UserDefaults.standard.string(forKey: githubEmailKey)
    }
    
    private func clearGitHubLoginInfo() {
        UserDefaults.standard.removeObject(forKey: githubUserIdKey)
        UserDefaults.standard.removeObject(forKey: githubUsernameKey)
        UserDefaults.standard.removeObject(forKey: githubEmailKey)
        print("🗑️ GitHub 로그인 정보 삭제")
    }
    
    // MARK: - Profile Management
    func saveProfile(nickname: String, bio: String? = nil) {
        UserDefaults.standard.set(nickname, forKey: userNicknameKey)
        
        if let bio = bio {
            UserDefaults.standard.set(bio, forKey: userBioKey)
        }
        
        print("💾 프로필 저장: \(nickname)")
    }
    
    func getProfile() -> (nickname: String?, bio: String?) {
        let nickname = UserDefaults.standard.string(forKey: userNicknameKey)
        let bio = UserDefaults.standard.string(forKey: userBioKey)
        return (nickname, bio)
    }
    
    private func clearProfile() {
        UserDefaults.standard.removeObject(forKey: userNicknameKey)
        UserDefaults.standard.removeObject(forKey: userBioKey)
        print("🗑️ 프로필 정보 삭제")
    }
    
    // MARK: - Onboarding
    func saveOnboardingCompleted(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: onboardingCompletedKey)
        
        if completed, let userId = getFirebaseUID() {
            UserDefaults.standard.set(userId, forKey: onboardingCompletedUserIdKey)
            print("✅ 온보딩 완료 기록: userId=\(userId)")
        }
    }
    
    func isOnboardingCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }
    
    func clearOnboardingIfDifferentUser(currentUserId: String) {
        let savedUserId = UserDefaults.standard.string(forKey: onboardingCompletedUserIdKey)
        
        if let saved = savedUserId, saved != currentUserId {
            print("⚠️ 다른 계정 로그인 감지: \(saved) → \(currentUserId)")
            print("   온보딩 상태 초기화")
            clearOnboardingState()
        }
    }
    
    private func clearOnboardingState() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        UserDefaults.standard.removeObject(forKey: onboardingCompletedUserIdKey)
        print("🗑️ 온보딩 상태 초기화")
    }
    
    // MARK: - Activity Tracking
    func saveLastActivityDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastActivityDateKey)
    }
    
    func getLastActivityDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastActivityDateKey) as? Date
    }
    
    func saveCurrentStreak(_ streak: Int) {
        UserDefaults.standard.set(streak, forKey: currentStreakKey)
    }
    
    func getCurrentStreak() -> Int {
        return UserDefaults.standard.integer(forKey: currentStreakKey)
    }
    
    private func clearActivityData() {
        UserDefaults.standard.removeObject(forKey: lastActivityDateKey)
        UserDefaults.standard.removeObject(forKey: currentStreakKey)
        print("🗑️ 활동 데이터 삭제")
    }
    
    // MARK: - Clear Data Scenarios
    
    /// 로그아웃: 인증 정보만 삭제, 사용자 활동 기록은 유지
    func clearForLogout() {
        clearFirebaseUID()
        clearAppleLoginInfo()
        clearGitHubLoginInfo()
        
        print("🔓 로그아웃 완료")
        print("   → 삭제: 로그인 정보")
        print("   → 유지: 프로필, 온보딩, 활동 기록")
    }
    
    /// 회원 탈퇴: 모든 데이터 삭제
    func clearForWithdraw() {
        clearFirebaseUID()
        clearAppleLoginInfo()
        clearGitHubLoginInfo()
        clearProfile()
        clearOnboardingState()
        clearActivityData()
        
        print("🗑️ 회원 탈퇴 완료 - 모든 데이터 삭제")
    }
    
    /// 앱 재설치/초기화: 완전 삭제
    private func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("🗑️ 모든 UserDefaults 데이터 삭제")
    }
    
    // MARK: - Debug
    func printCurrentStatus() {
        print("=== 📊 TokenStorage 현재 상태 ===")
        print("Firebase UID: \(getFirebaseUID() ?? "nil")")
        print("Apple User ID: \(getAppleUserId() ?? "nil")")
        print("Apple Email: \(getAppleEmail() ?? "nil")")
        print("Apple Name: \(getAppleFullName() ?? "nil")")
        print("GitHub User ID: \(getGitHubUserId() ?? "nil")")
        print("GitHub Username: \(getGitHubUsername() ?? "nil")")
        print("Nickname: \(getProfile().nickname ?? "nil")")
        print("Bio: \(getProfile().bio ?? "nil")")
        print("Onboarding Completed: \(isOnboardingCompleted())")
        print("Current Streak: \(getCurrentStreak())")
        print("=====================================")
    }
}
