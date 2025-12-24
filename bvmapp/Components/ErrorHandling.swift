//
//  ErrorHandling.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

// MARK: - Error Banner Component

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

// MARK: - Success Banner Component

struct SuccessBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.green)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

// MARK: - Loading Overlay Component

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// MARK: - Confirmation Dialog Component

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmText: String
    let cancelText: String
    let isDestructive: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(title: String, message: String, confirmText: String = "Confirm", 
         cancelText: String = "Cancel", isDestructive: Bool = false,
         onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button(cancelText) {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                Button(confirmText) {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDestructive ? Color.red : Color("BVMOrange"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

// MARK: - Form Validation Helper

struct ValidationError: Identifiable, Equatable {
    let id = UUID()
    let field: String
    let message: String
}

class FormValidator: ObservableObject {
    @Published var errors: [ValidationError] = []
    
    func clearErrors() {
        errors.removeAll()
    }
    
    func addError(field: String, message: String) {
        // Remove existing error for this field
        errors.removeAll { $0.field == field }
        
        // Add new error
        errors.append(ValidationError(field: field, message: message))
    }
    
    func removeError(field: String) {
        errors.removeAll { $0.field == field }
    }
    
    func hasError(for field: String) -> Bool {
        return errors.contains { $0.field == field }
    }
    
    func getError(for field: String) -> String? {
        return errors.first { $0.field == field }?.message
    }
    
    var isValid: Bool {
        return errors.isEmpty
    }
    
    // MARK: - Common Validations
    
    func validateRequired(_ value: String, field: String, fieldName: String) {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addError(field: field, message: "\(fieldName) is required")
        } else {
            removeError(field: field)
        }
    }
    
    func validateEmail(_ email: String, field: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            addError(field: field, message: "Email is required")
            return
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            addError(field: field, message: "Please enter a valid email address")
        } else {
            removeError(field: field)
        }
    }
    
    func validateYear(_ year: Int, field: String) {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        if year < 1900 || year > currentYear + 1 {
            addError(field: field, message: "Year must be between 1900 and \(currentYear + 1)")
        } else {
            removeError(field: field)
        }
    }
    
    func validateMileage(_ mileage: String, field: String) {
        guard let mileageInt = Int(mileage), mileageInt >= 0, mileageInt <= 999999 else {
            addError(field: field, message: "Mileage must be between 0 and 999,999")
            return
        }
        removeError(field: field)
    }
    
    func validateRegistration(_ registration: String, field: String) {
        let trimmed = registration.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            addError(field: field, message: "Registration is required")
            return
        }
        
        if trimmed.count < 2 || trimmed.count > 10 {
            addError(field: field, message: "Registration must be 2-10 characters")
            return
        }
        
        removeError(field: field)
    }
    
    func validateFutureDate(_ date: Date, field: String, fieldName: String) {
        if date < Date() {
            addError(field: field, message: "\(fieldName) cannot be in the past")
        } else {
            removeError(field: field)
        }
    }
}

// MARK: - Error-Aware Form Field Components

struct ValidatedTextField: View {
    let title: String
    let field: String
    @Binding var text: String
    @ObservedObject var validator: FormValidator
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let validation: (String) -> Void
    
    init(title: String, field: String, text: Binding<String>, validator: FormValidator,
         keyboardType: UIKeyboardType = .default, 
         autocapitalization: TextInputAutocapitalization = .sentences,
         validation: @escaping (String) -> Void) {
        self.title = title
        self.field = field
        self._text = text
        self.validator = validator
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.validation = validation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(validator.hasError(for: field) ? Color.red : Color.clear, lineWidth: 1)
                )
                .onChange(of: text) { _, newValue in
                    validation(newValue)
                }
            
            if let error = validator.getError(for: field) {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - App-wide Error Handler View Modifier

struct ErrorHandlerViewModifier: ViewModifier {
    @EnvironmentObject var coordinator: AppCoordinator
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let errorMessage = coordinator.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        coordinator.clearMessages()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
                
                if let successMessage = coordinator.successMessage {
                    SuccessBanner(message: successMessage) {
                        coordinator.clearMessages()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
                
                Spacer()
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: coordinator.errorMessage)
            .animation(.easeInOut(duration: 0.3), value: coordinator.successMessage)
            
            if coordinator.isLoading {
                LoadingOverlay(message: "Loading...")
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
    }
}

extension View {
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlerViewModifier())
    }
}

// MARK: - Retry Button Component

struct RetryButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                
                Text(isLoading ? "Retrying..." : "Retry")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color("BVMOrange"))
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Empty State Component

struct EmptyStateView: View {
    let title: String
    let description: String
    let iconName: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, description: String, iconName: String, 
         actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("BVMOrange"))
                    .cornerRadius(8)
            }
        }
        .padding(40)
    }
}