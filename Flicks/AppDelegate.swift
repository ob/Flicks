//
//  AppDelegate.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/12/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // https://stackoverflow.com/questions/22491317/reusing-uiviewcontroller-for-two-tab-bar-items
        // 
        var crazyCasting = true
        if let tabController = window?.rootViewController as? UITabBarController,
            let nv1 = tabController.customizableViewControllers?[0] as? UINavigationController,
            let nv2 = tabController.customizableViewControllers?[1] as? UINavigationController {
            if let movieListViewController = nv1.viewControllers[0] as? MovieListViewController {
                movieListViewController.movies = MoviesController(MovieListCategory.NowPlaying)
            } else {
                crazyCasting = false
            }
            if let movieListViewController = nv2.viewControllers[0] as? MovieListViewController {
                movieListViewController.movies = MoviesController(MovieListCategory.TopRated)
            } else {
                crazyCasting = false
            }
        } else {
            crazyCasting = false
        }
        if !crazyCasting {
            print("Crazy casting failed")
            exit(1)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

