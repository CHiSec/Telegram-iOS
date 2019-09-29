//
//  NGweb.swift
//  TelegramUI
//
//  Created by Sergey on 23/09/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Foundation
import Postbox
import TelegramCore

public var NGAPI = "https://my.nicegram.app/api/"
//public var SHOW_E = false
//public var BL_CH: [Int64] = []


public func ngAPIsetDefaults() {
    let UD = UserDefaults(suiteName: "NGAPISETTINGS")
    UD?.register(defaults: ["SHOW_E": false])
    UD?.register(defaults: ["BL_CH": []])
}

public class NGAPISETTINGS {
    let UD = UserDefaults(suiteName: "NGAPISETTINGS")
    
    public init() {
        ngAPIsetDefaults()
    }
    
    public var SHOW_E: Bool {
        get {
            return UD?.bool(forKey: "SHOW_E") ?? false
        }
        set {
            UD?.set(newValue, forKey: "SHOW_E")
        }
    }
    
    
    public var BL_CH: [Int64] {
        get {
            return UD?.array(forKey: "BL_CH") as? [Int64] ?? []
        }
        set {
            UD?.set(newValue, forKey: "BL_CH")
        }
        
    }
    
}


extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                ngApiLog(error.localizedDescription)
            }
        }
        return nil
    }
}

public func requestApi(_ path: String, pathParams: [String] = [], completion: @escaping (_ apiResult: [String: Any]?) -> Void) {
    let startTime = CFAbsoluteTimeGetCurrent()
    ngApiLog("DECLARING REQUEST \(path)")
    var urlString = NGAPI + path + "/"
    for param in pathParams {
        urlString = urlString + String(param) + "/"
    }
    let url = URL(string: urlString)!
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        ngApiLog("PROCESSED REQUEST \(path) IN \(timeElapsed) s.")
        if let error = error {
            ngApiLog("Error requesting settings: \(error)")
        } else {
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        completion(dataString.convertToDictionary())
                    }
                }
            }
        }
    }
    task.resume()
}

public func getNGEStatus(_ userId: Int64, completion: @escaping (_ result: Bool) -> Void) {
    requestApi("settings", pathParams: [String(userId)], completion: { (apiResponse) -> Void in
        var result = NGAPISETTINGS().SHOW_E
        
        if let response = apiResponse {
            if response["settings"] != nil {
                if (response["settings"]! as! [String: Any])["show_explicit"] != nil {
                    result = (response["settings"]! as! [String: Any])["show_explicit"] as! Bool
                }
            }
        }
        completion(result)
    })
}

public func getNGBlocked(completion: @escaping (_ result: [Int64]) -> Void) {
    requestApi("blocked", completion: { (apiResponse) -> Void in
        var result: [Int64] = []
        if let response = apiResponse {
            if response["chats"] != nil {
                for chat in response["chats"] as! [Any] {
                    if let chatId = (chat as! [String: Int64])["chat_id"] {
                        result.append(chatId)
                    }
                }
            }
        }
        completion(result)
    })
}

public func updateNGInfo(userId: Int64) {
    getNGEStatus(userId, completion: { (status) -> Void in
        NGAPISETTINGS().SHOW_E = status
        ngApiLog("[NGAPI] SHOW_E \(NGAPISETTINGS().SHOW_E)")
    })
    getNGBlocked(completion: { (blocked) -> Void in
        NGAPISETTINGS().BL_CH = blocked
        ngApiLog("[NGAPI] blocked \(NGAPISETTINGS().BL_CH)")
    })
}

public func isNGBlocked(_ peer: Peer?) -> Bool {
    if let peer = peer {
        var peerId: Int64
        if let peer = peer as? TelegramUser  {
            peerId = Int64(peer.id.hashValue)
        } else { // Channels, Chats, Groups
            peerId = Int64("-100" + String(peer.id.hashValue)) ?? 1
        }
        if NGAPISETTINGS().BL_CH.contains(peerId) {
            return true
        }
    }
    return false
}

