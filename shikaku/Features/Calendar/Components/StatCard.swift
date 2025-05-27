//
//  StatCard.swift
//  shikaku
//
//  Created by Hugo Peyron on 27/05/2025.
//

import SwiftUI

#Preview {
  StatCard(value: 45, label: "Test", icon: "sun.fill", color: .red)
}

struct StatCard: View {
  let value: Int
  let label: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(color)

      Text("\(value)")
        .font(.title3)
        .fontWeight(.medium)
        .monospacedDigit()

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
    )
  }
}
