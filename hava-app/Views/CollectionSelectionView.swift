import SwiftUI

struct CollectionSelectionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let recommendationId: String
    @State private var selectedCollectionIds: Set<String> = []
    @State private var isInSavedItems: Bool = false
    
    private var savedItemsCount: Int {
        store.savedRecommendations.count
    }
    
    var body: some View {
        NavigationView {
            List {
                // Saved Items collection (special)
                Section {
                    Button(action: {
                        isInSavedItems.toggle()
                        store.toggleSaveRecommendation(recommendationId)
                    }) {
                        HStack {
                            Image(systemName: isInSavedItems ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isInSavedItems ? .blue : .secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("Saved Items")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text("\(savedItemsCount) item\(savedItemsCount == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if !store.collections.isEmpty {
                    Section {
                        ForEach(store.collections) { collection in
                            Button(action: {
                                if selectedCollectionIds.contains(collection.id) {
                                    selectedCollectionIds.remove(collection.id)
                                    store.removeRecommendationFromCollection(recommendationId, collectionId: collection.id)
                                } else {
                                    selectedCollectionIds.insert(collection.id)
                                    store.addRecommendationToCollection(recommendationId, collectionId: collection.id)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedCollectionIds.contains(collection.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedCollectionIds.contains(collection.id) ? .blue : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(collection.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let description = collection.description, !description.isEmpty {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        
                                        Text("\(collection.recommendationIds.count) item\(collection.recommendationIds.count == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No Collections Yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Create a collection to organize your recommendations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            NavigationLink(destination: CollectionsView()) {
                                Text("Go to Collections")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedCollectionIds = Set(store.getCollectionsContaining(recommendationId).map { $0.id })
            isInSavedItems = store.savedRecommendations.contains(recommendationId)
        }
    }
}

