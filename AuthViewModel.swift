import Foundation
import SwiftUI
import Combine

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case protectedUser = "Protected Person"
    case guardian = "Guardian"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .protectedUser: return "Protected Person"
        case .guardian: return "Guardian"
        }
    }
    
    var subtitle: String {
        switch self {
        case .protectedUser: return "I am the person being protected"
        case .guardian: return "I am a guardian monitoring a loved one"
        }
    }
    
    var description: String {
        switch self {
        case .protectedUser:
            return "Access live GPS navigation, SOS emergency siren, safe journey tracking, and nearby verified safe zones."
        case .guardian:
            return "Monitor your protected loved one's live location, track active trip ETAs, and receive instant emergency alerts."
        }
    }
    
    var iconName: String {
        switch self {
        case .protectedUser: return "shield.fill"
        case .guardian: return "eye.fill"
        }
    }
}

struct UserProfile: Codable {
    var name: String
    var emailOrPhone: String
    var role: UserRole
}

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserProfile? = nil
    
    private let userKey = "aura_current_user_profile_key"
    
    init() {
        // App always starts on the Login & Role Selection page
        self.isLoggedIn = false
        self.currentUser = nil
    }
    
    func login(name: String, emailOrPhone: String, role: UserRole) {
        let profile = UserProfile(name: name, emailOrPhone: emailOrPhone, role: role)
        self.currentUser = profile
        self.isLoggedIn = true
        saveUser(profile: profile)
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    func switchRole(to newRole: UserRole) {
        guard var user = currentUser else {
            login(name: "User", emailOrPhone: "contact@aura.app", role: newRole)
            return
        }
        user.role = newRole
        self.currentUser = user
        saveUser(profile: user)
    }
    
    private func saveUser(profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
}
