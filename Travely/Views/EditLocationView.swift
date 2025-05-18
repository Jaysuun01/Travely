// Created by Jason Huynh

import SwiftUI
import FirebaseFirestore

struct EditLocationView: View {
    @Environment(\.presentationMode) var presentationMode
    let location: Location
    let tripId: String
    var onSave: (Location) -> Void
    var onDelete: (Location) -> Void
    
    @State private var locationName: String
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var transportation: TransportationType
    @State private var notes: String
    @State private var showDeleteConfirmation = false
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    init(location: Location, tripId: String, onSave: @escaping (Location) -> Void, onDelete: @escaping (Location) -> Void) {
        self.location = location
        self.tripId = tripId
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state variables with existing location data
        _locationName = State(initialValue: location.name)
        _selectedDate = State(initialValue: location.startDate)
        _startTime = State(initialValue: location.startDate)
        _endTime = State(initialValue: location.endDate)
        _transportation = State(initialValue: location.transportation)
        _notes = State(initialValue: location.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Location info card
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(accentColor)
                                TextField("Location Name", text: $locationName)
                                    .font(.headline)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            // Single Date Picker
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Date")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                Spacer()
                            }
                            
                            // Time Pickers
                            HStack(spacing: 16) {
                                // Start Time
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("Start Time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                    }
                                }
                                
                                // End Time
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("End Time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            
                            HStack(spacing: 12) {
                                Picker("Transportation", selection: $transportation) {
                                    ForEach(TransportationType.allCases) { type in
                                        HStack {
                                            Image(systemName: type.iconName)
                                                .foregroundColor(type.iconColor)
                                            Text(type.displayName)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(.white)
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
                        
                        // Save Button
                        Button(action: saveLocation) {
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
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Delete Button
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                Text("Delete Place")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(width: 200)
                            .background(Color.red)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Delete Location", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete(location)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this location? This action cannot be undone.")
            }
        }
    }
    
    private func saveLocation() {
        // Create start and end dates by combining the selected date with the times
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startDate = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                    minute: startComponents.minute ?? 0,
                                    second: 0,
                                    of: selectedDate) ?? selectedDate
        
        let endDate = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                  minute: endComponents.minute ?? 0,
                                  second: 0,
                                  of: selectedDate) ?? selectedDate
        
        let updatedLocation = Location(
            id: location.id,
            name: locationName,
            startDate: startDate,
            endDate: endDate,
            transportation: transportation,
            coordinates: location.coordinates,
            notes: notes,
            createdAt: location.createdAt,
            tripId: tripId
        )
        
        onSave(updatedLocation)
        // Optionally schedule notification here if you have access to the trip
        presentationMode.wrappedValue.dismiss()
    }
} 
