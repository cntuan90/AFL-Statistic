import Foundation

struct Player: Codable {
    let id: String?
    let playerName: String
    let positionNumber: Int
    let image: String
    var injuryStatus: Bool
    
    init(id: String? = nil, playerName: String, positionNumber: Int, image: String = "", injuryStatus: Bool = false) {
        self.id = id
        self.playerName = playerName
        self.positionNumber = positionNumber
        self.image = image
        self.injuryStatus = injuryStatus
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id as Any,
            "playerName": playerName,
            "positionNumber": positionNumber,
            "image": image,
            "injuryStatus": injuryStatus
        ]
    }
    
    static func from(dictionary: [String: Any]) -> Player? {
        guard let playerName = dictionary["playerName"] as? String,
              let positionNumber = dictionary["positionNumber"] as? Int,
              let image = dictionary["image"] as? String,
              let injuryStatus = dictionary["injuryStatus"] as? Bool else {
            return nil
        }
        return Player(id: dictionary["id"] as? String,
                     playerName: playerName,
                     positionNumber: positionNumber,
                     image: image,
                     injuryStatus: injuryStatus)
    }
}
