//
//  LoginView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @Binding var isLoggedIn: Bool
    
    // this is the URL to your local Docker container
    let loginURL = URL(string: "http://localhost:8000/api/token/pair")!
    
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
                
                // --- Input fields --
                VStack(alignment: .leading) {
                    Text("Username")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never) // Important!
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
                Button(action: performLogin) {
                    if isLoggedIn {
                        Image(systemName: "checkmark")
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.top, 10)
                
                // -- Status Message --
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(isLoggedIn ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(30)
        }
    }
    
    func performLogin() {
        message = "Connecting..."
        
        // 1. Create the JSON payload
        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        
        // 2. Configure the request
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // 3. Send it!
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.message = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.message = "✅ Success! Token received."
                        
                        //1. Prase the JSON to get the actual token string
                        if let data = data,
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let accessToken = json["access"] as? String {
                                // 2. Save it to the keychain
                                KeychainHelper.standard.save(token: accessToken)
                                print("Token saved to secure storage")
                            }
                        
                        self.isLoggedIn = true
                        
                        // NOTE: In the future, we will save the token here.
                        print("Login successful for: \(username)")
                    } else {
                        self.message = "❌ Login Failed (Status: \(httpResponse.statusCode))"
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
