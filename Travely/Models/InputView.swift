//
//  InputView.swift
//  Travely
//
//  Created by Phat is here on 5/1/25.

// InputView for SignIn/SignUp components

import SwiftUI
struct InputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.custom("Inter-Regular", size: 17))
                .foregroundColor(.gray)

            if isSecureField {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputView(text: .constant(""), title: "Email Address", placeholder: "name@example.com")
    }
}
