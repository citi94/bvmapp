//
//  ContentView.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "checkmark.shield.fill")
                    Text("MOT Check")
                }
                .tag(0)
            
            VehicleListView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("My Vehicles")
                }
                .tag(1)
            
            ContactView()
                .tabItem {
                    Image(systemName: "phone.fill")
                    Text("Contact")
                }
                .tag(2)
            
            // Hidden tabs - keep for future use
            if false {
                ServiceBookingView()
                    .tabItem {
                        Image(systemName: "calendar.badge.plus")
                        Text("Book Service")
                    }
                    .tag(3)
                
                RemindersView()
                    .tabItem {
                        Image(systemName: "bell.fill")
                        Text("Reminders")
                    }
                    .tag(4)
            }
        }
        .accentColor(Color("BVMOrange"))
        .withErrorHandling()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator.shared)
}
