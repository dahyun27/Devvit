//
//  HomeView.swift
//  Devvit
//
//  Created by 하다현 on 1/25/26.
//

import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @StateObject private var viewModel = HomeViewModel(coordinator: HomeCoordinator())

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }

            Text("친구")
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("친구")
                }

            Text("랭킹")
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("랭킹")
                }

            Text("프로필")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("프로필")
                }
        }
        .tint(Color(hex: "3DDC84"))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Home View

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color(hex: "0D1117")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HomeHeaderView(streak: viewModel.currentStreak)
                    ActivityCalendarView(viewModel: viewModel)
                    TodayRecordSection(viewModel: viewModel)
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Header

struct HomeHeaderView: View {
    let streak: Int

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text("나의 성장 기록")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Image(systemName: "info.circle")
                    .foregroundColor(Color(hex: "8B949E"))
                    .font(.system(size: 16))
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color(hex: "FF6B35"))
                    .font(.system(size: 14))

                Text("연속 기록 \(streak)일")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "1C2128"))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Activity Calendar

struct ActivityCalendarView: View {
    @ObservedObject var viewModel: HomeViewModel

    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            // 월 네비게이션
            HStack {
                Button(action: { viewModel.moveToPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                Text(viewModel.monthTitle())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.moveToNextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.horizontal, 8)

            // 요일 헤더
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "8B949E"))
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            level: viewModel.activityLevel(for: date),
                            isToday: viewModel.isToday(date),
                            isCurrentMonth: viewModel.isCurrentMonth(date)
                        )
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            // 범례 + 마지막 업데이트
            HStack(spacing: 4) {
                Text("적음")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B949E"))

                HStack(spacing: 3) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(activityColor(level: level))
                            .frame(width: 12, height: 12)
                    }
                }

                Text("많음")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B949E"))

                Spacer()

                Text("마지막 업데이트: \(viewModel.timeAgoString())")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B949E"))
            }
        }
        .padding(16)
        .background(Color(hex: "161B22"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "30363D"), lineWidth: 1)
        )
    }

    func activityColor(level: Int) -> Color {
        switch level {
        case 0:  return Color(hex: "21262D")
        case 1:  return Color(hex: "0E4429")
        case 2:  return Color(hex: "006D32")
        case 3:  return Color(hex: "26A641")
        case 4:  return Color(hex: "3DDC84")
        default: return Color(hex: "21262D")
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let level: Int
    let isToday: Bool
    let isCurrentMonth: Bool

    var body: some View {
        ZStack {
            if isCurrentMonth {
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellBackgroundColor)
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isToday ? Color.white.opacity(0.85) : Color.clear, lineWidth: 1.5)
                    )
                if isToday {
                    Text(dayText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(level >= 3 ? .black : .white)
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .frame(height: 36)
                Text(dayText)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "3D444D"))
            }
        }
    }

    private var dayText: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var cellBackgroundColor: Color {
        switch level {
        case 0:  return Color(hex: "21262D")
        case 1:  return Color(hex: "0E4429")
        case 2:  return Color(hex: "006D32")
        case 3:  return Color(hex: "26A641")
        case 4:  return Color(hex: "3DDC84")
        default: return Color(hex: "21262D")
        }
    }
}

// MARK: - Today Record Section

struct TodayRecordSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("오늘의 기록")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("오늘의 성장 기록")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(hex: "3DDC84"))
                    .cornerRadius(22)
                }
            }

            VStack(spacing: 10) {
                ForEach(viewModel.todayActivities) { record in
                    ActivityRecordCard(
                        record: record,
                        subtitle: viewModel.activitySubtitle(for: record)
                    )
                }
            }
        }
    }
}

// MARK: - Activity Record Card

struct ActivityRecordCard: View {
    let record: ActivityRecord
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "1C2128"))
                    .frame(width: 44, height: 44)

                Image(systemName: record.type.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "3DDC84"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.type.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8B949E"))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        record.isCompletedToday ? Color(hex: "3DDC84") : Color(hex: "3D444D"),
                        lineWidth: 1.5
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(
                        record.isCompletedToday ? Color(hex: "3DDC84") : Color(hex: "3D444D")
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "161B22"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    record.isCompletedToday ? Color(hex: "3DDC84").opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
