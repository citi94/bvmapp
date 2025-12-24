//
//  DashboardView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MOT Check")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("BVMOrange"))
                        Text("Check your vehicle's MOT status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Current Vehicle Card
                    if let selectedVehicle = coordinator.selectedVehicle {
                        VehicleStatusCard(vehicle: selectedVehicle)
                    }
                    
                    // Quick Actions - MOT Focused
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        QuickActionCard(title: "Add Vehicle", icon: "plus.circle.fill", color: Color("BVMOrange")) {
                            coordinator.selectedTab = 1 // Navigate to My Vehicles tab
                        }
                        
                        QuickActionCard(title: "Call BVM Deal", icon: "phone.fill", color: .blue) {
                            if let url = URL(string: "tel:+441304732747") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        QuickActionCard(title: "Get Directions", icon: "map.fill", color: .green) {
                            openMaps()
                        }
                        
                        QuickActionCard(title: "Emergency", icon: "exclamationmark.triangle.fill", color: .red) {
                            if let url = URL(string: "tel:+441304732747") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Add a helpful message when no vehicle is selected
                    if coordinator.selectedVehicle == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "car.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("BVMOrange"))
                            
                            Text("Add your first vehicle")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Tap 'Add Vehicle' to get started with MOT checking")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 40)
                    }
                    
                    // Hidden sections - keep for future use
                    if false {
                        // Upcoming Bookings
                        if !coordinator.getUpcomingBookings().isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Bookings")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(coordinator.getUpcomingBookings().prefix(3)) { booking in
                                    BookingCard(booking: booking)
                                }
                            }
                        }
                        
                        // Recent Reminders
                        if !coordinator.reminders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Reminders")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(coordinator.reminders.prefix(3)) { reminder in
                                    ReminderCard(reminder: reminder)
                                }
                            }
                        }
                        
                        // Services Overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Our Specialties")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(coordinator.serviceTypes.filter { $0.isSpecialty }.prefix(4)) { service in
                                    ServiceCard(service: service)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .refreshable {
                await coordinator.refreshData()
            }
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

struct VehicleStatusCard: View {
    let vehicle: VehicleEntity
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coordinator.getVehicleDisplayName(vehicle))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(vehicle.registration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: vehicle.fuelTypeEnum.icon)
                    .font(.title2)
                    .foregroundColor(vehicle.fuelTypeEnum.color)
            }
            
            HStack(spacing: 16) {
                StatusBadge(
                    title: "Service",
                    status: coordinator.getServiceStatus(for: vehicle).displayText,
                    color: coordinator.getServiceStatus(for: vehicle).color
                )
                
                StatusBadge(
                    title: "MOT",
                    status: coordinator.getMOTStatus(for: vehicle).displayText,
                    color: coordinator.getMOTStatus(for: vehicle).color
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(6)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BookingCard: View {
    let booking: ServiceBookingEntity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.serviceType?.name ?? "Unknown Service")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(booking.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(booking.statusEnum.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(booking.statusEnum.color.opacity(0.2))
                    .foregroundColor(booking.statusEnum.color)
                    .cornerRadius(6)
                
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ReminderCard: View {
    let reminder: ServiceReminderEntity
    
    var body: some View {
        HStack {
            Image(systemName: reminder.typeEnum.icon)
                .foregroundColor(reminder.typeEnum.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(reminder.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if reminder.isUrgent {
                Text("URGENT")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ServiceCard: View {
    let service: ServiceTypeEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: service.icon)
                .font(.title2)
                .foregroundColor(Color("BVMOrange"))
            
            Text(service.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppCoordinator.shared)
}