//
//  LoginView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

struct LoginView: View {
    // 1. Inject the Brain (AuthService)
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    
    // Note: We removed the @Binding var isLoggedIn because
    // authService.isAuthenticated now controls the flow globally.
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // -- HEADER --
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 20)
                
                Text("Manifest Me")
                    .font(.largeTitle)
                    .bold()
                
                // --- INPUT FIELDS ---
                VStack(alignment: .leading) {
                    Text("Email") // Changed Label
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress) // Adds @ symbol
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                // --- ACTION BUTTON ---
                Button(action: {
                    // Call the shared service instead of local code
                    authService.login(email: email, password: password)
                }) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                .padding(.top, 10)
                
                // --- STATUS MESSAGE ---
                if !authService.errorMessage.isEmpty {
                    Text(authService.errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
                
                // --- 2. THE BETA INVITE LINK ---
                // This takes them to the Sign Up screen
                NavigationLink(destination: SignUpView()) {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.primary)
                        Text("Join Beta")
                            .fontWeight(.bold)
                            .foregroundColor(.yellow) // Highlights the special invite nature
                    }
                    .padding()
                }
            }
            .padding(30)
            // Ensure the AuthService handles errors gracefully
            .onChange(of: authService.isAuthenticated) { oldValue, newValue in
                if newValue {
                    print("✅ LoginView detected success. Parent app should switch views now.")
                }
            }
        }
    }
}

// Preview needs the EnvironmentObject injected
#Preview {
    LoginView()
        .environmentObject(AuthService())
}