public func canAccessE(peer: Peer?) -> Bool {
    if !NGAPISETTINGS().SHOW_E {
        return false
    }
    if isNGBlocked(peer) {
        return false
    }
    
    return true
}




// Logging


enum NGAPIManagedFileMode {
    case read
    case readwrite
    case append
}

private func wrappedWrite(_ fd: Int32, _ data: UnsafeRawPointer, _ count: Int) -> Int {
    return write(fd, data, count)
}

private func wrappedRead(_ fd: Int32, _ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
    return read(fd, data, count)
}

final class NGAPIManagedFile {
    private let fd: Int32
    private let mode: NGAPIManagedFileMode
    
    init?(path: String, mode: NGAPIManagedFileMode) {
        self.mode = mode
        let fileMode: Int32
        let accessMode: UInt16
        switch mode {
        case .read:
            fileMode = O_RDONLY
            accessMode = S_IRUSR
        case .readwrite:
            fileMode = O_RDWR | O_CREAT
            accessMode = S_IRUSR | S_IWUSR
        case .append:
            fileMode = O_WRONLY | O_CREAT | O_APPEND
            accessMode = S_IRUSR | S_IWUSR
        }
        let fd = open(path, fileMode, accessMode)
        if fd >= 0 {
            self.fd = fd
        } else {
            return nil
        }
    }
    
    deinit {
        close(self.fd)
    }
    
    func write(_ data: UnsafeRawPointer, count: Int) -> Int {
        return wrappedWrite(self.fd, data, count)
    }
    
    func read(_ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
        return wrappedRead(self.fd, data, count)
    }
    
    func readData(count: Int) -> Data {
        var result = Data(count: count)
        result.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Int8>) -> Void in
            let readCount = self.read(bytes, count)
            assert(readCount == count)
        }
        return result
    }
    
    func seek(position: Int64) {
        lseek(self.fd, position, SEEK_SET)
    }
    
    func truncate(count: Int64) {
        ftruncate(self.fd, count)
    }
    
    func getSize() -> Int? {
        var value = stat()
        if fstat(self.fd, &value) == 0 {
            return Int(value.st_size)
        } else {
            return nil
        }
    }
    
    func sync() {
        fsync(self.fd)
    }
}


public var ngApiLogger: NGAPILogger?

public final class NGAPILogger {
    private let maxLength: Int = 2 * 1024 * 1024
    private let maxFiles: Int = 20
    
    private let basePath: String
    private var file: (NGAPIManagedFile, Int)?
    
    var logToFile: Bool = true
    var logToConsole: Bool = true
    
    public static func setSharedLogger(_ logger: NGAPILogger) {
        ngApiLogger = logger
    }
    
    public static var shared: NGAPILogger {
        if let ngApiLogger = ngApiLogger {
            return ngApiLogger
        } else {
            assertionFailure()
            let tempLogger = NGAPILogger(basePath: "")
            tempLogger.logToFile = false
            tempLogger.logToConsole = false
            return tempLogger
        }
    }
    
    public init(basePath: String) {
        self.basePath = basePath
        //self.logToConsole = false
    }
    
    public func log(_ tag: String, _ what: @autoclosure () -> String) {
        if !self.logToFile && !self.logToConsole {
            return
        }
        
        let string = what()
        
        var rawTime = time_t()
        time(&rawTime)
        var timeinfo = tm()
        localtime_r(&rawTime, &timeinfo)
        
        var curTime = timeval()
        gettimeofday(&curTime, nil)
        let milliseconds = curTime.tv_usec / 1000
        
        var consoleContent: String?
        if self.logToConsole {
            let content = String(format: "[%@] %d-%d-%d %02d:%02d:%02d.%03d %@", arguments: [tag, Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds), string])
            consoleContent = content
            print(content)
        }
        
        if self.logToFile {
            let content: String
            if let consoleContent = consoleContent {
                content = consoleContent
            } else {
                content = String(format: "[%@] %d-%d-%d %02d:%02d:%02d.%03d %@", arguments: [tag, Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds), string])
            }
            
