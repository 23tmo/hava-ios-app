import Foundation
import SwiftUI
import UserNotifications

class AppStore: ObservableObject {
    @Published var questions: [Question] = []
    @Published var recommendations: [Recommendation] = []
    @Published var rewards: [Reward] = []
    @Published var users: [User] = []
    @Published var currentUser: User
    @Published var collections: [Collection] = []
    @Published var badges: [Badge] = []
    @Published var userStreak: UserStreak = UserStreak(currentStreak: 0, longestStreak: 0, lastActivityDate: nil, weeklyCount: 0)
    @Published var savedRecommendations: Set<String> = []
    @Published var highContrastMode: Bool = false
    @Published var feedSortOption: FeedSortOption = .newest
    @Published var dynamicTypeSize: Double = 1.0
    
    func getUser(by id: String) -> User {
        return users.first { $0.id == id } ?? currentUser
    }
    
    init() {
        self.currentUser = User(
            id: "current_user",
            name: "Current User",
            avatarURL: nil,
            expertise: ["Food & Dining", "Home Services", "Healthcare"],
            stats: UserStats(
                questionsAnswered: 3,
                friendsCount: 4,
                recommendationsGiven: 5,
                recommendationsReceived: 8,
                categoriesHelped: ["Food & Dining": 2, "Healthcare": 1, "Home Services": 2]
            ),
            friendSince: Calendar.current.date(byAdding: .year, value: -2, to: Date())
        )
        
        self.users = [currentUser]
        
        loadSampleData()
        
        UserDefaults.standard.removeObject(forKey: "collections")
        UserDefaults.standard.removeObject(forKey: "badges")
        UserDefaults.standard.removeObject(forKey: "userStreak")
        
        createSampleCollections()
        createSampleBadges()
        createSampleStreak()
        initializeSavedRecommendations()
    }
    
    private func initializeSavedRecommendations() {
        let recsToSave = recommendations.prefix(4).map { $0.id }
        savedRecommendations = Set(recsToSave)
        
        for recId in recsToSave {
            if let index = recommendations.firstIndex(where: { $0.id == recId }) {
                var rec = recommendations[index]
                rec.isSaved = true
                recommendations[index] = rec
            }
        }
        saveRecommendations()
    }
    
    func createQuestion(text: String, location: String, selectedFriends: [String], visibility: QuestionVisibility) {
        let newQuestion = Question(
            id: UUID().uuidString,
            userId: currentUser.id,
            text: text,
            location: location,
            timestamp: Date(),
            visibility: visibility,
            selectedFriends: selectedFriends
        )
        
        questions.append(newQuestion)
        saveQuestions()
    }
    
    func addRecommendation(questionId: String, text: String, address: String?, phoneNumber: String?, website: String?) {
        let question = questions.first { $0.id == questionId }
        let autoTags = generateAutoTags(from: question?.text ?? "", recommendationText: text)
        
        let newRecommendation = Recommendation(
            id: UUID().uuidString,
            questionId: questionId,
            userId: currentUser.id,
            text: text,
            address: address,
            phoneNumber: phoneNumber,
            website: website,
            likes: 0,
            timestamp: Date(),
            tags: autoTags,
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        recommendations.append(newRecommendation)
        saveRecommendations()
        
        updateStreak()
        checkAndAwardBadges()
    }
    
    func quickAddRecommendation(questionId: String, text: String) {
        let question = questions.first { $0.id == questionId }
        let autoTags = generateAutoTags(from: question?.text ?? "", recommendationText: text)
        
        let newRecommendation = Recommendation(
            id: UUID().uuidString,
            questionId: questionId,
            userId: currentUser.id,
            text: text,
            address: nil,
            phoneNumber: nil,
            website: nil,
            likes: 0,
            timestamp: Date(),
            tags: autoTags,
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        recommendations.append(newRecommendation)
        saveRecommendations()
        
        updateStreak()
        checkAndAwardBadges()
        
        sendLocalNotificationToOwner(questionId: questionId, questionText: question?.text ?? "")
    }
    
    func markRecommendationUsed(_ recommendation: Recommendation, by userId: String) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            var updatedRecommendation = recommendation
            updatedRecommendation.timesUsed += 1
            updatedRecommendation.lastUsedAt = Date()
            recommendations[index] = updatedRecommendation
            saveRecommendations()
            
            let question = questions.first { $0.id == recommendation.questionId }
            let reward = Reward(
                id: UUID().uuidString,
                recommendationId: recommendation.id,
                questionId: recommendation.questionId,
                recipientUserId: recommendation.userId,
                message: "Your friend used your recommendation for \"\(question?.text ?? "")\"! 🎉",
                timestamp: Date()
            )
            rewards.append(reward)
            saveRewards()
            
            sendRewardNotification(reward: reward)
        }
    }
    
