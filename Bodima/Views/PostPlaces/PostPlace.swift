import SwiftUI
import MapKit
import CoreLocation
import PhotosUI
import FirebaseStorage

struct PostPlaceView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var habitationImageViewModel = HabitationImageViewModel()
    @StateObject private var habitationLocationViewModel = HabitationLocationViewModel()
    @StateObject private var habitationFeatureViewModel = HabitationFeatureViewModel()
    
    @State private var habitationName = ""
    @State private var habitationDescription = ""
    @State private var selectedHabitationType = HabitationType.singleRoom
    @State private var selectedImages: [UIImage] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isPhotoPickerPresented = false
    
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var locationDescription = "Tap to select location"
    @State private var showLocationPicker = false
    @State private var isLoadingLocation = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    
    @State private var addressNo = ""
    @State private var city = ""
    @State private var addressLine01 = ""
    @State private var addressLine02 = ""
    @State private var selectedDistrict = District.colombo
    
    @State private var sqft: Int = 0
    @State private var windowsCount: Int = 0
    @State private var selectedFamilyType = FamilyType.oneStory
    @State private var smallBedCount: Int = 0
    @State private var largeBedCount: Int = 0
    @State private var chairCount: Int = 0
    @State private var tableCount: Int = 0
    
    @State private var isElectricityAvailable = false
    @State private var isWashingMachineAvailable = false
    @State private var isWaterAvailable = false
    
    @State private var monthlyRent: Int = 0
    @State private var isReserved = false
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    @State private var isUploadingImages = false
    @State private var uploadedImageUrls: [String] = []
    @State private var imageUploadProgress = 0.0
    
    @State private var creationStep = 0
    @State private var maxSteps = 4
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationPicker) {
                locationPickerSheet
            }
            .photosPicker(isPresented: $isPhotoPickerPresented,
                         selection: $selectedPhotoItems,
                         maxSelectionCount: 10,
                         matching: .images)
            .onChange(of: selectedPhotoItems) { items in
                Task {
                    await loadImages(from: items)
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showSuccessAlert = false
                    resetForm()
                }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {
                    showAlert = false
                }
            } message: {
                Text(alertMessage)
            }
            // FIXED: Better observation of state changes
            .onChange(of: habitationViewModel.habitationCreationSuccess) { success in
                if success {
                    // Small delay to ensure the createdHabitation is properly set
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        handleHabitationCreationSuccess()
                    }
                }
            }
            .onChange(of: habitationViewModel.habitationCreationMessage) { message in
                if let message = message, !habitationViewModel.habitationCreationSuccess {
                    showErrorAlert(message)
                }
            }
            .onChange(of: habitationLocationViewModel.locationCreationSuccess) { success in
                if success {
                    handleLocationCreationSuccess()
                }
            }
            .onChange(of: habitationLocationViewModel.locationCreationMessage) { message in
                if let message = message, !habitationLocationViewModel.locationCreationSuccess {
                    showErrorAlert(message)
                }
            }
            .onChange(of: habitationFeatureViewModel.featureCreationSuccess) { success in
                if success {
                    handleFeatureCreationSuccess()
                }
            }
            .onChange(of: habitationFeatureViewModel.featureCreationMessage) { message in
                if let message = message, !habitationFeatureViewModel.featureCreationSuccess {
                    showErrorAlert(message)
                }
            }
            .onChange(of: habitationImageViewModel.hasError) { hasError in
                if hasError, let errorMessage = habitationImageViewModel.errorMessage {
                    showErrorAlert(errorMessage)
                }
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            headerSection
            progressSection
            formSections
            uploadProgressSection
            submitSection
        }
        .padding(.bottom, 80)
    }

    private var headerSection: some View {
        HeaderWidget(
            title: "Bodima",
            subtitle: "Post Your Place",
            onBackAction: {}
        )
    }

    private var progressSection: some View {
        Group {
            if creationStep > 0 {
                VStack(spacing: 8) {
                    Text("Step \(creationStep) of \(maxSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(creationStep), total: Double(maxSteps))
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                }
                .padding()
                .background(AppColors.card)
                .cornerRadius(12)
            }
        }
    }

    private var formSections: some View {
        VStack(spacing: 16) {
            BasicInfoCardWidget(
                habitationName: $habitationName,
                habitationDescription: $habitationDescription,
                selectedHabitationType: $selectedHabitationType,
                selectedImages: $selectedImages,
                selectedPhotoItems: $selectedPhotoItems,
                isPhotoPickerPresented: $isPhotoPickerPresented
            )
            
            AddressInfoCardWidget(
                selectedLocation: $selectedLocation,
                locationDescription: $locationDescription,
                showLocationPicker: $showLocationPicker,
                isLoadingLocation: $isLoadingLocation,
                addressNo: $addressNo,
                city: $city,
                addressLine01: $addressLine01,
                addressLine02: $addressLine02,
                selectedDistrict: $selectedDistrict
            )
            
            PropertyDetailsCardWidget(
                sqft: $sqft,
                windowsCount: $windowsCount,
                selectedFamilyType: $selectedFamilyType,
                smallBedCount: $smallBedCount,
                largeBedCount: $largeBedCount,
                chairCount: $chairCount,
                tableCount: $tableCount
            )
            
            AmenitiesCardWidget(
                isElectricityAvailable: $isElectricityAvailable,
                isWashingMachineAvailable: $isWashingMachineAvailable,
                isWaterAvailable: $isWaterAvailable
            )
            
            PricingCardWidget(
                monthlyRent: $monthlyRent,
                isReserved: $isReserved
            )
        }
    }

    private var uploadProgressSection: some View {
        Group {
            if isUploadingImages {
                VStack(spacing: 8) {
                    Text("Uploading Images...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: imageUploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                }
                .padding()
                .background(AppColors.card)
                .cornerRadius(12)
            }
        }
    }

    private var submitSection: some View {
        SubmitButtonWidget(
            isLoading: isSubmitLoading,
            canSubmit: canSubmit,
            onSubmit: submitPost
        )
    }

    private var locationPickerSheet: some View {
        LocationPickerView(
            selectedLocation: $selectedLocation,
            locationDescription: $locationDescription,
            onLocationSelected: { location, description in
                updateLocationFields(location: location, description: description)
            }
        )
    }

    private var isSubmitLoading: Bool {
        isLoading ||
        habitationViewModel.isCreatingHabitation ||
        habitationLocationViewModel.isCreatingLocation ||
        habitationFeatureViewModel.isCreatingFeature ||
        isUploadingImages
    }
    
    private var canSubmit: Bool {
        !habitationName.isEmpty &&
        !habitationDescription.isEmpty &&
        selectedLocation != nil &&
        !addressNo.isEmpty &&
        !addressLine01.isEmpty &&
        !city.isEmpty &&
        sqft > 0 &&
        monthlyRent > 0 &&
        !habitationViewModel.isCreatingHabitation &&
        !habitationLocationViewModel.isCreatingLocation &&
        !habitationFeatureViewModel.isCreatingFeature &&
        !isUploadingImages
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                newImages.append(image)
            }
        }
        
        await MainActor.run {
            selectedImages.append(contentsOf: newImages)
            if selectedImages.count > 10 {
                selectedImages = Array(selectedImages.prefix(10))
            }
        }
    }
    
    private func updateLocationFields(location: CLLocationCoordinate2D, description: String) {
        selectedLocation = location
        latitude = location.latitude
        longitude = location.longitude
        locationDescription = description
    }
    
    private func submitPost() {
        guard canSubmit else {
            showErrorAlert("Please fill in all required fields")
            return
        }
        
        print("🔍 DEBUG - Starting submission process")
        isLoading = true
        creationStep = 1
        maxSteps = selectedImages.isEmpty ? 3 : 4
        
        if !selectedImages.isEmpty {
            uploadImages()
        } else {
            createHabitation()
        }
    }
    
    private func uploadImages() {
        print("🔍 DEBUG - Starting Firebase image upload")
        isUploadingImages = true
        imageUploadProgress = 0.0
        uploadedImageUrls.removeAll()
        
        let storageService = FirebaseStorageService.shared
        let storagePath = "habitation_images"
        
        storageService.uploadMultipleImages(
            selectedImages,
            folderPath: storagePath,
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.imageUploadProgress = progress
                    print("🔍 DEBUG - Firebase image upload progress: \(progress)")
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let urls):
                        self.uploadedImageUrls = urls
                        print("🔍 DEBUG - All images uploaded to Firebase, creating habitation")
                        print("🔍 DEBUG - Uploaded URLs: \(urls)")
                        self.isUploadingImages = false
                        self.createHabitation()
                        
                    case .failure(let error):
                        print("❌ ERROR - Failed to upload images: \(error.localizedDescription)")
                        self.showErrorAlert("Failed to upload images: \(error.localizedDescription)")
                        self.isUploadingImages = false
                        self.isLoading = false
                    }
                }
            }
        )
    }
    
    private func createHabitation() {
        print("🔍 DEBUG - Creating habitation with data:")
        print("  - Name: \(habitationName)")
        print("  - Description: \(habitationDescription)")
        print("  - Type: \(selectedHabitationType)")
        print("  - Reserved: \(isReserved)")
        
        creationStep = selectedImages.isEmpty ? 1 : 2
        
        habitationViewModel.createHabitationWithCurrentUser(
            name: habitationName,
            description: habitationDescription,
            type: selectedHabitationType,
            isReserved: isReserved,
            price: monthlyRent
        )
    }
    
    private func handleHabitationCreationSuccess() {
        print("🔍 DEBUG - Habitation creation success handler called")
        print("🔍 DEBUG - Created habitation: \(String(describing: habitationViewModel.createdHabitation))")
        
        guard let createdHabitation = habitationViewModel.createdHabitation else {
            print("❌ ERROR - Habitation was created but data is missing")
            showErrorAlert("Habitation was created but data is missing")
            return
        }
        
        print("✅ SUCCESS - Habitation created with ID: \(createdHabitation.id)")
        creationStep = selectedImages.isEmpty ? 2 : 3
        
        // Add a small delay to ensure the state is properly updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.createLocation(for: createdHabitation)
        }
    }
    
    private func createLocation(for habitation: HabitationData) {
        print("🔍 DEBUG - Creating location for habitation: \(habitation.id)")
        print("🔍 DEBUG - Location data:")
        print("  - Address No: \(addressNo)")
        print("  - Address Line 1: \(addressLine01)")
        print("  - Address Line 2: \(addressLine02)")
        print("  - City: \(city)")
        print("  - District: \(selectedDistrict.rawValue)")
        print("  - Latitude: \(latitude)")
        print("  - Longitude: \(longitude)")
        
        let nearestLat = latitude
        let nearestLng = longitude
        
        habitationLocationViewModel.createLocationForHabitation(
            habitation: habitation,
            addressNo: addressNo,
            addressLine01: addressLine01,
            addressLine02: addressLine02,
            city: city,
            district: selectedDistrict.rawValue,
            latitude: latitude,
            longitude: longitude,
            nearestHabitationLatitude: nearestLat,
            nearestHabitationLongitude: nearestLng
        )
    }
    
    private func handleLocationCreationSuccess() {
        print("🔍 DEBUG - Location creation success handler called")
        
        guard let createdHabitation = habitationViewModel.createdHabitation else {
            print("❌ ERROR - Location was created but habitation data is missing")
            showErrorAlert("Location was created but habitation data is missing")
            return
        }
        
        print("✅ SUCCESS - Location created for habitation: \(createdHabitation.id)")
        creationStep = selectedImages.isEmpty ? 3 : 4
        
        // Add a small delay to ensure the state is properly updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.createFeatures(for: createdHabitation)
        }
    }
    
    private func createFeatures(for habitation: HabitationData) {
        print("🔍 DEBUG - Creating features for habitation: \(habitation.id)")
        print("🔍 DEBUG - Features data:")
        print("  - Sqft: \(sqft)")
        print("  - Windows: \(windowsCount)")
        print("  - Family Type: \(selectedFamilyType)")
        print("  - Small Beds: \(smallBedCount)")
        print("  - Large Beds: \(largeBedCount)")
        print("  - Chairs: \(chairCount)")
        print("  - Tables: \(tableCount)")
        print("  - Electricity: \(isElectricityAvailable)")
        print("  - Washing Machine: \(isWashingMachineAvailable)")
        print("  - Water: \(isWaterAvailable)")
        
        habitationFeatureViewModel.createFeatureForHabitation(
            habitation: habitation,
            sqft: sqft,
            familyType: selectedFamilyType,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: chairCount,
            tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWashingMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
    }
    
    private func handleFeatureCreationSuccess() {
        print("🔍 DEBUG - Feature creation success handler called")
        
        guard let createdHabitation = habitationViewModel.createdHabitation else {
            print("❌ ERROR - Features were created but habitation data is missing")
            showErrorAlert("Features were created but habitation data is missing")
            return
        }
        
        print("✅ SUCCESS - Features created for habitation: \(createdHabitation.id)")
        
        if !uploadedImageUrls.isEmpty {
            print("🔍 DEBUG - Adding images to habitation")
            addImagesToHabitation(habitationId: createdHabitation.id)
        } else {
            print("🔍 DEBUG - No images to upload, showing success")
            showSuccessMessage()
        }
    }
    
    private func addImagesToHabitation(habitationId: String) {
        print("🔍 DEBUG - Adding \(uploadedImageUrls.count) images to habitation: \(habitationId)")
        
        let totalImages = uploadedImageUrls.count
        var addedImages = 0
        
        for imageUrl in uploadedImageUrls {
            habitationImageViewModel.addHabitationImage(
                habitationId: habitationId,
                pictureUrl: imageUrl
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                addedImages += 1
                print("🔍 DEBUG - Added image \(addedImages)/\(totalImages)")
                
                if addedImages == totalImages {
                    print("✅ SUCCESS - All images added")
                    self.showSuccessMessage()
                }
            }
        }
    }
    
    private func showSuccessMessage() {
        print("🔍 DEBUG - Showing success message")
        isLoading = false
        creationStep = maxSteps
        
        successMessage = "Your place has been posted successfully! All details including location and features have been saved."
        showSuccessAlert = true
        
        // Reset all view model states
        habitationViewModel.resetHabitationCreationState()
        habitationLocationViewModel.resetLocationCreationState()
        habitationFeatureViewModel.resetFeatureCreationState()
        habitationImageViewModel.resetImageAdditionState()
    }
    
    private func showErrorAlert(_ message: String) {
        print("❌ ERROR - \(message)")
        isLoading = false
        isUploadingImages = false
        creationStep = 0
        alertMessage = message
        showAlert = true
    }
    
    private func resetForm() {
        print("🔍 DEBUG - Resetting form")
        
        habitationName = ""
        habitationDescription = ""
        selectedHabitationType = HabitationType.singleRoom
        selectedImages.removeAll()
        selectedPhotoItems.removeAll()
        
        selectedLocation = nil
        locationDescription = "Tap to select location"
        latitude = 0.0
        longitude = 0.0
        
        addressNo = ""
        city = ""
        addressLine01 = ""
        addressLine02 = ""
        selectedDistrict = District.colombo
        
        sqft = 0
        windowsCount = 0
        selectedFamilyType = FamilyType.oneStory
        smallBedCount = 0
        largeBedCount = 0
        chairCount = 0
        tableCount = 0
        
        isElectricityAvailable = false
        isWashingMachineAvailable = false
        isWaterAvailable = false
        
        monthlyRent = 0
        isReserved = false
        
        isLoading = false
        uploadedImageUrls.removeAll()
        imageUploadProgress = 0.0
        creationStep = 0
        
        habitationViewModel.resetHabitationCreationState()
        habitationLocationViewModel.resetLocationCreationState()
        habitationFeatureViewModel.resetFeatureCreationState()
        habitationImageViewModel.resetImageAdditionState()
    }
}

