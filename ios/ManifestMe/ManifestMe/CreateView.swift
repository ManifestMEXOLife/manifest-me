import SwiftUI

struct CreateView: View {
    @EnvironmentObject var videoService: VideoService
    @EnvironmentObject var authService: AuthService
    
    // This allows us to close the sheet programmatically
    @Environment(\.dismiss) var dismiss
    
    @State private var prompt: String = ""
    
    var contextKeyword: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // --- CLOSE BUTTON OVERLAY ---
                VStack {
                    HStack {
                        Button(action: {
                            dismiss() // 🏃💨 EXIT!
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(1) // Make sure it sits on top of everything
                
                // --- MAIN CONTENT ---
                VStack(spacing: 20) {
                    Text("Dream It.")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Text("Describe your future reality in the present tense.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // --- INPUT AREA ---
                    TextEditor(text: $prompt)
                        .frame(height: 150)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                    
                    Spacer()
                    
                    // --- ACTION BUTTON ---
                    Button(action: {
                        guard let token = KeychainHelper.standard.read() else { return }
                        
                        // Append context if it exists (e.g. "beach")
                        let finalPrompt = contextKeyword.isEmpty ? prompt : "\(prompt) \(contextKeyword)"
                        
                        videoService.manifest(prompt: finalPrompt, token: token)
                        dismiss()
                        
                    }) {
                        Text("Start Manifesting")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(prompt.isEmpty ? Color.gray : Color.yellow)
                            .cornerRadius(12)
                    }
                    .disabled(prompt.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