    func generateAutoTags(from questionText: String, recommendationText: String) -> [String] {
        let combinedText = (questionText + " " + recommendationText).lowercased()
        var tags: [String] = []
        
        let tagKeywords: [String: String] = [
            "restaurant": "Food & Dining",
            "food": "Food & Dining",
            "eat": "Food & Dining",
            "dining": "Food & Dining",
            "cafe": "Food & Dining",
            "dentist": "Healthcare",
            "doctor": "Healthcare",
            "medical": "Healthcare",
            "health": "Healthcare",
            "plumber": "Home Services",
            "electrician": "Home Services",
            "contractor": "Home Services",
            "repair": "Home Services",
            "mechanic": "Auto",
            "car": "Auto",
            "auto": "Auto",
            "beauty": "Beauty & Wellness",
            "salon": "Beauty & Wellness",
            "spa": "Beauty & Wellness",
            "fitness": "Fitness",
            "gym": "Fitness",
            "travel": "Travel",
            "hotel": "Travel",
            "education": "Education",
            "school": "Education",
            "legal": "Legal",
            "lawyer": "Legal"
        ]
        
        for (keyword, tag) in tagKeywords {
            if combinedText.contains(keyword) && !tags.contains(tag) {
                tags.append(tag)
            }
        }
        
        return tags.isEmpty ? ["General"] : tags
    }
    
