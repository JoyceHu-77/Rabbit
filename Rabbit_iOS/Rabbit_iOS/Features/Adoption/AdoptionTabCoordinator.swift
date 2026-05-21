//
//  AdoptionTabCoordinator.swift
//  Rabbit_iOS — 爱兔领养子 Tab 路由（@Observable 引用类型，真机改 section 更可靠）
//

import Observation

enum AdoptionSection: Int, CaseIterable {
    case process
    case storybook
    case adoptionCommunity
    case rabbitCommunity

    var title: String {
        switch self {
        case .process: return "领养流程"
        case .storybook: return "兔兔故事书"
        case .adoptionCommunity: return "领养社区"
        case .rabbitCommunity: return "爱兔社区"
        }
    }
}

@Observable @MainActor
final class AdoptionTabCoordinator {
    var section: AdoptionSection = .process

    func openAdoptionProcess() {
        section = .process
    }
}
