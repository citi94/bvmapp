//
//  BusinessLogicTests.swift
//  bvmappTests
//
//  Created by Peter Harding on 05/07/2025.
//

import XCTest
import SwiftData
@testable import bvmapp

@MainActor
final class BusinessLogicTests: XCTestCase {
    var dataStore: DataStore!
    var businessLogic: BusinessLogicService!
    
    override func setUp() async throws {
        // Create in-memory data store for testing
        let schema = Schema([
            VehicleEntity.self,
            ServiceTypeEntity.self,
            ServiceBookingEntity.self,
            ServiceReminderEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Note: We would need to modify DataStore to accept a custom ModelContainer for testing
        // For now, this is a template of how the tests would be structured
        
        businessLogic = BusinessLogicService(dataStore: DataStore.shared)
    }
    
    override func tearDown() async throws {
        dataStore = nil
        businessLogic = nil
    }
    
    // MARK: - Vehicle Creation Tests
    
    func testCreateVehicle_ValidData_Success() async throws {
        // Given
        let make = "Tesla"
        let model = "Model 3"
        let year = 2022
        let registration = "AB22XYZ"
        let mileage = 15000
        let fuelType = FuelType.electric
        let color = "Pearl White"
        
        // When
        let result = businessLogic.createVehicle(
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileage,
            fuelType: fuelType,
            color: color
        )
        
        // Then
        switch result {
        case .success(let vehicle):
            XCTAssertEqual(vehicle.make, make)
            XCTAssertEqual(vehicle.model, model)
            XCTAssertEqual(vehicle.year, year)
            XCTAssertEqual(vehicle.registration, registration.uppercased())
            XCTAssertEqual(vehicle.mileage, mileage)
            XCTAssertEqual(vehicle.fuelTypeEnum, fuelType)
            XCTAssertEqual(vehicle.color, color)
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }
    
    func testCreateVehicle_EmptyMake_Failure() async throws {
        // Given
        let make = ""
        let model = "Model 3"
        let year = 2022
        let registration = "AB22XYZ"
        let mileage = 15000
        let fuelType = FuelType.electric
        let color = "Pearl White"
        
        // When
        let result = businessLogic.createVehicle(
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileage,
            fuelType: fuelType,
            color: color
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to empty make")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput("All fields are required"))
        }
    }
    
    func testCreateVehicle_InvalidYear_Failure() async throws {
        // Given
        let make = "Tesla"
        let model = "Model 3"
        let year = 1800 // Invalid year
        let registration = "AB22XYZ"
        let mileage = 15000
        let fuelType = FuelType.electric
        let color = "Pearl White"
        
        // When
        let result = businessLogic.createVehicle(
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileage,
            fuelType: fuelType,
            color: color
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to invalid year")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput("Invalid year"))
        }
    }
    
    func testCreateVehicle_InvalidMileage_Failure() async throws {
        // Given
        let make = "Tesla"
        let model = "Model 3"
        let year = 2022
        let registration = "AB22XYZ"
        let mileage = -100 // Invalid mileage
        let fuelType = FuelType.electric
        let color = "Pearl White"
        
        // When
        let result = businessLogic.createVehicle(
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileage,
            fuelType: fuelType,
            color: color
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to invalid mileage")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput("Invalid mileage"))
        }
    }
    
    // MARK: - Service Status Tests
    
    func testGetServiceStatus_OverdueService_ReturnsOverdue() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White",
            nextServiceDue: Calendar.current.date(byAdding: .day, value: -10, to: Date()) // 10 days ago
        )
        
        // When
        let status = businessLogic.getServiceStatus(for: vehicle)
        
        // Then
        XCTAssertEqual(status, .overdue)
    }
    
    func testGetServiceStatus_DueSoon_ReturnsDueSoon() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White",
            nextServiceDue: Calendar.current.date(byAdding: .day, value: 15, to: Date()) // 15 days from now
        )
        
        // When
        let status = businessLogic.getServiceStatus(for: vehicle)
        
