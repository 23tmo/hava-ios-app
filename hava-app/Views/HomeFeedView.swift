import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.selectedTab) private var selectedTab
    @State private var searchText = ""
    @State private var showingAskQuestion = false
    @State private var isKeyboardVisible = false
    @State private var showingSortOptions = false
    
    var filteredFeedItems: [FeedItem] {
        var items = store.questions.map { question in
            FeedItem(
                id: question.id,
                question: question,
                recommendations: store.recommendations.filter { $0.questionId == question.id },
                user: store.getUser(by: question.userId)
            )
        }
        
        if !searchText.isEmpty {
            items = items.filter { item in
                item.question.text.localizedCaseInsensitiveContains(searchText) ||
                item.question.location.localizedCaseInsensitiveContains(searchText) ||
                item.recommendations.contains { rec in
                    rec.text.localizedCaseInsensitiveContains(searchText) ||
                    rec.address?.localizedCaseInsensitiveContains(searchText) ?? false ||
                    rec.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                    rec.website?.localizedCaseInsensitiveContains(searchText) ?? false
                }
            }
        }
        
        switch store.feedSortOption {
        case .newest:
            items.sort { $0.question.timestamp > $1.question.timestamp }
        case .mostRelevant:
            items.sort { $0.recommendations.count > $1.recommendations.count }
        case .inMyArea:
            let myArea = "NY"
            items = items.filter { $0.question.location.contains(myArea) }
            items.sort { $0.question.timestamp > $1.question.timestamp }
        case .byUrgency:
            items.sort { item1, item2 in
                let urgency1 = item1.question.urgencyLevel
                let urgency2 = item2.question.urgencyLevel
                
                func urgencyPriority(_ level: UrgencyLevel) -> Int {
                    switch level {
                    case .urgent: return 0
                    case .weekend: return 1
                    case .normal: return 2
                    }
                }
                
                let priority1 = urgencyPriority(urgency1)
                let priority2 = urgencyPriority(urgency2)
                
                if priority1 != priority2 {
                    return priority1 < priority2
                } else {
                    return item1.question.timestamp > item2.question.timestamp
                }
            }
        }
        
        return items
    }
    
    private func colorForUser(_ userId: String) -> Color {
        if userId == store.currentUser.id {
            return .blue
        }
        
        let userColorMap: [String: Color] = [
            "sarah_chen": .orange,
            "mike_johnson": .red,
            "alex_martinez": .teal,
            "jenny_liu": .purple
        ]
        
        if let color = userColorMap[userId] {
            return color
        }
        
        let colors: [Color] = [
            .green, .pink, .cyan, .indigo, .mint, .yellow, .brown
        ]
        
        var hash = 0
        for char in userId.utf8 {
            hash = ((hash << 5) &- hash) &+ Int(char)
        }
        let index = abs(hash) % colors.count
        return colors[index]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                selectedTab.wrappedValue = 1 
                            }) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 22 * store.dynamicTypeSize))
                            }
                            Button(action: {
                                selectedTab.wrappedValue = 2 
                            }) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(colorForUser(store.currentUser.id))
                                    .font(.system(size: 22 * store.dynamicTypeSize))
                            }
                        }
                    }
                    
                    Text("hava")
                        .font(.system(size: 24 * store.dynamicTypeSize, weight: .bold, design: .rounded))
                        .tracking(2)
                }
                .padding()
                .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .stroke(store.highContrastMode ? Color.primary : Color.clear, lineWidth: 1)
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        Button(action: { showingAskQuestion = true }) {
                            Text("Ask Friends for Recommendation")
                                .font(.system(size: 17 * store.dynamicTypeSize, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(store.highContrastMode ? Color.blue : Color.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(store.highContrastMode ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 17 * store.dynamicTypeSize))
                            TextField("Search recommendations...", text: $searchText)
                                .font(.system(size: 17 * store.dynamicTypeSize))
                            
                            Button(action: { showingSortOptions = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text(store.feedSortOption.rawValue)
                                        .font(.system(size: 12 * store.dynamicTypeSize))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(store.highContrastMode ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .sheet(isPresented: $showingSortOptions) {
                            SortOptionsView()
                                .environmentObject(store)
                        }
                        
                        if isKeyboardVisible {
                            Button("Hide Keyboard") {
                                hideKeyboard()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        let activeRequests = filteredFeedItems.filter { $0.isActiveRequest }
                        let activeRequestCount = activeRequests.count
                        if !activeRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.orange)
                                    Text("Active Requests")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(activeRequestCount)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(12)
                                    Text("friends are looking for recommendations")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.leading, 8)
                                }
                                .padding(.horizontal)
                                
                                ForEach(activeRequests) { item in
                                    ActiveRequestCard(item: item)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        if filteredFeedItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No recommendations yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Ask your friends for recommendations to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        } else {
                            let nonActiveRequests = filteredFeedItems.filter { !$0.isActiveRequest }
                            if !nonActiveRequests.isEmpty {
                                Text("All Recommendations")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                ForEach(nonActiveRequests) { item in
                                    FeedItemView(item: item)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAskQuestion) {
                AskQuestionView()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
        }
    }
}

struct FeedItemView: View {
    @EnvironmentObject private var store: AppStore
    let item: FeedItem
    @State private var selectedIndex = 0

    private var carouselArrowWidth: CGFloat { 36 }
    private var carouselHorizontalPadding: CGFloat { 16 }
    private var carouselCardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let calculatedWidth = screenWidth - (carouselArrowWidth * 2) - (carouselHorizontalPadding * 2) - 24
        return max(220, calculatedWidth)
    }
    
    var body: some View {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(colorForUser(item.user.id))
                        
                        VStack(alignment: .leading) {
                            Text(item.user.name)
                                .font(.system(size: 17 * store.dynamicTypeSize, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        Text(timeAgo(from: item.question.timestamp))
                            .font(.system(size: 12 * store.dynamicTypeSize))
                            .foregroundColor(.gray)
                    }
                    
                    Text(item.question.text)
                        .font(.system(size: 15 * store.dynamicTypeSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(item.question.location)
                        .font(.system(size: 12 * store.dynamicTypeSize))
                        .foregroundColor(.gray)
            
            if !item.recommendations.isEmpty {
                HStack(alignment: .center, spacing: 0) {
                    if selectedIndex > 0 {
                        Button(action: { withAnimation { selectedIndex -= 1 } }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 22 * store.dynamicTypeSize))
                                .foregroundColor(.blue)
                                .opacity(0.7)
                                .frame(width: carouselArrowWidth)
                        }
                    } else {
                        Spacer().frame(width: carouselArrowWidth)
                    }

                    TabView(selection: $selectedIndex) {
                        ForEach(Array(item.recommendations.enumerated()), id: \.element.id) { index, rec in
                            NavigationLink(destination: RecommendationDetailView(recommendation: rec, question: item.question).environmentObject(store)) {
                                UnifiedRecommendationCard(
                                    recommendation: rec,
                                    question: item.question,
                                    user: store.getUser(by: rec.userId)
                                )
                                .frame(width: carouselCardWidth)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: carouselCardWidth, height: 260)

                    if selectedIndex < item.recommendations.count - 1 {
                        Button(action: { withAnimation { selectedIndex += 1 } }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 22 * store.dynamicTypeSize))
                                .foregroundColor(.blue)
                                .opacity(0.7)
                                .frame(width: carouselArrowWidth)
                        }
                    } else {
                        Spacer().frame(width: carouselArrowWidth)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Text("\(item.recommendations.count) responses total")
                        .font(.system(size: 12 * store.dynamicTypeSize))
                        .foregroundColor(.gray)
                    Spacer()
                    NavigationLink(destination: RecommendationsListView(question: item.question, asker: item.user)) {
                        Text("View all")
                            .font(.system(size: 12 * store.dynamicTypeSize))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 8) {
                    NavigationLink(destination: QuickAddRecommendationView(question: item.question, asker: item.user).environmentObject(store)) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Quick Add (10 sec)")
                        }
                        .font(.system(size: 15 * store.dynamicTypeSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(store.highContrastMode ? Color.blue : Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(store.highContrastMode ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(10)
                    }
                    NavigationLink(destination: RespondToQuestionView(question: item.question, asker: item.user)) {
                        Text("Add Full Details")
                            .font(.system(size: 12 * store.dynamicTypeSize))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.highContrastMode ? Color.primary : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(radius: store.highContrastMode ? 0 : 2)
        .padding(.horizontal)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func colorForUser(_ userId: String) -> Color {
        // Ensure current user always gets blue
        if userId == store.currentUser.id {
            return .blue
        }
        
        // Assign distinct colors to known users
        let userColorMap: [String: Color] = [
            "sarah_chen": .orange,
            "mike_johnson": .red,
            "alex_martinez": .teal,
            "jenny_liu": .purple
        ]
        
        if let color = userColorMap[userId] {
            return color
        }
        
        // For unknown users, use a better hash function
        let colors: [Color] = [
            .green, .pink, .cyan, .indigo, .mint, .yellow, .brown
        ]
        
        // Create a more distributed hash using string characters
        var hash = 0
        for char in userId.utf8 {
            hash = ((hash << 5) &- hash) &+ Int(char)
        }
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

struct ActiveRequestCard: View {
    @EnvironmentObject private var store: AppStore
    let item: FeedItem
    @State private var showingQuickAdd = false
    
    var suggestedContributors: [User] {
        store.getSuggestedContributors(for: item.question)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.question.urgencyLevel.color)
                        .frame(width: 8, height: 8)
                    Text(item.question.urgencyLevel.displayName.uppercased())
                        .font(.system(size: 10 * store.dynamicTypeSize, weight: .bold))
                        .foregroundColor(item.question.urgencyLevel.color)
                }
                Spacer()
                Text(timeAgo(from: item.question.timestamp))
                    .font(.system(size: 12 * store.dynamicTypeSize))
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(colorForUser(item.user.id))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.user.name)
                        .font(.system(size: 17 * store.dynamicTypeSize, weight: .semibold))
                    Text(item.question.text)
                        .font(.system(size: 15 * store.dynamicTypeSize))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.question.location)
                        .font(.system(size: 12 * store.dynamicTypeSize))
                        .foregroundColor(.gray)
                }
            }
            
            Text("Help \(item.user.name) - they're actively looking for recommendations!")
                .font(.system(size: 12 * store.dynamicTypeSize))
                .foregroundColor(.orange)
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
            
            if !suggestedContributors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested contributors:")
                        .font(.system(size: 10 * store.dynamicTypeSize))
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        ForEach(suggestedContributors.prefix(3)) { user in
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(colorForUser(user.id))
                                Text(user.name)
                                    .font(.system(size: 10 * store.dynamicTypeSize))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            Button(action: { showingQuickAdd = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Add Recommendation")
                }
                .font(.system(size: 15 * store.dynamicTypeSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.highContrastMode ? Color.blue : Color.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(store.highContrastMode ? Color.white : Color.clear, lineWidth: 2)
                )
                .cornerRadius(10)
            }
        }
        .padding()
        .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: store.highContrastMode ? 0 : 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.highContrastMode ? Color.primary : item.question.urgencyLevel.color.opacity(0.3), lineWidth: store.highContrastMode ? 3 : 2)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingQuickAdd) {
            NavigationView {
                QuickAddRecommendationView(question: item.question, asker: item.user)
                    .environmentObject(store)
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func colorForUser(_ userId: String) -> Color {
        if userId == store.currentUser.id {
            return .blue
        }
        
        let userColorMap: [String: Color] = [
            "sarah_chen": .orange,
            "mike_johnson": .red,
            "alex_martinez": .teal,
            "jenny_liu": .purple
        ]
        
        if let color = userColorMap[userId] {
            return color
        }
        
        let colors: [Color] = [
            .green, .pink, .cyan, .indigo, .mint, .yellow, .brown
        ]
        
        var hash = 0
        for char in userId.utf8 {
            hash = ((hash << 5) &- hash) &+ Int(char)
        }
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

struct SortOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FeedSortOption.allCases, id: \.self) { option in
                    Button(action: {
                        store.feedSortOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                            Spacer()
                            if store.feedSortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

let sampleFeedItems = [
    FeedItem(
        id: "1",
        question: Question(
            id: "1",
            userId: "sarah",
            text: "Looking for a good dentist",
            location: "Brooklyn",
            timestamp: Date().addingTimeInterval(-7200),
            visibility: .friendsOnly,
            selectedFriends: []
        ),
        recommendations: [
            Recommendation(
                id: "1",
                questionId: "1",
                userId: "Mike Johnson",
                text: "Dr. Kim at Brooklyn Dental - been going for 3 years, super gentle and thorough",
                address: "123 Main St, Brooklyn, NY",
                phoneNumber: "(555) 123-4567",
                website: "brooklyndental.com",
                likes: 12,
                timestamp: Date().addingTimeInterval(-3600),
                tags: ["Healthcare"],
                timesUsed: 2,
                lastUsedAt: Date().addingTimeInterval(-86400)
            )
        ],
        user: User(
            id: "sarah",
            name: "Sarah Chen",
            avatarURL: nil,
            expertise: [],
            stats: UserStats(
                questionsAnswered: 0,
                friendsCount: 0,
                recommendationsGiven: 0,
                recommendationsReceived: 0,
                categoriesHelped: [:]
            ),
            friendSince: nil
        )
    )
] 
