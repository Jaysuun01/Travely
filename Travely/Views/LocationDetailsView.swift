// Created by Jason Huynh

import SwiftUI
import MapKit
import FirebaseFirestore

struct LocationDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    let mapItem: MKMapItem
    let tripId: String
    var onSave: (Location) -> Void
    
    @State private var locationName: String
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var transportation: TransportationType = .car
    @State private var notes = ""
    @State private var reminderSelection: ReminderOption = .fifteenMinutesBefore
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    private let reminderOptions: [ReminderOption] = [
        .none, .atTime, .fiveMinutesBefore, .tenMinutesBefore, .fifteenMinutesBefore, .thirtyMinutesBefore, .oneHourBefore
    ]
    
    init(mapItem: MKMapItem, tripId: String, onSave: @escaping (Location) -> Void) {
        self.mapItem = mapItem
        self.tripId = tripId
        self.onSave = onSave
        _locationName = State(initialValue: mapItem.name ?? "")
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
                            
                            if let address = mapItem.placemark.title {
                                HStack(spacing: 12) {
                                    Image(systemName: "map")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.orange)
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                }
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
                        
                        // Reminder Picker
                        HStack(spacing: 12) {
                            Image(systemName: "bell")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.orange)
                            Picker("Reminder", selection: $reminderSelection) {
                                ForEach(reminderOptions, id: \ .self) { option in
                                    Text(option.displayText).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        
                        // Reminder Card (show selected)
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "bell")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reminder")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Text(reminderSelection.displayText)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        Button(action: saveLocation) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.white)
                                Text("Add to Trip")
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
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Location Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
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
        
        let location = Location(
            id: UUID().uuidString,
            name: locationName,
            startDate: startDate,
            endDate: endDate,
            transportation: transportation,
            coordinates: GeoPoint(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            ),
            notes: notes,
            createdAt: Date(),
            tripId: tripId,
            reminderOffset: reminderSelection.offset
        )
        
        onSave(location)
        presentationMode.wrappedValue.dismiss()
    }
} 
