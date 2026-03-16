import SwiftUI

struct AuthView: View {
    @ObservedObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.accent)

                Text("Welcome to Judy")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to unlock personalized weather memory.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Picker("Mode", selection: $isSignUp) {
                    Text("Sign In").tag(false)
                    Text("Sign Up").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    Task { await submitEmailAuth() }
                } label: {
                    HStack {
                        if isBusy {
                            ProgressView()
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBusy)

                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                }

                Button {
                    Task { await runOAuth(.apple) }
                } label: {
                    Label("Continue with Apple", systemImage: "applelogo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)

                Button {
                    Task { await runOAuth(.google) }
                } label: {
                    Label("Continue with Google", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)

                if let info = authManager.authInfoMessage {
                    Text(info)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                if let error = authManager.authErrorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Authentication")
        }
    }

    private func submitEmailAuth() async {
        guard let validation = authManager.validateEmailAndPassword(email: email, password: password) else {
            isBusy = true
            defer { isBusy = false }

            if isSignUp {
                await authManager.signUp(email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }

            return
        }

        authManager.authErrorMessage = validation
    }

    private func runOAuth(_ provider: OAuthProvider) async {
        isBusy = true
        defer { isBusy = false }

        await authManager.signInWithProvider(provider)
    }
}

#Preview {
    AuthView(authManager: AuthManager())
}
