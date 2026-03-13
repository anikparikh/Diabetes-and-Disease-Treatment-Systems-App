//
//  GlucoseAppApp.swift
//  GlucoseApp
//
//  Created by Victor  Andrade on 10/17/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct GlucoseAppApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var authViewModel = AuthViewModel()

  var body: some Scene {
    WindowGroup {
      Group {
        if authViewModel.user != nil {
          ContentView()
        } else {
          LoginView()
        }
      }
      .environmentObject(authViewModel)
    }
  }
}
