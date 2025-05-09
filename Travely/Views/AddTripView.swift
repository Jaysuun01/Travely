import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

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
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Trip")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(accentColor)
                            Text("Plan your next adventure.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding([.top, .horizontal], 24)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Card-like form background
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "airplane.departure")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(accentColor)
                                    TextField("Trip Name", text: $tripName)
                                        .font(.headline)
                                        .padding(12)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.orange)
                                    TextField("Destination", text: $destination)
                                        .font(.headline)
                                        .padding(12)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("Start Date")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                    }
                                    Spacer()
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("End Date")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        DatePicker("", selection: $endDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                    }
                                    Spacer()
                                }
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "note.text")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.yellow)
                                    TextField("Notes", text: $notes, axis: .vertical)
                                        .lineLimit(3, reservesSpace: true)
                                        .padding(12)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 16)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        Button(action: saveTrip) {
                            if isSaving {
                                ProgressView()
                            } else {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.white)
                                    Text("Save Trip")
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(width: 200)
                                .background(accentColor)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .shadow(color: accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 30)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .onAppear {
                resetFields()
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }
    
    private func resetFields() {
        tripName = ""
        destination = ""
        startDate = Date()
        endDate = Date()
        notes = ""
        errorMessage = ""
        isSaving = false
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
            "locations": [],
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        tripRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save trip: \(error.localizedDescription)"
                print("Firestore error: \(error)")
            } else {
                print("Trip saved successfully with ID: \(tripId)")
                selectedTab = 0 // Switch to Home tab
                // Optionally navigate back or reset fields
            }
        }
    }
}
