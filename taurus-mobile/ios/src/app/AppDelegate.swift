// Numenta Platform for Intelligent Computing (NuPIC)
// Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
// Numenta, Inc. a separate commercial license for this software code, the
// following terms and conditions apply:
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero Public License version 3 as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero Public License for more details.
//
// You should have received a copy of the GNU Affero Public License
// along with this program.  If not, see http://www.gnu.org/licenses.
//
// http://numenta.org/licenses/

import UIKit
import CoreData
import MessageUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MFMailComposeViewControllerDelegate {

    var window: UIWindow?
    let syncQueue = dispatch_queue_create("com.numenta.Sync", nil)
    var syncService: TaurusDataSyncService?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        TaurusApplication.setup()
        
        // Launch sync service
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: AppConfig.identityPoolId)

        let client : TaurusClient = TaurusClient(provider: credentialsProvider, region: AWSRegionType.USWest2)
        
        syncService = TaurusDataSyncService(client:client)
        
        TaurusApplication.client = syncService?.client as? TaurusClient

        dispatch_async(syncQueue) {
            application.networkActivityIndicatorVisible = true
            self.syncService!.synchronizeWithServer()
            application.networkActivityIndicatorVisible = false
        }
        


        let defaults = NSUserDefaults.standardUserDefaults()

        // Update version
        let appVersionString = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let appBuildString =  NSBundle.mainBundle().objectForInfoDictionaryKey( "CFBundleVersion") as! String
        let versionBuildString = String(format: "%@  (%@)", appVersionString, appBuildString)
        defaults.setValue(versionBuildString, forKey: "version")

        // Update notifications

        application.registerUserNotificationSettings(
            UIUserNotificationSettings(
                forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound],
                categories: nil))

        defaults.synchronize()

        // Request background syncs
        let frequency =  defaults.integerForKey("refreshFrequency")
        var interval : NSTimeInterval  = Double(frequency) * 60.0
        if (interval<60.0){
            interval = 60.0
        }
        application.setMinimumBackgroundFetchInterval(interval)

        // Configure Google Analytics tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions

        return true
    }



    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        dispatch_async(syncQueue) {
            application.networkActivityIndicatorVisible = true
            self.syncService!.synchronizeWithServer()
            application.networkActivityIndicatorVisible = false
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
       
        dispatch_async(syncQueue) {
            self.syncService?.synchronizeWithServer()
            completionHandler(.NewData)
        }
    }
    
    /** mail delegate
     */
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        
        controller.dismissViewControllerAnimated(true, completion: nil)
        
        
    }
    
   

}

