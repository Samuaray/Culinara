import SwiftUI
import SwiftData

struct SubstitutionView: View {
    @Environment(\.dismiss) private var dismiss

    let ingredient: Ingredient

    @State private var substitutions: [Substitution] = []
    @State private var isLoading = false
    @State private var selectedConstraints: Set<SubstitutionConstraint> = []
    @State private var errorMessage: String?

    @StateObject private var geminiService = GeminiService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Magic Substitution")
                                .font(.largeTitle.weight(.bold))
                        }

                        Text("Find alternatives for")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(ingredient.item)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                    }

                    // Constraints
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dietary Constraints (Optional)")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(SubstitutionConstraint.allCases, id: \.self) { constraint in
                                ConstraintChip(
                                    constraint: constraint,
                                    isSelected: selectedConstraints.contains(constraint)
                                ) {
                                    if selectedConstraints.contains(constraint) {
                                        selectedConstraints.remove(constraint)
                                    } else {
                                        selectedConstraints.insert(constraint)
                                    }
                                }
                            }
                        }
                    }

                    // Find Substitutions Button
                    Button {
                        findSubstitutions()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }

                            Text(isLoading ? "Finding..." : "Find Substitutions")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading)

                    // Error Message
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Substitutions List
                    if !substitutions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Substitutions")
                                .font(.headline)

                            ForEach(substitutions) { substitution in
                                SubstitutionCard(substitution: substitution)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func findSubstitutions() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let results = try await geminiService.findSubstitutions(
                    for: ingredient.item,
                    constraints: Array(selectedConstraints).map { $0.rawValue }
                )

                await MainActor.run {
                    substitutions = results
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Substitution Card

struct SubstitutionCard: View {
    let substitution: Substitution

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(substitution.alternative)
                        .font(.headline)

                    Text(substitution.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(substitution.category.color.opacity(0.2))
                        .foregroundStyle(substitution.category.color)
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            Text(substitution.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                // Apply substitution
            } label: {
                Text("Use This")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Constraint Chip

struct ConstraintChip: View {
    let constraint: SubstitutionConstraint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: constraint.icon)
                    .font(.caption)
                Text(constraint.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for index in row.range {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)

                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )

                x += size.width + spacing
            }

            y += row.height + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(range: 0..<0, height: 0)
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && !currentRow.range.isEmpty {
                rows.append(currentRow)
                currentRow = Row(range: index..<index, height: 0)
                x = 0
            }

            currentRow.range = currentRow.range.lowerBound..<(index + 1)
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }

        if !currentRow.range.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var range: Range<Int>
        var height: CGFloat
    }
}

// MARK: - Supporting Types

struct Substitution: Identifiable {
    let id = UUID()
    let original: String
    let alternative: String
    let reason: String
    let category: SubstitutionCategory
}

enum SubstitutionCategory: String, Codable {
    case vegan = "Vegan"
    case kosher = "Kosher"
    case allergy = "Allergy"
    case preference = "Preference"
    case availability = "Availability"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .vegan: return .green
        case .kosher: return .blue
        case .allergy: return .red
        case .preference: return .orange
        case .availability: return .purple
        }
    }
}

enum SubstitutionConstraint: String, CaseIterable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case kosher = "Kosher"
    case halal = "Halal"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .vegan, .vegetarian: return "leaf.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .nutFree: return "allergens"
        case .kosher: return "k.circle.fill"
        case .halal: return "h.circle.fill"
        }
    }
}

#Preview {
    let ingredient = Ingredient(item: "Heavy Cream", quantity: 1, unit: "cup")
    return SubstitutionView(ingredient: ingredient)
}
