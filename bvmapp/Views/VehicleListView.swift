//
//  VehicleListView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

struct VehicleListView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingAddVehicle = false
    @State private var selectedVehicle: VehicleEntity?
    @State private var showingDeleteConfirmation = false
    @State private var vehicleToDelete: VehicleEntity?
    
    var body: some View {
        NavigationView {
            Group {
                if coordinator.vehicles.isEmpty {
                    EmptyStateView(
                        title: "No Vehicles Added",
                        description: "Add your first vehicle to start tracking services and reminders",
                        iconName: "car.fill",
                        actionTitle: "Add Vehicle"
                    ) {
                        showingAddVehicle = true
                    }
                } else {
                    List {
                        ForEach(coordinator.vehicles) { vehicle in
                            VehicleRow(vehicle: vehicle)
                                .onTapGesture {
                                    coordinator.selectVehicle(vehicle)
                                    selectedVehicle = vehicle
                                }
                        }
                        .onDelete(perform: deleteVehicles)
                    }
                    .refreshable {
                        await coordinator.refreshData()
                    }
                }
            }
            .navigationTitle("My Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVehicle = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(coordinator.isLoading)
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .sheet(item: $selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle)
            }
            .overlay {
                if showingDeleteConfirmation, let vehicle = vehicleToDelete {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingDeleteConfirmation = false
                            vehicleToDelete = nil
                        }
                    
                    ConfirmationDialog(
                        title: "Delete Vehicle",
                        message: "Are you sure you want to delete \(coordinator.getVehicleDisplayName(vehicle))? This will also delete all associated bookings and reminders.",
                        confirmText: "Delete",
                        isDestructive: true,
                        onConfirm: {
                            confirmDelete()
                        },
                        onCancel: {
                            showingDeleteConfirmation = false
                            vehicleToDelete = nil
                        }
                    )
                }
            }
        }
    }
    
    private func deleteVehicles(offsets: IndexSet) {
        for index in offsets {
            vehicleToDelete = coordinator.vehicles[index]
            showingDeleteConfirmation = true
            break // Only handle one deletion at a time for better UX
        }
    }
    
    private func confirmDelete() {
        guard let vehicle = vehicleToDelete else {
            return
        }
        
        coordinator.deleteVehicle(vehicle)
        showingDeleteConfirmation = false
        vehicleToDelete = nil
    }
}

struct VehicleRow: View {
    let vehicle: VehicleEntity
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(coordinator.getVehicleDisplayName(vehicle))
                    .font(.headline)
                
