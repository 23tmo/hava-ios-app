import SwiftUI
import MapKit
import CoreLocation
import Foundation

struct QuickAddRecommendationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var recommendationText = ""
    @State private var detectedURL: String? = nil
    @State private var extractedPreview: String? = nil
    @State private var urlImagePreview: UIImage? = nil
    @State private var mapLocation: String? = nil
    @State private var showingMapPicker = false
    @State private var isRemovingURL = false
    @FocusState private var isTextFieldFocused: Bool
    
    let question: Question
    let asker: User
    
    var impactCount: Int {
        store.getImpactCount(for: question.id)
    }
    
    var canSubmit: Bool {
        !recommendationText.isEmpty || mapLocation != nil || detectedURL != nil
    }
    
    private func fetchImagePreview(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8),
                  let imageURL = extractImageURL(from: html, baseURL: url) else {
                return
            }
            
            URLSession.shared.dataTask(with: imageURL) { imageData, _, _ in
                if let imageData = imageData, let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.urlImagePreview = image
                    }
                }
            }.resume()
        }.resume()
    }
    
    private func extractImageURL(from html: String, baseURL: URL) -> URL? {
        
        let patterns = [
            #"property="og:image"\s+content="([^"]+)""#,
            #"property='og:image'\s+content='([^']+)'"#,
            #"<meta\s+property="og:image"\s+content="([^"]+)""#,
            #"og:image"\s+content="([^"]+)""#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
               match.numberOfRanges > 1 {
                let urlRange = Range(match.range(at: 1), in: html)!
                var urlString = String(html[urlRange])
                
                
                urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                    return URL(string: urlString)
                } else if urlString.hasPrefix("//") {
                    return URL(string: "https://\(urlString)")
                } else if urlString.hasPrefix("/") {
                    return URL(string: urlString, relativeTo: baseURL)
                } else {
                    return URL(string: urlString, relativeTo: baseURL)
                }
            }
        }
        
        return nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Help \(asker.name) in under 10 seconds")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text("They're asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(question.text)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                if impactCount > 0 {
                    Text("Your recommendation may help \(impactCount) friend\(impactCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Your recommendation will help \(asker.name)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your recommendation:")
                    .font(.headline)
                
                TextField("e.g., Dr. Kim at Brooklyn Dental - super gentle!", text: $recommendationText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .focused($isTextFieldFocused)
                    .onChange(of: recommendationText) { newValue in
                        
                        guard !isRemovingURL else { return }
                        
                        
                        if let url = store.detectURLInText(newValue) {
                            
                            if detectedURL != url {
                                detectedURL = url
                                extractedPreview = store.extractPreviewFromURL(url)
                                
                                
                                isRemovingURL = true
                                var cleanedText = newValue
                                
                                
                                let urlVariations = [
                                    url,
                                    url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""),
                                    url.replacingOccurrences(of: "https://", with: ""),
                                    url.replacingOccurrences(of: "http://", with: "")
                                ]
                                
                                for urlVar in urlVariations {
                                    if let range = cleanedText.range(of: urlVar) {
                                        cleanedText.removeSubrange(range)
                                        break
                                    }
                                }
                                
                                
                                cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
                                cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                
                                if cleanedText != newValue {
                                    recommendationText = cleanedText
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isRemovingURL = false
                                }
                                
                                
                                fetchImagePreview(from: url)
                            }
                        } else {
                            
                            if detectedURL != nil {
                                detectedURL = nil
                                extractedPreview = nil
                                urlImagePreview = nil
                            }
                        }
                    }
            }
            .padding(.horizontal)
            
            
            if let url = detectedURL {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            if let preview = extractedPreview {
                                Text(preview)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Link detected")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            Text(url)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: {
                            detectedURL = nil
                            extractedPreview = nil
                            urlImagePreview = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    
                    if let image = urlImagePreview {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            
            Button(action: {
                showingMapPicker = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Autofill from Maps")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            
            if let location = mapLocation {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text(location)
                        .font(.caption)
                    Spacer()
                    Button(action: { mapLocation = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            
            if let question = store.questions.first(where: { $0.id == question.id }) {
                let suggestedTags = store.generateAutoTags(from: question.text, recommendationText: recommendationText)
                if !suggestedTags.isEmpty && !recommendationText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            
            Button(action: submitRecommendation) {
                Text("Share Recommendation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canSubmit)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .sheet(isPresented: $showingMapPicker) {
            MapLocationPickerView(selectedLocation: $mapLocation)
        }
    }
    
    private func submitRecommendation() {
        var finalText = recommendationText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        if let location = mapLocation {
            if finalText.isEmpty {
                finalText = "📍 \(location)"
            } else {
                finalText += "\n📍 \(location)"
            }
        }
        
        
        if let url = detectedURL {
            if finalText.isEmpty {
                finalText = "🔗 \(url)"
            } else {
                finalText += "\n🔗 \(url)"
            }
        }
        
        
        guard !finalText.isEmpty else { return }
        
        store.quickAddRecommendation(questionId: question.id, text: finalText)
        dismiss()
    }
}

struct MapLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: String?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for a restaurant, place...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            searchPlaces(query: newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No places found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
                
                List(Array(searchResults.enumerated()), id: \.offset) { index, mapItem in
                    Button(action: {
                        let name = mapItem.name ?? "Unknown"
                        let address = formatAddress(from: mapItem.placemark)
                        selectedLocation = "\(name), \(address)"
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mapItem.name ?? "Unknown Place")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(formatAddress(from: mapItem.placemark))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchPlaces(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -73.9352), 
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    searchResults = []
                } else if let response = response {
                    searchResults = Array(response.mapItems.prefix(10))
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let street = placemark.thoroughfare {
            addressComponents.append(street)
        }
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let zip = placemark.postalCode {
            addressComponents.append(zip)
        }
        
        return addressComponents.joined(separator: ", ")
    }
}