// MARK: - Header Widget
struct HeaderWidget: View {
    let title: String
    let subtitle: String
    let onBackAction: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: onBackAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.foreground)
                    .frame(width: 44, height: 44)
                    .background(AppColors.input)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
}

// MARK: - Basic Info Card Widget
struct BasicInfoCardWidget: View {
    @Binding var habitationName: String
    @Binding var habitationDescription: String
    @Binding var selectedHabitationType: HabitationType
    @Binding var selectedImages: [UIImage]
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var isPhotoPickerPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Place Name")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("Enter place name", text: $habitationName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("Describe your place", text: $habitationDescription, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Room Type")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Menu {
                    ForEach(HabitationType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            selectedHabitationType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedHabitationType.displayName)
                            .foregroundStyle(AppColors.foreground)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                    .padding()
                    .background(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                if selectedImages.isEmpty {
                    Button(action: {
                        isPhotoPickerPresented = true
                    }) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.input)
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(AppColors.mutedForeground)
                                    
                                    Text("Add Photos")
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.mutedForeground)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    ImageGalleryWidget(
                        selectedImages: $selectedImages,
                        selectedPhotoItems: $selectedPhotoItems,
                        isPhotoPickerPresented: $isPhotoPickerPresented
                    )
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
}

// MARK: - Image Gallery Widget
struct ImageGalleryWidget: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var isPhotoPickerPresented: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(12)
                        
                        Button(action: {
                            selectedImages.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .offset(x: 8, y: -8)
                    }
                }
                
                if selectedImages.count < 10 {
                    Button(action: {
                        isPhotoPickerPresented = true
                    }) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.input)
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppColors.mutedForeground)
                                    
                                    Text("Add")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.mutedForeground)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                Text("\(selectedImages.count)/10 photos")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
                
                Spacer()
                
                if !selectedImages.isEmpty {
                    Button("Remove All") {
                        selectedImages.removeAll()
                        selectedPhotoItems.removeAll()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Address Info Card Widget
struct AddressInfoCardWidget: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationDescription: String
    @Binding var showLocationPicker: Bool
    @Binding var isLoadingLocation: Bool
    @Binding var addressNo: String
    @Binding var city: String
    @Binding var addressLine01: String
    @Binding var addressLine02: String
    @Binding var selectedDistrict: District
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address Information")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            showLocationPicker = true
                        }) {
                            HStack {
                                Image(systemName: "location")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColors.mutedForeground)
                                
                                Text(locationDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(selectedLocation != nil ? AppColors.foreground : AppColors.mutedForeground)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.mutedForeground)
                            }
                            .padding()
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            isLoadingLocation = true
                            locationManager.requestLocation { location in
                                DispatchQueue.main.async {
                                    isLoadingLocation = false
                                    if let location = location {
                                        selectedLocation = location.coordinate
                                        reverseGeocode(location: location.coordinate)
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isLoadingLocation {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(AppColors.primary)
                                } else {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppColors.primary)
                                }
                                
                                Text(isLoadingLocation ? "Getting location..." : "Use Current Location")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.primary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoadingLocation)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address No")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("123/A", text: $addressNo)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("Colombo", text: $city)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address Line 1")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    TextField("Main Street", text: $addressLine01)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address Line 2")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    TextField("Second Lane", text: $addressLine02)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("District")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Menu {
                        ForEach(District.allCases, id: \.self) { district in
                            Button(district.displayName) {
                                selectedDistrict = district
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedDistrict.displayName)
                                .foregroundStyle(AppColors.foreground)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.mutedForeground)
                        }
                        .padding()
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
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
    
    private func reverseGeocode(location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    addressNo = placemark.subThoroughfare ?? ""
                    addressLine01 = placemark.thoroughfare ?? ""
                    addressLine02 = placemark.subLocality ?? ""
                    city = placemark.locality ?? ""
                    
                    if let administrativeArea = placemark.administrativeArea,
                       let district = District.allCases.first(where: { $0.rawValue == administrativeArea }) {
                        selectedDistrict = district
                    }
                    
                    var components: [String] = []
                    if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
                    if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
                    if let locality = placemark.locality { components.append(locality) }
                    if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }
                    
                    locationDescription = components.joined(separator: ", ")
                    if locationDescription.isEmpty {
                        locationDescription = "Location selected"
                    }
                }
            }
        }
    }
}

