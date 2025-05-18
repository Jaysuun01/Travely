import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var hasAppeared = false

    var body: some View {
        NavigationView {
            List {
                ForEach(appViewModel.notifications) { notification in
                    NotificationCard(notification: notification)
                        .onAppear {
                            if hasAppeared {
                                appViewModel.updateNotificationReadStatus(notification)
                            }
                        }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        appViewModel.clearNotifications()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                }
                appViewModel.loadNotifications()
            }
        }
    }
}

struct NotificationCard: View {
    let notification: AppNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(.vertical, 8)
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppViewModel())
}


