import SwiftUI
import UserNotifications

struct RespondToQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var recommendationText = ""
    @State private var address = ""
    @State private var phoneNumber = ""
    @State private var website = ""
    
    let question: Question
    let asker: User
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        AsyncImage(url: URL(string: asker.avatarURL ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(asker.name)
                                .font(.headline)
                            Text("asked via text")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(question.text)
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Recommendation")
                        .font(.headline)
                    
                    TextEditor(text: $recommendationText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address (optional)")
                        .font(.headline)
                    TextField("e.g., 123 Main St, Brooklyn, NY", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number (optional)")
                        .font(.headline)
                    TextField("e.g., (555) 123-4567", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Website (optional)")
                        .font(.headline)
                    TextField("e.g., brooklyndental.com", text: $website)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                
                Button(action: submitRecommendation) {
                    Text("Submit Recommendation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                
                Button(action: { dismiss() }) {
                    Text("Skip - I don't have a recommendation")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
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
                Text("Help \(asker.name)")
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
    
    private func submitRecommendation() {
        store.addRecommendation(
            questionId: question.id,
            text: recommendationText,
            address: address.isEmpty ? nil : address,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            website: website.isEmpty ? nil : website
        )
        dismiss()
    }
}


struct RespondToQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        RespondToQuestionView(
            question: Question(
                id: "1",
                userId: "sarah",
                text: "Looking for a good dentist in Brooklyn",
                location: "Brooklyn",
                timestamp: Date(),
                visibility: .friendsOnly,
                selectedFriends: []
            ),
            asker: User(
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
        ).environmentObject(AppStore())
    }
} 