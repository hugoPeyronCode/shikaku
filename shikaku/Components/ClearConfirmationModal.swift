//
//  ClearConfirmationModal.swift
//  shikaku
//
//  Created by Hugo Peyron on 24/05/2025.
//


import SwiftUI

struct ClearConfirmationModal: View {
  let onConfirm: () -> Void
  let onCancel: () -> Void

  var body: some View {
    ZStack {
      // Background overlay
      Rectangle()
        .fill(.black.opacity(0.3))
        .ignoresSafeArea()
        .onTapGesture {
          onCancel()
        }

      // Modal content
      VStack(spacing: 24) {
        // Title
        Text("Clear board?")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        // Message
        Text("This will remove all your progress on the current puzzle.")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(nil)

        // Buttons
        HStack(spacing: 12) {
          // Cancel button
          Button {
            onCancel()
          } label: {
            Text("Cancel")
              .font(.body)
              .fontWeight(.medium)
              .foregroundColor(.primary)
              .frame(maxWidth: .infinity)
              .frame(height: 44)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
              )
          }
          .sensoryFeedback(.impact(weight: .light), trigger: UUID())

          // Clear button
          Button {
            onConfirm()
          } label: {
            Text("Clear")
              .font(.body)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 44)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(.red)
              )
          }
          .sensoryFeedback(.impact(weight: .medium), trigger: UUID())
        }
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.regularMaterial)
          .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
      )
      .padding(.horizontal, 40)
    }
  }
}