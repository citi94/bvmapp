//
//  DataModels.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Vehicle Models
struct Vehicle: Identifiable, Codable, Hashable {
    let id: UUID
    var make: String
    var model: String
    var year: Int
    var registration: String
    var mileage: Int
    var fuelType: FuelType
    var color: String
    var lastServiceDate: Date?
    var nextServiceDue: Date?
    var motDue: Date?
    
    init(id: UUID = UUID(), make: String, model: String, year: Int, registration: String, mileage: Int, fuelType: FuelType, color: String, lastServiceDate: Date? = nil, nextServiceDue: Date? = nil, motDue: Date? = nil) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.registration = registration
        self.mileage = mileage
        self.fuelType = fuelType
        self.color = color
        self.lastServiceDate = lastServiceDate
        self.nextServiceDue = nextServiceDue
        self.motDue = motDue
    }
}

enum FuelType: String, CaseIterable, Codable {
    case petrol = "Petrol"
    case diesel = "Diesel"
    case electric = "Electric"
    case hybrid = "Hybrid"
    case pluginHybrid = "Plugin Hybrid"
    
    var icon: String {
        switch self {
        case .petrol: return "fuelpump.fill"
        case .diesel: return "fuelpump.fill"
        case .electric: return "bolt.fill"
        case .hybrid: return "leaf.fill"
        case .pluginHybrid: return "plug.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .petrol: return .blue
        case .diesel: return .orange
        case .electric: return .green
        case .hybrid: return .mint
        case .pluginHybrid: return .purple
        }
    }
}

// MARK: - Service Models
struct ServiceType: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let estimatedDuration: Int // in minutes
    let minPrice: Int
    let maxPrice: Int
    let isSpecialty: Bool
    let icon: String
    
    var priceRange: (Int, Int) {
        return (minPrice, maxPrice)
    }
    
    init(id: UUID = UUID(), name: String, description: String, estimatedDuration: Int, priceRange: (Int, Int), isSpecialty: Bool, icon: String) {
        self.id = id
        self.name = name
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.minPrice = priceRange.0
        self.maxPrice = priceRange.1
        self.isSpecialty = isSpecialty
        self.icon = icon
    }
}

struct ServiceBooking: Identifiable, Codable {
    let id: UUID
    let vehicleId: UUID
    let serviceType: ServiceType
    let scheduledDate: Date
    var status: BookingStatus
    var estimatedCost: Double
    var actualCost: Double?
    var notes: String
    var completedDate: Date?
    
    init(id: UUID = UUID(), vehicleId: UUID, serviceType: ServiceType, scheduledDate: Date, status: BookingStatus, estimatedCost: Double, actualCost: Double? = nil, notes: String = "", completedDate: Date? = nil) {
        self.id = id
        self.vehicleId = vehicleId
        self.serviceType = serviceType
        self.scheduledDate = scheduledDate
        self.status = status
        self.estimatedCost = estimatedCost
        self.actualCost = actualCost
        self.notes = notes
        self.completedDate = completedDate
    }
}

enum BookingStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case confirmed = "Confirmed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .confirmed: return .green
        case .inProgress: return .orange
        case .completed: return .purple
        case .cancelled: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .confirmed: return "checkmark.circle"
        case .inProgress: return "wrench"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Reminder Models
struct ServiceReminder: Identifiable, Codable {
    let id: UUID
    let vehicleId: UUID
    let title: String
    let description: String
    let dueDate: Date
    let type: ReminderType
    var isCompleted: Bool
    var isUrgent: Bool
    
    init(id: UUID = UUID(), vehicleId: UUID, title: String, description: String, dueDate: Date, type: ReminderType, isCompleted: Bool = false, isUrgent: Bool = false) {
        self.id = id
        self.vehicleId = vehicleId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.type = type
        self.isCompleted = isCompleted
        self.isUrgent = isUrgent
    }
}

enum ReminderType: String, CaseIterable, Codable {
    case service = "Service"
    case mot = "MOT"
    case insurance = "Insurance"
    case roadTax = "Road Tax"
    case tyres = "Tyres"
    case brake = "Brake Check"
    case battery = "Battery Check"
    
    var icon: String {
        switch self {
        case .service: return "wrench.and.screwdriver"
        case .mot: return "doc.text"
        case .insurance: return "shield"
        case .roadTax: return "banknote"
        case .tyres: return "circle"
        case .brake: return "stop"
        case .battery: return "battery.100"
        }
    }
    
    var color: Color {
        switch self {
        case .service: return .blue
        case .mot: return .green
        case .insurance: return .purple
        case .roadTax: return .orange
        case .tyres: return .gray
        case .brake: return .red
        case .battery: return .yellow
        }
    }
}

// MARK: - Status Models
enum ServiceStatus {
    case current
    case due
    case dueSoon
    case upToDate
    case overdue
    case unknown
    
    var color: Color {
        switch self {
        case .current: return .green
        case .due: return .orange
        case .dueSoon: return .yellow
        case .upToDate: return .green
        case .overdue: return .red
        case .unknown: return .gray
        }
    }
    
    var displayText: String {
        switch self {
        case .current: return "Current"
        case .due: return "Due"
        case .dueSoon: return "Due Soon"
        case .upToDate: return "Up to Date"
        case .overdue: return "Overdue"
        case .unknown: return "Unknown"
        }
    }
}

enum MOTStatus {
    case current
    case due
    case dueSoon
    case expired
    case valid
    case overdue
    case unknown
    
    var color: Color {
        switch self {
        case .current: return .green
        case .due: return .orange
        case .dueSoon: return .yellow
        case .expired: return .red
        case .valid: return .green
        case .overdue: return .red
        case .unknown: return .gray
        }
    }
    
    var displayText: String {
        switch self {
        case .current: return "Current"
        case .due: return "Due"
        case .dueSoon: return "Due Soon"
        case .expired: return "Expired"
        case .valid: return "Valid"
        case .overdue: return "Overdue"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Cost Estimation Models
struct CostEstimate: Identifiable {
    let id: UUID
    let serviceType: ServiceType
    let vehicleType: String
    let basePrice: Double
    let additionalCosts: [AdditionalCost]
    let totalEstimate: Double
    let estimatedDuration: String
    
    init(id: UUID = UUID(), serviceType: ServiceType, vehicleType: String, basePrice: Double, additionalCosts: [AdditionalCost] = [], totalEstimate: Double, estimatedDuration: String) {
        self.id = id
        self.serviceType = serviceType
        self.vehicleType = vehicleType
        self.basePrice = basePrice
        self.additionalCosts = additionalCosts
        self.totalEstimate = totalEstimate
        self.estimatedDuration = estimatedDuration
    }
}

struct AdditionalCost: Identifiable {
    let id: UUID
    let name: String
    let cost: Double
    let isOptional: Bool
    
    init(id: UUID = UUID(), name: String, cost: Double, isOptional: Bool = false) {
        self.id = id
        self.name = name
        self.cost = cost
        self.isOptional = isOptional
    }
}

// MARK: - Contact Information
struct ContactInfo {
    static let phone = "01304 732 747"
    static let mobile = "07441 111 189"
    static let email = "info@bvmdeal.co.uk"
    static let whatsapp = "https://wa.me/message/2ABQLRICNXSZJ1"
    static let instagram = "https://www.instagram.com/bespokevehiclemaintenance/"
    static let address = "Unit 3a, Southwall Industrial Estate, Southwall Road, Deal, Kent CT14 9QB"
    static let openingHours = "0900 to 1700, Monday to Friday"
    static let latitude = 51.228312
    static let longitude = 1.388879
}