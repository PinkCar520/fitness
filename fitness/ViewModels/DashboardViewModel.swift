import Foundation
import SwiftUI

// 1. Model for a single dashboard card
struct DashboardCard: Identifiable, Codable, Hashable {
    let id: CardType
    var name: String
    var isVisible: Bool = true

    enum CardType: String, Codable, CaseIterable {
        case fitnessRings = "FitnessRings"
        case goalProgress = "GoalProgress"
        case stepsAndDistance = "StepsAndDistance"
        case monthlyChallenge = "MonthlyChallenge"
        case recentActivity = "RecentActivity"
        case historyList = "HistoryList"
    }
}

// 2. View Model to manage the cards
class DashboardViewModel: ObservableObject {
    @Published var cards: [DashboardCard] = []
    private let userDefaultsKey = "dashboard_card_order"

    init() {
        loadCardOrder()
    }

    // Computed properties to easily get filtered lists
    var visibleCards: [DashboardCard] {
        cards.filter { $0.isVisible }
    }

    var hiddenCards: [DashboardCard] {
        cards.filter { !$0.isVisible }
    }

    func moveCard(from source: IndexSet, to destination: Int) {
        var visibleCardIDs = visibleCards.map { $0.id }
        visibleCardIDs.move(fromOffsets: source, toOffset: destination)

        // Sort the main cards array: visible cards first, in their new order, then hidden cards
        cards.sort { (card1, card2) -> Bool in
            let isVisible1 = visibleCardIDs.contains(card1.id)
            let isVisible2 = visibleCardIDs.contains(card2.id)

            if isVisible1 && !isVisible2 {
                return true
            }
            if !isVisible1 && isVisible2 {
                return false
            }
            if !isVisible1 && !isVisible2 {
                return false // Keep original relative order of hidden items
            }

            // Both are visible, sort according to the new explicit order
            if let index1 = visibleCardIDs.firstIndex(of: card1.id),
               let index2 = visibleCardIDs.firstIndex(of: card2.id) {
                return index1 < index2
            }

            return false
        }
        
        saveCardOrder()
    }
    
    func toggleVisibility(for card: DashboardCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index].isVisible.toggle()
        saveCardOrder()
    }

    func saveCardOrder() {
        if let encoded = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadCardOrder() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([DashboardCard].self, from: data) {
            self.cards = decoded
            addNewCardTypes(to: &self.cards)
        } else {
            self.cards = defaultCards
        }
    }
    
    private var defaultCards: [DashboardCard] {
        [
            DashboardCard(id: .fitnessRings, name: "健身圆环"),
            DashboardCard(id: .goalProgress, name: "目标进度"),
            DashboardCard(id: .stepsAndDistance, name: "步数与距离"),
            DashboardCard(id: .monthlyChallenge, name: "每月挑战"),
            DashboardCard(id: .recentActivity, name: "最近活动"),
            DashboardCard(id: .historyList, name: "历史记录", isVisible: false) // Hidden by default
        ]
    }
    
    private func addNewCardTypes(to existingCards: inout [DashboardCard]) {
        let allTypes = DashboardCard.CardType.allCases
        let existingTypes = Set(existingCards.map { $0.id })
        
        for type in allTypes {
            if !existingTypes.contains(type) {
                if let newCard = defaultCards.first(where: { $0.id == type }) {
                    existingCards.append(newCard)
                }
            }
        }
    }
}
