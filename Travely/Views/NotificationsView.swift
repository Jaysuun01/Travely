import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var hasAppeared = false
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.black)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                List {
                    ForEach(appViewModel.notifications) { notification in
                        NotificationCard(notification: notification)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                if hasAppeared {
                                    appViewModel.updateNotificationReadStatus(notification)
                                }
                            }
                    }
                    .onDelete { indexSet in
                        appViewModel.deleteNotification(at: indexSet)
                    }
                }
                .listStyle(PlainListStyle())

                // Floating Clear Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showClearConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Color.red)
                                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                                .scaleEffect(showClearConfirmation ? 0.95 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: showClearConfirmation)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Clear All Notifications")
                        .padding(.bottom, 32)
                        .padding(.trailing, 24)
                    }
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                }
                appViewModel.loadNotifications()
            }
            .alert(isPresented: $showClearConfirmation) {
                Alert(
                    title: Text("Clear All Notifications?"),
                    message: Text("Are you sure you want to clear all notifications? This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear")) {
                        appViewModel.clearNotifications()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct NotificationCard: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? Color.gray.opacity(0.3) : Color.orange)
                    .frame(width: 36, height: 36)
                Image(systemName: notification.isRead ? "bell" : "bell.fill")
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .gray : .primary)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(notification.isRead ? .gray : .primary)
                Text(notification.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppViewModel())
}


