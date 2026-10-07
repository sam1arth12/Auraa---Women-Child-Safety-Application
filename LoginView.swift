import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var emailOrPhone: String = ""
    @State private var selectedRole: UserRole = .protectedUser
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Bar
                    HStack {
                        Spacer()
                        Text("AURA Safety Platform")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Logo Hero Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [Color.red.opacity(0.18), Color.red.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 96, height: 96)
                            
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 52))
                                .foregroundStyle(AuraTheme.primaryRedGradient)
                        }
                        
                        Text("AURA Safety")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Select your account type to launch your interface")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Input Credentials Form
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Full Name")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            TextField("e.g. Sarah Jenkins", text: $name)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone Number or Email")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            TextField("e.g. +1 555-0199 or sarah@aura.com", text: $emailOrPhone)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Two Role Selection Cards
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Select User Role")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(UserRole.allCases) { role in
                            RoleSelectionCard(
                                role: role,
                                isSelected: selectedRole == role,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedRole = role
                                    }
                                }
                            )
                        }
                    }
                    
                    // Launch Interface Button
                    Button(action: {
                        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (selectedRole == .protectedUser ? "Protected Person" : "Guardian User") : name
                        let finalContact = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "user@aura.app" : emailOrPhone
                        authViewModel.login(name: finalName, emailOrPhone: finalContact, role: selectedRole)
                    }) {
                        HStack {
                            Text("Launch \(selectedRole.title) Dashboard")
                                .font(.headline.weight(.bold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedRole == .protectedUser ? AuraTheme.primaryRedGradient : AuraTheme.guardianIndigoGradient
                        )
                        .clipShape(Capsule())
                        .shadow(color: (selectedRole == .protectedUser ? Color.red : Color.indigo).opacity(0.35), radius: 10, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 36)
                }
            }
        }
    }
}

private struct RoleSelectionCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? (role == .protectedUser ? Color.red : Color.indigo) : Color.gray.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: role.iconName)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(role.title)
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text(role.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? (role == .protectedUser ? .red : .indigo) : .secondary)
                    
                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? (role == .protectedUser ? .red : .indigo) : .gray.opacity(0.3))
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? (role == .protectedUser ? Color.red : Color.indigo) : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
