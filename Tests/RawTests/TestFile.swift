//
//  File.swift
//  
//
//  Created by Christoffer Buusmann on 18/03/2022.
//

import Foundation
import Raw
enum TestFile: String, CaseIterable {
    case appleGPS = "TEST_APPLE_GPS.JPG"
    case fuliJPG = "DSCF5353.jpeg"
    case eightBim = "TEST_8BIM.psd"
    case canon = "TEST_CANON.cr2"
    case ciff = "TEST_CIFF.CRW"
    case dng = "TEST_DNG.dng"
    case gif = "TEST_GIF.gif"
    case iptc = "TEST_IPTC.jpg"
    case iptc2 = "TEST_IPTC_2.jpg"
    case nikon = "TEST_NIKON.nef"
    case pictureStyle = "TEST_PICTURESTYLE.CR2"
    case png = "TEST_PNG.png"
    case unreadable = "TEST_unreadable.txt"
    
    var url: URL! {
        Bundle(for: RawTests.self).url(forResource: rawValue, withExtension: nil, subdirectory: "files")
    }
    
    func readMetadata() throws -> Metadata {
        return try Metadata(fileURL: url)
    }
}
