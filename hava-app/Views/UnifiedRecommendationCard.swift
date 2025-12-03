import SwiftUI
import MapKit

struct UnifiedRecommendationCard: View {
    @EnvironmentObject private var store: AppStore
    let recommendation: Recommendation
    let question: Question
    let user: User
    @State private var showShareSheet = false
    @State private var showCollectionSelection = false
    
    private var collectionsContaining: [Collection] {
        store.getCollectionsContaining(recommendation.id)
    }
    
    private var totalCollectionsCount: Int {
        let regularCollections = collectionsContaining.count
        let savedItemsCount = store.savedRecommendations.contains(recommendation.id) ? 1 : 0
        return regularCollections + savedItemsCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(colorForUser(user.id))
                
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.system(size: 17 * store.dynamicTypeSize, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                        if let friendSince = user.friendSince {
                            Text("• Friend since \(formatYear(friendSince))")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !recommendation.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(recommendation.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10 * store.dynamicTypeSize))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(store.highContrastMode ? Color.blue : Color.blue.opacity(0.1))
                                        .foregroundColor(store.highContrastMode ? .white : .blue)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(store.highContrastMode ? Color.white : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Text(timeAgo(from: recommendation.timestamp))
                    .font(.system(size: 12 * store.dynamicTypeSize))
                    .foregroundColor(.secondary)
            }
            
            Text(recommendation.text)
                .font(.system(size: 17 * store.dynamicTypeSize))
                .fixedSize(horizontal: false, vertical: true)
            
            if let address = recommendation.address, !address.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12 * store.dynamicTypeSize))
                    Text(address)
                        .font(.system(size: 12 * store.dynamicTypeSize))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(8)
                .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(store.highContrastMode ? Color.primary : Color.clear, lineWidth: 1)
                )
                .cornerRadius(8)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    showCollectionSelection = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: totalCollectionsCount == 0 ? "folder.badge.plus" : "folder.fill")
                            .font(.system(size: 12 * store.dynamicTypeSize))
                        if totalCollectionsCount == 0 {
                            Text("Add")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                                .lineLimit(1)
                        } else {
                            Text("Collections")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                                .lineLimit(1)
                            Text("(\(totalCollectionsCount))")
                                .font(.system(size: 10 * store.dynamicTypeSize))
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(totalCollectionsCount == 0 ? .secondary : .blue)
                    .fixedSize(horizontal: true, vertical: false)
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 12 * store.dynamicTypeSize))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                }
                
                if recommendation.userId != store.currentUser.id {
                    Button(action: {
                        store.markRecommendationUsed(recommendation, by: store.currentUser.id)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                            Text("Used")
                        }
                        .font(.system(size: 12 * store.dynamicTypeSize))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                
                Spacer(minLength: 4)
                
                HStack(spacing: 8) {
                    if recommendation.likes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                            Text("\(recommendation.likes)")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                                .fixedSize(horizontal: true, vertical: false)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if recommendation.timesUsed > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                            Text("\(recommendation.timesUsed)")
                                .font(.system(size: 12 * store.dynamicTypeSize))
                                .fixedSize(horizontal: true, vertical: false)
                                .lineLimit(1)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(store.highContrastMode ? Color(.systemBackground) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.highContrastMode ? Color.primary : Color.clear, lineWidth: 2)
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [recommendation.text, question.text])
        }
        .sheet(isPresented: $showCollectionSelection) {
            CollectionSelectionView(recommendationId: recommendation.id)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
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