// MARK: - Property Details Card Widget
struct PropertyDetailsCardWidget: View {
    @Binding var sqft: Int
    @Binding var windowsCount: Int
    @Binding var selectedFamilyType: FamilyType
    @Binding var smallBedCount: Int
    @Binding var largeBedCount: Int
    @Binding var chairCount: Int
    @Binding var tableCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Details")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Square Feet")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("1500", value: $sqft, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Windows")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("8", value: $windowsCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Family Type")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Menu {
                        ForEach(FamilyType.allCases, id: \.self) { type in
                            Button(type.displayName) {
                                selectedFamilyType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFamilyType.displayName)
                                .foregroundStyle(AppColors.foreground)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.mutedForeground)
                        }
                        .padding()
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small Beds")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("0", value: $smallBedCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Beds")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("1", value: $largeBedCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chairs")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("6", value: $chairCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tables")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("2", value: $tableCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
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
}

// MARK: - Amenities Card Widget
struct AmenitiesCardWidget: View {
    @Binding var isElectricityAvailable: Bool
    @Binding var isWashingMachineAvailable: Bool
    @Binding var isWaterAvailable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amenities")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.mutedForeground)
                        Text("Electricity")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.foreground)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isElectricityAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                }
                
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "washer.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.mutedForeground)
                        Text("Washing Machine")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.foreground)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isWashingMachineAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                }
                
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.mutedForeground)
                        Text("Water")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.foreground)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isWaterAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
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
}

