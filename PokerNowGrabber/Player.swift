//
//  Player.swift
//  PokerNowGrabber
//
//  Created by PJ Gray on 7/10/20.
//  Copyright © 2020 Say Goodnight Software. All rights reserved.
//

import Foundation

class Player: NSObject, Codable {
    enum Status : String, Codable {
        case inGame, watching, quiting, requestedGameIngress, waitingNextGameToEnter, standingUp
    }
    
    var id: String?
    var name: String?
    var status: Status?
}
