//
//  PerformanceOptimizations.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Performance Optimized Data Store Extension

extension DataStore {
    
    // MARK: - Pagination Support
    
    func loadVehiclesPaginated(limit: Int = 20, offset: Int = 0) -> [VehicleEntity] {
        var descriptor = FetchDescriptor<VehicleEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load paginated vehicles: \(error)")
            return []
        }
    }
    
    func loadBookingsPaginated(limit: Int = 50, offset: Int = 0) -> [ServiceBookingEntity] {
        var descriptor = FetchDescriptor<ServiceBookingEntity>(
            sortBy: [SortDescriptor(\.scheduledDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load paginated bookings: \(error)")
            return []
        }
    }
    
    // MARK: - Optimized Queries
    
    func searchVehicles(query: String) -> [VehicleEntity] {
        let searchPredicate = #Predicate<VehicleEntity> { vehicle in
            vehicle.make.localizedStandardContains(query) ||
            vehicle.model.localizedStandardContains(query) ||
            vehicle.registration.localizedStandardContains(query)
        }
        
        let descriptor = FetchDescriptor<VehicleEntity>(
            predicate: searchPredicate,
            sortBy: [SortDescriptor(\.make), SortDescriptor(\.model)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to search vehicles: \(error)")
            return []
        }
    }
    
    func getActiveBookings() -> [ServiceBookingEntity] {
        let activePredicate = #Predicate<ServiceBookingEntity> { booking in
            booking.status == "Scheduled" || booking.status == "Confirmed" || booking.status == "In Progress"
        }
        
        let descriptor = FetchDescriptor<ServiceBookingEntity>(
            predicate: activePredicate,
            sortBy: [SortDescriptor(\.scheduledDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load active bookings: \(error)")
            return []
        }
    }
    
    func getUpcomingReminders(days: Int = 30) -> [ServiceReminderEntity] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        let upcomingPredicate = #Predicate<ServiceReminderEntity> { reminder in
            reminder.dueDate <= futureDate && !reminder.isCompleted
        }
        
        let descriptor = FetchDescriptor<ServiceReminderEntity>(
            predicate: upcomingPredicate,
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load upcoming reminders: \(error)")
            return []
        }
    }
    
    // MARK: - Batch Operations
    
    func batchUpdateVehicleMileage(_ updates: [(UUID, Int)]) {
        for (vehicleId, newMileage) in updates {
            if let vehicle = vehicles.first(where: { $0.id == vehicleId }) {
                vehicle.mileage = newMileage
                vehicle.updatedAt = Date()
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to batch update vehicle mileage: \(error)")
        }
    }
    
    func batchDeleteBookings(_ bookingIds: [UUID]) {
        let bookingsToDelete = bookings.filter { bookingIds.contains($0.id) }
        
        for booking in bookingsToDelete {
            modelContext.delete(booking)
        }
        
        do {
            try modelContext.save()
            loadBookings()
        } catch {
            print("Failed to batch delete bookings: \(error)")
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData(olderThan days: Int = 365) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Clean up completed bookings older than cutoff
        let oldCompletedPredicate = #Predicate<ServiceBookingEntity> { booking in
            booking.status == "Completed" && 
            (booking.completedDate ?? booking.createdAt) < cutoffDate
        }
        
        let oldBookingsDescriptor = FetchDescriptor<ServiceBookingEntity>(predicate: oldCompletedPredicate)
        
        do {
            let oldBookings = try modelContext.fetch(oldBookingsDescriptor)
            for booking in oldBookings {
                modelContext.delete(booking)
            }
            
            // Clean up completed reminders older than cutoff
            let oldRemindersPredicate = #Predicate<ServiceReminderEntity> { reminder in
                reminder.isCompleted && reminder.dueDate < cutoffDate
            }
            
            let oldRemindersDescriptor = FetchDescriptor<ServiceReminderEntity>(predicate: oldRemindersPredicate)
            let oldReminders = try modelContext.fetch(oldRemindersDescriptor)
            
            for reminder in oldReminders {
                modelContext.delete(reminder)
            }
            
            try modelContext.save()
            
            // Reload data
            loadBookings()
            loadReminders()
            
            print("Cleaned up \(oldBookings.count) old bookings and \(oldReminders.count) old reminders")
        } catch {
            print("Failed to cleanup old data: \(error)")
        }
    }
}

// MARK: - Memory-Efficient Image Loading

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Lazy Loading Components

struct LazyVehicleRow: View {
    let vehicle: VehicleEntity
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                VehicleRow(vehicle: vehicle)
            } else {
                VStack {
                    Text(coordinator.getVehicleDisplayName(vehicle))
                    .font(.headline)
                    .redacted(reason: .placeholder)
                }
                .onAppear {
                    // Simulate loading delay for large datasets
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isLoaded = true
                    }
                }
            }
        }
    }
}

// MARK: - Search and Filter Optimizations

class SearchManager: ObservableObject {
    @Published var searchText = ""
    @Published var filteredResults: [VehicleEntity] = []
    @Published var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    func search() {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filteredResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task { @MainActor in
            // Add small delay to avoid too many searches while typing
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            // Perform search
            let results = dataStore.searchVehicles(query: searchText)
            
            guard !Task.isCancelled else { return }
            
            filteredResults = results
            isSearching = false
        }
    }
    
    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        filteredResults = []
        isSearching = false
    }
}

// MARK: - Database Maintenance

extension DataStore {
    
    func performMaintenance() async {
        await MainActor.run {
            // Cleanup old data
            cleanupOldData()
            
            // Optimize database (this would be database-specific)
            // For SwiftData, we rely on Core Data's automatic optimizations
            
            print("Database maintenance completed")
        }
    }
    
    func getDatabaseSize() -> String {
        // Get the database file size
        guard let storeURL = modelContainer.configurations.first?.url else {
            return "Unknown"
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            if let fileSize = attributes[FileAttributeKey.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("Failed to get database size: \(error)")
        }
        
        return "Unknown"
    }
    
    func getEntityCounts() -> (vehicles: Int, bookings: Int, reminders: Int, serviceTypes: Int) {
        return (
            vehicles: vehicles.count,
            bookings: bookings.count,
            reminders: reminders.count,
            serviceTypes: serviceTypes.count
        )
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var operationTimes: [String: TimeInterval] = [:]
    
    private init() {}
    
    func startOperation(_ name: String) -> CFAbsoluteTime {
        let startTime = CFAbsoluteTimeGetCurrent()
        return startTime
    }
    
    func endOperation(_ name: String, startTime: CFAbsoluteTime) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        operationTimes[name] = duration
        
        if duration > 1.0 { // Log operations taking more than 1 second
            print("⚠️ Slow operation: \(name) took \(String(format: "%.2f", duration))s")
        }
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        return operationTimes[operation]
    }
    
    func getAllOperationTimes() -> [String: TimeInterval] {
        return operationTimes
    }
    
    func clearMetrics() {
        operationTimes.removeAll()
    }
}