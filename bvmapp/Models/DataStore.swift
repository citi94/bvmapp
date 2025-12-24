//
//  DataStore.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Models

@Model
final class VehicleEntity {
    @Attribute(.unique) var id: UUID
    var make: String
    var model: String
    var year: Int
    var registration: String
    var mileage: Int
    var fuelType: String
    var color: String
    var lastServiceDate: Date?
    var nextServiceDue: Date?
    var motDue: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ServiceBookingEntity.vehicle)
    var bookings: [ServiceBookingEntity] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ServiceReminderEntity.vehicle)
    var reminders: [ServiceReminderEntity] = []
    
    init(id: UUID = UUID(), make: String, model: String, year: Int, registration: String, 
         mileage: Int, fuelType: FuelType, color: String, lastServiceDate: Date? = nil, 
         nextServiceDue: Date? = nil, motDue: Date? = nil) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.registration = registration
        self.mileage = mileage
        self.fuelType = fuelType.rawValue
        self.color = color
        self.lastServiceDate = lastServiceDate
        self.nextServiceDue = nextServiceDue
        self.motDue = motDue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed properties for legacy compatibility
    var fuelTypeEnum: FuelType {
        return FuelType(rawValue: fuelType) ?? .petrol
    }
}

@Model
final class ServiceTypeEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var serviceDescription: String
    var estimatedDuration: Int
    var minPrice: Int
    var maxPrice: Int
    var isSpecialty: Bool
    var icon: String
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \ServiceBookingEntity.serviceType)
    var bookings: [ServiceBookingEntity] = []
    
    init(id: UUID = UUID(), name: String, description: String, estimatedDuration: Int, 
         priceRange: (Int, Int), isSpecialty: Bool, icon: String) {
        self.id = id
        self.name = name
        self.serviceDescription = description
        self.estimatedDuration = estimatedDuration
        self.minPrice = priceRange.0
        self.maxPrice = priceRange.1
        self.isSpecialty = isSpecialty
        self.icon = icon
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var priceRange: (Int, Int) {
        return (minPrice, maxPrice)
    }
}

@Model
final class ServiceBookingEntity {
    @Attribute(.unique) var id: UUID
    var scheduledDate: Date
    var status: String
    var estimatedCost: Double
    var actualCost: Double?
    var notes: String
    var completedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var vehicle: VehicleEntity?
    var serviceType: ServiceTypeEntity?
    
    init(id: UUID = UUID(), vehicle: VehicleEntity, serviceType: ServiceTypeEntity, 
         scheduledDate: Date, status: BookingStatus, estimatedCost: Double, 
         actualCost: Double? = nil, notes: String = "", completedDate: Date? = nil) {
        self.id = id
        self.vehicle = vehicle
        self.serviceType = serviceType
        self.scheduledDate = scheduledDate
        self.status = status.rawValue
        self.estimatedCost = estimatedCost
        self.actualCost = actualCost
        self.notes = notes
        self.completedDate = completedDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var statusEnum: BookingStatus {
        return BookingStatus(rawValue: status) ?? .scheduled
    }
}

@Model
final class ServiceReminderEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var reminderDescription: String
    var dueDate: Date
    var type: String
    var isCompleted: Bool
    var isUrgent: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var vehicle: VehicleEntity?
    
    init(id: UUID = UUID(), vehicle: VehicleEntity, title: String, description: String, 
         dueDate: Date, type: ReminderType, isCompleted: Bool = false, isUrgent: Bool = false) {
        self.id = id
        self.vehicle = vehicle
        self.title = title
        self.reminderDescription = description
        self.dueDate = dueDate
        self.type = type.rawValue
        self.isCompleted = isCompleted
        self.isUrgent = isUrgent
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var typeEnum: ReminderType {
        return ReminderType(rawValue: type) ?? .service
    }
}

// MARK: - Data Store Manager

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    internal var modelContainer: ModelContainer
    internal var modelContext: ModelContext
    
    @Published var vehicles: [VehicleEntity] = []
    @Published var serviceTypes: [ServiceTypeEntity] = []
    @Published var bookings: [ServiceBookingEntity] = []
    @Published var reminders: [ServiceReminderEntity] = []
    @Published var selectedVehicle: VehicleEntity?
    
