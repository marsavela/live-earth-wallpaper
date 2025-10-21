//
//  SettingsView.swift
//  Live Earth Wallpaper
//
//  Created by Sergiu Marsavela on 25/9/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var apiToken: String
    @Binding var imageSize: String
    @Binding var useMarine: Bool
    @Binding var twilightAngle: Double
    @Binding var autoRefreshMinutes: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingApiHelp = false
    
    private var refreshIntervalText: String {
        if autoRefreshMinutes >= 60 {
            let hours = Int(autoRefreshMinutes / 60)
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(Int(autoRefreshMinutes)) min"
        }
    }

    private func intervalButtonText(for minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            return "\(hours)h"
        } else {
            return "\(Int(minutes))m"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Help") {
                    showingApiHelp = true
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            Form {
                Section {
                    HStack {
                        Text("API Token")
                            .frame(width: 100, alignment: .leading)
                        SecureField("Required for API access", text: $apiToken)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("API Configuration")
                }

                Section {
                    Picker("Size", selection: $imageSize) {
                        Text("Small").tag("small")
                        Text("Medium").tag("medium")
                        Text("Large").tag("large")
                        Text("Full").tag("full")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Image Settings")
                }

                Section {
                    Toggle("Marine Bathymetry", isOn: $useMarine)

                    HStack {
                        Text("Twilight Angle")
                            .frame(width: 110, alignment: .leading)

                        Spacer()

                        ForEach([0.0, 3.0, 6.0, 12.0, 18.0], id: \.self) { preset in
                            Button(preset == 0 ? "None" : "\(Int(preset))°") {
                                twilightAngle = preset
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .background(twilightAngle == preset ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                } header: {
                    Text("Earth Settings")
                }

                Section {
                    HStack {
                        Text("Refresh Interval")
                            .frame(width: 110, alignment: .leading)

                        Spacer()

                        ForEach([15.0, 30.0, 60.0, 120.0, 360.0], id: \.self) { preset in
                            Button(intervalButtonText(for: preset)) {
                                autoRefreshMinutes = preset
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .background(autoRefreshMinutes == preset ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                } header: {
                    Text("Auto Refresh")
                } footer: {
                    Text("Automatically refreshes wallpaper at the specified interval. API limited to 1 request/minute.")
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
            .padding(.top, 8)
        }
        .frame(width: 520, height: 520)
        .sheet(isPresented: $showingApiHelp) {
            ApiHelpView()
        }
    }
}

struct ApiHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Getting Your API Token")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("To use this app, you need an API token for the daynight.sdmn.eu service.")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Steps:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("1.")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contact the API administrator")
                                        .fontWeight(.medium)
                                    Text("Request access to the Earth Compositor API")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Text("2.")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Receive your API token")
                                        .fontWeight(.medium)
                                    Text("You'll get a secret token string like 'your-secret-token-123'")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Text("3.")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enter the token in settings")
                                        .fontWeight(.medium)
                                    Text("Paste the token in the API Token field above")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Service URL: https://daynight.sdmn.eu")
                            Text("• Rate limit: 1 request per minute per token")
                            Text("• Generates high-quality Earth composite images")
                            Text("• Shows real-time day/night terminator")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Security Note")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Keep your API token secure and don't share it with others. It's stored securely in your keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("API Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    SettingsView(
        apiToken: .constant(""),
        imageSize: .constant("large"),
        useMarine: .constant(true),
        twilightAngle: .constant(6.0),
        autoRefreshMinutes: .constant(60)
    )
}