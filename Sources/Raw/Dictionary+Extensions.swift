//
//  File.swift
//  
//
//  Created by Christoffer Buusmann on 18/03/2022.
//

import Foundation

extension Dictionary where Key: CustomStringConvertible {
    var allKeyPaths: [String] {
        var keyPaths = [String]()
        
        for key in keys {
            let keyString = key.description
            keyPaths.append(keyString)
            
            if let subDic = self[key] as? [Key: Any] {
                let subKeyPaths = subDic.allKeyPaths.map { keyString + "." + $0 }
                keyPaths.append(contentsOf: subKeyPaths)
            }
        }
        
        return keyPaths
    }
}
