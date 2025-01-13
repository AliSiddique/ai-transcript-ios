//
//  Config.swift
//  transcript-ai-meeting
//
//  Created by Ali Siddique on 1/13/25.
//

import Foundation
import SwiftUI
//
//  Config.swift
//  ios-student
//
//  Created by Ali Siddique on 12/17/24.
//

import Foundation
//
//  Config.swift
//  firebase-boilerplate
//
//  Created by Ali Siddique on 10/10/2024.
//

import Foundation
import SwiftUI

struct AppConfiguration {
    // MARK: - Basic App Information
    static let appName = "Feynman AI"
    static let appDescription = "Break free from the chains of addiction"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    static let bundleIdentifier = "com.salinash.no-nut"
    static let appIcon = UIImage(named: "AppIcon") ?? UIImage()
//    static let backendURL = "https://ai-students.onrender.com"
    static let backendURL = "http://192.168.0.201:3000"
    
    // MARK: - App Store Information
    struct AppStoreInfo {
        static let appStoreID = "1234567890"
        static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"
        static let appStoreCountry = "US"
        static let supportURL = "https://www.example.com/support"
        static let marketingURL = "https://www.example.com"
        static let privacyPolicyURL = "https://www.example.com/privacy"
    }
    
    // MARK: - Technical Requirements
    static let minimumIOSVersion = "15.0"
    static let supportedDeviceFamilies: [UIUserInterfaceIdiom] = [.phone, .pad]
    static let supportedOrientations: UIInterfaceOrientationMask = .all
    static let requiredDeviceCapabilities = ["armv7", "metal"]
    static let applicationQueriesSchemes = ["twitter", "facebook"]
    
    // MARK: - Localization
    static let primaryLanguage = "en"
    static let supportedLocales = ["en", "es", "fr", "de", "ja", "zh-Hans", "ru", "ar"]
    static let useBaseInternationalization = true
    

    
    
    
    // MARK: - Privacy Permissions
    struct PrivacyPermissions {
        static let cameraUsageDescription = "We need access to your camera to take photos."
        static let photoLibraryUsageDescription = "We need access to your photo library to save photos."
        static let microphoneUsageDescription = "We need access to your microphone for voice messages."
        static let locationWhenInUseUsageDescription = "We use your location to provide personalized recommendations."
        static let locationAlwaysUsageDescription = "We use your location to provide continuous tracking for fitness activities."
        static let bluetoothUsageDescription = "We use Bluetooth to connect to nearby devices."
        static let calendarUsageDescription = "We need access to your calendar to add events."
        static let contactsUsageDescription = "We need access to your contacts to find friends."
        static let healthShareUsageDescription = "We use HealthKit to track your fitness progress."
        static let healthUpdateUsageDescription = "We update HealthKit with your workout data."
        static let motionUsageDescription = "We use motion & fitness tracking for step counting."
        static let faceIDUsageDescription = "We use Face ID for secure authentication."
        static let siriUsageDescription = "We use Siri to enable voice commands."
        static let speechRecognitionUsageDescription = "We use speech recognition for voice input."
    }
    
    
    
    // MARK: - Environment Variables
    struct EnvironmentVariables {
        static let superwallAPIKey = "pk_495f024c29b25124a2374d09787b34277c16d40ed6615c57"
        static let wishkitAPIKey = "FEAEAF36-5204-4CF2-B88B-62EE874F2934"
        // Add other environment variables as needed
    }
    

}

// MARK: - SwiftUI Preview
extension AppConfiguration {
    static var previewData: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("App Name: \(appName)")
            Text("Version: \(appVersion) (\(buildNumber))")
            Text("Bundle ID: \(bundleIdentifier)")
            Text("Description: \(appDescription)")
            Image(uiImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            Text("Supported Locales: \(supportedLocales.joined(separator: ", "))")
            Text("Minimum iOS Version: \(minimumIOSVersion)")
        }
        .padding()
    }
}

#if DEBUG
struct AppConfiguration_Previews: PreviewProvider {
    static var previews: some View {
        AppConfiguration.previewData
    }
}
#endif
