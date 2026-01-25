//
//  Coordinator.swift
//  Devvit
//
//  Created by 하다현 on 1/25/26.
//

import Foundation

protocol Coordinator: ObservableObject, Identifiable {
    var id: UUID { get }
    func start()
}

// 기본 구현 (id 자동 생성)
extension Coordinator {
    var id: UUID { UUID() }
}