                Text(vehicle.registration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label(vehicle.fuelTypeEnum.rawValue, systemImage: vehicle.fuelTypeEnum.icon)
                        .font(.caption)
                        .foregroundColor(vehicle.fuelTypeEnum.color)
                    
                    Label("\(vehicle.mileage) miles", systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(coordinator.getServiceStatus(for: vehicle).color)
                        .frame(width: 8, height: 8)
                    
                    Text("Service")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(coordinator.getMOTStatus(for: vehicle).color)
                        .frame(width: 8, height: 8)
                    
                    Text("MOT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        Task {
                            await coordinator.checkMOTStatus(for: vehicle)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundColor(Color("BVMOrange"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var validator = FormValidator()
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var registration = ""
    @State private var mileage = ""
    @State private var fuelType = FuelType.petrol
    @State private var color = ""
    
    // Smart lookup states
    @State private var isLookingUp = false
    @State private var hasLookedUp = false
    @State private var lookupError: String?
    @State private var isManualEntry = false
    
    var body: some View {
        NavigationView {
            Form {
                // Smart Registration Lookup Section
                Section {
                    HStack {
                        ValidatedTextField(
                            title: "Registration Number",
                            field: "registration",
                            text: $registration,
                            validator: validator,
                            autocapitalization: .characters
                        ) { value in
                            validator.validateRegistration(value, field: "registration")
                        }
                        
                        if !registration.isEmpty && !hasLookedUp {
                            Button(action: lookupVehicle) {
                                if isLookingUp {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .foregroundColor(Color("BVMOrange"))
                                }
                            }
                            .disabled(isLookingUp || registration.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    if let error = lookupError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if hasLookedUp {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Vehicle details fetched from MOT database")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Button("Manual Entry") {
                                isManualEntry = true
                                hasLookedUp = false
                                clearFields()
                            }
                            .font(.caption)
                            .foregroundColor(Color("BVMOrange"))
                        }
                    }
                } header: {
                    Text("Start by entering your registration number")
                } footer: {
                    if !hasLookedUp && !isManualEntry {
                        Text("We'll automatically fetch your vehicle details from the MOT database")
                    }
                }
                
                // Vehicle Details Section (shown after lookup or manual entry)
                if hasLookedUp || isManualEntry {
                    Section(header: Text("Vehicle Details")) {
                        ValidatedTextField(
                            title: "Make",
                            field: "make",
                            text: $make,
                            validator: validator
                        ) { value in
                            validator.validateRequired(value, field: "make", fieldName: "Make")
                        }
                        
                        ValidatedTextField(
                            title: "Model",
                            field: "model",
                            text: $model,
                            validator: validator
                        ) { value in
                            validator.validateRequired(value, field: "model", fieldName: "Model")
                        }
                        
                        Picker("Year", selection: $year) {
                            ForEach(1990...Calendar.current.component(.year, from: Date()) + 1, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .onChange(of: year) { _, newValue in
                            validator.validateYear(newValue, field: "year")
                        }
                        
                        ValidatedTextField(
                            title: "Mileage",
                            field: "mileage",
                            text: $mileage,
                            validator: validator,
                            keyboardType: .numberPad
                        ) { value in
                            validator.validateMileage(value, field: "mileage")
                        }
                        
                        Picker("Fuel Type", selection: $fuelType) {
                            ForEach(FuelType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        
                        ValidatedTextField(
                            title: "Color",
                            field: "color",
                            text: $color,
                            validator: validator
                        ) { value in
                            validator.validateRequired(value, field: "color", fieldName: "Color")
                        }
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!canSave || coordinator.isLoading)
                }
            }
            .onAppear {
                validateAll()
            }
        }
    }
    
    private var canSave: Bool {
        // Can save if we have looked up data or manually entered data
        let hasRequiredFields = !make.isEmpty && !model.isEmpty && !registration.isEmpty && 
                               !mileage.isEmpty && !color.isEmpty
        
        let isReadyToSave = (hasLookedUp || isManualEntry) && hasRequiredFields && 
                           !isLookingUp && validator.isValid
        
        return isReadyToSave
    }
    
    private func validateAll() {
        validator.validateRequired(make, field: "make", fieldName: "Make")
        validator.validateRequired(model, field: "model", fieldName: "Model")
        validator.validateYear(year, field: "year")
        validator.validateRegistration(registration, field: "registration")
        validator.validateMileage(mileage, field: "mileage")
        validator.validateRequired(color, field: "color", fieldName: "Color")
    }
    
    private func saveVehicle() {
        validateAll()
        
        guard validator.isValid,
              let mileageInt = Int(mileage) else { return }
        
        coordinator.createVehicle(
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileageInt,
            fuelType: fuelType,
            color: color
        )
        
        // Only dismiss if no error occurred
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if coordinator.errorMessage == nil {
                dismiss()
            }
        }
    }
    
    // MARK: - Smart Lookup Functions
    
    private func lookupVehicle() {
        guard !registration.isEmpty else { return }
        
        isLookingUp = true
        lookupError = nil
        
        Task {
            let result = await coordinator.motService.checkMOTStatus(for: registration)
            
            await MainActor.run {
                isLookingUp = false
                
                switch result {
                case .success(let motData):
                    populateFromMOTData(motData)
                    hasLookedUp = true
                    lookupError = nil
                case .failure(let error):
                    handleLookupError(error)
                }
            }
        }
    }
    
    private func populateFromMOTData(_ motData: MOTData) {
        // Populate basic vehicle info
        if let make = motData.make, !make.isEmpty {
            self.make = make
        }
        
        if let model = motData.model, !model.isEmpty {
            self.model = model
        }
        
        if let manufactureYear = motData.manufactureYear {
            self.year = manufactureYear
        }
        
        if let fuelTypeString = motData.fuelType, !fuelTypeString.isEmpty {
            // Map fuel type string to enum
            switch fuelTypeString.lowercased() {
            case "petrol":
                self.fuelType = .petrol
            case "diesel":
                self.fuelType = .diesel
            case "electric":
                self.fuelType = .electric
            case "hybrid":
                self.fuelType = .hybrid
            default:
                self.fuelType = .petrol // Default fallback
            }
        }
        
        if let color = motData.primaryColour, !color.isEmpty {
            self.color = color
        }
        
        // Set a default mileage if we don't have one
        if mileage.isEmpty {
            // Try to get mileage from latest MOT test
            if let latestTest = motData.latestMOTTest,
               let odometerValue = latestTest.odometerValue {
                self.mileage = String(odometerValue)
            } else {
                // Default to a reasonable estimate based on vehicle age
                let currentYear = Calendar.current.component(.year, from: Date())
                let vehicleAge = currentYear - year
                let estimatedMileage = max(0, vehicleAge * 10000) // 10k miles per year estimate
                self.mileage = String(estimatedMileage)
            }
        }
        
        // Validate all fields after population
        validateAll()
    }
    
    private func handleLookupError(_ error: MOTError) {
        switch error {
        case .vehicleNotFound:
            lookupError = "Vehicle not found. This might be a new vehicle or the registration may be incorrect."
            // Offer manual entry for new vehicles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isManualEntry = true
            }
        case .invalidRegistration:
            lookupError = "Please check the registration number format."
        case .networkError:
            lookupError = "Network error. Please check your connection and try again."
        case .authenticationError:
            lookupError = "Service temporarily unavailable. Please try manual entry."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isManualEntry = true
            }
        default:
            lookupError = "Unable to fetch vehicle details. Please try manual entry."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isManualEntry = true
            }
        }
    }
    
    private func clearFields() {
        make = ""
        model = ""
        year = Calendar.current.component(.year, from: Date())
        mileage = ""
        fuelType = .petrol
        color = ""
        lookupError = nil
    }
}

struct VehicleDetailView: View {
    let vehicle: VehicleEntity
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Vehicle Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(coordinator.getVehicleDisplayName(vehicle))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(vehicle.registration)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Vehicle Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Color", value: vehicle.color)
                        DetailRow(title: "Fuel Type", value: vehicle.fuelTypeEnum.rawValue)
                        DetailRow(title: "Mileage", value: "\(vehicle.mileage) miles")
                        
                        if let lastService = vehicle.lastServiceDate {
                            DetailRow(title: "Last Service", value: lastService.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        if let nextService = vehicle.nextServiceDue {
                            DetailRow(title: "Next Service Due", value: nextService.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        if let motDue = vehicle.motDue {
                            DetailRow(title: "MOT Due", value: motDue.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Status Overview
                    HStack(spacing: 16) {
                        StatusCard(
                            title: "Service Status",
                            status: coordinator.getServiceStatus(for: vehicle).displayText,
                            color: coordinator.getServiceStatus(for: vehicle).color
                        )
                        
                        StatusCard(
                            title: "MOT Status",
                            status: coordinator.getMOTStatus(for: vehicle).displayText,
                            color: coordinator.getMOTStatus(for: vehicle).color
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Vehicle Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditVehicleView(vehicle: vehicle)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct StatusCard: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(status)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EditVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    
    let vehicle: VehicleEntity
    
    @State private var make: String
    @State private var model: String
    @State private var year: Int
    @State private var registration: String
    @State private var mileage: String
    @State private var fuelType: FuelType
    @State private var color: String
    
    init(vehicle: VehicleEntity) {
        self.vehicle = vehicle
        self._make = State(initialValue: vehicle.make)
        self._model = State(initialValue: vehicle.model)
        self._year = State(initialValue: vehicle.year)
        self._registration = State(initialValue: vehicle.registration)
        self._mileage = State(initialValue: String(vehicle.mileage))
        self._fuelType = State(initialValue: vehicle.fuelTypeEnum)
        self._color = State(initialValue: vehicle.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach(1990...Calendar.current.component(.year, from: Date()) + 1, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    
                    TextField("Registration", text: $registration)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                    
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    TextField("Color", text: $color)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !make.isEmpty && !model.isEmpty && !registration.isEmpty && !mileage.isEmpty && !color.isEmpty
    }
    
    private func saveChanges() {
        guard let mileageInt = Int(mileage) else { return }
        
        coordinator.updateVehicle(
            vehicle,
            make: make,
            model: model,
            year: year,
            registration: registration,
            mileage: mileageInt,
            fuelType: fuelType,
            color: color
        )
        
        dismiss()
    }
}

#Preview {
    VehicleListView()
        .environmentObject(AppCoordinator.shared)
}