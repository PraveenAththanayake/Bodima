import SwiftUI
import UIKit
import Foundation

struct MyHabitationDetailView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var navigateBack = false
    
    // Editable fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var selectedType: HabitationType = .singleRoom
    
    @StateObject private var habitationViewModel = HabitationViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    private var fullAddress: String {
        guard let location = locationData else { 
            if let user = habitation.user {
                return "\(user.phoneNumber)" 
            } else {
                return "Unknown location"
            }
        }
        return "\(location.addressNo), \(location.addressLine01), \(location.city), \(location.district)"
    }
    
    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: habitation.createdAt) else { return "now" }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "now"
        }
    }
    
    private var userInitials: String {
        if let user = habitation.user {
            return String(user.firstName.prefix(1)) + String(user.lastName.prefix(1))
        } else {
            return "?"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    
                    if isEditing {
                        editFormView
                            .padding(.horizontal, 16)
                    } else {
                        contentCard
                            .padding(.horizontal, 16)
                        
                        if featureData != nil {
                            amenitiesSection
                                .padding(.horizontal, 16)
                        }
                        
                        pricingSection
                            .padding(.horizontal, 16)
                    }
                    
                    actionButtonsSection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .onChange(of: habitationViewModel.habitationCreationSuccess) { success in
                if success {
                    isEditing = false
                }
            }
            .onChange(of: navigateBack) { goBack in
                if goBack {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Habitation"),
                    message: Text("Are you sure you want to delete this habitation? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteHabitation()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                // Initialize editable fields with current values
                name = habitation.name
                description = habitation.description
                price = String(habitation.price)
                if let type = HabitationType(rawValue: habitation.type) {
                    selectedType = type
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bodima")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.foreground)
                
                Text("My Habitation")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(AppColors.input)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            habitationImageView
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(habitation.name)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Text(habitation.type.capitalized)
                        .font(.caption)
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        )
                }
                
                Text(habitation.description)
                    .font(.body)
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(5)
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text(fullAddress)
                        .font(.caption)
                        .foregroundColor(AppColors.mutedForeground)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Created \(formattedTime) ago")
                        .font(.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var habitationImageView: some View {
        Group {
            if let pictures = habitation.pictures, !pictures.isEmpty, let firstPicture = pictures.first {
                CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.input)
                        .frame(width: 350, height: 280)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .frame(width: 350, height: 280)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(width: 350, height: 280)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(AppColors.mutedForeground)
                    )
            }
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amenities")
                .font(.headline)
                .foregroundColor(AppColors.foreground)
            
            if let feature = featureData {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MyAmenityView(icon: "bed.double", text: "\(feature.smallBedCount) Small Beds\n\(feature.largeBedCount) Large Beds")
                    MyAmenityView(icon: "chair", text: "\(feature.chairCount) Chairs\n\(feature.tableCount) Tables")
                    MyAmenityView(icon: "window.vertical", text: "\(feature.windowsCount) Windows")
                    MyAmenityView(icon: "square.and.arrow.up.on.square", text: "\(feature.sqft) sqft")
                    MyAmenityView(icon: "person.2", text: "\(feature.familyType)")
                    MyAmenityView(icon: "bolt", text: feature.isElectricityAvailable ? "Electricity Available" : "No Electricity")
                    MyAmenityView(icon: "drop", text: feature.isWaterAvailable ? "Water Available" : "No Water")
                    MyAmenityView(icon: "washer", text: feature.isWachineMachineAvailable ? "Washing Machine" : "No Washing Machine")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.headline)
                .foregroundColor(AppColors.foreground)
            
            HStack(alignment: .center) {
                Text("Rs. \(habitation.price)")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.foreground)
                
                Text("/ month")
                    .font(.subheadline)
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
                
                Text(habitation.isReserved ? "Reserved" : "Available")
                    .font(.caption.bold())
                    .foregroundColor(habitation.isReserved ? .white : AppColors.foreground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(habitation.isReserved ? AppColors.primary : AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(habitation.isReserved ? AppColors.primary : AppColors.border, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var editFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Habitation")
                .font(.headline)
                .foregroundColor(AppColors.foreground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(AppColors.foreground)
                
                TextField("Habitation name", text: $name)
                    .padding()
                    .background(AppColors.input)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(AppColors.foreground)
                
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(AppColors.input)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Type")
                    .font(.subheadline)
                    .foregroundColor(AppColors.foreground)
                
                Picker("Type", selection: $selectedType) {
                    ForEach(HabitationType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(AppColors.input)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Price (Rs.)")
                    .font(.subheadline)
                    .foregroundColor(AppColors.foreground)
                
                TextField("Price", text: $price)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(AppColors.input)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isEditing {
                Button(action: saveChanges) {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .disabled(habitationViewModel.isLoading)
                
                Button(action: { isEditing = false }) {
                    HStack {
                        Spacer()
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.input)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .disabled(habitationViewModel.isLoading)
            } else {
                Button(action: { isEditing = true }) {
                    HStack {
                        Spacer()
                        Text("Edit Habitation")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                
                Button(action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Spacer()
                        Text("Delete Habitation")
                            .font(.headline)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.input)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let priceInt = Int(price) else {
            // Show error for invalid price
            return
        }
        
        habitationViewModel.updateHabitation(
            habitationId: habitation.id,
            name: name,
            description: description,
            type: selectedType,
            isReserved: habitation.isReserved,
            price: priceInt
        )
    }
    
    private func deleteHabitation() {
        habitationViewModel.deleteHabitation(habitationId: habitation.id)
        
        // Add a slight delay before navigating back to allow the delete operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateBack = true
        }
    }
}

// Reuse AmenityView from DetailView
struct MyAmenityView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.mutedForeground)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.foreground)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
}