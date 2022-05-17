//
//  Metadata.swift
//  SYPictureMetadata
//
//  Created by Stanislas Chevallier on 20/01/2020.
//  Copyright © 2020 Syan.me. All rights reserved.
//

import Foundation
import ImageIO
import Photos

// http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/index.html
// http://www.exiv2.org/tags.html

public class Metadata: MetadataBase {

    public enum Error: Swift.Error, Equatable {
        case photoMissingData
        case notAFileURL
        case cannotCreateSource
        case cannotCreateDestination
        case cannotCopyPropertiesAtIndexZero
        case cannotDetermineSourceImageType
        case cannotCreateDataFromDestination
        case emptyData
        case unknown
    }
    
    // MARK: Init
    public required init(dictionary: Dictionary<String, Any>) {
        super.init(dictionary: dictionary)
    }
    
    @available(iOS 10.0, tvOS 10.0, macCatalyst 13.0, macOS 10.15, *)
    public static func metadata(asset: PHAsset, networkAccessAllowed: Bool, completion: @escaping (Metadata?, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = networkAccessAllowed
        
        let completion = { (data: Data?) -> Void in
            guard let data = data else { return completion(nil, .photoMissingData) }
            do {
                let metadata = try Metadata(imageData: data)
                completion(metadata, nil)
            }
            catch {
                completion(nil, (error as! Error))
            }
        }
        
        #if os(macOS) || targetEnvironment(macCatalyst)
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (data, _, _, _) in  completion(data) }
        #else
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (data, _, _, _) in completion(data) }
        #endif
    }
    
    public convenience init(fileURL: URL) throws {
        guard fileURL.isFileURL else { throw Error.notAFileURL }
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { throw Error.cannotCreateSource }

        let options = [kCGImageSourceShouldCache.string: false]
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options as CFDictionary) as? [String: Any] else { throw Error.cannotCopyPropertiesAtIndexZero }
        
        self.init(dictionary: properties)
    }

    public convenience init(imageData: Data) throws {
        guard imageData.count > 0 else { throw Error.emptyData }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { throw Error.cannotCreateSource }

        let options = [kCGImageSourceShouldCache.string: false]
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options as CFDictionary) as? [String: Any] else { throw Error.cannotCopyPropertiesAtIndexZero }
        
        self.init(dictionary: properties)
    }
    
    // MARK: Image Data
    @discardableResult
    public static func apply(metadata: [String: Any], to originalImageData: Data) throws -> Data {
        // https://github.com/Nikita2k/SimpleExif/blob/master/Classes/ios/UIImage%2BExif.m
        guard let source = CGImageSourceCreateWithData(originalImageData as CFData, nil) else {
            throw Error.cannotCreateSource
        }

        guard let sourceImageType = CGImageSourceGetType(source) else {
            throw Error.cannotDetermineSourceImageType
        }
        
        let count = CGImageSourceGetCount(source)
        
        // create a new data object and write the new image into it
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.rawImage as! CFString, count, nil) else {
            throw Error.cannotCreateDestination
        }
        
        // add the image contained in the image source to the destination, overidding the old metadata with our modified
        CGImageDestinationSetProperties(destination, metadata as CFDictionary)
        (0..<count).forEach { (index) in
            CGImageDestinationAddImageFromSource(destination, source, index, metadata as CFDictionary)
        }
        
        let finalizeSuccess = CGImageDestinationFinalize(destination)
        guard finalizeSuccess else {
            throw Error.cannotCreateDataFromDestination
        }
        
        return data as Data
    }

    public func apply(to originalImageData: Data) throws -> Data {
        return try Metadata.apply(metadata: currentDictionary, to: originalImageData)
    }
    
    public static func stripAllMetadata(from originalImageData: Data) throws -> Data {
        let metadata = try Metadata(imageData: originalImageData)
        // As per documentation, if you need a key removed, assign it kCFNull
        let keysToKeep = [kCGImagePropertyOrientation.string]
        let keysToClear = metadata.originalDictionary.keys.filter { k in !keysToKeep.contains(k) }
        let clearDic = keysToClear.reduce(into: [String: Any]()) { res, key in res[key] = kCFNull }
        return try Metadata.apply(metadata: clearDic, to: originalImageData)
    }
    
    // MARK: Children
    internal override class var childrenMappings: [String: MetadataBase.Type] {
        return [
            kCGImagePropertyTIFFDictionary.string: MetadataTIFF.self,
            kCGImagePropertyExifDictionary.string: MetadataExif.self,
            kCGImagePropertyExifAuxDictionary.string: MetadataExifAux.self,
            kCGImagePropertyGIFDictionary.string: MetadataGIF.self,
            kCGImagePropertyJFIFDictionary.string: MetadataJFIF.self,
            kCGImagePropertyPNGDictionary.string: MetadataPNG.self,
            kCGImagePropertyIPTCDictionary.string: MetadataIPTC.self,
            kCGImagePropertyGPSDictionary.string: MetadataGPS.self,
            kCGImagePropertyRawDictionary.string: MetadataRaw.self,
            kCGImagePropertyCIFFDictionary.string: MetadataCIFF.self,
            kCGImagePropertyMakerAppleDictionary.string: MetadataMakerApple.self,
            kCGImagePropertyMakerCanonDictionary.string: MetadataMakerCanon.self,
            kCGImagePropertyMakerNikonDictionary.string: MetadataMakerNikon.self,
            kCGImagePropertyMakerMinoltaDictionary.string: MetadataMakerMinolta.self,
            kCGImagePropertyMakerFujiDictionary.string: MetadataMakerFuji.self,
            kCGImagePropertyMakerOlympusDictionary.string: MetadataMakerOlympus.self,
            kCGImagePropertyMakerPentaxDictionary.string: MetadataMakerPentax.self,
            kCGImageProperty8BIMDictionary.string: Metadata8BIM.self,
            kCGImagePropertyDNGDictionary.string: MetadataDNG.self
        ]
    }
    
    public var metadataTIFF: MetadataTIFF? {
        get { getChildren(key: kCGImagePropertyTIFFDictionary.string) }
        set { setChildren(key: kCGImagePropertyTIFFDictionary.string, value: newValue) }
    }
    
    public var metadataExif: MetadataExif? {
        get { getChildren(key: kCGImagePropertyExifDictionary.string) }
        set { setChildren(key: kCGImagePropertyExifDictionary.string, value: newValue) }
    }
    
    public var metadataExifAux: MetadataExifAux? {
        get { getChildren(key: kCGImagePropertyExifAuxDictionary.string) }
        set { setChildren(key: kCGImagePropertyExifAuxDictionary.string, value: newValue) }
    }
    
    public var metadataGIF: MetadataGIF? {
        get { getChildren(key: kCGImagePropertyGIFDictionary.string) }
        set { setChildren(key: kCGImagePropertyGIFDictionary.string, value: newValue) }
    }
    
    public var metadataJFIF: MetadataJFIF? {
        get { getChildren(key: kCGImagePropertyJFIFDictionary.string) }
        set { setChildren(key: kCGImagePropertyJFIFDictionary.string, value: newValue) }
    }
    
    public var metadataPNG: MetadataPNG? {
        get { getChildren(key: kCGImagePropertyPNGDictionary.string) }
        set { setChildren(key: kCGImagePropertyPNGDictionary.string, value: newValue) }
    }
    
    public var metadataIPTC: MetadataIPTC? {
        get { getChildren(key: kCGImagePropertyIPTCDictionary.string) }
        set { setChildren(key: kCGImagePropertyIPTCDictionary.string, value: newValue) }
    }
    
    public var metadataGPS: MetadataGPS? {
        get { getChildren(key: kCGImagePropertyGPSDictionary.string) }
        set { setChildren(key: kCGImagePropertyGPSDictionary.string, value: newValue) }
    }
    
    public var metadataRaw: MetadataRaw? {
        get { getChildren(key: kCGImagePropertyRawDictionary.string) }
        set { setChildren(key: kCGImagePropertyRawDictionary.string, value: newValue) }
    }
    
    public var metadataCIFF: MetadataCIFF? {
        get { getChildren(key: kCGImagePropertyCIFFDictionary.string) }
        set { setChildren(key: kCGImagePropertyCIFFDictionary.string, value: newValue) }
    }

    public var metadataMakerApple: MetadataMakerApple? {
        get { getChildren(key: kCGImagePropertyMakerAppleDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerAppleDictionary.string, value: newValue) }
    }

    public var metadataMakerCanon: MetadataMakerCanon? {
        get { getChildren(key: kCGImagePropertyMakerCanonDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerCanonDictionary.string, value: newValue) }
    }
    
    public var metadataMakerNikon: MetadataMakerNikon? {
        get { getChildren(key: kCGImagePropertyMakerNikonDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerNikonDictionary.string, value: newValue) }
    }
    
    public var metadataMakerMinolta: MetadataMakerMinolta? {
        get { getChildren(key: kCGImagePropertyMakerMinoltaDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerMinoltaDictionary.string, value: newValue) }
    }
    
    public var metadataMakerFuji: MetadataMakerFuji? {
        get { getChildren(key: kCGImagePropertyMakerFujiDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerFujiDictionary.string, value: newValue) }
    }
    
    public var metadataMakerOlympus: MetadataMakerOlympus? {
        get { getChildren(key: kCGImagePropertyMakerOlympusDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerOlympusDictionary.string, value: newValue) }
    }
    
    public var metadataMakerPentax: MetadataMakerPentax? {
        get { getChildren(key: kCGImagePropertyMakerPentaxDictionary.string) }
        set { setChildren(key: kCGImagePropertyMakerPentaxDictionary.string, value: newValue) }
    }

    public var metadata8BIM: Metadata8BIM? {
        get { getChildren(key: kCGImageProperty8BIMDictionary.string) }
        set { setChildren(key: kCGImageProperty8BIMDictionary.string, value: newValue) }
    }
    
    public var metadataDNG: MetadataDNG? {
        get { getChildren(key: kCGImagePropertyDNGDictionary.string) }
        set { setChildren(key: kCGImagePropertyDNGDictionary.string, value: newValue) }
    }
    
    // MARK: Types
    public enum ColorModel: String, CaseIterable {
        case rgb = "RGB"    // kCGImagePropertyColorModelRGB
        case gray = "Gray"  // kCGImagePropertyColorModelGray
        case cmyk = "CMYK"  // kCGImagePropertyColorModelCMYK
        case lab = "Lab"    // kCGImagePropertyColorModelLab
    }

    // MARK: Values
    public var fileSize: Int? {
        return getValue(key: kCGImagePropertyFileSize.string)
    }
    
    public var pixelHeight: Int? {
        return getValue(key: kCGImagePropertyPixelHeight.string)
    }
    
    public var pixelWidth: Int? {
        return getValue(key: kCGImagePropertyPixelWidth.string)
    }
    
    public var dpiHeight: Int? {
        return getValue(key: kCGImagePropertyDPIHeight.string)
    }
    
    public var dpiWidth: Int? {
        return getValue(key: kCGImagePropertyDPIWidth.string)
    }
    
    public var depth: Int? {
        return getValue(key: kCGImagePropertyDepth.string)
    }
    
    public var orientation: CGImagePropertyOrientation? {
        get { getValue(key: kCGImagePropertyOrientation.string) }
        set { setValue(key: kCGImagePropertyOrientation.string, value: newValue) }
    }
    
    public var isFloat: Bool? {
        return getValue(key: kCGImagePropertyIsFloat.string)
    }
    
    public var isIndexed: Bool? {
        return getValue(key: kCGImagePropertyIsIndexed.string)
    }
    
    public var hasAlpha: Bool? {
        return getValue(key: kCGImagePropertyHasAlpha.string)
    }
    
    public var colorModel: ColorModel? {
        return getValue(key: kCGImagePropertyColorModel.string)
    }
    
    public var profileName: String? {
        return getValue(key: kCGImagePropertyProfileName.string)
    }

    public var pictureStyle: Dictionary<String, Any>? {
        get { getValue(key: kSYImagePropertyPictureStyle.string) }
        set { setValue(key: kSYImagePropertyPictureStyle.string, value: newValue) }
    }
}
