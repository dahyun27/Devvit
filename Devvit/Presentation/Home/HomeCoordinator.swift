//
//  HomeCoordinator.swift
//  Devvit
//
//  Created by 하다현 on 2/28/26.
//

import SwiftUI
import Combine

enum HomeRoute {
    case profile
}

class HomeCoordinator: Coordinator {
    let id = UUID()
    var onFinish: (() -> Void)?
    @Published var path: [HomeRoute] = []

    func start() {}

    func navigate(to route: HomeRoute) {
        switch route {
        case .profile:
            break
        }
    }
}
