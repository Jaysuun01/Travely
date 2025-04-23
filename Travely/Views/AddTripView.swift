import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AddTripView: View {
    @Binding var selectedTab: Int
    @State private var tripName = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    
    @State private var isSaving = false
    @State private var errorMessage = ""
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("New Trip")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(.top, 40)
                        
                        Group {
                            TextField("Trip Name", text: $tripName)
                            TextField("Destination", text: $destination)
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            TextField("Notes", text: $notes, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: saveTrip) {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Trip")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(accentColor)
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal)
                }
                .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
            }
            .navigationBarHidden(true)
        }
    }
    
    func saveTrip() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return
        }

        isSaving = true
        errorMessage = ""

        let tripRef = db.collection("trips").document()
        let tripId = tripRef.documentID

        let data: [String: Any] = [
            "tripId": tripId,
            "tripName": tripName,
            "destination": destination,
            "ownerId": userId,
            "collaborators": [],
            "notes": notes,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        tripRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save trip: \(error.localizedDescription)"
                print("Firestore error: \(error)")
            } else {
                print("Trip saved successfully with ID: \(tripId)")
                selectedTab = 0 // 👈 Switch to Home tab
                // Optionally navigate back or reset fields
            }
        }
    }
}
