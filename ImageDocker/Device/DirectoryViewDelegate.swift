//
//  DirectoryViewDelegate.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2018/8/18.
//  Copyright © 2018年 nonamecat. All rights reserved.
//

import Foundation

class AndroidDirectoryViewDelegate : DirectoryViewDelegate {
    
    var deviceId:String
    
    init(deviceId:String){
        self.deviceId = deviceId
    }
    
    func listSubFolders(in path: String) -> [String] {
        return Android.bridge.folders(device: deviceId, in: path)
    }
    
    func listFiles(in path: String) -> [String] {
        return Android.bridge.filenames(device: deviceId, in: path)
    }
    
    func home() -> String{
        return "/sdcard/"
    }
    
    func shortcuts() -> [DirectoryViewShortcut] {
        return [
            DirectoryViewShortcut(title: "Home", path: home()),
            DirectoryViewShortcut(title: "Camera", path: "/sdcard/DCIM/Camera/")
        ]
    }
    
    
}

class LocalDirectoryViewDelegate : DirectoryViewDelegate {
    func listSubFolders(in path: String) -> [String] {
        return LocalDirectory.bridge.folders(in: path)
    }
    
    func listFiles(in path: String) -> [String] {
        return LocalDirectory.bridge.filenames(in: path)
    }
    
    func home() -> String{
        return FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    func shortcuts() -> [DirectoryViewShortcut] {
        return [
            DirectoryViewShortcut(title: "Home", path: home()),
            DirectoryViewShortcut(title: "MacStorage", path: "/MacStorage/"),
            DirectoryViewShortcut(title: "Volumes", path: "/Volumes/")
        ]
    }
    
    
}
