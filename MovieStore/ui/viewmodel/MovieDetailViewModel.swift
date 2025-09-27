import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {
    let movie: Movie

    @Published var orderAmount: Int = 1
    @Published var isAddingToCart: Bool = false
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    
    private let addToCartURL = "http://kasimadalan.pe.hu/movies/insertMovie.php"

    init(movie: Movie) {
        self.movie = movie
    }
    
    func incrementAmount() {
        orderAmount += 1
    }
    
    func decrementAmount() {
        guard orderAmount > 1 else { return }
        orderAmount -= 1
    }

    func addToCart() async {
        isAddingToCart = true
        
        guard let url = URL(string: addToCartURL) else {
            setAlert(message: "Geçersiz API Adresi")
            isAddingToCart = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let userName = "aylin_yildiz"

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: movie.name),
            URLQueryItem(name: "image", value: movie.image),
            URLQueryItem(name: "price", value: "\(movie.price ?? 0)"),
            URLQueryItem(name: "category", value: movie.category),
            URLQueryItem(name: "rating", value: "\(movie.rating ?? 0.0)"),
            URLQueryItem(name: "year", value: "\(movie.year ?? 0)"),
            URLQueryItem(name: "director", value: movie.director),
            URLQueryItem(name: "description", value: movie.description),
            URLQueryItem(name: "orderAmount", value: "\(orderAmount)"),
            URLQueryItem(name: "userName", value: userName)
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            
            if response.success == 1 {
                setAlert(message: "'\(movie.name ?? "")' başarıyla sepete eklendi!")
            } else {
                setAlert(message: "Hata: \(response.message)")
            }
            
        } catch {
            setAlert(message: "Bir sorun oluştu: \(error.localizedDescription)")
        }
        
        isAddingToCart = false
    }
    
    private func setAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}

