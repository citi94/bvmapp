//
//  BusinessLogicService.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Business Logic Service

@MainActor
class BusinessLogicService: ObservableObject {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Vehicle Business Logic
    
    func createVehicle(make: String, model: String, year: Int, registration: String, 
                      mileage: Int, fuelType: FuelType, color: String) -> Result<VehicleEntity, BusinessError> {
        // Validation
        guard !make.isEmpty, !model.isEmpty, !registration.isEmpty, !color.isEmpty else {
            return .failure(.invalidInput("All fields are required"))
        }
        
        guard year >= 1900, year <= Calendar.current.component(.year, from: Date()) + 1 else {
            return .failure(.invalidInput("Invalid year"))
        }
        
        guard mileage >= 0, mileage <= 999999 else {
            return .failure(.invalidInput("Invalid mileage"))
        }
        
        // Check for duplicate registration
        if dataStore.vehicles.contains(where: { $0.registration.uppercased() == registration.uppercased() }) {
            return .failure(.duplicateData("Vehicle with this registration already exists"))
        }
        
        let vehicle = VehicleEntity(
            make: make.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            year: year,
            registration: registration.uppercased().trimmingCharacters(in: .whitespacesAndNewlines),
            mileage: mileage,
            fuelType: fuelType,
            color: color.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        dataStore.addVehicle(vehicle)
        return .success(vehicle)
    }
    
    func updateVehicle(_ vehicle: VehicleEntity, make: String? = nil, model: String? = nil, 
                      year: Int? = nil, registration: String? = nil, mileage: Int? = nil, 
                      fuelType: FuelType? = nil, color: String? = nil) -> Result<VehicleEntity, BusinessError> {
        
        // Update only provided fields
        if let make = make {
            guard !make.isEmpty else {
                return .failure(.invalidInput("Make cannot be empty"))
            }
            vehicle.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let model = model {
            guard !model.isEmpty else {
                return .failure(.invalidInput("Model cannot be empty"))
            }
            vehicle.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let year = year {
            guard year >= 1900, year <= Calendar.current.component(.year, from: Date()) + 1 else {
                return .failure(.invalidInput("Invalid year"))
            }
            vehicle.year = year
        }
        
        if let registration = registration {
            guard !registration.isEmpty else {
                return .failure(.invalidInput("Registration cannot be empty"))
            }
            let cleanRegistration = registration.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            // Check for duplicate registration (excluding current vehicle)
            if dataStore.vehicles.contains(where: { $0.registration == cleanRegistration && $0.id != vehicle.id }) {
                return .failure(.duplicateData("Vehicle with this registration already exists"))
            }
            vehicle.registration = cleanRegistration
        }
        
        if let mileage = mileage {
            guard mileage >= 0, mileage <= 999999 else {
                return .failure(.invalidInput("Invalid mileage"))
            }
            vehicle.mileage = mileage
        }
        
        if let fuelType = fuelType {
            vehicle.fuelType = fuelType.rawValue
        }
        
        if let color = color {
            guard !color.isEmpty else {
                return .failure(.invalidInput("Color cannot be empty"))
            }
            vehicle.color = color.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        dataStore.updateVehicle(vehicle)
        return .success(vehicle)
    }
    
    func deleteVehicle(_ vehicle: VehicleEntity) -> Result<Void, BusinessError> {
        // Check if vehicle has pending bookings
        let pendingBookings = vehicle.bookings.filter { booking in
            let status = BookingStatus(rawValue: booking.status) ?? .scheduled
            return status == .scheduled || status == .confirmed
        }
        
        if !pendingBookings.isEmpty {
            return .failure(.businessRuleViolation("Cannot delete vehicle with pending bookings. Please cancel bookings first."))
        }
        
        dataStore.deleteVehicle(vehicle)
        return .success(())
    }
    
    // MARK: - Service Booking Business Logic
    
    func createBooking(vehicle: VehicleEntity, serviceType: ServiceTypeEntity, 
                      scheduledDate: Date, notes: String) -> Result<ServiceBookingEntity, BusinessError> {
        
        // Validation
        guard scheduledDate >= Date() else {
            return .failure(.invalidInput("Cannot schedule booking in the past"))
        }
        
        // Check for conflicting bookings on the same day
        let calendar = Calendar.current
        let existingBookings = dataStore.bookings.filter { booking in
            guard let bookingVehicle = booking.vehicle else { return false }
            return bookingVehicle.id == vehicle.id && 
                   calendar.isDate(booking.scheduledDate, inSameDayAs: scheduledDate)
        }
        
        if !existingBookings.isEmpty {
            return .failure(.businessRuleViolation("Vehicle already has a booking scheduled for this date"))
        }
        
        let estimatedCost = calculateEstimatedCost(for: serviceType, vehicle: vehicle)
        let booking = ServiceBookingEntity(
            vehicle: vehicle,
            serviceType: serviceType,
            scheduledDate: scheduledDate,
            status: .scheduled,
            estimatedCost: estimatedCost,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        dataStore.addBooking(booking)
        
        // Auto-create reminder if service date is more than 7 days away
        let daysUntilService = calendar.dateComponents([.day], from: Date(), to: scheduledDate).day ?? 0
        if daysUntilService > 7 {
            let reminderDate = calendar.date(byAdding: .day, value: -2, to: scheduledDate) ?? scheduledDate
            let reminder = ServiceReminderEntity(
                vehicle: vehicle,
                title: "Upcoming Service",
                description: "Your \(serviceType.name) is scheduled for \(scheduledDate.formatted(date: .abbreviated, time: .omitted))",
                dueDate: reminderDate,
                type: .service,
                isUrgent: false
            )
            dataStore.addReminder(reminder)
        }
        
        return .success(booking)
    }
    
    func updateBookingStatus(_ booking: ServiceBookingEntity, to status: BookingStatus, 
                           actualCost: Double? = nil, completedDate: Date? = nil) -> Result<ServiceBookingEntity, BusinessError> {
        
        // Business rules for status transitions
        let currentStatus = BookingStatus(rawValue: booking.status) ?? .scheduled
        
        switch (currentStatus, status) {
        case (.scheduled, .confirmed), (.scheduled, .cancelled):
            break // Valid transitions
        case (.confirmed, .inProgress), (.confirmed, .cancelled):
            break // Valid transitions
        case (.inProgress, .completed), (.inProgress, .cancelled):
            break // Valid transitions
        case (.completed, _), (.cancelled, _):
            return .failure(.businessRuleViolation("Cannot change status of completed or cancelled booking"))
        default:
            return .failure(.businessRuleViolation("Invalid status transition from \(currentStatus.rawValue) to \(status.rawValue)"))
        }
        
        // Validate completion requirements
        if status == .completed {
            guard let actualCost = actualCost, actualCost >= 0 else {
                return .failure(.invalidInput("Actual cost is required for completed bookings"))
            }
            booking.actualCost = actualCost
            booking.completedDate = completedDate ?? Date()
        }
        
        booking.status = status.rawValue
        dataStore.updateBooking(booking)
        
        return .success(booking)
    }
    
    // MARK: - Reminder Business Logic
    
    func createReminder(vehicle: VehicleEntity, title: String, description: String, 
                       dueDate: Date, type: ReminderType, isUrgent: Bool = false) -> Result<ServiceReminderEntity, BusinessError> {
        
        guard !title.isEmpty, !description.isEmpty else {
            return .failure(.invalidInput("Title and description are required"))
        }
        
        let reminder = ServiceReminderEntity(
            vehicle: vehicle,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            type: type,
            isUrgent: isUrgent
        )
        
        dataStore.addReminder(reminder)
        return .success(reminder)
    }
    
    func generateSmartReminders(for vehicle: VehicleEntity) -> [ServiceReminderEntity] {
        var suggestions: [ServiceReminderEntity] = []
        let currentYear = Calendar.current.component(.year, from: Date())
        let vehicleAge = currentYear - vehicle.year
        
        // High mileage service recommendation
        if vehicle.mileage > 60000 {
            let reminder = ServiceReminderEntity(
                vehicle: vehicle,
                title: "High Mileage Service Recommended",
                description: "Your vehicle has high mileage (\(vehicle.mileage) miles). Consider a comprehensive service including cambelt and fluid changes.",
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                type: .service,
                isUrgent: vehicle.mileage > 100000
            )
            suggestions.append(reminder)
        }
        
        // Age-based brake check
        if vehicleAge > 5 {
            let reminder = ServiceReminderEntity(
                vehicle: vehicle,
                title: "Brake System Check Due",
                description: "Vehicles over 5 years old should have brake systems inspected annually for safety.",
                dueDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date(),
                type: .brake,
                isUrgent: vehicleAge > 10
            )
            suggestions.append(reminder)
        }
        
        // Electric vehicle specific checks
        if vehicle.fuelTypeEnum == .electric {
            let reminder = ServiceReminderEntity(
                vehicle: vehicle,
                title: "EV Battery Health Check",
                description: "Electric vehicle batteries benefit from regular health monitoring to ensure optimal performance.",
                dueDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date(),
                type: .battery,
                isUrgent: false
            )
            suggestions.append(reminder)
        }
        
        // MOT reminder based on due date
        if let motDue = vehicle.motDue {
            let daysUntilMOT = Calendar.current.dateComponents([.day], from: Date(), to: motDue).day ?? 0
            if daysUntilMOT <= 60 && daysUntilMOT > 0 {
                let reminder = ServiceReminderEntity(
                    vehicle: vehicle,
                    title: "MOT Test Due Soon",
                    description: "Your MOT expires on \(motDue.formatted(date: .abbreviated, time: .omitted)). Book your test to avoid driving illegally.",
                    dueDate: Calendar.current.date(byAdding: .day, value: -7, to: motDue) ?? motDue,
                    type: .mot,
                    isUrgent: daysUntilMOT <= 30
                )
                suggestions.append(reminder)
            }
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func calculateEstimatedCost(for serviceType: ServiceTypeEntity, vehicle: VehicleEntity) -> Double {
        var baseCost = Double(serviceType.minPrice)
        
        // Adjust cost based on vehicle characteristics
        let vehicleAge = Calendar.current.component(.year, from: Date()) - vehicle.year
        
        // Age multiplier
        if vehicleAge > 10 {
            baseCost *= 1.2 // 20% increase for older vehicles
        } else if vehicleAge > 5 {
            baseCost *= 1.1 // 10% increase for middle-aged vehicles
        }
        
        // Mileage multiplier
        if vehicle.mileage > 100000 {
            baseCost *= 1.15 // 15% increase for high mileage
        } else if vehicle.mileage > 60000 {
            baseCost *= 1.05 // 5% increase for moderate mileage
        }
        
        // Electric vehicle premium for specialized services
        if vehicle.fuelTypeEnum == .electric && serviceType.isSpecialty {
            baseCost *= 1.1 // 10% premium for EV specialty work
        }
        
        return min(baseCost, Double(serviceType.maxPrice))
    }
    
    // MARK: - Status Calculations
    
    func getServiceStatus(for vehicle: VehicleEntity) -> ServiceStatus {
        guard let nextServiceDue = vehicle.nextServiceDue else {
            return .unknown
        }
        
        let daysUntilService = Calendar.current.dateComponents([.day], from: Date(), to: nextServiceDue).day ?? 0
        
        if daysUntilService < 0 {
            return .overdue
        } else if daysUntilService <= 30 {
            return .dueSoon
        } else {
            return .upToDate
        }
    }
    
    func getMOTStatus(for vehicle: VehicleEntity) -> MOTStatus {
        guard let motDue = vehicle.motDue else {
            return .unknown
        }
        
        let daysUntilMOT = Calendar.current.dateComponents([.day], from: Date(), to: motDue).day ?? 0
        
        if daysUntilMOT < 0 {
            return .expired
        } else if daysUntilMOT <= 30 {
            return .dueSoon
        } else {
            return .valid
        }
    }
    
    func getVehicleDisplayName(_ vehicle: VehicleEntity) -> String {
        return "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }
}

// MARK: - Business Error Types

enum BusinessError: LocalizedError, Equatable {
    case invalidInput(String)
    case duplicateData(String)
    case businessRuleViolation(String)
    case dataNotFound(String)
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid Input: \(message)"
        case .duplicateData(let message):
            return "Duplicate Data: \(message)"
        case .businessRuleViolation(let message):
            return "Business Rule Violation: \(message)"
        case .dataNotFound(let message):
            return "Data Not Found: \(message)"
        case .systemError(let message):
            return "System Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please check your input and try again."
        case .duplicateData:
            return "Please use different values to avoid duplicates."
        case .businessRuleViolation:
            return "Please resolve the business constraint before proceeding."
        case .dataNotFound:
            return "Please ensure the data exists before accessing it."
        case .systemError:
            return "Please try again later or contact support."
        }
    }
}