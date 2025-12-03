import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = 0
    @State private var showEditExpertise = false
    @State private var newExpertise = ""
    
    var user: User { store.currentUser }
    
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
    
    var userRecommendations: [Recommendation] {
        store.recommendations.filter { $0.userId == user.id }
    }
    
    var userQuestions: [Question] {
        store.questions.filter { $0.userId == user.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(colorForUser(user.id).opacity(0.2))
                            .frame(width: 72, height: 72)
                        
                        AsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(colorForUser(user.id))
                                    .padding(6)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(colorForUser(user.id))
                                    .padding(6)
                            @unknown default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(colorForUser(user.id))
                                    .padding(6)
                            }
                        }
                        .clipShape(Circle())
                        .frame(width: 72, height: 72)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Answered \(userRecommendations.count) questions • \(userQuestions.count) asked")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shared History")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(user.stats.recommendationsGiven)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Given")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(user.stats.recommendationsReceived)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Received")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    
                    if !user.stats.categoriesHelped.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categories you help most with:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(user.stats.categoriesHelped.keys.sorted()), id: \.self) { category in
                                    HStack(spacing: 4) {
                                        Text(category)
                                        Text("(\(user.stats.categoriesHelped[category] ?? 0))")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                
                NavigationLink(destination: CollectionsView().environmentObject(store)) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("My Collections")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Known for:")
                            .font(.headline)
                        Spacer()
                        Button(action: { showEditExpertise = true }) {
                            Image(systemName: "pencil")
                            Text("Edit")
                                .font(.caption)
                        }
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(user.expertise, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                
                
                HStack {
                    TabButton(title: "Recommendations", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Questions", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.vertical)
                
                
                if selectedTab == 0 {
                    recommendationsList
                } else {
                    questionsList
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Current User")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AccessibilitySettingsView().environmentObject(store)) {
                    Image(systemName: "accessibility")
                }
            }
        }
        .sheet(isPresented: $showEditExpertise) {
            EditExpertiseSheet(expertise: user.expertise) { newTags in
                
                var updatedUser = user
                updatedUser = User(
                    id: user.id,
                    name: user.name,
                    avatarURL: user.avatarURL,
                    expertise: newTags,
                    stats: user.stats
                )
                store.currentUser = updatedUser
            }
        }
    }
    
    private var recommendationsList: some View {
        VStack(spacing: 16) {
            if userRecommendations.isEmpty {
                Text("No recommendations yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(userRecommendations) { recommendation in
                    NavigationLink(destination: RecommendationDetailView(recommendation: recommendation, question: store.questions.first(where: { $0.id == recommendation.questionId }) ?? Question(id: "", userId: "", text: "", location: "", timestamp: Date(), visibility: .friendsOnly, selectedFriends: []))) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recommendation.text)
                                .font(.headline)
                                .foregroundColor(.primary)
                            if let address = recommendation.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            if let phone = recommendation.phoneNumber, !phone.isEmpty {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            if let website = recommendation.website, !website.isEmpty {
                                Text(website)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Text("For: \(store.questions.first(where: { $0.id == recommendation.questionId })?.text ?? "Unknown question")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    if recommendation.id != userRecommendations.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    private var questionsList: some View {
        VStack(spacing: 16) {
            if userQuestions.isEmpty {
                Text("No questions yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(userQuestions) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.text)
                            .font(.headline)
                        Text(question.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(store.recommendations.filter { $0.questionId == question.id }.count) recommendations")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    if question.id != userQuestions.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct EditExpertiseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var expertise: [String]
    @State private var newTag = ""
    var onSave: ([String]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add what you're knowledgeable about:")
                    .font(.headline)
                FlowLayout(spacing: 8) {
                    ForEach(expertise, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            Button(action: {
                                expertise.removeAll { $0 == tag }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                HStack {
                    TextField("Add expertise", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !expertise.contains(trimmed) {
                            expertise.append(trimmed)
                        }
                        newTag = ""
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Expertise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(expertise)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    VStack {
                        Spacer()
                        if isSelected {
                            Color.blue
                                .frame(height: 2)
                        }
                    }
                )
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        guard let containerWidth = proposal.width else {
            return (sizes.map { _ in .zero }, .zero)
        }
        
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}


struct RecommendationItem: Identifiable {
    let id: String
    let title: String
    let meta: String
}

let sampleRecommendations = [
    RecommendationItem(id: "1", title: "Brooklyn Dental Care", meta: "Recommended for \"dentist in Brooklyn\" • 2 hours ago"),
    RecommendationItem(id: "2", title: "Tony's Auto Repair", meta: "Recommended for \"car mechanic\" • 1 week ago"),
    RecommendationItem(id: "3", title: "Home Depot Contractor Services", meta: "Recommended for \"bathroom renovation\" • 2 weeks ago"),
    RecommendationItem(id: "4", title: "Joe's Pizza", meta: "Recommended for \"best pizza near NYU\" • 3 weeks ago")
]

let sampleQuestions = [
    RecommendationItem(id: "1", title: "Looking for a good dentist", meta: "Asked in Brooklyn • 2 hours ago"),
    RecommendationItem(id: "2", title: "Need a reliable plumber", meta: "Asked in Queens • 3 days ago"),
    RecommendationItem(id: "3", title: "Best pizza place near NYU?", meta: "Asked in Manhattan • 1 week ago")
] 