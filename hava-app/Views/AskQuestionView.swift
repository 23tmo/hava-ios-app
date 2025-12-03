import SwiftUI

struct AskQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var questionText = ""
    @State private var location = ""
    @State private var selectedFriends: Set<String> = []
    @State private var visibility: QuestionVisibility = .friendsOnly
    @State private var urgencyLevel: UrgencyLevel = .normal
    @State private var showShareSheet = false
    @State private var shareText: String = ""
    @State private var shareURL: URL? = nil
    
    let friends = ["Sarah", "Mike", "Alex", "Jenny", "Tom"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading) {
                        Text("Does anyone have a recommendation for...")
                            .font(.headline)
                        
                        TextEditor(text: $questionText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.headline)
                        
                        TextField("e.g., Brooklyn, NYC or Near 10001", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Ask these friends:")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(friends, id: \.self) { friend in
                                    FriendChip(
                                        name: friend,
                                        isSelected: selectedFriends.contains(friend),
                                        action: {
                                            if selectedFriends.contains(friend) {
                                                selectedFriends.remove(friend)
                                            } else {
                                                selectedFriends.insert(friend)
                                            }
                                        }
                                    )
                                }
                                
                                Button(action: {}) {
                                    Text("+ Add more")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Urgency Level")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            Button(action: { urgencyLevel = .urgent }) {
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                    Text("Urgent")
                                        .font(.subheadline)
                                    Spacer()
                                    if urgencyLevel == .urgent {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(urgencyLevel == .urgent ? Color.red.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(urgencyLevel == .urgent ? .red : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(urgencyLevel == .urgent ? Color.red : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(8)
                            }
                            
                            Button(action: { urgencyLevel = .weekend }) {
                                HStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 12, height: 12)
                                    Text("Weekend Plans")
                                        .font(.subheadline)
                                    Spacer()
                                    if urgencyLevel == .weekend {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(urgencyLevel == .weekend ? Color.orange.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(urgencyLevel == .weekend ? .orange : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(urgencyLevel == .weekend ? Color.orange : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(8)
                            }
                            
                            Button(action: { urgencyLevel = .normal }) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                    Text("Normal")
                                        .font(.subheadline)
                                    Spacer()
                                    if urgencyLevel == .normal {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(urgencyLevel == .normal ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .foregroundColor(urgencyLevel == .normal ? .blue : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(urgencyLevel == .normal ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(8)
                            }
                        }
                        
                        Text("Urgent: Time-sensitive requests that need immediate attention. Weekend Plans: For weekend activities. Normal: Standard requests.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Who can see this question?")
                            .font(.headline)
                        
                        HStack(spacing: 0) {
                            Button(action: { visibility = .friendsOnly }) {
                                Text("Friends Only")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(visibility == .friendsOnly ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(visibility == .friendsOnly ? .white : .gray)
                            }
                            
                            Button(action: { visibility = .friendsOfFriends }) {
                                Text("Friends of Friends")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(visibility == .friendsOfFriends ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(visibility == .friendsOfFriends ? .white : .gray)
                            }
                        }
                        .cornerRadius(8)
                        
                        Text("Friends Only: Only people you directly ask can see and respond. Friends of Friends: Your friends can share with their friends too.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    
                    
                    Button(action: submitQuestion) {
                        Text("Share this question with friends")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(questionText.isEmpty || location.isEmpty || selectedFriends.isEmpty)
                    .sheet(isPresented: $showShareSheet, onDismiss: { dismiss() }) {
                        if let url = shareURL {
                            ShareSheet(activityItems: [shareText, url])
                        } else {
                            ShareSheet(activityItems: [shareText])
                        }
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works:")
                            .font(.headline)
                        
                        Text("• Choose how to share (text, email, etc.)")
                        Text("• Friends get a link to respond in the app")
                        Text("• All recommendations saved here for you")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Ask Friends")
                        .font(.headline)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hide Keyboard") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
    
    private func submitQuestion() {
        var newQuestion = Question(
            id: UUID().uuidString,
            userId: store.currentUser.id,
            text: questionText,
            location: location,
            timestamp: Date(),
            visibility: visibility,
            selectedFriends: Array(selectedFriends)
        )
        newQuestion.urgencyLevel = urgencyLevel
        store.questions.append(newQuestion)
        store.saveQuestions()
        
        
        let webURLString = "https://example.com/question/\(newQuestion.id)"
        let shareText = """
        \(store.currentUser.name) wants you to recommend them this:
        "\(newQuestion.text)"
        Location: \(newQuestion.location)
        
        Tap here to help: \(webURLString)
        """
        self.shareText = shareText
        self.shareURL = URL(string: webURLString)
        showShareSheet = true
    }
}

struct FriendChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(16)
        }
    }
} 