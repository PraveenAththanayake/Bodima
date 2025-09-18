import Foundation

/**
 * PaymentViewModel manages payment processing operations for the Bodima application.
 * Handles payment creation, server connectivity testing, and provides comprehensive
 * state management for payment-related UI components.
 * 
 * Features:
 * - Secure payment creation with proper validation
 * - Real-time payment processing status updates
 * - Server connectivity testing and diagnostics
 * - Comprehensive error handling with user-friendly messages
 * - Success and failure state management for UI feedback
 */
class PaymentViewModel: ObservableObject {
    
    /**
     * Published properties for reactive UI updates and state management.
     */
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    /**
     * Network manager instance for API communication.
     */
    private let networkManager = NetworkManager.shared
    
    /**
     * Core payment processing methods.
     */
    
    /**
     * Creates a new payment for a habitation reservation.
     * Processes payment request with proper validation and state management.
     * Provides real-time feedback through completion handler and published properties.
     * 
     * @param habitationOwnerId The unique identifier of the habitation owner
     * @param reservationId The unique identifier of the reservation being paid for
     * @param amount The payment amount in the appropriate currency
     * @param completion Completion handler called with success/failure status
     */
    func createPayment(habitationOwnerId: String, reservationId: String, amount: Double, completion: @escaping (Bool) -> Void) {
        guard validatePaymentParameters(habitationOwnerId: habitationOwnerId, reservationId: reservationId, amount: amount) else {
            completion(false)
            return
        }
        
        preparePaymentRequest()
        
        let paymentRequest = PaymentRequest(
            habitationOwnerId: habitationOwnerId,
            reservationId: reservationId,
            amount: amount
        )
        
        processPaymentRequest(paymentRequest, completion: completion)
    }
    
    /**
     * Tests server connectivity for payment processing diagnostics.
     * Validates that the payment server is accessible and responding properly.
     * Used for troubleshooting and system health checks.
     * 
     * @param completion Completion handler called with connection test results
     */
    func testConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3000/payments/test") else {
            showError("Invalid server URL configuration")
            completion(false)
            return
        }
        
        performConnectionTest(url: url, completion: completion)
    }
    
    /**
     * Private helper methods for internal payment processing operations.
     */
    
    /**
     * Validates payment parameters before processing.
     * Ensures all required parameters are valid and within acceptable ranges.
     * 
     * @param habitationOwnerId The habitation owner identifier to validate
     * @param reservationId The reservation identifier to validate
     * @param amount The payment amount to validate
     * @return True if all parameters are valid, false otherwise
     */
    private func validatePaymentParameters(habitationOwnerId: String, reservationId: String, amount: Double) -> Bool {
        guard !habitationOwnerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Habitation owner ID is required")
            return false
        }
        
        guard !reservationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Reservation ID is required")
            return false
        }
        
        guard amount > 0 else {
            showError("Payment amount must be greater than zero")
            return false
        }
        
        guard amount <= 1000000 else { // Reasonable upper limit
            showError("Payment amount exceeds maximum allowed limit")
            return false
        }
        
        return true
    }
    
    /**
     * Prepares the payment request by clearing previous states.
     * Resets error and success messages and sets loading state.
     */
    private func preparePaymentRequest() {
        isLoading = true
        clearMessages()
    }
    
    /**
     * Processes the payment request through the network manager.
     * Handles the API call and delegates response processing.
     * 
     * @param paymentRequest The payment request object to process
     * @param completion Completion handler for the payment operation
     */
    private func processPaymentRequest(_ paymentRequest: PaymentRequest, completion: @escaping (Bool) -> Void) {
        networkManager.request(
            endpoint: .createPayment,
            body: paymentRequest,
            responseType: PaymentResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handlePaymentResponse(result, completion: completion)
            }
        }
    }
    
    /**
     * Handles the response from payment creation API calls.
     * Processes successful responses and manages error scenarios.
     * 
     * @param result The result from the payment creation network request
     * @param completion Completion handler to call with the final result
     */
    private func handlePaymentResponse(_ result: Result<PaymentResponse, Error>, completion: @escaping (Bool) -> Void) {
        isLoading = false
        
        switch result {
        case .success(let response):
            if response.success {
                showSuccess(response.message)
                completion(true)
            } else {
                showError(response.message)
                completion(false)
            }
            
        case .failure(let error):
            handleNetworkError(error)
            completion(false)
        }
    }
    
    /**
     * Performs the actual connection test to the payment server.
     * Uses URLSession to test server accessibility and response.
     * 
     * @param url The server URL to test
     * @param completion Completion handler for the connection test
     */
    private func performConnectionTest(url: URL, completion: @escaping (Bool) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleConnectionTestResponse(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }
    
    /**
     * Handles the response from connection test operations.
     * Evaluates server response and provides appropriate feedback.
     * 
     * @param data Response data from the server
     * @param response HTTP response object
     * @param error Any error that occurred during the request
     * @param completion Completion handler for the connection test
     */
    private func handleConnectionTestResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Bool) -> Void) {
        if let error = error {
            showError("Cannot connect to server: \(error.localizedDescription)")
            completion(false)
        } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            clearMessages()
            completion(true)
        } else {
            showError("Server connection failed")
            completion(false)
        }
    }
    
    /**
     * Message and state management methods.
     */
    
    /**
     * Displays an error message to the user and clears success messages.
     * 
     * @param message The error message to display
     */
    private func showError(_ message: String) {
        errorMessage = message
        successMessage = nil
    }
    
    /**
     * Displays a success message to the user and clears error messages.
     * 
     * @param message The success message to display
     */
    private func showSuccess(_ message: String) {
        successMessage = message
        errorMessage = nil
    }
    
    /**
     * Clears all current messages (both error and success).
     * Used when starting new operations or resetting state.
     */
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    /**
     * Handles network errors with appropriate user feedback.
     * Provides specific error messages based on error type.
     * 
     * @param error The network error to handle and present to the user
     */
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("Authentication failed. Please check your credentials.")
                
            case .clientError(let message):
                showError("Payment request error: \(message)")
                
            case .serverError(let message):
                showError("Payment server error: \(message)")
                
            default:
                showError("Payment processing failed: \(networkError.localizedDescription)")
            }
        } else {
            showError("Network error during payment: \(error.localizedDescription)")
        }
    }
    
    /**
     * Utility methods for payment management.
     */
    
    /**
     * Resets all payment state to initial values.
     * Clears loading state, messages, and prepares for new operations.
     */
    func resetPaymentState() {
        isLoading = false
        clearMessages()
    }
    
    /**
     * Formats payment amounts for display with proper currency formatting.
     * 
     * @param amount The payment amount to format
     * @param currency The currency code (defaults to LKR for Sri Lankan Rupees)
     * @return Formatted currency string
     */
    func formatPaymentAmount(_ amount: Double, currency: String = "LKR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(String(format: "%.2f", amount))"
    }
}