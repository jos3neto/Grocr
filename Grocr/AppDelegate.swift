
import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
  {
	// this command will do the setup on the server side
	FirebaseApp.configure()
	
	// this will allow offline persistence and database syncing once the app goes online
	// even across app terminations and launches
	Database.database().isPersistenceEnabled = true
    return true
  }
}
