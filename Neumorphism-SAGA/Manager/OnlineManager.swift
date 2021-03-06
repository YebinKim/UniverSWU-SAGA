//
//  OnlineManager.swift
//  PlanetSAGA
//
//  Created by Yebin Kim on 2020/03/11.
//  Copyright © 2020 김예빈. All rights reserved.
//

import Foundation
import Firebase

class OnlineManager: NSObject {
    
    static var online: Bool = false
    
    static var user: User?
    static var userInfo: UserInfo? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUser"), object: nil)
        }
    }
    
    static func registerUser() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AuthStateDidChange, object: Auth.auth(), queue: nil) { _ in
            if let user = Auth.auth().currentUser {
                self.online = true
                self.user = User(authData: user)
                self.updateUserInfo(user.uid)
            } else {
                self.online = false
                self.user = nil
                self.userInfo = nil
            }
        }
    }
    
    static func createUser(email: String?, password: String?, name: String?, completion: @escaping (Error?) -> Void) {
        guard let email = email,
            let password = password,
            let name = name else { return }
        
        Auth.auth().createUser(withEmail: email,
                               password: password) { user, error in
                                if let error = error, user == nil {
                                    print("Create User Error: \(error.localizedDescription)")
                                    completion(error)
                                } else {
                                    let userInfo = UserInfo(email: email,
                                                            name: name)
                                    let userInfoRef = PSDatabase.userInfoRef.child(user!.user.uid)
                                    userInfoRef.setValue(userInfo.toAnyObject())
                                    
                                    completion(nil)
                                }
        }
    }
    
    static func signInUser(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard let email = email,
            let password = password else { return }
        
        Auth.auth().signIn(withEmail: email,
                           password: password) { _, error in
                            completion(error)
        }
    }
    
    static func signOutUser() {
        if self.user != nil {
            do {
                try Auth.auth().signOut()
            } catch {
                print("SignOut Error: \(error.localizedDescription)")
            }
        }
    }
    
    static func deleteUser(password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser,
            let password = password else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)
        user.reauthenticate(with: credential, completion: { (_, error) in
            if let error = error {
                print("Reauthentication Password Error: \(error.localizedDescription)")
            } else {
                user.delete { error in
                    if error != nil {
                        self.online = false
                        self.user = nil
                        self.userInfo = nil
                    }
                    completion(error)
                }
            }
        })
    }
    
    static func updateUserInfo(_ uid: String?) {
        guard let uid = uid else { return }
        PSDatabase.userInfoRef
            .queryEqual(toValue: nil, childKey: uid)
            .observeSingleEvent(of: .value, with: { snapshot in
                guard let child = snapshot.children.allObjects.first,
                    let snapshot = child as? DataSnapshot else { return }
                
                self.userInfo = UserInfo(snapshot: snapshot)
                
                let storageRef = PSDatabase.storageRef.child(uid)
                storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error, data == nil {
                        print("Update User Error: \(error.localizedDescription)")
                    } else {
                        self.userInfo?.profileImage = UIImage(data: data!)
                    }
                }
            })
    }
    
    static func updateUserName(_ name: String?, completion: @escaping () -> Void) {
        guard let user = user,
            let name = name else { return }
        let userInfoRef = PSDatabase.userInfoRef.child(user.uid)
        userInfoRef.updateChildValues(UserInfo.toName(name: name))
        
        updateUserInfo(user.uid)
        completion()
    }
    
    static func updateUserPassword(oldPassword: String?, newPassword: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser,
            let oldPassword = oldPassword,
            let newPassword = newPassword else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: oldPassword)
        user.reauthenticate(with: credential, completion: { (_, error) in
            if let error = error {
                print("Reauthentication Password Error: \(error.localizedDescription)")
            } else {
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    completion(error)
                }
            }
        })
    }
    
}
