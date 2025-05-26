//
//  StatItem.swift
//  shikaku
//
//  Created by Hugo Peyron on 26/05/2025.
//


import SwiftUI
import SwiftData

struct StatItem: View {
  let value: Int
  let label: String

  var body: some View {
    VStack(spacing: 8) {
      Text("\(value)")
        .font(.title)
        .fontWeight(.regular)
        .contentTransition(.numericText())

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
  }
}
