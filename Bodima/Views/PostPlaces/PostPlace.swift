import SwiftUI
import MapKit
import CoreLocation

struct PostPlaceView: View {
    @StateObject private var viewModel = HabitationViewModel()
    @StateObject private var locationManager = LocationManager()
    
    // Location related states
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var locationDescription = "Tap to select location"
    @State private var showLocationPicker = false
    @State private var isLoadingLocation = false
    
    // Pricing (not in the original model but commonly needed)
    @State private var monthlyRent = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    
                    // Progress Indicator
                    if viewModel.creationProgress.isInProgress {
                        progressView
                            .padding(.horizontal, 16)
                    }
                    
                    // Basic Information Card
                    basicInfoCard
                        .padding(.horizontal, 16)
                    
                    // Address Information Card
                    addressInfoCard
                        .padding(.horizontal, 16)
                    
                    // Property Details Card
                    propertyDetailsCard
                        .padding(.horizontal, 16)
                    
                    // Amenities Card
                    amenitiesCard
                        .padding(.horizontal, 16)
                    
                    // Pricing Card
                    pricingCard
                        .padding(.horizontal, 16)
                    
                    // Submit Button
                    submitButton
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    selectedLocation: $selectedLocation,
                    locationDescription: $locationDescription,
                    onLocationSelected: { location, description in
                        updateLocationFields(location: location, description: description)
                    }
                )
            }
            .alert("Alert", isPresented: Binding<Bool>(
                get: { viewModel.alertMessage != nil },
                set: { _ in viewModel.clearAlert() }
            )) {
                Button("OK") {
                    viewModel.clearAlert()
                }
            } message: {
                Text(viewModel.alertMessage?.message ?? "")
            }

        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bodima")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Post Your Place")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {}) {
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
    }
    
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Creating Habitation")
                .font(.headline)
                .foregroundStyle(AppColors.foreground)
            
            Text(viewModel.creationProgress.description)
                .font(.subheadline)
                .foregroundStyle(AppColors.mutedForeground)
            
            ProgressView()
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                .frame(maxWidth: .infinity)
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
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Place Name")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("Enter place name", text: $viewModel.habitationName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("Describe your place", text: $viewModel.habitationDescription, axis: .vertical)
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
                            viewModel.selectedHabitationType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedHabitationType.displayName)
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
            
            // Image Upload Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Button(action: {}) {
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
    
    private var addressInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address Information")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                // Location Selection Section
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
                        
                        // Current Location Button
                        Button(action: {
                            getCurrentLocation()
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
                        TextField("123/A", text: $viewModel.addressNo)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("Colombo", text: $viewModel.city)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address Line 1")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    TextField("Main Street", text: $viewModel.addressLine01)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address Line 2")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    TextField("Second Lane", text: $viewModel.addressLine02)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("District")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Menu {
                        ForEach(District.allCases, id: \.self) { district in
                            Button(district.displayName) {
                                viewModel.selectedDistrict = district
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedDistrict.displayName)
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
    
    private var propertyDetailsCard: some View {
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
                        TextField("1500", value: $viewModel.sqft, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Windows")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("8", value: $viewModel.windowsCount, formatter: NumberFormatter())
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
                                viewModel.selectedFamilyType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedFamilyType.displayName)
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
                        TextField("0", value: $viewModel.smallBedCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Beds")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("1", value: $viewModel.largeBedCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chairs")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("6", value: $viewModel.chairCount, formatter: NumberFormatter())
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tables")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        TextField("2", value: $viewModel.tableCount, formatter: NumberFormatter())
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
    
    private var amenitiesCard: some View {
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
                    
                    Toggle("", isOn: $viewModel.isElectricityAvailable)
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
                    
                    Toggle("", isOn: $viewModel.isWashingMachineAvailable)
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
                    
                    Toggle("", isOn: $viewModel.isWaterAvailable)
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
    
    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Monthly Rent (LKR)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                TextField("4,500.00", text: $monthlyRent)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(viewModel.isReserved ? AppColors.primary : AppColors.mutedForeground)
                    Text("Mark as Reserved")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isReserved)
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
    
    private var submitButton: some View {
        Button(action: {
            submitPost()
        }) {
            HStack {
                if viewModel.isLoading {
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
            .background(viewModel.canCreateHabitation ? AppColors.primary : AppColors.mutedForeground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canCreateHabitation || viewModel.isLoading)
        .accessibilityLabel("Post Your Place")
    }
    
    // MARK: - Location Methods
    
    private func getCurrentLocation() {
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
    }
    
    private func reverseGeocode(location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    updateLocationFields(from: placemark, coordinate: location)
                }
            }
        }
    }
    
    private func updateLocationFields(from placemark: CLPlacemark, coordinate: CLLocationCoordinate2D) {
        // Update coordinates in viewModel
        viewModel.latitude = coordinate.latitude
        viewModel.longitude = coordinate.longitude
        
        // Update address fields in viewModel
        viewModel.addressNo = placemark.subThoroughfare ?? ""
        viewModel.addressLine01 = placemark.thoroughfare ?? ""
        viewModel.addressLine02 = placemark.subLocality ?? ""
        viewModel.city = placemark.locality ?? ""
        
        // Update district if it matches one in our enum
        if let administrativeArea = placemark.administrativeArea,
           let district = District.allCases.first(where: { $0.rawValue == administrativeArea }) {
            viewModel.selectedDistrict = district
        }
        
        // Update location description for display
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
    
    private func updateLocationFields(location: CLLocationCoordinate2D, description: String) {
        selectedLocation = location
        viewModel.latitude = location.latitude
        viewModel.longitude = location.longitude
        locationDescription = description
        
        // Set nearest habitation coordinates (for now, same as current location)
        viewModel.nearestHabitationLatitude = location.latitude
        viewModel.nearestHabitationLongitude = location.longitude
    }
    
    private func submitPost() {
        Task {
            await viewModel.createCompleteHabitation()
        }
    }
}

// MARK: - Location Manager (unchanged)

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

// MARK: - Location Picker View (unchanged)

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationDescription: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a location", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchLocation()
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                
                // Search Results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                            
                            let addressComponents = [
                                item.placemark.subThoroughfare,
                                item.placemark.thoroughfare,
                                item.placemark.locality,
                                item.placemark.administrativeArea
                            ].compactMap { $0 }
                            
                            Text(addressComponents.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectLocation(item)
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                // Map View
                Map(coordinateRegion: $region, annotationItems: selectedLocation != nil ? [LocationPin(coordinate: selectedLocation!)] : []) { pin in
                    MapPin(coordinate: pin.coordinate, tint: .red)
                }
                .onTapGesture { location in
                    let coordinate = region.center
                    selectLocationFromMap(coordinate: coordinate)
                }
                .gesture(
                    DragGesture()
                        .onEnded { _ in
                            let coordinate = region.center
                            selectLocationFromMap(coordinate: coordinate)
                        }
                )
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        if let location = selectedLocation {
                                            onLocationSelected(location, locationDescription)
                                        }
                                        dismiss()
                                    }
                                    .disabled(selectedLocation == nil)
                                }
                            }
                        }
                    }
                    
                    private func searchLocation() {
                        guard !searchText.isEmpty else { return }
                        
                        isSearching = true
                        let request = MKLocalSearch.Request()
                        request.naturalLanguageQuery = searchText
                        request.region = region
                        
                        let search = MKLocalSearch(request: request)
                        search.start { response, error in
                            DispatchQueue.main.async {
                                isSearching = false
                                if let response = response {
                                    searchResults = response.mapItems
                                } else {
                                    searchResults = []
                                }
                            }
                        }
                    }
                    
                    private func selectLocation(_ item: MKMapItem) {
                        let coordinate = item.placemark.coordinate
                        selectedLocation = coordinate
                        
                        // Update region to center on selected location
                        region = MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        
                        // Create description from placemark
                        let components = [
                            item.placemark.subThoroughfare,
                            item.placemark.thoroughfare,
                            item.placemark.locality,
                            item.placemark.administrativeArea
                        ].compactMap { $0 }
                        
                        locationDescription = components.joined(separator: ", ")
                        if locationDescription.isEmpty {
                            locationDescription = item.name ?? "Selected Location"
                        }
                        
                        // Clear search results
                        searchResults = []
                        searchText = ""
                    }
                    
                    private func selectLocationFromMap(coordinate: CLLocationCoordinate2D) {
                        selectedLocation = coordinate
                        
                        // Reverse geocode to get address
                        let geocoder = CLGeocoder()
                        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        
                        geocoder.reverseGeocodeLocation(location) { placemarks, error in
                            if let placemark = placemarks?.first {
                                DispatchQueue.main.async {
                                    let components = [
                                        placemark.subThoroughfare,
                                        placemark.thoroughfare,
                                        placemark.locality,
                                        placemark.administrativeArea
                                    ].compactMap { $0 }
                                    
                                    locationDescription = components.joined(separator: ", ")
                                    if locationDescription.isEmpty {
                                        locationDescription = "Selected Location"
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: - Supporting Types

                struct LocationPin: Identifiable {
                    let id = UUID()
                    let coordinate: CLLocationCoordinate2D
                }

               
                // MARK: - Preview

                #Preview {
                    PostPlaceView()
                }
