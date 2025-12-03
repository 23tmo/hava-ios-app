import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    
    var savedRecommendations: [Recommendation] {
        store.recommendations.filter { store.savedRecommendations.contains($0.id) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Button(action: {
                    showingCreateCollection = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Collection")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    if !savedRecommendations.isEmpty {
                        CollectionSection(
                            title: "Saved Items",
                            icon: "bookmark.fill",
                            recommendations: savedRecommendations,
                            color: .blue
                        )
                    }
                    
                    
                    let myRecommendations = store.recommendations.filter { $0.userId == store.currentUser.id }
                    if !myRecommendations.isEmpty {
                        CollectionSection(
                            title: "My Recommendations",
                            icon: "person.fill",
                            recommendations: myRecommendations,
                            color: .green
                        )
                    }
                    
                    
                    ForEach(store.collections) { collection in
                        let collectionRecs = store.recommendations.filter { collection.recommendationIds.contains($0.id) }
                        if !collectionRecs.isEmpty {
                            CollectionSection(
                                title: collection.name,
                                icon: "folder.fill",
                                recommendations: collectionRecs,
                                color: .purple
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Collections")
        .sheet(isPresented: $showingCreateCollection) {
            CreateCollectionView(
                name: $newCollectionName,
                description: $newCollectionDescription,
                onSave: { name, description in
                    let savedIds = savedRecommendations.map { $0.id }
                    store.createCollection(name: name, description: description, recommendationIds: savedIds)
                    newCollectionName = ""
                    newCollectionDescription = ""
                }
            )
        }
    }
}

struct CollectionSection: View {
    @EnvironmentObject private var store: AppStore
    let title: String
    let icon: String
    let recommendations: [Recommendation]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(recommendations.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations.prefix(10)) { recommendation in
                        if let question = store.questions.first(where: { $0.id == recommendation.questionId }) {
                            NavigationLink(destination: RecommendationDetailView(recommendation: recommendation, question: question)) {
                                CollectionCard(recommendation: recommendation, question: question)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CollectionCard: View {
    let recommendation: Recommendation
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recommendation.text)
                .font(.caption)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            if !recommendation.tags.isEmpty {
                Text(recommendation.tags.first ?? "")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
        }
        .frame(width: 150, height: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct CreateCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var description: String
    let onSave: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Details")) {
                    TextField("Collection Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }
                
                Section {
                    Button(action: {
                        onSave(name, description)
                        dismiss()
                    }) {
                        Text("Create Collection")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

