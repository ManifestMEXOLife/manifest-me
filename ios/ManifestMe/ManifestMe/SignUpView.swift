//
//  SignUpView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = "" // <--- The Golden Ticket Field
    @State private var isLoading = false
    
    // To dismiss this view and go back to Login
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Manifest Me")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // --- FORM FIELDS ---
                VStack(spacing: 15) {
                    TextField("Email Address", text: $email) // Changed Label
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress) // Adds @ symbol
                        .textInputAutocapitalization(.never) // Emails are lowercase
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // 🎟️ THE GOLDEN TICKET INPUT
                    TextField("Invite Code (Required)", text: $inviteCode)
                        .padding()
                        .background(Color.white) // 1. Change background to White for readability
                        .cornerRadius(8)
                        .foregroundColor(.black) // 2. Force text to be black
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow, lineWidth: 2) // 3. Keep the Gold Border (maybe thicker!)
                        )
                        .autocapitalization(.allCharacters) // Codes are usually UPPERCASE
                }
                .padding(.horizontal, 30)
                
                // --- ERROR MESSAGE ---
                if !authService.errorMessage.isEmpty {
                    Text(authService.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // --- SUBMIT BUTTON ---
                Button(action: {
                    isLoading = true
                    // Call the backend
                    authService.register(email: email, password: password, inviteCode: inviteCode)
                    
                    // Simple loading reset (in real app, wait for callback)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                }) {
                    Text(isLoading ? "Verifying Ticket..." : "Join Beta")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inviteCode.isEmpty ? Color.gray : Color.yellow) // Gold button!
                        .cornerRadius(8)
                }
                .disabled(inviteCode.isEmpty) // Block button if no code
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                Spacer()
                
                // Back to Login
                Button("Already have an account? Log In") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            }
        }
    }
}

// Preview Provider
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView().environmentObject(AuthService())
    }
}
