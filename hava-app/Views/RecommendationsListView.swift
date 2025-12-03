import SwiftUI

struct RecommendationsListView: View {
    @EnvironmentObject private var store: AppStore
    let question: Question
    let asker: User

    @State private var showRespondSheet = false

    var recommendations: [Recommendation] {
        store.recommendations.filter { $0.questionId == question.id }
    }

    var body: some View {
        VStack {
            List {
                Section(header: Text("All Recommendations")) {
                    if recommendations.isEmpty {
                        Text("No recommendations yet. Be the first to respond!")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(recommendations) { rec in
                            NavigationLink(destination: RecommendationDetailView(recommendation: rec, question: question)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rec.text)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    if let address = rec.address, !address.isEmpty {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    if let phone = rec.phoneNumber, !phone.isEmpty {
                                        Text(phone)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    if let website = rec.website, !website.isEmpty {
                                        Text(website)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    HStack {
                                        Text("By \(rec.userId)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Button(action: {
                                            store.likeRecommendation(rec)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "hand.thumbsup")
                                                Text("\(rec.likes)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Button(action: { showRespondSheet = true }) {
                Text("Submit Another Recommendation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .navigationTitle("Responses")
        .sheet(isPresented: $showRespondSheet) {
            RespondToQuestionView(question: question, asker: asker)
                .environmentObject(store)
        }
    }
} 