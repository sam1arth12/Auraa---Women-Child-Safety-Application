import Foundation
import SwiftUI
import Combine

struct Guardian: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var relationship: String
    var isPrimary: Bool = false
}

class GuardiansViewModel: ObservableObject {
    @Published var guardians: [Guardian] = [] {
        didSet {
            saveGuardians()
        }
    }
    
    private let storageKey = "aura_guardians_storage_key"
    
    init() {
        loadGuardians()
        if guardians.isEmpty {
            // Provide default initial guardians for demo/testing
            guardians = [
                Guardian(name: "Mom", phone: "+1234567890", relationship: "Family", isPrimary: true),
                Guardian(name: "Alex Smith", phone: "+1987654321", relationship: "Friend", isPrimary: false)
            ]
        }
    }
    
    func addGuardian(name: String, phone: String, relationship: String, isPrimary: Bool = false) {
        var newGuardian = Guardian(name: name, phone: phone, relationship: relationship, isPrimary: isPrimary)
        if isPrimary {
            // Set all existing guardians isPrimary to false
            for index in guardians.indices {
                guardians[index].isPrimary = false
            }
        }
        guardians.append(newGuardian)
    }
    
    func deleteGuardian(at offsets: IndexSet) {
        guardians.remove(atOffsets: offsets)
    }
    
    func togglePrimary(guardian: Guardian) {
        for index in guardians.indices {
            guardians[index].isPrimary = (guardians[index].id == guardian.id)
        }
    }
    
    func primaryGuardian() -> Guardian? {
        return guardians.first(where: { $0.isPrimary }) ?? guardians.first
    }
    
    private func saveGuardians() {
        if let encoded = try? JSONEncoder().encode(guardians) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadGuardians() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Guardian].self, from: data) {
            self.guardians = decoded
        }
    }
}
