import Foundation

enum ReminderOption: String, CaseIterable, Identifiable, Codable {
    case none
    case atTime
    case fiveMinutesBefore
    case tenMinutesBefore
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case oneHourBefore

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .none: return "No Reminder"
        case .atTime: return "At Start Time"
        case .fiveMinutesBefore: return "5 Minutes Before"
        case .tenMinutesBefore: return "10 Minutes Before"
        case .fifteenMinutesBefore: return "15 Minutes Before"
        case .thirtyMinutesBefore: return "30 Minutes Before"
        case .oneHourBefore: return "1 Hour Before"
        }
    }

    var offset: TimeInterval? {
        switch self {
        case .none: return nil
        case .atTime: return 0
        case .fiveMinutesBefore: return 5 * 60
        case .tenMinutesBefore: return 10 * 60
        case .fifteenMinutesBefore: return 15 * 60
        case .thirtyMinutesBefore: return 30 * 60
        case .oneHourBefore: return 60 * 60
        }
    }
} 