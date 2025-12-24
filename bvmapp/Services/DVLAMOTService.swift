//
//  DVLAMOTService.swift
//  bvmapp
//
//  Created by Peter Harding on 06/07/2025.
//

import Foundation
import Combine

// MARK: - DVLA MOT API Service

@MainActor
class DVLAMOTService: ObservableObject {
    private let apiBaseURL = "https://history.mot.api.gov.uk/v1/trade/vehicles/registration"
    private let tokenURL = "https://login.microsoftonline.com/a455b827-244f-4c97-b5b4-ce5d13b4d00c/oauth2/v2.0/token"
    private let scope = "https://tapi.dvsa.gov.uk/.default"
    
    private let clientID: String
    private let clientSecret: String
    private let apiKey: String
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var accessToken: String?
    private var tokenExpiryDate: Date?
    
    init(clientID: String, clientSecret: String, apiKey: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    func checkMOTStatus(for registration: String) async -> Result<MOTData, MOTError> {
        isLoading = true
        lastError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            // Ensure we have a valid access token
            try await ensureValidAccessToken()
            
            let motData = try await fetchMOTData(registration: registration)
            return .success(motData)
        } catch let error as MOTError {
            lastError = error.localizedDescription
            return .failure(error)
        } catch {
            let motError = MOTError.networkError(error.localizedDescription)
            lastError = motError.localizedDescription
            return .failure(motError)
        }
    }
    
    // MARK: - Private Methods
    
    private func ensureValidAccessToken() async throws {
        // Check if we have a valid token
        if let token = accessToken,
           let expiryDate = tokenExpiryDate,
           expiryDate > Date().addingTimeInterval(300) { // 5 minutes buffer
            return
        }
        
        // Get new access token
        try await getAccessToken()
    }
    