            var currentFile: NGAPIManagedFile?
            var openNew = false
            if let (file, length) = self.file {
                if length >= self.maxLength {
                    self.file = nil
                    openNew = true
                } else {
                    currentFile = file
                }
            } else {
                openNew = true
            }
            if openNew {
                let _ = try? FileManager.default.createDirectory(atPath: self.basePath, withIntermediateDirectories: true, attributes: nil)
                
                var createNew = false
                if let files = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: self.basePath), includingPropertiesForKeys: [URLResourceKey.creationDateKey], options: []) {
                    var minCreationDate: (Date, URL)?
                    var maxCreationDate: (Date, URL)?
                    var count = 0
                    for url in files {
                        if url.lastPathComponent.hasPrefix("log-") {
                            if let values = try? url.resourceValues(forKeys: Set([URLResourceKey.creationDateKey])), let creationDate = values.creationDate {
                                count += 1
                                if minCreationDate == nil || minCreationDate!.0 > creationDate {
                                    minCreationDate = (creationDate, url)
                                }
                                if maxCreationDate == nil || maxCreationDate!.0 < creationDate {
                                    maxCreationDate = (creationDate, url)
                                }
                            }
                        }
                    }
                    if let (_, url) = minCreationDate, count >= self.maxFiles {
                        let _ = try? FileManager.default.removeItem(at: url)
                    }
                    if let (_, url) = maxCreationDate {
                        var value = stat()
                        if stat(url.path, &value) == 0 && Int(value.st_size) < self.maxLength {
                            if let file = NGAPIManagedFile(path: url.path, mode: .append) {
                                self.file = (file, Int(value.st_size))
                                currentFile = file
                            }
                        } else {
                            createNew = true
                        }
                    } else {
                        createNew = true
                    }
                }
                
                if createNew {
                    let fileName = String(format: "log-%d-%d-%d_%02d-%02d-%02d.%03d.txt", arguments: [Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds)])
                    
                    let path = self.basePath + "/" + fileName
                    
                    if let file = NGAPIManagedFile(path: path, mode: .append) {
                        self.file = (file, 0)
                        currentFile = file
                    }
                }
            }
            
            if let currentFile = currentFile {
                if let data = content.data(using: .utf8) {
                    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                        let _ = currentFile.write(bytes, count: data.count)
                    }
                    var newline: UInt8 = 0x0a
                    let _ = currentFile.write(&newline, count: 1)
                    if let file = self.file {
                        self.file = (file.0, file.1 + data.count + 1)
                    } else {
                        assertionFailure()
                    }
                }
            }
        }
    }
}


public func ngApiLog(_ text: String, _ tag: String = "NGAPI") {
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let appGroupName = "group.\(baseAppBundleId)"
    let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
    
    if let appGroupUrl = maybeAppGroupUrl {
        let rootPath = appGroupUrl.path + "/telegram-data"
        
        if ngApiLogger == nil {
            let logsPath = rootPath + "/ngApiLogs"
            NGAPILogger.setSharedLogger(NGAPILogger(basePath: logsPath))
        }
    } else {
        let appBundleIdentifier = Bundle.main.bundleIdentifier!
        guard let lastDotRange = appBundleIdentifier.range(of: ".", options: [.backwards]) else {
            Logger.shared.log(tag + " (Main Logger)", text)
            return
        }
        
        let baseAppBundleId = String(appBundleIdentifier[..<lastDotRange.lowerBound])
        let appGroupName = "group.\(baseAppBundleId)"
        let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
        
        if let appGroupUrl = maybeAppGroupUrl {
            let rootPath = appGroupUrl.path + "/telegram-data"
            
            if ngApiLogger == nil {
                let logsPath = rootPath + "/ngApiLogs"
                NGAPILogger.setSharedLogger(NGAPILogger(basePath: logsPath))
            }
        } else {
            Logger.shared.log(tag + " (Main Logger)", text)
        }
    }
    
    
    NGAPILogger.shared.log(tag, text)
}
