    //
    //  StyleButton.swift
    //  Travely
    //
    //  Created by Phat is here on 5/10/25.
    //

    import SwiftUI

    // Custom button styles
    struct PrimaryButtonStyle: ButtonStyle {
        var color: Color
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(height: 36)
                .padding(.horizontal, 20)
                .background(color)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        }
    }

    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline)
                .foregroundColor(.red)
                .frame(height: 36)
                .padding(.horizontal, 20)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(height: 36)
                .padding(.horizontal, 20)
                .background(Color.gray)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        }
    }


#Preview {
    VStack(spacing: 16) {
        Button("Destructive Button") {}
            .buttonStyle(DestructiveButtonStyle())

        Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
            .padding()
            .background(Color.white)

        Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle(color: .orange))
            .padding()
            .background(Color.white)
    }
    .padding()
    .background(Color(white: 0.95))
}

