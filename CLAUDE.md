# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift iOS application built with SwiftUI using Xcode. The project is named "bvmapp" and follows standard iOS app architecture patterns.

## Development Commands

Since this is an Xcode project, development is primarily done through the Xcode IDE:

- **Build**: Use Xcode's build system (Cmd+B) - command line tools not sufficient
- **Run**: Use Xcode's run functionality (Cmd+R) with iOS Simulator
- **Test**: Run tests through Xcode (Cmd+U)
- **Note**: Full Xcode installation required for building iOS projects
- **Compilation Status**: ✅ App compiles successfully with zero errors/warnings
- **Development Status**: Comprehensive feature implementation with all views and models complete

### Command Line Development (Optimized Workflow)

For faster development iteration, you can use command line tools with full Xcode:

```bash
# Quick compilation check (iOS device build)
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project bvmapp.xcodeproj -scheme bvmapp -destination 'generic/platform=iOS' -configuration Debug build

# Build for specific simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project bvmapp.xcodeproj -scheme bvmapp -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -project bvmapp.xcodeproj -scheme bvmapp -destination 'platform=iOS Simulator,name=iPhone 16'

# List available simulators
xcrun simctl list devices

# Check project structure
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -list -project bvmapp.xcodeproj
```

**Note**: Ensure Xcode developer directory is set correctly: `xcode-select -p` should show `/Applications/Xcode.app/Contents/Developer`

## Architecture

- **App Entry Point**: `bvmapp/bvmappApp.swift` - Main app structure using SwiftUI's `@main` attribute
- **Main View**: `bvmapp/ContentView.swift` - Primary content view with basic SwiftUI layout
- **Test Structure**: 
  - `bvmappTests/` - Unit tests
  - `bvmappUITests/` - UI/Integration tests
- **Assets**: `bvmapp/Assets.xcassets/` - App icons, colors, and other visual assets

## Key Files

- `bvmapp.xcodeproj/` - Xcode project configuration
- `bvmapp/bvmappApp.swift` - App delegate and main entry point with environment objects
- `bvmapp/ContentView.swift` - Main TabView with 5 tabs (Dashboard, Vehicles, Booking, Reminders, Contact)
- `bvmapp/Models/` - Data models and managers
  - `DataModels.swift` - Core data structures (Vehicle, ServiceType, ServiceBooking, etc.)
  - `ServiceManager.swift` - Service and booking management logic
  - `VehicleManager.swift` - Vehicle management with status tracking
- `bvmapp/Views/` - SwiftUI view components
  - `DashboardView.swift` - Dashboard with vehicle status and quick actions
  - `VehicleListView.swift` - Vehicle CRUD operations with detailed views
  - `ServiceBookingView.swift` - Service booking with cost estimation
  - `RemindersView.swift` - Smart reminders with AI-powered suggestions
  - `ContactView.swift` - Contact information with MapKit integration
- `bvmapp/Assets.xcassets/` - App icons, colors (including BVMOrange brand color)

## App Architecture

This is a comprehensive customer-focused mobile app for BVM Deal with the following features:

### Core Functionality
- **Dashboard**: Overview of vehicle status, quick actions, upcoming bookings
- **Vehicle Management**: Add, edit, and track multiple vehicles with service history
- **Service Booking**: Book services with cost estimates and date selection
- **Smart Reminders**: AI-powered maintenance suggestions based on vehicle data
- **Contact Integration**: Direct calling, texting, WhatsApp, and maps integration

### Novel Customer Features
- **Intelligent Vehicle Lookup**: One-tap vehicle adding with auto-population from DVLA database
- **Smart Maintenance Tracker**: Analyzes vehicle age, mileage, and service history
- **Real MOT Integration**: Live MOT status checking with government data
- **Emergency Contact**: Quick access to urgent support
- **Location Services**: Integrated maps and directions to workshop
- **Service Status Tracking**: Visual indicators for MOT, service due dates
- **WhatsApp Integration**: Direct messaging for quick communication

### Technical Architecture
- **MVVM Pattern**: Uses `@StateObject` and `@EnvironmentObject` for data management
- **Data Managers**: `ServiceManager` and `VehicleManager` handle business logic
- **Custom Models**: Comprehensive data structures for vehicles, services, bookings, reminders
- **iPhone Optimized**: Responsive design with iOS-specific UI patterns
- **Brand Integration**: Custom BVMOrange color matching website branding

