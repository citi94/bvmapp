//
//  ContactView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI
import MapKit

struct ContactView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: ContactInfo.latitude, longitude: ContactInfo.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact BVM Deal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get in touch with our expert team")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Quick Contact Actions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ContactActionCard(
                            title: "Call Now",
                            subtitle: ContactInfo.phone,
                            icon: "phone.fill",
                            color: .green
                        ) {
                            if let url = URL(string: "tel:+441304732747") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactActionCard(
                            title: "Text Message",
                            subtitle: ContactInfo.mobile,
                            icon: "message.fill",
                            color: .blue
                        ) {
                            if let url = URL(string: "sms:+447441111189") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactActionCard(
                            title: "Email",
                            subtitle: ContactInfo.email,
                            icon: "envelope.fill",
                            color: .purple
                        ) {
                            if let url = URL(string: "mailto:\(ContactInfo.email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactActionCard(
                            title: "WhatsApp",
                            subtitle: "Chat with us",
                            icon: "message.badge.fill",
                            color: Color("BVMOrange")
                        ) {
                            if let url = URL(string: ContactInfo.whatsapp) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    // Opening Hours
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Opening Hours")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            OpeningHoursRow(day: "Monday - Friday", hours: "9:00 AM - 5:00 PM")
                            OpeningHoursRow(day: "Saturday", hours: "Closed")
                            OpeningHoursRow(day: "Sunday", hours: "Closed")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Location")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ContactInfo.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Get Directions") {
                                openMaps()
                            }
                            .font(.subheadline)
                            .foregroundColor(Color("BVMOrange"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Map
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Find Us")
                            .font(.headline)
                        
                        Map(position: $position) {
                            Marker("BVM Deal", coordinate: CLLocationCoordinate2D(latitude: ContactInfo.latitude, longitude: ContactInfo.longitude))
                                .tint(Color("BVMOrange"))
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .onTapGesture {
                            openMaps()
                        }
                    }
                    
                    // Social Media
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Follow Us")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            SocialMediaButton(
                                title: "Instagram",
                                icon: "camera.fill",
                                color: .pink
                            ) {
                                if let url = URL(string: ContactInfo.instagram) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            SocialMediaButton(
                                title: "WhatsApp",
                                icon: "message.fill",
                                color: .green
                            ) {
                                if let url = URL(string: ContactInfo.whatsapp) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About BVM Deal")
                            .font(.headline)
                        
                        Text("Since 2019, we've provided bespoke vehicle maintenance services in Deal, Kent. Our approach is tailored to meet each customer's unique needs, specializing in technical work including electrical diagnostics, cambelt replacement, and electric vehicle servicing.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Emergency Contact
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emergency Support")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For urgent vehicle issues outside business hours:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Call Emergency Line") {
                                if let url = URL(string: "tel:+441304732747") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func openMaps() {
        let coordinates = "\(ContactInfo.latitude),\(ContactInfo.longitude)"
        let address = ContactInfo.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "maps://?q=\(address)&ll=\(coordinates)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to Google Maps in browser
                let googleMapsURL = "https://www.google.com/maps/search/?api=1&query=\(ContactInfo.latitude),\(ContactInfo.longitude)"
                if let fallbackURL = URL(string: googleMapsURL) {
                    UIApplication.shared.open(fallbackURL)
                }
            }
        }
    }
}

struct ContactActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OpeningHoursRow: View {
    let day: String
    let hours: String
    
    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(hours)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct SocialMediaButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// Emergency Contact View - Quick access to emergency services
struct EmergencyContactView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("Emergency Contact")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("For urgent vehicle issues")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Emergency Actions
            VStack(spacing: 16) {
                Button("Call BVM Deal") {
                    if let url = URL(string: "tel:+441304732747") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
                
                Button("Send Emergency WhatsApp") {
                    if let url = URL(string: ContactInfo.whatsapp) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            
            // Emergency Tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Emergency Tips")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Move to a safe location if possible")
                    Text("• Turn on hazard lights")
                    Text("• Call for help immediately")
                    Text("• Have your vehicle details ready")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    ContactView()
}