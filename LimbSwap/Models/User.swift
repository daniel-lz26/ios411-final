import Foundation

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var location: String
    var amputationType: AmputationType
    var affectedSide: Side
    var profileImageURL: String?
    var createdAt: Date
    
    enum AmputationType: String, Codable, CaseIterable {
        case belowKnee = "Below Knee"
        case aboveKnee = "Above Knee"
        case belowElbow = "Below Elbow"
        case aboveElbow = "Above Elbow"
        case foot = "Foot"
        case hand = "Hand"
    }
    
    enum Side: String, Codable, CaseIterable {
        case left = "Left"
        case right = "Right"
        case both = "Both"
    }
}