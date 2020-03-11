//
//  UserInfo.swift
//  PlanetSAGA
//
//  Created by Yebin Kim on 2020/03/09.
//  Copyright © 2020 김예빈. All rights reserved.
//

import UIKit
import Firebase

struct UserInfo {
    
    let ref: DatabaseReference?
    let key: String
    
    var name: String
    var profilePicURL: String = ""
    var maxScore: Int = 0
    var playCounts: Int = 0
    
    init(email: String, name: String, key: String = "") {
        self.ref = nil
        self.key = key
        
        self.name = name
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String else {
                return nil
        }
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        
        self.name = name
    }
    
    func toAnyObject() -> [AnyHashable: Any] {
        return [
            "name": self.name,
            "profilePicURL": self.profilePicURL,
            "maxScore": self.maxScore,
            "playCounts": self.playCounts
        ]
    }
    
    static func toName(name: String) -> [AnyHashable: Any] {
        return [
            "name": name
        ]
    }
    
    static func toProfilePic(profilePicURL: String) -> [AnyHashable: Any] {
        return [
            "profilePicURL": profilePicURL
        ]
    }
    
    static func toPlayScore(maxScore: Int, playCounts: Int) -> [AnyHashable: Any] {
        return [
            "maxScore": maxScore,
            "playCounts": playCounts
        ]
    }
    
}
