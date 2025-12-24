//
//  RemindersView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingAddReminder = false
    @State private var selectedFilter: ReminderFilter = .all
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ReminderFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Reminders List
                List {
                    ForEach(filteredReminders) { reminder in
                        ReminderRowView(reminder: reminder)
                    }
                    .onDelete(perform: deleteReminders)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddReminder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
            }
        }
    }
    
    private var filteredReminders: [ServiceReminderEntity] {
        let allReminders = coordinator.reminders.filter { !$0.isCompleted }
        
        switch selectedFilter {
        case .all:
            return allReminders
        case .urgent:
            return allReminders.filter { $0.isUrgent }
        case .thisWeek:
            let weekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
            return allReminders.filter { $0.dueDate <= weekFromNow }
        case .thisMonth:
            let monthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            return allReminders.filter { $0.dueDate <= monthFromNow }
        }
    }
    
    private func deleteReminders(offsets: IndexSet) {
        withAnimation {
            let remindersToDelete = filteredReminders
            for index in offsets {
                let reminder = remindersToDelete[index]
                coordinator.deleteReminder(reminder)
            }
        }
    }
}

enum ReminderFilter: String, CaseIterable {
    case all = "All"
    case urgent = "Urgent"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
}

struct ReminderRowView: View {
    let reminder: ServiceReminderEntity
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var isCompleted = false
    
    var body: some View {
        HStack {
            // Reminder Icon
            Image(systemName: reminder.typeEnum.icon)
                .foregroundColor(reminder.typeEnum.color)
                .frame(width: 24, height: 24)
            
            // Reminder Details
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted)
                
                Text(reminder.reminderDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(reminder.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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
                    
                    Spacer()
                    
                    Text(daysUntilDue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(daysUntilDueColor)
                }
            }
            
            Spacer()
            
            // Completion Toggle
            Button(action: {
                withAnimation {
                    isCompleted.toggle()
                    if isCompleted {
                        coordinator.completeReminder(reminder)
                    }
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var daysUntilDue: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: reminder.dueDate).day ?? 0
        
        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
    
    private var daysUntilDueColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: reminder.dueDate).day ?? 0
        
        if days < 0 {
            return .red
        } else if days <= 7 {
            return .orange
        } else {
            return .secondary
        }
    }
}

struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var reminderType = ReminderType.service
    @State private var isUrgent = false
    @State private var selectedVehicle: VehicleEntity?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    
                    Picker("Type", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Toggle("Mark as Urgent", isOn: $isUrgent)
                }
                
                Section(header: Text("Vehicle")) {
                    Picker("Select Vehicle", selection: $selectedVehicle) {
                        Text("No Vehicle Selected").tag(Optional<VehicleEntity>.none)
                        ForEach(coordinator.vehicles) { vehicle in
                            Text(coordinator.getVehicleDisplayName(vehicle))
                                .tag(Optional<VehicleEntity>.some(vehicle))
                        }
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !description.isEmpty && selectedVehicle != nil
    }
    
    private func saveReminder() {
        guard let vehicle = selectedVehicle else { return }
        
        coordinator.createReminder(
            vehicle: vehicle,
            title: title,
            description: description,
            dueDate: dueDate,
            type: reminderType,
            isUrgent: isUrgent
        )
        
        dismiss()
    }
}

// Smart Reminders View - Shows AI-powered maintenance suggestions
struct SmartRemindersView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var smartReminders: [SmartReminder] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Maintenance Suggestions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Based on your vehicle's age, mileage, and service history")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Smart Reminders
                ForEach(smartReminders) { reminder in
                    SmartReminderCard(reminder: reminder)
                }
                
                // Maintenance Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Maintenance Tips")
                        .font(.headline)
                    
                    ForEach(maintenanceTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 16, height: 16)
                            
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .onAppear {
            generateSmartReminders()
        }
    }
    
    private func generateSmartReminders() {
        guard let vehicle = coordinator.selectedVehicle else { return }
        
        var suggestions: [SmartReminder] = []
        
        // Generate suggestions based on vehicle age and mileage
        let currentYear = Calendar.current.component(.year, from: Date())
        let vehicleAge = currentYear - vehicle.year
        
        if vehicle.mileage > 60000 {
            suggestions.append(SmartReminder(
                title: "High Mileage Service",
                description: "Your vehicle has high mileage. Consider a comprehensive service including cambelt and fluid changes.",
                priority: .high
            ))
        }
        
        if vehicleAge > 5 {
            suggestions.append(SmartReminder(
                title: "Brake System Check",
                description: "Vehicles over 5 years old should have brake systems inspected annually.",
                priority: .medium
            ))
        }
        
        if vehicle.fuelTypeEnum == .electric {
            suggestions.append(SmartReminder(
                title: "Battery Health Check",
                description: "Electric vehicle batteries benefit from regular health monitoring.",
                priority: .medium
            ))
        }
        
        smartReminders = suggestions
    }
    
    private let maintenanceTips = [
        "Check tyre pressure monthly for better fuel efficiency",
        "Replace air filter every 12,000 miles or annually",
        "Keep up with regular oil changes to extend engine life",
        "Electric vehicles need less maintenance but still require regular checks",
        "Book your MOT test a month before expiry to avoid issues"
    ]
}

struct SmartReminder: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct SmartReminderCard: View {
    let reminder: SmartReminder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(reminder.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reminder.priority.color.opacity(0.2))
                    .foregroundColor(reminder.priority.color)
                    .cornerRadius(6)
            }
            
            Text(reminder.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                
                Button("Book Service") {
                    // Navigate to booking with this service pre-selected
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("BVMOrange"))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RemindersView()
        .environmentObject(AppCoordinator.shared)
}