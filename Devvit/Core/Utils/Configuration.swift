//
//  Configuration.swift
//  Devvit
//

import Foundation

enum Configuration {
    static var githubToken: String {
        guard let token = Bundle.main.infoDictionary?["GITHUB_TOKEN"] as? String,
              !token.isEmpty else {
            fatalError("GITHUB_TOKEN이 Info.plist에 없습니다. Secrets.xcconfig를 확인해주세요.")
        }
        return token
    }
}