## Development Notes

- Built with SwiftUI and follows iOS Human Interface Guidelines
- Uses environment objects for state management across views
- Implements iOS-specific features like MapKit, URL schemes for calling/texting
- Custom color assets for brand consistency
- Modular view architecture for maintainability
- **iOS 17+ Compatible**: Uses modern MapKit APIs (Map with MapCameraPosition, Marker)
- **Type Safety**: All models conform to required protocols (Hashable, Codable, Identifiable)
- **Zero Compilation Issues**: App builds successfully without errors or warnings

## Recent Updates

### Latest Updates (July 2025):

**Smart Vehicle Management:**
1. **Intelligent Vehicle Adding**: Revolutionary one-tap vehicle lookup from DVLA MOT database
2. **Auto-Population**: Automatically fills make, model, year, fuel type, color, and mileage
3. **Fixed MOT API Integration**: Corrected endpoints and authentication for production use
4. **Enhanced UX**: Progressive form disclosure and graceful error handling

**DVLA MOT API (Fixed & Production-Ready):**
- **Correct API Endpoints**: Updated to use `history.mot.api.gov.uk` (official MOT History API)
- **Dual Authentication**: Bearer token + X-API-Key header as per specification
- **Smart Error Handling**: Handles new vehicles, network errors, and invalid registrations
- **Real-time Vehicle Data**: Fetches official make, model, year, fuel type, color, and mileage
- **OAuth2 + API Key**: Full compliance with government API requirements

**User Experience Improvements:**
1. **One-Step Vehicle Adding**: Enter registration → tap lookup → auto-filled form → save
2. **Intelligent Defaults**: Smart mileage estimation based on vehicle age and MOT data
3. **Fallback Options**: Manual entry mode when lookup fails
4. **Clear Feedback**: Loading states, success confirmations, helpful error messages

### Latest Compilation Fixes (December 2024):
1. **AdditionalCost Type Ambiguity**: Removed duplicate struct definition from ServiceBookingView.swift
2. **SwiftData Property Conflicts**: Renamed `description` properties in SwiftData models:
   - `ServiceTypeEntity.description` → `serviceDescription`
   - `ServiceReminderEntity.description` → `reminderDescription`
3. **Access Level Issues**: Updated DataStore properties from private to internal for extension access
4. **Missing Enum Cases**: Added missing status cases:
   - ServiceStatus: `.dueSoon`, `.upToDate`
   - MOTStatus: `.dueSoon`, `.expired`, `.valid`
5. **ContentView Structure**: Fixed missing closing brace in struct definition
6. **PerformanceOptimizations**: Fixed FetchDescriptor mutability (`let` → `var`)
7. **BackupService References**: Updated to use renamed description properties

### Previous Compilation Fixes:
1. **MapKit Modernization**: Updated from deprecated `MapAnnotation` to modern `Marker` API
2. **Type Conformance**: Added `Hashable` conformance to `Vehicle` struct
3. **Picker Optimization**: Fixed Optional Vehicle selection with explicit type annotations
4. **String Literal Cleanup**: Removed escape sequence errors throughout codebase
5. **Data Model Restructuring**: Converted tuple `priceRange` to individual `minPrice`/`maxPrice` properties

### App Features Verified:
- ✅ Tab-based navigation (5 tabs)
- ✅ **Intelligent vehicle adding** with DVLA MOT database lookup
- ✅ Vehicle management with CRUD operations
- ✅ Service booking (pricing removed for professional UI)
- ✅ **Working MOT API integration** with correct endpoints
- ✅ Smart reminders with AI-powered suggestions
- ✅ Contact integration (phone, SMS, WhatsApp, maps)
- ✅ Real-time status tracking (MOT, service due dates)
- ✅ Brand-consistent UI with BVMOrange color scheme

### Current Status (July 2025):
- **Build Status**: ✅ App compiles successfully with zero errors
- **API Status**: ✅ DVLA MOT API fully functional with correct endpoints
- **UX Status**: ✅ Intelligent vehicle adding dramatically improves user experience
- **Production Status**: ✅ Ready for deployment with working government API integration