import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override init() {
    super.init()
    print("=== APPDELEGATE INITIALIZED ===")
  }
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Enable APNS debugging
    print("=== APNS DEBUGGING ENABLED ===")
    print("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
    print("Device: \(UIDevice.current.name)")
    print("iOS Version: \(UIDevice.current.systemVersion)")
    
    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self
    print("Notification delegate set")
    
    // Check if push notifications are enabled
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("=== NOTIFICATION SETTINGS ===")
      print("Authorization Status: \(settings.authorizationStatus.rawValue)")
      print("Alert Setting: \(settings.alertSetting.rawValue)")
      print("Badge Setting: \(settings.badgeSetting.rawValue)")
      print("Sound Setting: \(settings.soundSetting.rawValue)")
      print("Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
      print("Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    print("=== REGISTERING FOR REMOTE NOTIFICATIONS ===")
    print("Registered for remote notifications")
    
    // Try to get APNS token directly
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      if let apnsToken = Messaging.messaging().apnsToken {
        print("=== APNS TOKEN FOUND ===")
        print("APNS Token: \(apnsToken)")
      } else {
        print("=== NO APNS TOKEN AVAILABLE ===")
        print("This is expected in simulator")
      }
    }
    
    // Test if AppDelegate is working
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      print("🔥🔥🔥 APPDELEGATE WORKING - CHECK XCODE CONSOLE 🔥🔥🔥")
      print("=== APPDELEGATE TEST - This should appear in Xcode console ===")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNS token registration
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    
    print("=== APNS DEVICE TOKEN RECEIVED ===")
    print("APNS Device Token: \(tokenString)")
    print("Token Length: \(deviceToken.count) bytes")
    print("Token Hex: \(tokenString)")
    
    // Set the APNS token for Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("APNS token set for Firebase Messaging")
    
    // Get FCM token after APNS token is set
    Messaging.messaging().token { token, error in
      if let error = error {
        print("Error getting FCM token: \(error)")
      } else if let token = token {
        print("=== FCM TOKEN RECEIVED ===")
        print("FCM Token: \(token)")
      }
    }
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("=== APNS REGISTRATION FAILED ===")
    print("Failed to register for remote notifications: \(error)")
    print("Error Description: \(error.localizedDescription)")
    
    // Check if it's a simulator
    #if targetEnvironment(simulator)
    print("Running on iOS Simulator - APNS tokens are not available in simulator")
    #else
    print("Running on real device - APNS registration should work")
    #endif
  }
  
  // Handle incoming notifications when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("=== FOREGROUND NOTIFICATION RECEIVED ===")
    print("Notification Title: \(notification.request.content.title)")
    print("Notification Body: \(notification.request.content.body)")
    print("Notification User Info: \(notification.request.content.userInfo)")
    
    // Show the notification even when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
    print("=== NOTIFICATION TAPPED ===")
    print("Notification Title: \(response.notification.request.content.title)")
    print("Notification Body: \(response.notification.request.content.body)")
    print("Notification User Info: \(response.notification.request.content.userInfo)")
    
    completionHandler()
  }
}
