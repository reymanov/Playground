import SwiftUI

struct UserDetailView: View {
    let userId: Int
    let userFullName: String
    @State private var user: DetailedUser?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let user = user {
                AsyncImage(url: URL(string: user.image)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .imageScale(.large)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())

                Section(header: Text("Personal Information")) {
                    InfoRow(title: "Name", value: "\(user.firstName) \(user.lastName)")
                    InfoRow(title: "Age", value: "\(user.age)")
                    InfoRow(title: "Gender", value: user.gender.capitalized)
                    InfoRow(title: "Email", value: user.email)
                    InfoRow(title: "Phone", value: user.phone)
                }

                Section(header: Text("Work")) {
                    InfoRow(title: "Company", value: user.company.name)
                    InfoRow(title: "Department", value: user.company.department)
                    InfoRow(title: "Title", value: user.company.title)
                }

                Section(header: Text("Address")) {
                    InfoRow(title: "Street", value: user.address.address)
                    InfoRow(title: "City", value: user.address.city)
                    InfoRow(title: "State", value: user.address.state)
                    InfoRow(title: "Country", value: user.address.country)
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(userFullName)
        .onAppear(perform: fetchUserDetails)
    }

    private func fetchUserDetails() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://dummyjson.com/users/\(userId)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }

                do {
                    let decodedUser = try JSONDecoder().decode(DetailedUser.self, from: data)
                    self.user = decodedUser
                } catch {
                    errorMessage = "Error decoding user: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct DetailedUser: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let age: Int
    let gender: String
    let email: String
    let phone: String
    let image: String
    let company: Company
    let address: Address
}

struct Company: Codable {
    let name: String
    let department: String
    let title: String
}

struct Address: Codable {
    let address: String
    let city: String
    let state: String
    let country: String
}

#Preview {
    UserDetailView(userId: 1, userFullName: "Emily Johnson")
}
