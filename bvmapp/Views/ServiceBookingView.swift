//
//  ServiceBookingView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

struct ServiceBookingView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedService: ServiceTypeEntity?
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Book a Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose a service and schedule your appointment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Vehicle Selection
                    if let selectedVehicle = coordinator.selectedVehicle {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Selected Vehicle")
                                .font(.headline)
                            
                            VehicleSelectionCard(vehicle: selectedVehicle)
                        }
                    }
                    
                    // Service Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Services")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(coordinator.serviceTypes) { service in
                                ServiceSelectionCard(
                                    service: service,
                                    isSelected: selectedService?.id == service.id
                                ) {
                                    selectedService = service
                                }
                            }
                        }
                    }
                    
                    // Date Selection
                    if selectedService != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Date")
                                .font(.headline)
                            
                            DatePicker(
                                "Service Date",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Notes
                    if selectedService != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Quick Contact Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Need to Discuss Your Requirements?")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ContactButton(
                                title: "Call Now",
                                icon: "phone.fill",
                                color: .green
                            ) {
                                if let url = URL(string: "tel:+441304732747") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            ContactButton(
                                title: "WhatsApp",
                                icon: "message.fill",
                                color: .blue
                            ) {
                                if let url = URL(string: ContactInfo.whatsapp) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    
                    // Book Button
                    if selectedService != nil && coordinator.selectedVehicle != nil {
                        Button(action: {
                            showingConfirmation = true
                        }) {
                            Text("Book Service")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("BVMOrange"))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingConfirmation) {
                BookingConfirmationView(
                    service: selectedService!,
                    date: selectedDate,
                    notes: notes
                ) {
                    if let service = selectedService,
                       let vehicle = coordinator.selectedVehicle {
                        coordinator.createBooking(
                            vehicle: vehicle,
                            serviceType: service,
                            scheduledDate: selectedDate,
                            notes: notes
                        )
                    }
                    showingConfirmation = false
                    // Reset form
                    selectedService = nil
                    selectedDate = Date()
                    notes = ""
                }
            }
        }
    }
}

struct VehicleSelectionCard: View {
    let vehicle: VehicleEntity
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(coordinator.getVehicleDisplayName(vehicle))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(vehicle.registration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: vehicle.fuelTypeEnum.icon)
                .foregroundColor(vehicle.fuelTypeEnum.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ServiceSelectionCard: View {
    let service: ServiceTypeEntity
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: service.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : Color("BVMOrange"))
                    
                    if service.isSpecialty {
                        Spacer()
                        Text("SPECIALTY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white.opacity(0.3) : Color("BVMOrange").opacity(0.2))
                            .foregroundColor(isSelected ? .white : Color("BVMOrange"))
                            .cornerRadius(4)
                    }
                }
                
                Text(service.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Text(service.serviceDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("\(service.estimatedDuration) min")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color("BVMOrange") : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(8)
        }
    }
}

struct BookingConfirmationView: View {
    let service: ServiceTypeEntity
    let date: Date
    let notes: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Your Booking")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please review your booking details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Booking Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Service", value: service.name)
                        DetailRow(title: "Date", value: date.formatted(date: .complete, time: .omitted))
                        DetailRow(title: "Duration", value: "\(service.estimatedDuration) minutes")
                        
                        if !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(notes)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("We'll Contact You")
                            .font(.headline)
                        
                        Text("We'll call you within 24 hours to confirm your appointment time and discuss any specific requirements.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Confirm Button
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        Text("Confirm Booking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("BVMOrange"))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Booking Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ServiceBookingView()
        .environmentObject(AppCoordinator.shared)
}