        // Then
        XCTAssertEqual(status, .dueSoon)
    }
    
    func testGetServiceStatus_UpToDate_ReturnsUpToDate() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White",
            nextServiceDue: Calendar.current.date(byAdding: .day, value: 60, to: Date()) // 60 days from now
        )
        
        // When
        let status = businessLogic.getServiceStatus(for: vehicle)
        
        // Then
        XCTAssertEqual(status, .upToDate)
    }
    
    func testGetServiceStatus_NoServiceDate_ReturnsUnknown() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White",
            nextServiceDue: nil
        )
        
        // When
        let status = businessLogic.getServiceStatus(for: vehicle)
        
        // Then
        XCTAssertEqual(status, .unknown)
    }
    
    // MARK: - Smart Reminders Tests
    
    func testGenerateSmartReminders_HighMileageVehicle_CreatesHighMileageReminder() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Ford",
            model: "Focus",
            year: 2015,
            registration: "AB15XYZ",
            mileage: 80000, // High mileage
            fuelType: .petrol,
            color: "Blue"
        )
        
        // When
        let reminders = businessLogic.generateSmartReminders(for: vehicle)
        
        // Then
        XCTAssertTrue(reminders.contains { $0.title.contains("High Mileage") })
    }
    
    func testGenerateSmartReminders_OldVehicle_CreatesBrakeCheckReminder() async throws {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())
        let vehicle = VehicleEntity(
            make: "Ford",
            model: "Focus",
            year: currentYear - 8, // 8 years old
            registration: "AB15XYZ",
            mileage: 50000,
            fuelType: .petrol,
            color: "Blue"
        )
        
        // When
        let reminders = businessLogic.generateSmartReminders(for: vehicle)
        
        // Then
        XCTAssertTrue(reminders.contains { $0.title.contains("Brake") })
    }
    
    func testGenerateSmartReminders_ElectricVehicle_CreatesBatteryCheckReminder() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2020,
            registration: "AB20XYZ",
            mileage: 30000,
            fuelType: .electric,
            color: "White"
        )
        
        // When
        let reminders = businessLogic.generateSmartReminders(for: vehicle)
        
        // Then
        XCTAssertTrue(reminders.contains { $0.title.contains("Battery") })
    }
    
    // MARK: - Cost Calculation Tests
    
    func testCalculateEstimatedCost_NewVehicle_ReturnsBaseCost() async throws {
        // This would test the private calculateEstimatedCost method
        // We would need to expose it for testing or test it indirectly through createBooking
    }
    
    func testCalculateEstimatedCost_OldVehicle_ReturnsIncreasedCost() async throws {
        // This would test cost adjustment for older vehicles
    }
    
    func testCalculateEstimatedCost_HighMileage_ReturnsIncreasedCost() async throws {
        // This would test cost adjustment for high mileage vehicles
    }
    
    // MARK: - Booking Business Logic Tests
    
    func testCreateBooking_PastDate_Failure() async throws {
        // Given
        let vehicle = VehicleEntity(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            registration: "AB22XYZ",
            mileage: 15000,
            fuelType: .electric,
            color: "Pearl White"
        )
        
        let serviceType = ServiceTypeEntity(
            name: "Basic Service",
            description: "Basic maintenance",
            estimatedDuration: 60,
            priceRange: (100, 200),
            isSpecialty: false,
            icon: "wrench"
        )
        
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // When
        let result = businessLogic.createBooking(
            vehicle: vehicle,
            serviceType: serviceType,
            scheduledDate: pastDate,
            notes: "Test booking"
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to past date")
        case .failure(let error):
            XCTAssertEqual(error, .invalidInput("Cannot schedule booking in the past"))
        }
    }
    
    // MARK: - Form Validation Tests
    
    func testFormValidator_RequiredField_Empty_AddsError() async throws {
        // Given
        let validator = FormValidator()
        
        // When
        validator.validateRequired("", field: "test", fieldName: "Test Field")
        
        // Then
        XCTAssertTrue(validator.hasError(for: "test"))
        XCTAssertEqual(validator.getError(for: "test"), "Test Field is required")
    }
    
    func testFormValidator_RequiredField_WhitespaceOnly_AddsError() async throws {
        // Given
        let validator = FormValidator()
        
        // When
        validator.validateRequired("   ", field: "test", fieldName: "Test Field")
        
        // Then
        XCTAssertTrue(validator.hasError(for: "test"))
    }
    
    func testFormValidator_RequiredField_ValidValue_RemovesError() async throws {
        // Given
        let validator = FormValidator()
        validator.addError(field: "test", message: "Test error")
        
        // When
        validator.validateRequired("Valid Value", field: "test", fieldName: "Test Field")
        
        // Then
        XCTAssertFalse(validator.hasError(for: "test"))
    }
    
    func testFormValidator_ValidateEmail_InvalidEmail_AddsError() async throws {
        // Given
        let validator = FormValidator()
        
        // When
        validator.validateEmail("invalid-email", field: "email")
        
        // Then
        XCTAssertTrue(validator.hasError(for: "email"))
        XCTAssertEqual(validator.getError(for: "email"), "Please enter a valid email address")
    }
    
    func testFormValidator_ValidateEmail_ValidEmail_RemovesError() async throws {
        // Given
        let validator = FormValidator()
        validator.addError(field: "email", message: "Test error")
        
        // When
        validator.validateEmail("test@example.com", field: "email")
        
        // Then
        XCTAssertFalse(validator.hasError(for: "email"))
    }
    
    func testFormValidator_ValidateYear_InvalidYear_AddsError() async throws {
        // Given
        let validator = FormValidator()
        
        // When
        validator.validateYear(1800, field: "year")
        
        // Then
        XCTAssertTrue(validator.hasError(for: "year"))
    }
    
    func testFormValidator_ValidateMileage_InvalidMileage_AddsError() async throws {
        // Given
        let validator = FormValidator()
        
        // When
        validator.validateMileage("invalid", field: "mileage")
        
        // Then
        XCTAssertTrue(validator.hasError(for: "mileage"))
        XCTAssertEqual(validator.getError(for: "mileage"), "Mileage must be between 0 and 999,999")
    }
    
    func testFormValidator_ValidateMileage_ValidMileage_RemovesError() async throws {
        // Given
        let validator = FormValidator()
        validator.addError(field: "mileage", message: "Test error")
        
        // When
        validator.validateMileage("50000", field: "mileage")
        
        // Then
        XCTAssertFalse(validator.hasError(for: "mileage"))
    }
}