// MARK: - Pricing Card Widget

struct PricingCardWidget: View {
    @Binding var monthlyRent: Int
    @Binding var isReserved: Bool
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_LK")
        return formatter
    }()
    
    var body: some View {
        
        let monthlyRentBinding = Binding<String>(
            get: {
               
                if let formatted = currencyFormatter.string(from: NSNumber(value: monthlyRent)) {
                   
                    return formatted.replacingOccurrences(of: "LKR", with: "").trimmingCharacters(in: .whitespaces)
                }
                return String(monthlyRent) // Fallback
            },
            set: { newValue in
                
                let cleanedValue = newValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                
                if let number = currencyFormatter.number(from: cleanedValue) ?? NumberFormatter().number(from: cleanedValue) {
                    monthlyRent = Int(number.doubleValue)
                }
                
            }
        )
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Monthly Rent (LKR)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("4,500.00", text: monthlyRentBinding)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isReserved ? AppColors.primary : AppColors.mutedForeground)
                    Text("Mark as Reserved")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Spacer()
                
                Toggle("", isOn: $isReserved)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
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
}

// MARK: - Submit Button Widget
struct SubmitButtonWidget: View {
    let isLoading: Bool
    let canSubmit: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        Button(action: onSubmit) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text("Post Your Place")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? AppColors.primary : AppColors.mutedForeground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isLoading)
        .accessibilityLabel("Post Your Place")
        .padding(.horizontal, 16)
    }
}


