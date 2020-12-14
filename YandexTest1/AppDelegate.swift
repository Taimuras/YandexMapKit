//
//  AppDelegate.swift
//  YandexTest1
//
//  Created by tami on 12/10/20.
//

import UIKit
import YandexMapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    let MAPKIT_API_KEY = "2d3ae7d5-7d09-40f3-bb3a-b34e990ea2f7"


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        YMKMapKit.setApiKey(MAPKIT_API_KEY)

        /**
         * You can optionaly customize  locale.
         * Otherwise MapKit will use default location.
         */
        YMKMapKit.setLocale("en_US")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

