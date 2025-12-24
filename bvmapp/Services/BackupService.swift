//
//  BackupService.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import Foundation
import SwiftData

// MARK: - Backup Service

@MainActor
class BackupService: ObservableObject {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Backup Data Structure
    
    struct BackupData: Codable {
        let version: String
        let createdAt: Date
        let vehicles: [BackupVehicle]
        let serviceTypes: [BackupServiceType]
        let bookings: [BackupBooking]
        let reminders: [BackupReminder]
    }
    
    struct BackupVehicle: Codable, Identifiable {
        let id: UUID
        let make: String
        let model: String
        let year: Int
        let registration: String
        let mileage: Int
        let fuelType: String
        let color: String
        let lastServiceDate: Date?
        let nextServiceDue: Date?
        let motDue: Date?
        let createdAt: Date
        let updatedAt: Date
    }
    
    struct BackupServiceType: Codable, Identifiable {
        let id: UUID
        let name: String
        let description: String
        let estimatedDuration: Int
        let minPrice: Int
        let maxPrice: Int
        let isSpecialty: Bool
        let icon: String
        let createdAt: Date
        let updatedAt: Date
    }
    
    struct BackupBooking: Codable, Identifiable {
        let id: UUID
        let vehicleId: UUID
        let serviceTypeId: UUID
        let scheduledDate: Date
        let status: String
        let estimatedCost: Double
        let actualCost: Double?
        let notes: String
        let completedDate: Date?
        let createdAt: Date
        let updatedAt: Date
    }
    
    struct BackupReminder: Codable, Identifiable {
        let id: UUID
        let vehicleId: UUID
        let title: String
        let description: String
        let dueDate: Date
        let type: String
        let isCompleted: Bool
        let isUrgent: Bool
        let createdAt: Date
        let updatedAt: Date
    }
    
    // MARK: - Backup Operations
    
    func createBackup() -> Result<BackupData, BackupError> {
        do {
            let vehicles = dataStore.vehicles.map { entity in
                BackupVehicle(
                    id: entity.id,
                    make: entity.make,
                    model: entity.model,
                    year: entity.year,
                    registration: entity.registration,
                    mileage: entity.mileage,
                    fuelType: entity.fuelType,
                    color: entity.color,
                    lastServiceDate: entity.lastServiceDate,
                    nextServiceDue: entity.nextServiceDue,
                    motDue: entity.motDue,
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
            
            let serviceTypes = dataStore.serviceTypes.map { entity in
                BackupServiceType(
                    id: entity.id,
                    name: entity.name,
                    description: entity.serviceDescription,
                    estimatedDuration: entity.estimatedDuration,
                    minPrice: entity.minPrice,
                    maxPrice: entity.maxPrice,
                    isSpecialty: entity.isSpecialty,
                    icon: entity.icon,
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
            
            let bookings = dataStore.bookings.map { entity in
                BackupBooking(
                    id: entity.id,
                    vehicleId: entity.vehicle?.id ?? UUID(),
                    serviceTypeId: entity.serviceType?.id ?? UUID(),
                    scheduledDate: entity.scheduledDate,
                    status: entity.status,
                    estimatedCost: entity.estimatedCost,
                    actualCost: entity.actualCost,
                    notes: entity.notes,
                    completedDate: entity.completedDate,
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
            
            let reminders = dataStore.reminders.map { entity in
                BackupReminder(
                    id: entity.id,
                    vehicleId: entity.vehicle?.id ?? UUID(),
                    title: entity.title,
                    description: entity.reminderDescription,
                    dueDate: entity.dueDate,
                    type: entity.type,
                    isCompleted: entity.isCompleted,
                    isUrgent: entity.isUrgent,
                    createdAt: entity.createdAt,
                    updatedAt: entity.updatedAt
                )
            }
            
            let backup = BackupData(
                version: "1.0",
                createdAt: Date(),
                vehicles: vehicles,
                serviceTypes: serviceTypes,
                bookings: bookings,
                reminders: reminders
            )
            
            return .success(backup)
        } catch {
            return .failure(.exportFailed("Failed to create backup: \(error.localizedDescription)"))
        }
    }
    
    func exportBackupToJSON() -> Result<Data, BackupError> {
        switch createBackup() {
        case .success(let backup):
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(backup)
                return .success(data)
            } catch {
                return .failure(.exportFailed("Failed to encode backup: \(error.localizedDescription)"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func saveBackupToDocuments() -> Result<URL, BackupError> {
        switch exportBackupToJSON() {
        case .success(let data):
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "BVM_Backup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                return .success(fileURL)
            } catch {
                return .failure(.exportFailed("Failed to save backup file: \(error.localizedDescription)"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Restore Operations
    
    func validateBackup(from data: Data) -> Result<BackupData, BackupError> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)
            
            // Validate backup version
            guard backup.version == "1.0" else {
                return .failure(.invalidBackup("Unsupported backup version: \(backup.version)"))
            }
            
            // Basic validation
            if backup.vehicles.isEmpty && backup.bookings.isEmpty && backup.reminders.isEmpty {
                return .failure(.invalidBackup("Backup appears to be empty"))
            }
            
            return .success(backup)
        } catch {
            return .failure(.invalidBackup("Failed to parse backup file: \(error.localizedDescription)"))
        }
    }
    
    func restoreFromBackup(_ backup: BackupData, replaceExisting: Bool = false) -> Result<Void, BackupError> {
        do {
            // TODO: Implement restore logic
            // This would require careful handling of:
            // 1. Clearing existing data if replaceExisting is true
            // 2. Creating new entities from backup data
            // 3. Handling ID conflicts
            // 4. Maintaining relationships
            
            return .failure(.restoreFailed("Restore functionality not yet implemented"))
        } catch {
            return .failure(.restoreFailed("Failed to restore backup: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Auto Backup
    
    func scheduleAutoBackup() {
        // TODO: Implement automatic backup scheduling
        // This could use:
        // 1. UserDefaults to track last backup date
        // 2. Background app refresh to create periodic backups
        // 3. CloudKit or iCloud Documents for cloud backups
    }
}

// MARK: - Backup Errors

enum BackupError: LocalizedError, Equatable {
    case exportFailed(String)
    case importFailed(String)
    case invalidBackup(String)
    case restoreFailed(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return "Export Failed: \(message)"
        case .importFailed(let message):
            return "Import Failed: \(message)"
        case .invalidBackup(let message):
            return "Invalid Backup: \(message)"
        case .restoreFailed(let message):
            return "Restore Failed: \(message)"
        case .permissionDenied:
            return "Permission Denied: Cannot access files"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exportFailed, .importFailed:
            return "Please ensure you have sufficient storage space and try again."
        case .invalidBackup:
            return "Please ensure you're using a valid BVM Deal backup file."
        case .restoreFailed:
            return "Please try again or contact support if the problem persists."
        case .permissionDenied:
            return "Please grant file access permissions in Settings."
        }
    }
}