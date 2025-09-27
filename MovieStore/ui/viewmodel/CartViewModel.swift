import Foundation

@MainActor
class CartViewModel: ObservableObject {

    @Published var cartItems: [CartMovie] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var rawCartItems: [CartMovie] = []
    
    var totalPrice: Int {
        cartItems.reduce(0) { $0 + (($1.price ?? 0) * ($1.orderAmount ?? 0)) }
    }
    
    var totalItemCount: Int {
        cartItems.reduce(0) { $0 + ($1.orderAmount ?? 0) }
    }
    
    private let getCartURL = URL(string: "http://kasimadalan.pe.hu/movies/getMovieCart.php")!
    private let deleteFromCartURL = URL(string: "http://kasimadalan.pe.hu/movies/deleteMovie.php")!
    private let insertToCartURL = URL(string: "http://kasimadalan.pe.hu/movies/insertMovie.php")!
    private let userName = "kasim_adalan"

    func loadCart() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let decodedResponse = try await fetchRawCartFromServer()
            self.rawCartItems = decodedResponse
            self.cartItems = groupAndSumCartItems(items: decodedResponse)
        } catch is DecodingError {
            self.rawCartItems = []
            self.cartItems = []
        } catch {
            self.errorMessage = "Sepet yüklenirken hata oluştu: \(error.localizedDescription)"
            self.cartItems = []
        }
        isLoading = false
    }
    
    func increaseQuantity(for item: CartMovie) async {
        if let index = cartItems.firstIndex(where: { $0.name == item.name }) {
            var updatedItem = cartItems[index]
            updatedItem.orderAmount = (updatedItem.orderAmount ?? 0) + 1
            cartItems[index] = updatedItem

            await insertSingleItemToServer(for: item)
        }
    }

    func decreaseQuantity(for item: CartMovie) async {
        guard let currentAmount = item.orderAmount, currentAmount > 0 else { return }

        if currentAmount <= 1 {
            await deleteAllInstances(of: item)
            return
        }
        
        if let index = cartItems.firstIndex(where: { $0.name == item.name }) {
            var updatedItem = cartItems[index]
            updatedItem.orderAmount = currentAmount - 1
            cartItems[index] = updatedItem
        }

        if let itemToDeleteOnServer = rawCartItems.first(where: { $0.name == item.name }) {
            await deleteSingleItemFromServer(cartId: itemToDeleteOnServer.id)
          
            if let rawIndex = rawCartItems.firstIndex(where: { $0.id == itemToDeleteOnServer.id }) {
                rawCartItems.remove(at: rawIndex)
            }
        }
    }
    

    func deleteAllInstances(of itemToDelete: CartMovie) {
        let allServerInstances = rawCartItems.filter { $0.name == itemToDelete.name }
        
        cartItems.removeAll { $0.name == itemToDelete.name }
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for instance in allServerInstances {
                    group.addTask {
                        await self.deleteSingleItemFromServer(cartId: instance.id)
                    }
                }
            }
        }
    }

    
    private func groupAndSumCartItems(items: [CartMovie]) -> [CartMovie] {
        let grouped = Dictionary(grouping: items, by: { $0.name })
        return grouped.compactMap { (_, items) -> CartMovie? in
            guard let firstItem = items.first else { return nil }
            let totalAmount = items.reduce(0) { $0 + ($1.orderAmount ?? 0) }
            
            return CartMovie(id: firstItem.id, name: firstItem.name, image: firstItem.image, price: firstItem.price, category: firstItem.category, rating: firstItem.rating, year: firstItem.year, director: firstItem.director, description: firstItem.description, orderAmount: totalAmount, userName: firstItem.userName)
        }.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    private func fetchRawCartFromServer() async throws -> [CartMovie] {
        var request = URLRequest(url: getCartURL)
        request.httpMethod = "POST"
        request.httpBody = "userName=\(userName)".data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CartResponse.self, from: data).cartMovies
    }
    
    private func deleteSingleItemFromServer(cartId: Int) async {
        var request = URLRequest(url: deleteFromCartURL)
        request.httpMethod = "POST"
        request.httpBody = "cartId=\(cartId)&userName=\(userName)".data(using: .utf8)
        do { _ = try await URLSession.shared.data(for: request) }
        catch {  }
    }
    
    private func insertSingleItemToServer(for item: CartMovie) async {
        var request = URLRequest(url: insertToCartURL)
        request.httpMethod = "POST"
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "name", value: item.name),
            URLQueryItem(name: "image", value: item.image),
            URLQueryItem(name: "price", value: "\(item.price ?? 0)"),
            URLQueryItem(name: "orderAmount", value: "1"),
            URLQueryItem(name: "userName", value: userName)
        ]
        request.httpBody = components.query?.data(using: .utf8)
        do { _ = try await URLSession.shared.data(for: request) }
        catch {  }
    }
}