    private init() {
        do {
            let schema = Schema([
                VehicleEntity.self,
                ServiceTypeEntity.self,
                ServiceBookingEntity.self,
                ServiceReminderEntity.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = modelContainer.mainContext
            
            loadInitialData()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        loadVehicles()
        loadServiceTypes()
        loadBookings()
        loadReminders()
        
        // Create default service types if none exist
        if serviceTypes.isEmpty {
            createDefaultServiceTypes()
        }
        
        // Create sample vehicle if none exist
        if vehicles.isEmpty {
            createSampleVehicle()
        }
    }
    
    private func loadVehicles() {
        let descriptor = FetchDescriptor<VehicleEntity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            vehicles = try modelContext.fetch(descriptor)
            selectedVehicle = vehicles.first
        } catch {
            print("Failed to load vehicles: \(error)")
        }
    }
    
    private func loadServiceTypes() {
        let descriptor = FetchDescriptor<ServiceTypeEntity>(sortBy: [SortDescriptor(\.name)])
        do {
            serviceTypes = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load service types: \(error)")
        }
    }
    
    internal func loadBookings() {
        let descriptor = FetchDescriptor<ServiceBookingEntity>(sortBy: [SortDescriptor(\.scheduledDate)])
        do {
            bookings = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load bookings: \(error)")
        }
    }
    
    internal func loadReminders() {
        let descriptor = FetchDescriptor<ServiceReminderEntity>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        do {
            reminders = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load reminders: \(error)")
        }
    }
    
    // MARK: - Save Context
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Vehicle Operations
    
    func addVehicle(_ vehicle: VehicleEntity) {
        modelContext.insert(vehicle)
        save()
        loadVehicles()
        
        if selectedVehicle == nil {
            selectedVehicle = vehicle
        }
    }
    
    func updateVehicle(_ vehicle: VehicleEntity) {
        vehicle.updatedAt = Date()
        save()
        loadVehicles()
    }
    
    func deleteVehicle(_ vehicle: VehicleEntity) {
        modelContext.delete(vehicle)
        save()
        loadVehicles()
        loadBookings()
        loadReminders()
        
        if selectedVehicle?.id == vehicle.id {
            selectedVehicle = vehicles.first
        }
    }
    
    func selectVehicle(_ vehicle: VehicleEntity) {
        selectedVehicle = vehicle
    }
    
    // MARK: - Booking Operations
    
    func addBooking(_ booking: ServiceBookingEntity) {
        modelContext.insert(booking)
        save()
        loadBookings()
    }
    
    func updateBooking(_ booking: ServiceBookingEntity) {
        booking.updatedAt = Date()
        save()
        loadBookings()
    }
    
    func deleteBooking(_ booking: ServiceBookingEntity) {
        modelContext.delete(booking)
        save()
        loadBookings()
    }
    
    // MARK: - Reminder Operations
    
    func addReminder(_ reminder: ServiceReminderEntity) {
        modelContext.insert(reminder)
        save()
        loadReminders()
    }
    
    func updateReminder(_ reminder: ServiceReminderEntity) {
        reminder.updatedAt = Date()
        save()
        loadReminders()
    }
    
    func deleteReminder(_ reminder: ServiceReminderEntity) {
        modelContext.delete(reminder)
        save()
        loadReminders()
    }
    
    func completeReminder(_ reminder: ServiceReminderEntity) {
        reminder.isCompleted = true
        reminder.updatedAt = Date()
        save()
        loadReminders()
    }
    
    // MARK: - Default Data Creation
    
    private func createDefaultServiceTypes() {
        let defaultServices = [
            ServiceTypeEntity(
                name: "Electric Vehicle Servicing",
                description: "Expert electric vehicle maintenance including independent Tesla servicing and other EV brands",
                estimatedDuration: 120,
                priceRange: (150, 300),
                isSpecialty: true,
                icon: "car.fill"
            ),
            ServiceTypeEntity(
                name: "Technical Diagnostics",
                description: "Advanced electrical diagnostics and computer-based fault finding",
                estimatedDuration: 90,
                priceRange: (80, 200),
                isSpecialty: true,
                icon: "wrench.and.screwdriver.fill"
            ),
            ServiceTypeEntity(
                name: "Cambelt Replacement",
                description: "Expert cambelt and timing chain services",
                estimatedDuration: 180,
                priceRange: (200, 500),
                isSpecialty: true,
                icon: "gear"
            ),
            ServiceTypeEntity(
                name: "Vehicle Servicing",
                description: "Complete servicing for cars and small vans including routine maintenance",
                estimatedDuration: 60,
                priceRange: (60, 150),
                isSpecialty: false,
                icon: "car.2.fill"
            ),
            ServiceTypeEntity(
                name: "Brake Service",
                description: "Comprehensive brake inspection and repair services",
                estimatedDuration: 75,
                priceRange: (80, 250),
                isSpecialty: false,
                icon: "stop.fill"
            ),
            ServiceTypeEntity(
                name: "Engine Repair",
                description: "Complex engine diagnostics and mechanical repairs",
                estimatedDuration: 240,
                priceRange: (150, 800),
                isSpecialty: true,
                icon: "engine.combustion.fill"
            )
        ]
        
        for service in defaultServices {
            modelContext.insert(service)
        }
        save()
        loadServiceTypes()
    }
    
    private func createSampleVehicle() {
        let sampleVehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22 XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White",
            lastServiceDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
            nextServiceDue: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            motDue: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
        
        modelContext.insert(sampleVehicle)
        save()
        loadVehicles()
        selectedVehicle = sampleVehicle
        
        // Create sample booking and reminder
        if let firstServiceType = serviceTypes.first {
            let sampleBooking = ServiceBookingEntity(
                vehicle: sampleVehicle,
                serviceType: firstServiceType,
                scheduledDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                status: .scheduled,
                estimatedCost: 220,
                notes: "Annual service for Model 3"
            )
            modelContext.insert(sampleBooking)
        }
        
        let sampleReminder = ServiceReminderEntity(
            vehicle: sampleVehicle,
            title: "Service Due",
            description: "Annual service is due for your vehicle",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            type: .service,
            isUrgent: false
        )
        modelContext.insert(sampleReminder)
        
        save()
        loadBookings()
        loadReminders()
    }
}