// Created by Jason Huynh

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var trip: Trip
    var onSave: ((Trip) -> Void)?
    var onDelete: ((Trip) -> Void)?
    
    @State private var tripName: String
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var newEmail: String = ""
    @State private var existingCollaborators: [String] = []
    @State private var collaborators: [String] = []
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage = ""
    
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    private let db = Firestore.firestore()
    
    init(trip: Trip, onSave: ((Trip) -> Void)? = nil, onDelete: ((Trip) -> Void)? = nil) {
        self._trip = State(initialValue: trip)
        self.onSave = onSave
        self.onDelete = onDelete
        self._tripName = State(initialValue: trip.tripName)
        self._destination = State(initialValue: trip.destination)
        self._startDate = State(initialValue: trip.startDate)
        self._endDate = State(initialValue: trip.endDate)
        self._existingCollaborators = State(initialValue: trip.collaborators)
        self._collaborators = State(initialValue: [])
        self._notes = State(initialValue: trip.notes)
    }
    
    var body: some View {
        let allCollaborators = existingCollaborators + collaborators
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Trip")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(accentColor)
                            Text("Update your trip details below.")
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
                                    if !allCollaborators.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(allCollaborators, id: \.self) { email in
                                                    let isCurrentUser = email == Auth.auth().currentUser?.email
                                                    let label = isCurrentUser ? "Owner" : email

                                                    HStack(spacing: 6) {
                                                        Text(label)
                                                            .font(.caption)
                                                            .foregroundColor(.white)

                                                        Button {
                                                            if collaborators.contains(email) {
                                                                collaborators.removeAll { $0 == email }
                                                            } else {
                                                                existingCollaborators.removeAll { $0 == email }
                                                            }
                                                        } label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.gray)
                                                        }
                                                        .disabled(isCurrentUser) // Optional: prevent removing yourself
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
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                    Text("Save Changes")
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
                        
                        Button(role: .destructive, action: deleteTrip) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Trip")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(width: 200)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear{
                fetchExistingCollaboratorsIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func addEmail() {
        let email = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !collaborators.contains(email) else { return }

        collaborators.append(email)
        newEmail = ""   // Clear input field
    }
    
    private func fetchExistingCollaboratorsIfNeeded() {
        // If editing an existing trip, pass the trip ID and fetch

        let tripId = trip.tripId

        db.collection("trips").document(tripId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let saved = data["collaborators"] as? [String] {
                self.existingCollaborators = saved
            }
        }
    }
    
    private func saveTrip() {
        addEmail()
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return
        }
        let combined = Array(Set(existingCollaborators + collaborators))
        isSaving = true
        errorMessage = ""
        let tripRef = db.collection("trips").document(trip.tripId)
        let data: [String: Any] = [
            "tripId": trip.tripId,
            "tripName": tripName,
            "destination": destination,
            "ownerId": trip.ownerId,
            "collaborators": existingCollaborators,
            "pendingInvites": collaborators,
            "notes": notes,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "locations": trip.locations.map { try? Firestore.Encoder().encode($0) },
            "createdAt": trip.createdAt ?? FieldValue.serverTimestamp()
        ]
        print("👥 Collaborators:", collaborators)
        tripRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to update trip: \(error.localizedDescription)"
            } else {
                // Update local trip state
                trip.tripName = tripName
                trip.destination = destination
                trip.startDate = startDate
                trip.endDate = endDate
                trip.collaborators = existingCollaborators
                trip.notes = notes
                onSave?(trip)
                // Reschedule notifications for all locations
                NotificationManager.shared.scheduleAllLocationNotifications(for: trip)
                
                // Send notifications to new collaborators
                let newCollaborators = combined.filter { !existingCollaborators.contains($0) }
                for collaboratorEmail in newCollaborators {
                    NotificationManager.shared.notifyCollaboratorAdded(
                        tripName: tripName,
                        tripId: trip.tripId,
                        collaboratorEmail: collaboratorEmail
                    )
                }
                
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func deleteTrip() {
        let tripRef = db.collection("trips").document(trip.tripId)
        tripRef.delete { error in
            if let error = error {
                errorMessage = "Failed to delete trip: \(error.localizedDescription)"
            } else {
                onDelete?(trip)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
