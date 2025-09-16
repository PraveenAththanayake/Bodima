import Foundation

class PaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Create Payment
    func createPayment(habitationOwnerId: String, reservationId: String, amount: Double, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let paymentRequest = PaymentRequest(
            habitationOwnerId: habitationOwnerId,
            reservationId: reservationId,
            amount: amount
        )
        
        networkManager.request(
            endpoint: .createPayment,
            body: paymentRequest,
            responseType: PaymentResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self?.successMessage = response.message
                        completion(true)
                    } else {
                        self?.errorMessage = response.message
                        completion(false)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Test Connection
    func testConnection(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3000/payments/test") else {
            self.errorMessage = "Invalid URL"
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Cannot connect to server: \(error.localizedDescription)"
                    completion(false)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    self?.errorMessage = "Server connection failed"
                    completion(false)
                }
            }
        }.resume()
    }
}