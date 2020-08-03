//
//  GameConnection.swift
//  PokerNowGrabber
//
//  Created by PJ Gray on 7/10/20.
//  Copyright © 2020 Say Goodnight Software. All rights reserved.
//

import Foundation
import SocketIO
import PokerNowKit

class GameConnection: NSObject {

    var debug: Bool = false
    var manager: SocketManager?
    var connected: Bool = false
    
    
    var ready = false
    var loadedRUP = false
    
    var startTime: Int?
    
    var players: [Player] = []
    
    var heroName: String?
    var npt: String?
    var dpt: String?
    var handHistoryDirectory: String?
    var multiplier: Double?
    
    init(gameIdOrURL: String, heroName: String?, npt: String?, dpt: String?, handHistoryDirectory: String?, multiplier: Double?) {
        super.init()

        struct GameState : Codable {
            var players: [String:Player]?
        }

        self.heroName = heroName
        self.multiplier = multiplier
        self.npt = npt
        self.dpt = dpt
        self.handHistoryDirectory = handHistoryDirectory
        let gameIdOrURL = gameIdOrURL

        let group = DispatchGroup()
        
        let gameId = gameIdOrURL.replacingOccurrences(of: "https://www.pokernow.club/games/", with: "")
        
        print("Connecting to: \(gameId)...")
        let request = URLRequest(url: URL(string: "https://www.pokernow.club/games/\(gameId)")!)

        group.enter()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let url = response?.url,
                let httpResponse = response as? HTTPURLResponse,
                let fields = httpResponse.allHeaderFields as? [String: String]
            else { return }

            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
            for cookie in cookies {
                var cookieProperties = [HTTPCookiePropertyKey: Any]()
                cookieProperties[.name] = cookie.name
                cookieProperties[.value] = cookie.value
                cookieProperties[.domain] = cookie.domain
                cookieProperties[.path] = cookie.path
                cookieProperties[.version] = cookie.version
                cookieProperties[.expires] = Date().addingTimeInterval(31536000)

                let newCookie = HTTPCookie(properties: cookieProperties)
                HTTPCookieStorage.shared.setCookie(newCookie!)
            }

            group.leave()
            
        }
        task.resume()


        group.notify(queue: DispatchQueue.main) {
            self.manager = SocketManager(socketURL: URL(string: "http://www.pokernow.club/")!, config: [.log(false), .cookies(HTTPCookieStorage.shared.cookies!), .forceWebsockets(true), .connectParams(["gameID":gameId])])
            
            let socket = self.manager?.defaultSocket
            socket?.on(clientEvent: .connect) {data, ack in
                if !self.connected {
                    socket?.emit("action", ["type":"RUP"])
                   self.connected = true
                }
            }

            socket?.on("rup", callback: { (json, ack) in
                self.loadedRUP = true
                
                print("**** Connected - Loaded RUP")
            })

            socket?.on("gC", callback: { (newStateArray, ack) in
                if self.loadedRUP {
                    if let json = newStateArray.first as? [String:Any] {
                        if (json["gT"] as? String) == "gameResult" {
                            print("**** Detected End of Hand")
                            if let now = json["now"] as? Int {
                                let nowTime = now * 100
                                if let startTime = self.startTime {
                                    print("**** Writing raw hand history log: \(nowTime)")
                                    self.writeHandLog(gameId: gameId, startTime: startTime, endTime: nowTime)
                                }
                                self.startTime = nowTime
                            }
                        }
                    }
                }
            })

            socket?.connect()
        }
        

    }

    func writeHandLog(gameId: String, startTime: Int, endTime: Int) {
        let urlString =  "https://www.pokernow.club/games/\(gameId)/log?after_at=\(startTime)&before_at=\(endTime)"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)

        struct LogEntry : Codable {
            let msg: String?
            let at: String?
            let createdAt: String?
        }
        struct LogResponse : Codable {
            let logs: [LogEntry]?
        }

        if let npt = self.npt {
            var cookieString = "npt=\(npt)"
            if let dpt = self.dpt {
                cookieString = "\(cookieString);dpt=\(dpt)"
            }
            request.allHTTPHeaderFields = ["Cookie":cookieString]
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let logResponse = try decoder.decode(LogResponse.self, from: data)
                    
                    var foundEnding = false
                    var foundStarting = false
                    var rows: [[String:String]] = []
                    
                    //let _ = logResponse.logs?.map({ print($0.msg ?? "") })
                    
                    for log in logResponse.logs ?? [] {
                        if let msg = log.msg, let at = log.at, let order = log.createdAt {
                            if msg.contains("-- ending hand") {
                                foundEnding = true
                            }
                            if foundEnding && !foundStarting {
                                rows.append([
                                    "entry":msg,
                                    "at":"\(at)",
                                    "order":"\(order)"
                                ])
                            }
                            
                            if msg.contains("-- starting hand") {
                                foundStarting = true
                            }
                        }
                    }
                    
                    if let heroName = self.heroName, let handHistoryDirectory = self.handHistoryDirectory {
                        let game = Game(rows: rows)
                        let pokerStarsLines = game.hands.first?.getPokerStarsDescription(heroName: heroName, multiplier: self.multiplier ?? 0.01, tableName: "\(gameId)")
                        let output = pokerStarsLines?.joined(separator: "\n") ?? ""
                        let outputURL = URL(fileURLWithPath: "\(handHistoryDirectory)/pokernowgrabber_hand_\(endTime).txt")
                        try output.write(to: outputURL, atomically: false, encoding: .utf8)
                    }
                } catch let error {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    
}
