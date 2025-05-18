import Foundation

struct AppNotification: Identifiable, Encodable, Decodable {
    let id: String
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    
    var minutesLeft: Int? {
        let interval = date.timeIntervalSince(Date())
        if interval < 0 { return nil }
        return Int(round(interval / 60))
    }
}