import SwiftUI

struct CartView: View {
    
    @StateObject private var viewModel = CartViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.cartItems.isEmpty {
                ProgressView("Sepet Yükleniyor...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if !viewModel.cartItems.isEmpty {
                cartListView
            } else {
                emptyCartView
            }
        }
        .navigationTitle("Sepetim")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadCart() }
        .refreshable { await viewModel.loadCart() }
        .environmentObject(viewModel)
    }
    
    private var cartListView: some View {
        List {
            ForEach(viewModel.cartItems) { item in
                CartItemRow(item: item)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                let itemsToDelete = indexSet.map { viewModel.cartItems[$0] }
                for item in itemsToDelete {
                    viewModel.deleteAllInstances(of: item)
                }
            }
            
            Section {
                HStack {
                    Text("Toplam Tutar").fontWeight(.bold)
                    Spacer()
                    Text("₺\(viewModel.totalPrice)").fontWeight(.bold).foregroundColor(.red)
                }
                .foregroundColor(.white)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 80))
            Text("Sepetiniz Boş").font(.title2).fontWeight(.semibold).foregroundColor(.white)
            Text(viewModel.errorMessage ?? "Beğendiğiniz filmleri ekleyerek alışverişe başlayın.")
                .font(.subheadline).multilineTextAlignment(.center).padding(.horizontal)
                .foregroundColor(.gray)
        }
    }
}

struct CartItemRow: View {
    @EnvironmentObject var viewModel: CartViewModel
    let item: CartMovie
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: item.imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 80, height: 100).cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name ?? "Film Adı").font(.headline).foregroundColor(.white)
                Text("Birim Fiyat: ₺\(item.price ?? 0)").font(.subheadline).foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Button { Task { await viewModel.decreaseQuantity(for: item) } } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Text("\(item.orderAmount ?? 0)").font(.headline).frame(minWidth: 20).foregroundColor(.white)
                    
                    Button { Task { await viewModel.increaseQuantity(for: item) } } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .font(.title2).foregroundColor(.red).buttonStyle(.plain)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Button(action: {
                    viewModel.deleteAllInstances(of: item)
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("₺\((item.price ?? 0) * (item.orderAmount ?? 0))")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CartView().preferredColorScheme(.dark)
        }
    }
}
