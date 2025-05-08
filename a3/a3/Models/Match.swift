import Foundation
import FirebaseFirestore

struct Match: Codable {
    let id: String?
    let home: Team
    let away: Team
    let status: String
    let currentQuarter: Int
    let startTime: TimeInterval
    let lastAction: Action?
    let matchStarted: Bool
    let date: String
    
    struct Team: Codable {
        let name: String
        var players: [Player]
        var actions: [Action]
    }
    
    struct Action: Codable {
        let action: String
        let actionTeam: String
        let time: String
        let playerName: String
        let positionNumber: Int
        let actionQuarter: Int
    }
}

extension Match {
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let homeData = data["home"] as? [String: Any],
              let awayData = data["away"] as? [String: Any],
              let homeName = homeData["name"] as? String,
              let awayName = awayData["name"] as? String,
              let status = data["status"] as? String,
              let currentQuarter = data["currentQuarter"] as? Int,
              let startTime = data["startTime"] as? TimeInterval,
              let matchStarted = data["matchStarted"] as? Bool,
              let date = data["date"] as? String else {
            self.id = nil
            self.home = Team(name: "", players: [], actions: [])
            self.away = Team(name: "", players: [], actions: [])
            self.status = ""
            self.currentQuarter = 0
            self.startTime = 0
            self.lastAction = nil
            self.matchStarted = false
            self.date = ""
            return nil
        }
        
        let homePlayers = (homeData["players"] as? [[String: Any]] ?? []).compactMap { playerData in
            Player.from(dictionary: playerData)
        }
        
        let awayPlayers = (awayData["players"] as? [[String: Any]] ?? []).compactMap { playerData in
            Player.from(dictionary: playerData)
        }
        
        let homeActions = (homeData["actions"] as? [[String: Any]] ?? []).compactMap { actionData -> Action? in
            guard let action = actionData["action"] as? String,
                  let actionTeam = actionData["actionTeam"] as? String,
                  let time = actionData["time"] as? String,
                  let playerName = actionData["playerName"] as? String,
                  let positionNumber = actionData["positionNumber"] as? Int,
                  let actionQuarter = actionData["actionQuarter"] as? Int else {
                return nil
            }
            return Action(action: action,
                         actionTeam: actionTeam,
                         time: time,
                         playerName: playerName,
                         positionNumber: positionNumber,
                         actionQuarter: actionQuarter)
        }
        
        let awayActions = (awayData["actions"] as? [[String: Any]] ?? []).compactMap { actionData -> Action? in
            guard let action = actionData["action"] as? String,
                  let actionTeam = actionData["actionTeam"] as? String,
                  let time = actionData["time"] as? String,
                  let playerName = actionData["playerName"] as? String,
                  let positionNumber = actionData["positionNumber"] as? Int,
                  let actionQuarter = actionData["actionQuarter"] as? Int else {
                return nil
            }
            return Action(action: action,
                         actionTeam: actionTeam,
                         time: time,
                         playerName: playerName,
                         positionNumber: positionNumber,
                         actionQuarter: actionQuarter)
        }
        
        let lastActionData = data["lastAction"] as? [String: Any]
        let lastAction: Action?
        if let lastActionData = lastActionData {
            guard let action = lastActionData["action"] as? String,
                  let actionTeam = lastActionData["actionTeam"] as? String,
                  let time = lastActionData["time"] as? String,
                  let playerName = lastActionData["playerName"] as? String,
                  let positionNumber = lastActionData["positionNumber"] as? Int,
                  let actionQuarter = lastActionData["actionQuarter"] as? Int else {
                self.id = nil
                self.home = Team(name: "", players: [], actions: [])
                self.away = Team(name: "", players: [], actions: [])
                self.status = ""
                self.currentQuarter = 0
                self.startTime = 0
                self.lastAction = nil
                self.matchStarted = false
                self.date = ""
                return nil
            }
            lastAction = Action(action: action,
                                actionTeam: actionTeam,
                                time: time,
                                playerName: playerName,
                                positionNumber: positionNumber,
                                actionQuarter: actionQuarter)
        } else {
            lastAction = nil
        }
        
        self.id = document.documentID
        self.home = Team(name: homeName, players: homePlayers, actions: homeActions)
        self.away = Team(name: awayName, players: awayPlayers, actions: awayActions)
        self.status = status
        self.currentQuarter = currentQuarter
        self.startTime = startTime
        self.lastAction = lastAction
        self.matchStarted = matchStarted
        self.date = date
    }
}
