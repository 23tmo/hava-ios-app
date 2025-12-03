import Foundation
import SwiftUI

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let avatarURL: String?
    let expertise: [String]
    let stats: UserStats
    var friendSince: Date?
}

struct UserStats: Codable {
    let questionsAnswered: Int
    let friendsCount: Int
    var recommendationsGiven: Int
    var recommendationsReceived: Int
    var categoriesHelped: [String: Int]
}

struct Question: Identifiable, Codable {
    let id: String
    let userId: String
    let text: String
    let location: String
    let timestamp: Date
    let visibility: QuestionVisibility
    let selectedFriends: [String]
    var urgencyLevel: UrgencyLevel = .normal
    var isActive: Bool {
        let daysSince = Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
        return daysSince < 7
    }
}

enum UrgencyLevel: String, Codable {
    case urgent = "urgent"
    case weekend = "weekend"
    case normal = "normal"
    
    var color: Color {
        switch self {
        case .urgent: return .red
        case .weekend: return .orange
        case .normal: return .blue
        }
    }
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .weekend: return "Weekend Plans"
        case .normal: return "Normal"
        }
    }
}

enum QuestionVisibility: String, Codable {
    case friendsOnly
    case friendsOfFriends
}

struct Recommendation: Identifiable, Codable {
    let id: String
    let questionId: String
    let userId: String
    let text: String
    let address: String?
    let phoneNumber: String?
    let website: String?
    var likes: Int
    let timestamp: Date
    var tags: [String]
    var timesUsed: Int
    var lastUsedAt: Date?
    var isSaved: Bool = false
    var mapPreviewURL: String?
    var extractedURL: String?
    var extractedPreview: String?
}

struct FeedItem: Identifiable {
    let id: String
    let question: Question
    let recommendations: [Recommendation]
    let user: User
    var isActiveRequest: Bool {
        question.isActive && recommendations.count < 3
    }
}

struct Reward: Identifiable, Codable {
    let id: String
    let recommendationId: String
    let questionId: String
    let recipientUserId: String
    let message: String
    let timestamp: Date
}

struct Collection: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    var recommendationIds: [String]
    let createdAt: Date
}

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let earnedAt: Date
}

struct UserStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    var weeklyCount: Int
}

enum FeedSortOption: String, CaseIterable {
    case newest = "Newest"
    case mostRelevant = "Most relevant to me"
    case inMyArea = "In my area"
    case byUrgency = "By urgency"
} 