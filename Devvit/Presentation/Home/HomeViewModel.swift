//
//  HomeViewModel.swift
//  Devvit
//
//  Created by 하다현 on 2/28/26.
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - Models

struct ActivityRecord: Identifiable {
    let id = UUID()
    let type: ActivityType
    var count: Int
    var isCompletedToday: Bool
}

enum ActivityType {
    case commit
    case blog
    case algorithm

    var title: String {
        switch self {
        case .commit:    return "커밋 기록"
        case .blog:      return "블로그 기록"
        case .algorithm: return "알고리즘 풀이 기록"
        }
    }

    var iconName: String {
        switch self {
        case .commit:    return "point.3.connected.trianglepath.dotted"
        case .blog:      return "text.alignleft"
        case .algorithm: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - ViewModel

class HomeViewModel: ObservableObject {
    @Published var currentStreak: Int = 35
    @Published var selectedMonth: Date = Date()
    @Published var activityData: [Date: Int] = [:]
    @Published var todayActivities: [ActivityRecord] = []
    @Published var lastUpdated: Date = Date()

    private let authService = AuthService.shared
    private let tokenStorage = TokenStorageService.shared
    private let coordinator: HomeCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
        loadData()
    }

    func loadData() {
        currentStreak = max(tokenStorage.getCurrentStreak(), 35)
        generateMockActivityData()
        loadTodayActivities()
    }

    // MARK: - Calendar

    func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    func activityLevel(for date: Date) -> Int {
        let key = Calendar.current.startOfDay(for: date)
        return activityData[key] ?? 0
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isCurrentMonth(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: date) == cal.component(.month, from: selectedMonth)
            && cal.component(.year, from: date) == cal.component(.year, from: selectedMonth)
    }

    func monthTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: selectedMonth)
    }

    func moveToPreviousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }

    func moveToNextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }

    func timeAgoString() -> String {
        let minutes = Int(Date().timeIntervalSince(lastUpdated) / 60)
        if minutes < 1 { return "방금 전" }
        return "\(minutes)분 전"
    }

    func activitySubtitle(for record: ActivityRecord) -> String {
        !record.isEmpty ? "오늘 \(record.count)개 기록됨" : "아직 기록 없음"
    }

    // MARK: - Mock Data

    private func generateMockActivityData() {
        let calendar = Calendar.current
        let today = Date()
        var data: [Date: Int] = [:]

        for offset in 0..<35 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                data[calendar.startOfDay(for: date)] = Int.random(in: 1...4)
            }
        }
        for offset in 35..<60 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                data[calendar.startOfDay(for: date)] = Int.random(in: 0...4)
            }
        }
        activityData = data
    }

    private func loadTodayActivities() {
        todayActivities = [
            ActivityRecord(type: .commit, count: 1, isCompletedToday: true),
            ActivityRecord(type: .blog, count: 0, isCompletedToday: false),
            ActivityRecord(type: .algorithm, count: 0, isCompletedToday: false)
        ]
    }

    func signOut() {
        authService.signOut()
    }
}
