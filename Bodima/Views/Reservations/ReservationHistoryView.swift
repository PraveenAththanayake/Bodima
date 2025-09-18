import SwiftUI

struct ReservationHistoryView: View {
    // State management for reservation data and UI states
    @StateObject private var reservationViewModel = ReservationViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var userReservationHistory: UserReservationHistory?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ReservationHistoryLoadingComponent()
                    } else if let history = userReservationHistory {
                        if history.total == 0 {
                            ReservationHistoryEmptyStateComponent()
                        } else {
                            reservationSectionsView(history: history)
                        }
                    } else if let error = errorMessage {
                        ReservationHistoryErrorComponent(
                            message: error,
                            onRetry: {
                                Task {
                                    await loadReservationHistory()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle("My Reservations")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadReservationHistory()
            }
        }
        .onAppear {
            Task {
                await loadReservationHistory()
            }
        }
    }
    
    // Organize reservations into categorized sections with visual indicators
    // Displays current, upcoming, and past reservations with appropriate styling
    
    private func reservationSectionsView(history: UserReservationHistory) -> some View {
        VStack(spacing: 24) {
            // Current active reservations with green indicator
            if !history.current.isEmpty {
                ReservationHistorySectionComponent(
                    title: "Current Stay",
                    reservations: history.current,
                    color: .green,
                    icon: "house.fill"
                )
            }
            
            // Future reservations with blue indicator
            if !history.upcoming.isEmpty {
                ReservationHistorySectionComponent(
                    title: "Upcoming",
                    reservations: history.upcoming,
                    color: .blue,
                    icon: "calendar"
                )
            }
            
            // Historical reservations with gray indicator
            if !history.past.isEmpty {
                ReservationHistorySectionComponent(
                    title: "Past Reservations",
                    reservations: history.past,
                    color: .gray,
                    icon: "clock"
                )
            }
        }
    }
    
    // Asynchronously load user reservation history with proper error handling
    // Manages authentication validation and network request lifecycle
    @MainActor
    private func loadReservationHistory() async {
        let authUserId = authViewModel.currentUser?.id
        let userDefaultsId = UserDefaults.standard.string(forKey: "user_id")
        
        print("🔍 DEBUG - Auth user ID: \(authUserId ?? "nil")")
        print("🔍 DEBUG - UserDefaults user ID: \(userDefaultsId ?? "nil")")
        
        guard let userId = authUserId ?? userDefaultsId else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            NetworkManager.shared.request(
                endpoint: .getUserReservations(userId: userId),
                responseType: GetUserReservationHistoryResponse.self
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        print("🔍 DEBUG - Received response: \(response)")
                        if response.success {
                            self.userReservationHistory = response.data
                            print("🔍 DEBUG - Total reservations loaded: \(response.data?.total ?? 0)")
                        } else {
                            self.errorMessage = response.message ?? "Failed to load reservations"
                        }
                    case .failure(let error):
                        print("🔍 DEBUG - Request failed with error: \(error)")
                        print("🔍 DEBUG - Request failed with error: \(error)")
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
}



#Preview {
    ReservationHistoryView()
}
