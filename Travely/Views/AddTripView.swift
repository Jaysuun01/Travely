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
    @State private var newEmail: String = ""
    @State private var existingCollaborators: [String] = []
    @State private var collaborators: [String] = []
    
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var attemptedSave = false
    
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
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.badge.plus.fill")
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(.orange)

                                        TextField("Add Collaborator Emails", text: $newEmail)
                                            .font(.headline)
                                            .padding(12)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(10)
                                            .foregroundColor(.white)
                                            .onSubmit {
                                                addEmail()
                                            }
                                    }

                                    // Show list of added collaborators
                                    if !collaborators.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(collaborators, id: \.self) { email in
                                                    HStack(spacing: 6) {
                                                        Text(email)
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                        Button {
                                                            collaborators.removeAll { $0 == email }
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.white.opacity(0.15))
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
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
                        
                        let showFieldError = (tripName.trimmingCharacters(in: .whitespaces).isEmpty || destination.trimmingCharacters(in: .whitespaces).isEmpty) && attemptedSave

                        if showFieldError {
                            Text("Trip name and destination are required.")
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }

                        if !errorMessage.isEmpty && !showFieldError {
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
    
    private func addEmail() {
        let email = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !collaborators.contains(email) else { return }

        collaborators.append(email)
        newEmail = ""   // Clear input field
    }
    
    private func resetFields() {
        tripName = ""
        destination = ""
        startDate = Date()
        endDate = Date()
        collaborators = []
        notes = ""
        errorMessage = ""
        isSaving = false
        attemptedSave = false
    }
    
    func saveTrip() {
        attemptedSave = true
        addEmail()
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return
        }
        if tripName.trimmingCharacters(in: .whitespaces).isEmpty || destination.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = ""
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
            "pendingInvites": collaborators,
            "notes": notes,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "locations": [],
            "createdAt": FieldValue.serverTimestamp()
        ]
        print("👥 Collaborators:", collaborators)
        tripRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save trip: \(error.localizedDescription)"
                print("Firestore error: \(error)")
            } else {
                print("Trip saved successfully with ID: \(tripId)")
                // Create a Trip object and schedule notifications
                let newTrip = Trip(
                    id: tripId,
                    tripName: tripName,
                    destination: destination,
                    notes: notes,
                    startDate: startDate,
                    endDate: endDate,
                    ownerId: userId,
                    collaborators: collaborators,
                    tripId: tripId,
                    locations: [],
                    createdAt: Date()
                )
                NotificationManager.shared.scheduleAllLocationNotifications(for: newTrip)
                
                // Send notifications to collaborators
                for collaboratorEmail in collaborators {
                    NotificationManager.shared.notifyCollaboratorAdded(
                        tripName: tripName,
                        tripId: tripId,
                        collaboratorEmail: collaboratorEmail
                    )
                }
                
                selectedTab = 0 // Switch to Home tab
                // Optionally navigate back or reset fields
            }
        }
    }
}
