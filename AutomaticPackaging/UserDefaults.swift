//
//  UserDefaults.swift
//  AutomaticPackaging
//
//  Created by 马洪亮 on 2020/4/18.
//

import Foundation


public func getUserDefaultsValue(key:String) -> String {
    
    return UserDefaults.standard.value(forKey: key) as? String ?? ""
    
}

public func serUserDefaultsValue(key:String,value:String) -> Void {
    
    UserDefaults.standard.setValue(value, forKey: key)
    
}
