import SwiftUI

struct MovieDetailView: View {
    
    @StateObject private var viewModel: MovieDetailViewModel
    
    init(movie: Movie) {
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(movie: movie))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: viewModel.movie.imageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "film.fill").font(.largeTitle).foregroundColor(.secondary)
                        default:
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.2))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.movie.name ?? "Film Adı")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("₺\(viewModel.movie.price ?? 0)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        HStack {
                            Text("Yönetmen:").fontWeight(.semibold)
                            Text(viewModel.movie.director ?? "Bilinmiyor")
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Yıl:").fontWeight(.semibold)
                            Text("\(viewModel.movie.year ?? 0)")
                        }
                        .font(.subheadline)
                        
                        Divider()
                            .background(Color.gray)
                        
                        Text(viewModel.movie.description ?? "Açıklama mevcut değil.")
                            .font(.body)
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                }
            }
        }
        .navigationTitle(viewModel.movie.name ?? "Detay")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomControls
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Bilgi"), message: Text(viewModel.alertMessage ?? ""), dismissButton: .default(Text("Tamam")))
        }
    }
    
    private var bottomControls: some View {
        HStack(spacing: 20) {
            HStack {
                Button(action: viewModel.decrementAmount) {
                    Image(systemName: "minus.circle.fill")
                }
                .disabled(viewModel.orderAmount == 1)
                
                Text("\(viewModel.orderAmount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(minWidth: 40)
                
                Button(action: viewModel.incrementAmount) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .font(.title)
            .foregroundColor(.red)
            
            Button(action: {
                Task {
                    await viewModel.addToCart()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isAddingToCart {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "cart.fill.badge.plus")
                        Text("Sepete Ekle")
                    }
                    Spacer()
                }
                .padding()
                .background(viewModel.isAddingToCart ? Color.gray : Color.red)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
            }
            .disabled(viewModel.isAddingToCart)
        }
        .padding()
        .background(.black)
    }
}

struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMovie = Movie(id: 1, name: "Örnek Film", image: "dune.png", price: 150, category: "Bilim Kurgu", rating: 8.5, year: 2021, director: "Denis Villeneuve", description: "Açıklama.")
        
        NavigationView {
            MovieDetailView(movie: sampleMovie)
                .preferredColorScheme(.dark)
        }
    }
}