// MARK: - LocationPickerView (Unchanged)
struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationDescription: String
    @Environment(\.dismiss) private var dismiss
    
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var mapSelection: CLLocationCoordinate2D?
    @State private var isLoadingLocation = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search location", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchLocation()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Search Results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            selectSearchResult(item)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Unknown")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxHeight: 150)
                }
                
                // Map View
                Map(coordinateRegion: $region, annotationItems: mapSelection != nil ? [MapPin(coordinate: mapSelection!)] : []) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                            )
                    }
                }
                .onTapGesture { coordinate in
                    let location = region.center
                    mapSelection = location
                    reverseGeocode(location: location)
                }
                .overlay(
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        )
                )
                
                // Bottom Actions
                VStack(spacing: 12) {
                    Button(action: {
                        getCurrentLocation()
                    }) {
                        HStack {
                            if isLoadingLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16))
                                
                                Text("Use Current Location")
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isLoadingLocation)
                    
                    Button(action: {
                        if let location = mapSelection {
                            onLocationSelected(location, locationDescription)
                        } else {
                            onLocationSelected(region.center, "Selected location")
                        }
                        dismiss()
                    }) {
                        Text("Confirm Location")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        mapSelection = coordinate
        region.center = coordinate
        locationDescription = item.placemark.title ?? "Selected location"
        searchText = ""
        searchResults = []
    }
    
    private func getCurrentLocation() {
        isLoadingLocation = true
        
        locationManager.requestLocation { location in
            DispatchQueue.main.async {
                isLoadingLocation = false
                if let location = location {
                    mapSelection = location.coordinate
                    region.center = location.coordinate
                    reverseGeocode(location: location.coordinate)
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    var components: [String] = []
                    if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
                    if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
                    if let locality = placemark.locality { components.append(locality) }
                    if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }
                    
                    locationDescription = components.joined(separator: ", ")
                    if locationDescription.isEmpty {
                        locationDescription = "Selected location"
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types (Unchanged)
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(nil)
        @unknown default:
            completion(nil)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion?(nil)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
}

enum District: String, CaseIterable {
    case colombo = "Colombo"
    case gampaha = "Gampaha"
    case kalutara = "Kalutara"
    case kandy = "Kandy"
    case matale = "Matale"
    case nuwara_eliya = "Nuwara Eliya"
    case galle = "Galle"
    case matara = "Matara"
    case hambantota = "Hambantota"
    case jaffna = "Jaffna"
    case kilinochchi = "Kilinochchi"
    case mannar = "Mannar"
    case mullaitivu = "Mullaitivu"
    case vavuniya = "Vavuniya"
    case puttalam = "Puttalam"
    case kurunegala = "Kurunegala"
    case anuradhapura = "Anuradhapura"
    case polonnaruwa = "Polonnaruwa"
    case badulla = "Badulla"
    case monaragala = "Monaragala"
    case ratnapura = "Ratnapura"
    case kegalle = "Kegalle"
    case ampara = "Ampara"
    case batticaloa = "Batticaloa"
    case trincomalee = "Trincomalee"
    
    var displayName: String {
        return rawValue
    }
}

#Preview {
    PostPlaceView()
}