    private func getAccessToken() async throws {
        guard let url = URL(string: tokenURL) else {
            throw MOTError.authenticationError("Invalid token URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "client_credentials",
            "client_id": clientID,
            "client_secret": clientSecret,
            "scope": scope
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MOTError.authenticationError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MOTError.authenticationError("Authentication failed: HTTP \(httpResponse.statusCode)")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        accessToken = tokenResponse.accessToken
        tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    }
    
    private func fetchMOTData(registration: String) async throws -> MOTData {
        let cleanRegistration = registration.replacingOccurrences(of: " ", with: "").uppercased()
        
        guard let url = URL(string: "\(apiBaseURL)/\(cleanRegistration)") else {
            throw MOTError.invalidRegistration
        }
        
        guard let token = accessToken else {
            throw MOTError.authenticationError("No access token available")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MOTError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try decodeMOTResponse(data)
        case 404:
            throw MOTError.vehicleNotFound
        case 422:
            throw MOTError.invalidRegistration
        case 429:
            throw MOTError.rateLimitExceeded
        case 500...599:
            throw MOTError.serverError
        default:
            throw MOTError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func decodeMOTResponse(_ data: Data) throws -> MOTData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as VehicleWithMotResponse first
            if let vehicle = try? decoder.decode(MOTAPIResponse.self, from: data) {
                return MOTData(
                    registration: vehicle.registration ?? "",
                    make: vehicle.make,
                    model: vehicle.model,
                    primaryColour: vehicle.primaryColour,
                    manufactureYear: vehicle.manufactureYear,
                    engineSize: vehicle.engineSize,
                    fuelType: vehicle.fuelType,
                    motStatus: determineMOTStatus(from: vehicle.motTests),
                    motExpiryDate: getLatestMOTExpiryDate(from: vehicle.motTests),
                    latestMOTTest: getLatestMOTTest(from: vehicle.motTests),
                    motHistory: vehicle.motTests?.compactMap { convertToMOTTest($0) } ?? []
                )
            }
            
            // Try to decode as NewRegVehicleResponse for new vehicles
            if let newVehicle = try? decoder.decode(NewRegVehicleResponse.self, from: data) {
                return MOTData(
                    registration: newVehicle.registration ?? "",
                    make: newVehicle.make,
                    model: newVehicle.model,
                    primaryColour: newVehicle.primaryColour,
                    manufactureYear: Int(newVehicle.manufactureYear ?? "0"),
                    engineSize: nil,
                    fuelType: newVehicle.fuelType,
                    motStatus: newVehicle.motTestDueDate != nil ? .valid : .unknown,
                    motExpiryDate: parseDate(newVehicle.motTestDueDate),
                    latestMOTTest: nil,
                    motHistory: []
                )
            }
            
            throw MOTError.invalidResponse
        } catch {
            throw MOTError.invalidResponse
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func determineMOTStatus(from motTests: [MOTTestAPIResponse]?) -> MOTStatus {
        guard let tests = motTests, !tests.isEmpty else {
            return .unknown
        }
        
        let latestTest = tests.first // API returns most recent first
        
        guard let expiryDate = latestTest?.expiryDate else {
            return .unknown
        }
        
        let calendar = Calendar.current
        let today = Date()
        let daysUntilExpiry = calendar.dateComponents([.day], from: today, to: expiryDate).day ?? 0
        
        if daysUntilExpiry < 0 {
            return .expired
        } else if daysUntilExpiry <= 14 {
            return .dueSoon
        } else {
            return .valid
        }
    }
    
    private func getLatestMOTExpiryDate(from motTests: [MOTTestAPIResponse]?) -> Date? {
        return motTests?.first?.expiryDate
    }
    
    private func getLatestMOTTest(from motTests: [MOTTestAPIResponse]?) -> MOTTest? {
        guard let latestTest = motTests?.first else { return nil }
        return convertToMOTTest(latestTest)
    }
    
    private func convertToMOTTest(_ apiTest: MOTTestAPIResponse) -> MOTTest? {
        guard let testResult = apiTest.testResult else { return nil }
        
        return MOTTest(
            completedDate: apiTest.completedDate,
            testResult: testResult,
            expiryDate: apiTest.expiryDate,
            odometerValue: apiTest.odometerValue,
            odometerUnit: apiTest.odometerUnit,
            motTestNumber: apiTest.motTestNumber,
            defects: apiTest.rfrAndComments?.map { defect in
                MOTDefect(
                    text: defect.text,
                    type: defect.type,
                    dangerous: defect.dangerous
                )
            } ?? []
        )
    }
}

// MARK: - Data Models

struct MOTData {
    let registration: String
    let make: String?
    let model: String?
    let primaryColour: String?
    let manufactureYear: Int?
    let engineSize: Int?
    let fuelType: String?
    let motStatus: MOTStatus
    let motExpiryDate: Date?
    let latestMOTTest: MOTTest?
    let motHistory: [MOTTest]
}

struct MOTTest {
    let completedDate: Date?
    let testResult: String
    let expiryDate: Date?
    let odometerValue: Int?
    let odometerUnit: String?
    let motTestNumber: String?
    let defects: [MOTDefect]
}

struct MOTDefect {
    let text: String?
    let type: String?
    let dangerous: Bool?
}

// MARK: - Authentication Models

private struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - API Response Models

private struct MOTAPIResponse: Codable {
    let registration: String?
    let make: String?
    let model: String?
    let primaryColour: String?
    let manufactureYear: Int?
    let engineSize: Int?
    let fuelType: String?
    let motTests: [MOTTestAPIResponse]?
    let hasOutstandingRecall: String?
}

private struct NewRegVehicleResponse: Codable {
    let registration: String?
    let make: String?
    let model: String?
    let manufactureYear: String?
    let fuelType: String?
    let primaryColour: String?
    let registrationDate: String?
    let manufactureDate: String?
    let motTestDueDate: String?
    let hasOutstandingRecall: String
}

private struct MOTTestAPIResponse: Codable {
    let completedDate: Date?
    let testResult: String?
    let expiryDate: Date?
    let odometerValue: Int?
    let odometerUnit: String?
    let motTestNumber: String?
    let rfrAndComments: [MOTDefectAPIResponse]?
}

private struct MOTDefectAPIResponse: Codable {
    let text: String?
    let type: String?
    let dangerous: Bool?
}

// MARK: - Error Types

enum MOTError: LocalizedError, Equatable {
    case invalidRegistration
    case vehicleNotFound
    case noDataAvailable
    case networkError(String)
    case invalidResponse
    case rateLimitExceeded
    case serverError
    case authenticationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRegistration:
            return "Invalid vehicle registration number"
        case .vehicleNotFound:
            return "Vehicle not found in DVLA records"
        case .noDataAvailable:
            return "No MOT data available for this vehicle"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from DVLA service"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .serverError:
            return "DVLA service temporarily unavailable"
        case .authenticationError(let message):
            return "Authentication failed: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidRegistration:
            return "Please check the registration number and try again"
        case .vehicleNotFound:
            return "Ensure the registration is correct and the vehicle is registered in the UK"
        case .noDataAvailable:
            return "This vehicle may not require MOT testing or data may not be available"
        case .networkError:
            return "Check your internet connection and try again"
        case .invalidResponse:
            return "Please try again later"
        case .rateLimitExceeded:
            return "Wait a few minutes before checking again"
        case .serverError:
            return "The DVLA service is temporarily unavailable. Please try again later"
        case .authenticationError:
            return "Please check your API credentials and try again"
        }
    }
}