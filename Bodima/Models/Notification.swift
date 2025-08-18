import Foundation

// MARK: - Notification Model
struct NotificationModel: Codable, Identifiable {
    let id: String
    let description: String
    var isTouched: Bool
    let createdAt: String
    let updatedAt: String
    let isToday: Bool
    let isYesterday: Bool
    let isPast: Bool
    let v: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case description
        case isTouched
        case createdAt
        case updatedAt
        case isToday
        case isYesterday
        case isPast
        case v = "__v"
    }
    
    // Helper computed properties for UI
    var formattedDate: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            // Format the date from createdAt
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let date = dateFormatter.date(from: createdAt) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMM d, yyyy"
                return displayFormatter.string(from: date)
            }
            return "Some time ago"
        }
    }
    
    var timeAgo: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: createdAt) else {
            return "Unknown time"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "\(day) day ago" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "\(hour) hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "\(minute) minute ago" : "\(minute) minutes ago"
        }
        
        return "Just now"
    }
}

// MARK: - Notification Response
struct NotificationResponse: Codable {
    let success: Bool
    let data: [NotificationModel]
}
