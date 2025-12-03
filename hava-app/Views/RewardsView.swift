import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showBadgeAnimation = false
    
    var userRewards: [Reward] {
        store.rewards.filter { $0.recipientUserId == store.currentUser.id }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Streak")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(store.userStreak.currentStreak) day\(store.userStreak.currentStreak == 1 ? "" : "s")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Best Streak")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(store.userStreak.longestStreak) day\(store.userStreak.longestStreak == 1 ? "" : "s")")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if store.userStreak.weeklyCount > 0 {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.blue)
                                Text("You've helped \(store.userStreak.weeklyCount) friend\(store.userStreak.weeklyCount == 1 ? "" : "s") this week!")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    
                    if !store.badges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Badges")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(store.badges) { badge in
                                    BadgeView(badge: badge)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Rewards")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if userRewards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No rewards yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Keep sharing recommendations! When friends use them, you'll see rewards here.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(userRewards) { reward in
                                RewardCardView(reward: reward)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Your Rewards")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BadgeView: View {
    let badge: Badge
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.iconName)
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            isAnimating = true
        }
    }
}

struct RewardCardView: View {
    let reward: Reward
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.title)
                .foregroundColor(.yellow)
                .frame(width: 50, height: 50)
                .background(Color.yellow.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.message)
                    .font(.headline)
                Text(timeAgo(from: reward.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