    private func sendLocalNotificationToOwner(questionId: String, questionText: String) {
        let question = questions.first { $0.id == questionId }
        if let question = question, currentUser.id != question.userId {
            let content = UNMutableNotificationContent()
            content.title = "You got a new recommendation!"
            content.body = "Someone responded to your question: \"\(questionText)\""
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
    private func sendRewardNotification(reward: Reward) {
        if reward.recipientUserId == currentUser.id {
            let content = UNMutableNotificationContent()
            content.title = "🎉 Your recommendation was used!"
            content.body = reward.message
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
    func likeRecommendation(_ recommendation: Recommendation) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            var updatedRecommendation = recommendation
            updatedRecommendation.likes += 1
            recommendations[index] = updatedRecommendation
            saveRecommendations()
        }
    }
    
    private func loadSampleData() {
        loadScreenshotUsers()
        
        UserDefaults.standard.removeObject(forKey: "questions")
        UserDefaults.standard.removeObject(forKey: "recommendations")
        UserDefaults.standard.removeObject(forKey: "rewards")
        
        loadScreenshotData()
    }
    
    private func loadScreenshotUsers() {
        let now = Date()
        let calendar = Calendar.current
        
        let sarah = User(
            id: "sarah_chen",
            name: "Sarah Chen",
            avatarURL: nil,
            expertise: ["Healthcare", "Beauty & Wellness"],
            stats: UserStats(
                questionsAnswered: 8,
                friendsCount: 24,
                recommendationsGiven: 12,
                recommendationsReceived: 15,
                categoriesHelped: ["Healthcare": 5, "Beauty & Wellness": 7]
            ),
            friendSince: calendar.date(byAdding: .year, value: -3, to: now)
        )
        
        let mike = User(
            id: "mike_johnson",
            name: "Mike Johnson",
            avatarURL: nil,
            expertise: ["Home Services", "Auto", "Food & Dining"],
            stats: UserStats(
                questionsAnswered: 15,
                friendsCount: 32,
                recommendationsGiven: 20,
                recommendationsReceived: 18,
                categoriesHelped: ["Home Services": 8, "Auto": 6, "Food & Dining": 6]
            ),
            friendSince: calendar.date(byAdding: .year, value: -5, to: now)
        )
        
        let alex = User(
            id: "alex_martinez",
            name: "Alex Martinez",
            avatarURL: nil,
            expertise: ["Food & Dining", "Travel"],
            stats: UserStats(
                questionsAnswered: 12,
                friendsCount: 28,
                recommendationsGiven: 18,
                recommendationsReceived: 14,
                categoriesHelped: ["Food & Dining": 10, "Travel": 8]
            ),
            friendSince: calendar.date(byAdding: .year, value: -2, to: now)
        )
        
        let jenny = User(
            id: "jenny_liu",
            name: "Jenny Liu",
            avatarURL: nil,
            expertise: ["Beauty & Wellness", "Fitness"],
            stats: UserStats(
                questionsAnswered: 6,
                friendsCount: 19,
                recommendationsGiven: 9,
                recommendationsReceived: 11,
                categoriesHelped: ["Beauty & Wellness": 5, "Fitness": 4]
            ),
            friendSince: calendar.date(byAdding: .year, value: -1, to: now)
        )
        
        if !users.contains(where: { $0.id == sarah.id }) {
            users.append(sarah)
        }
        if !users.contains(where: { $0.id == mike.id }) {
            users.append(mike)
        }
        if !users.contains(where: { $0.id == alex.id }) {
            users.append(alex)
        }
        if !users.contains(where: { $0.id == jenny.id }) {
            users.append(jenny)
        }
        if !users.contains(where: { $0.id == currentUser.id }) {
            users.append(currentUser)
        }
    }
    
    private func loadScreenshotData() {
        let now = Date()
        let calendar = Calendar.current
        
        loadScreenshotUsers()
        
        let sarah = users.first { $0.id == "sarah_chen" }!
        let mike = users.first { $0.id == "mike_johnson" }!
        let alex = users.first { $0.id == "alex_martinez" }!
        let jenny = users.first { $0.id == "jenny_liu" }!
        
        var question1 = Question(
            id: "q1",
            userId: alex.id,
            text: "Anyone know where to get custom embroidery done?",
            location: "Manhattan, NY",
            timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [currentUser.id, jenny.id]
        )
        question1.urgencyLevel = .weekend
        
        var question2 = Question(
            id: "q2",
            userId: mike.id,
            text: "Need a reliable plumber ASAP",
            location: "Queens, NY",
            timestamp: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [currentUser.id]
        )
        question2.urgencyLevel = .urgent
        
        var question3 = Question(
            id: "q3",
            userId: currentUser.id,
            text: "Looking for a good mechanic for my Honda",
            location: "Brooklyn, NY",
            timestamp: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [mike.id]
        )
        question3.urgencyLevel = .normal
        
        var question4 = Question(
            id: "q4",
            userId: sarah.id,
            text: "Looking for a good dentist in Brooklyn",
            location: "Brooklyn, NY",
            timestamp: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [currentUser.id, mike.id]
        )
        question4.urgencyLevel = .normal
        
        var question5 = Question(
            id: "q5",
            userId: jenny.id,
            text: "Best Italian restaurant for a date night?",
            location: "Manhattan, NY",
            timestamp: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [currentUser.id, alex.id]
        )
        question5.urgencyLevel = .weekend
        
        var question6 = Question(
            id: "q6",
            userId: sarah.id,
            text: "Looking for a good yoga studio",
            location: "Brooklyn, NY",
            timestamp: calendar.date(byAdding: .day, value: -12, to: now) ?? now,
            visibility: .friendsOnly,
            selectedFriends: [currentUser.id, jenny.id]
        )
        question6.urgencyLevel = .normal
        
        questions = [question1, question2, question3, question4, question5, question6]
        
        let rec1 = Recommendation(
            id: "r1",
            questionId: question1.id,
            userId: jenny.id,
            text: "Stitch Perfect on 5th Ave - they did my wedding stuff, amazing quality and super professional!",
            address: "789 5th Ave, Manhattan, NY 10001",
            phoneNumber: "(555) 345-6789",
            website: "stitchperfect.com",
            likes: 7,
            timestamp: calendar.date(byAdding: .hour, value: -12, to: now) ?? now,
            tags: ["General"],
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        let rec2 = Recommendation(
            id: "r2",
            questionId: question1.id,
            userId: currentUser.id,
            text: "The Brooklyn Tailor on 5th Ave does amazing custom work. They made my wedding suit and it was perfect!",
            address: "890 5th Ave, Brooklyn, NY 11215",
            phoneNumber: "(555) 890-1234",
            website: "brooklyntailor.com",
            likes: 9,
            timestamp: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
            tags: ["General"],
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        let rec3 = Recommendation(
            id: "r3",
            questionId: question2.id,
            userId: currentUser.id,
            text: "Tony's Plumbing - used them last month, fast response and fair pricing. Highly recommend!",
            address: "321 Queens Blvd, Queens, NY 11101",
            phoneNumber: "(555) 456-7890",
            website: nil,
            likes: 5,
            timestamp: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            tags: ["Home Services"],
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        let rec4 = Recommendation(
            id: "r4",
            questionId: question3.id,
            userId: mike.id,
            text: "Brooklyn Auto Repair on Atlantic Ave - honest mechanics, great with Japanese cars. Been going there for years!",
            address: "555 Atlantic Ave, Brooklyn, NY 11217",
            phoneNumber: "(555) 789-0123",
            website: "brooklynauto.com",
            likes: 18,
            timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            tags: ["Auto"],
            timesUsed: 0,
            lastUsedAt: nil
        )
        
        let rec5 = Recommendation(
            id: "r5",
            questionId: question4.id,
            userId: mike.id,
            text: "Dr. Kim at Brooklyn Dental - been going for 3 years, super gentle and thorough. Great with anxious patients!",
            address: "123 Main St, Brooklyn, NY 11201",
            phoneNumber: "(555) 123-4567",
            website: "brooklyndental.com",
            likes: 12,
            timestamp: calendar.date(byAdding: .day, value: -9, to: now) ?? now,
            tags: ["Healthcare"],
            timesUsed: 2,
            lastUsedAt: calendar.date(byAdding: .day, value: -5, to: now)
        )
        
        let rec6 = Recommendation(
            id: "r6",
            questionId: question4.id,
            userId: currentUser.id,
            text: "Dr. Patel at Park Slope Dental is amazing! Very modern office and they accept most insurance.",
            address: "456 Park Ave, Brooklyn, NY 11215",
            phoneNumber: "(555) 234-5678",
            website: nil,
            likes: 8,
            timestamp: calendar.date(byAdding: .day, value: -9, to: now) ?? now,
            tags: ["Healthcare"],
            timesUsed: 1,
            lastUsedAt: calendar.date(byAdding: .day, value: -3, to: now)
        )
        
        let rec7 = Recommendation(
            id: "r7",
            questionId: question4.id,
            userId: alex.id,
            text: "Dr. Smith at Park Slope Dental Care is fantastic. Very modern office, great with kids too!",
            address: "234 7th Ave, Brooklyn, NY 11215",
            phoneNumber: "(555) 901-2345",
            website: nil,
            likes: 6,
            timestamp: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
            tags: ["Healthcare"],
            timesUsed: 1,
            lastUsedAt: calendar.date(byAdding: .day, value: -4, to: now)
        )
        
        let rec8 = Recommendation(
            id: "r8",
            questionId: question5.id,
            userId: alex.id,
            text: "Il Mulino in the West Village - romantic atmosphere, authentic Italian, perfect for dates!",
            address: "86 W 3rd St, Manhattan, NY 10012",
            phoneNumber: "(555) 567-8901",
            website: "ilmulino.com",
            likes: 15,
            timestamp: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            tags: ["Food & Dining"],
            timesUsed: 3,
            lastUsedAt: calendar.date(byAdding: .day, value: -1, to: now)
        )
        
        let rec9 = Recommendation(
            id: "r9",
            questionId: question5.id,
            userId: currentUser.id,
            text: "Carbone is pricey but worth it - best Italian food in the city. Make reservations weeks in advance!",
            address: "181 Thompson St, Manhattan, NY 10012",
            phoneNumber: "(555) 678-9012",
            website: "carbone.com",
            likes: 22,
            timestamp: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            tags: ["Food & Dining"],
            timesUsed: 1,
            lastUsedAt: calendar.date(byAdding: .day, value: -3, to: now)
        )
        
        let rec10 = Recommendation(
            id: "r10",
            questionId: question6.id,
            userId: jenny.id,
            text: "YogaWorks in Park Slope - great instructors, clean studio, and flexible class schedules!",
            address: "123 7th Ave, Brooklyn, NY 11215",
            phoneNumber: "(555) 111-2222",
            website: "yogaworks.com",
            likes: 10,
            timestamp: calendar.date(byAdding: .day, value: -11, to: now) ?? now,
            tags: ["Fitness"],
            timesUsed: 2,
            lastUsedAt: calendar.date(byAdding: .day, value: -6, to: now)
        )
        
        recommendations = [rec1, rec2, rec3, rec4, rec5, rec6, rec7, rec8, rec9, rec10]
        
        let reward1 = Reward(
            id: "rw1",
            recommendationId: rec8.id,
            questionId: question5.id,
            recipientUserId: currentUser.id,
            message: "Your friend used your recommendation for \"Best Italian restaurant for a date night?\"! 🎉",
            timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
        )
        
        let reward2 = Reward(
            id: "rw2",
            recommendationId: rec9.id,
            questionId: question5.id,
            recipientUserId: currentUser.id,
            message: "Your friend used your recommendation for \"Best Italian restaurant for a date night?\"! 🎉",
            timestamp: calendar.date(byAdding: .day, value: -3, to: now) ?? now
        )
        
        rewards = [reward1, reward2]
        
        savedRecommendations = Set(["r1", "r5", "r6", "r3", "r9", "r10"])
        for recId in savedRecommendations {
            if let index = recommendations.firstIndex(where: { $0.id == recId }) {
                var rec = recommendations[index]
                rec.isSaved = true
                recommendations[index] = rec
            }
        }
        
        userStreak = UserStreak(
            currentStreak: 5,
            longestStreak: 12,
            lastActivityDate: calendar.date(byAdding: .day, value: -1, to: now),
            weeklyCount: 3
        )
        
        let trustedFoodieBadge = Badge(
            id: "trusted_foodie",
            name: "Trusted Foodie",
            description: "Shared 5+ food recommendations",
            iconName: "fork.knife",
            earnedAt: calendar.date(byAdding: .day, value: -15, to: now) ?? now
        )
        
        let helperBadge = Badge(
            id: "helper",
            name: "Helper",
            description: "Helped 3 friends this week",
            iconName: "hand.raised.fill",
            earnedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now
        )
        
        badges = [trustedFoodieBadge, helperBadge]
        
        currentUser = User(
            id: currentUser.id,
            name: currentUser.name,
            avatarURL: currentUser.avatarURL,
            expertise: currentUser.expertise,
            stats: UserStats(
                questionsAnswered: 3,
                friendsCount: 4,
                recommendationsGiven: 5,
                recommendationsReceived: 8,
                categoriesHelped: ["Food & Dining": 2, "Healthcare": 1, "Home Services": 2]
            ),
            friendSince: currentUser.friendSince
        )
        
        saveQuestions()
        saveRecommendations()
        saveRewards()
        saveCollections()
        saveBadges()
        saveStreak()
    }
    
    func saveQuestions() {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: "questions")
        }
    }
    
    private func saveRecommendations() {
        if let encoded = try? JSONEncoder().encode(recommendations) {
            UserDefaults.standard.set(encoded, forKey: "recommendations")
        }
    }
    
    private func saveRewards() {
        if let encoded = try? JSONEncoder().encode(rewards) {
            UserDefaults.standard.set(encoded, forKey: "rewards")
        }
    }
    
    func toggleSaveRecommendation(_ recommendationId: String) {
        if savedRecommendations.contains(recommendationId) {
            savedRecommendations.remove(recommendationId)
            if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
                var rec = recommendations[index]
                rec.isSaved = false
                recommendations[index] = rec
            }
        } else {
            savedRecommendations.insert(recommendationId)
            if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
                var rec = recommendations[index]
                rec.isSaved = true
                recommendations[index] = rec
            }
        }
        saveRecommendations()
    }
    
    func createCollection(name: String, description: String?, recommendationIds: [String]) {
        let collection = Collection(
            id: UUID().uuidString,
            name: name,
            description: description,
            recommendationIds: recommendationIds,
            createdAt: Date()
        )
        collections.append(collection)
        saveCollections()
    }
    
    func addRecommendationToCollection(_ recommendationId: String, collectionId: String) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            var collection = collections[index]
            if !collection.recommendationIds.contains(recommendationId) {
                collection.recommendationIds.append(recommendationId)
                collections[index] = collection
                saveCollections()
            }
        }
    }
    
    func removeRecommendationFromCollection(_ recommendationId: String, collectionId: String) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            var collection = collections[index]
            collection.recommendationIds.removeAll { $0 == recommendationId }
            collections[index] = collection
            saveCollections()
        }
    }
    
    func getCollectionsContaining(_ recommendationId: String) -> [Collection] {
        return collections.filter { $0.recommendationIds.contains(recommendationId) }
    }
    
    func isRecommendationInCollection(_ recommendationId: String, collectionId: String) -> Bool {
        return collections.first(where: { $0.id == collectionId })?.recommendationIds.contains(recommendationId) ?? false
    }
    
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastActivity = userStreak.lastActivityDate {
            let lastActivityDay = Calendar.current.startOfDay(for: lastActivity)
            let daysSince = Calendar.current.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0
            
            if daysSince == 0 {
                return
            } else if daysSince == 1 {
                userStreak.currentStreak += 1
            } else {
                userStreak.currentStreak = 1
            }
        } else {
            userStreak.currentStreak = 1
        }
        
        userStreak.longestStreak = max(userStreak.longestStreak, userStreak.currentStreak)
        userStreak.lastActivityDate = Date()
        
        if let lastActivity = userStreak.lastActivityDate {
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            if lastActivity < weekAgo {
                userStreak.weeklyCount = 0
            }
        }
        userStreak.weeklyCount += 1
        saveStreak()
    }
    
    func checkAndAwardBadges() {
        let existingBadgeIds = Set(badges.map { $0.id })
        
        let foodRecs = recommendations.filter { $0.userId == currentUser.id && $0.tags.contains("Food & Dining") }.count
        if foodRecs >= 5 && !existingBadgeIds.contains("trusted_foodie") {
            badges.append(Badge(
                id: "trusted_foodie",
                name: "Trusted Foodie",
                description: "Shared 5+ food recommendations",
                iconName: "fork.knife",
                earnedAt: Date()
            ))
        }
        
        let nycRecs = recommendations.filter { $0.userId == currentUser.id && ($0.address?.contains("NY") ?? false) }.count
        if nycRecs >= 10 && !existingBadgeIds.contains("nyc_expert") {
            badges.append(Badge(
                id: "nyc_expert",
                name: "NYC Expert",
                description: "Shared 10+ NYC recommendations",
                iconName: "building.2",
                earnedAt: Date()
            ))
        }
        
        if userStreak.weeklyCount >= 3 && !existingBadgeIds.contains("helper") {
            badges.append(Badge(
                id: "helper",
                name: "Helper",
                description: "Helped 3 friends this week",
                iconName: "hand.raised.fill",
                earnedAt: Date()
            ))
        }
        
        saveBadges()
    }
    
    func getSuggestedContributors(for question: Question) -> [User] {
        let questionTags = generateAutoTags(from: question.text, recommendationText: "")
        var contributors: [User] = []
        
        for user in users where user.id != question.userId {
            let userRecs = recommendations.filter { $0.userId == user.id }
            let matchingRecs = userRecs.filter { rec in
                !Set(rec.tags).isDisjoint(with: Set(questionTags))
            }
            if !matchingRecs.isEmpty {
                contributors.append(user)
            }
        }
        
        return Array(contributors.prefix(3))
    }
    
    func getFriendsWhoNeedHelp() -> Int {
        let activeQuestions = questions.filter { $0.isActive && $0.userId != currentUser.id }
        return activeQuestions.count
    }
    
    func detectURLInText(_ text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let firstMatch = matches.first,
           let url = firstMatch.url {
            return url.absoluteString
        }
        
        let urlPattern = #"(?i)\b(?:https?://)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)"#
        if let regex = try? NSRegularExpression(pattern: urlPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range, in: text) {
            var urlString = String(text[range])
            if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                urlString = "https://\(urlString)"
            }
            return urlString
        }
        
        return nil
    }
    
    func extractPreviewFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        if let host = url.host {
            let domain = host.replacingOccurrences(of: "www.", with: "")
            
            if urlString.contains("tiktok") {
                return "TikTok Video"
            } else if urlString.contains("instagram") {
                return "Instagram Post"
            } else if urlString.contains("yelp") {
                return "Yelp Review"
            } else if urlString.contains("google.com/maps") || urlString.contains("maps") {
                return "Google Maps Location"
            } else if urlString.contains("menu") || urlString.contains("menus") {
                return "Menu - \(domain)"
            } else if urlString.contains("booking") || urlString.contains("reserve") || urlString.contains("opentable") {
                return "Booking Page - \(domain)"
            } else if urlString.contains("tripadvisor") {
                return "TripAdvisor Review"
            } else {
                let parts = domain.components(separatedBy: ".")
                if let siteName = parts.first, !siteName.isEmpty {
                    return "Link from \(siteName.capitalized)"
                }
                return "Web Link"
            }
        }
        
        return "Web Link"
    }
    
    func getImpactCount(for questionId: String) -> Int {
        let question = questions.first { $0.id == questionId }
        return question?.selectedFriends.count ?? 0
    }
    
    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "collections")
        }
    }
    
    private func saveBadges() {
        if let encoded = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(encoded, forKey: "badges")
        }
    }
    
    private func saveStreak() {
        if let encoded = try? JSONEncoder().encode(userStreak) {
            UserDefaults.standard.set(encoded, forKey: "userStreak")
        }
    }
    
    private func createSampleCollections() {
        let now = Date()
        let calendar = Calendar.current
        
        guard !recommendations.isEmpty else { return }
        
        let foodRecs = recommendations.filter { $0.tags.contains("Food & Dining") }.prefix(2).map { $0.id }
        let homeRecs = recommendations.filter { $0.tags.contains("Home Services") }.prefix(1).map { $0.id }
        let healthcareRecs = recommendations.filter { $0.tags.contains("Healthcare") }.prefix(3).map { $0.id }
        
        if !foodRecs.isEmpty {
            let dateNightCollection = Collection(
                id: "collection_2",
                name: "Date Night Ideas",
                description: "Perfect spots for romantic evenings",
                recommendationIds: Array(foodRecs),
                createdAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now
            )
            collections.append(dateNightCollection)
        }
        
        if !homeRecs.isEmpty {
            let homeServicesCollection = Collection(
                id: "collection_3",
                name: "Home Services You Trust",
                description: "Reliable contractors and services",
                recommendationIds: Array(homeRecs),
                createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now
            )
            collections.append(homeServicesCollection)
        }
        
        if !healthcareRecs.isEmpty {
            let healthcareCollection = Collection(
                id: "collection_4",
                name: "Healthcare Recommendations",
                description: "Trusted healthcare providers",
                recommendationIds: Array(healthcareRecs),
                createdAt: calendar.date(byAdding: .day, value: -10, to: now) ?? now
            )
            collections.append(healthcareCollection)
        }
        
        saveCollections()
    }
    
    private func createSampleBadges() {
        let now = Date()
        let calendar = Calendar.current
        
        let foodRecs = recommendations.filter { $0.userId == currentUser.id && $0.tags.contains("Food & Dining") }.count
        let weeklyCount = userStreak.weeklyCount
        
        if foodRecs >= 5 {
            let trustedFoodieBadge = Badge(
                id: "trusted_foodie",
                name: "Trusted Foodie",
                description: "Shared 5+ food recommendations",
                iconName: "fork.knife",
                earnedAt: calendar.date(byAdding: .day, value: -15, to: now) ?? now
            )
            badges.append(trustedFoodieBadge)
        }
        
        if weeklyCount >= 3 {
            let helperBadge = Badge(
                id: "helper",
                name: "Helper",
                description: "Helped 3 friends this week",
                iconName: "hand.raised.fill",
                earnedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            )
            badges.append(helperBadge)
        }
        
        saveBadges()
    }
    
    private func createSampleStreak() {
        let now = Date()
        let calendar = Calendar.current
        
        userStreak = UserStreak(
            currentStreak: 5,
            longestStreak: 12,
            lastActivityDate: calendar.date(byAdding: .day, value: -1, to: now),
            weeklyCount: 3
        )
        
        saveStreak()
    }
} 
