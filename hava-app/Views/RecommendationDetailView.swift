import SwiftUI

struct RecommendationDetailView: View {
    @EnvironmentObject private var store: AppStore
    let recommendation: Recommendation
    let question: Question
    @State private var showUsedAnimation = false
    @State private var hasBeenUsed = false
    @State private var showCollectionSelection = false
    
    private var collectionsContaining: [Collection] {
        store.getCollectionsContaining(recommendation.id)
    }
    
    private var isInSavedItems: Bool {
        store.savedRecommendations.contains(recommendation.id)
    }
    
    private var allCollectionsCount: Int {
        let regularCollections = collectionsContaining.count
        let savedItemsCount = isInSavedItems ? 1 : 0
        return regularCollections + savedItemsCount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    Text("Recommendation by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.userId)
                        .font(.headline)
                }
                .padding(.top)

                
                VStack(alignment: .leading, spacing: 8) {
                    Text("For the question:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(question.text)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(question.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendation:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendation.text)
                        .font(.body)
                }

                
                if let address = recommendation.address, !address.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(address)
                            .font(.body)
                    }
                }
                
                if let phone = recommendation.phoneNumber, !phone.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(phone)
                            .font(.body)
                    }
                }
                
                if let website = recommendation.website, !website.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Website:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Link(website, destination: URL(string: website.hasPrefix("http") ? website : "https://\(website)")!)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }

                
                if !recommendation.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recommendation.tags, id: \.self) { tag in
                                    Text(tag)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collections:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if allCollectionsCount == 0 {
                        Button(action: {
                            showCollectionSelection = true
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("Add to Collection")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if isInSavedItems {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bookmark.fill")
                                            .font(.caption2)
                                        Text("Saved Items")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                                
                                ForEach(collectionsContaining) { collection in
                                    HStack(spacing: 4) {
                                        Image(systemName: "folder.fill")
                                            .font(.caption2)
                                        Text(collection.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    showCollectionSelection = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.caption2)
                                        Text("Manage")
                                            .font(.caption)
                                    }
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
                
                
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.thumbsup")
                            .foregroundColor(.blue)
                        Text("\(recommendation.likes) likes")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    if recommendation.timesUsed > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Used \(recommendation.timesUsed) time\(recommendation.timesUsed == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 8)
                
                
                if recommendation.userId != store.currentUser.id && !hasBeenUsed {
                    Button(action: {
                        store.markRecommendationUsed(recommendation, by: store.currentUser.id)
                        hasBeenUsed = true
                        showUsedAnimation = true
                        
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showUsedAnimation = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("I Used This Recommendation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                
                
                if showUsedAnimation {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .scaleEffect(showUsedAnimation ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showUsedAnimation)
                        
                        Text("Thank you for using this recommendation! 🎉")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recommendation Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCollectionSelection) {
            CollectionSelectionView(recommendationId: recommendation.id)
        }
    }
} 