//
//  DevvitApp.swift
//  Devvit
//
//  Created by 하다현 on 1/13/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // 파이어베이스 시동 걸기
        return true
    }
}

@main
struct DevvitApp: App {
    // 앱 델리게이트 연결
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
