import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    let existingHabits: [Habit]
    let habitToEdit: Habit?
    let onSave: (String, String, String, Bool) -> Void
    var onClose: (() -> Void)? = nil

    @State private var name = ""
    @State private var iconName = "figure.run"
    @State private var colorHex = AppConstants.Colors.secondaryTeal
    @State private var isActive = true

    private let iconOptions = [
        "figure.run", "book.closed.fill", "drop.fill", "heart.fill",
        "figure.mind.and.body", "moon.stars.fill", "sun.max.fill", "flame.fill",
        "music.note", "fork.knife", "dumbbell.fill", "brain.head.profile",
        "leaf.fill", "sparkles", "bolt.fill", "cup.and.saucer.fill",
        "figure.walk", "bed.double.fill"
    ]

    private let colorOptions: [String] = [
        AppConstants.Colors.premiumSkyBlue,
        AppConstants.Colors.premiumCoralRed,
        AppConstants.Colors.premiumEmerald,
        AppConstants.Colors.secondaryTeal,        // replaces premiumWarmPurple
        AppConstants.Colors.premiumSunsetOrange,
        AppConstants.Colors.premiumRosePink,
        AppConstants.Colors.premiumSteelTeal,
        AppConstants.Colors.premiumGolden
    ]

    private var trimmedName: String {
        String(name.prefix(30)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        existingHabits.contains { habit in
            guard habit.id != habitToEdit?.id else { return false }
            return habit.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !isDuplicate
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 18) {
                    nameField
                    if isDuplicate { duplicateHint }
                    iconPicker
                    colorPicker
                    previewRow
                    activeToggle
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if let habitToEdit {
                name = habitToEdit.name
                iconName = habitToEdit.iconName
                colorHex = habitToEdit.colorHex
                isActive = habitToEdit.isActive
            }
        }
        .task {
            // Auto-focus the name field after the open animation settles.
            try? await Task.sleep(for: .milliseconds(450))
            if habitToEdit == nil && name.isEmpty {
                isNameFocused = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: close) {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(habitToEdit == nil ? "New Habit" : "Edit Habit")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))

            Spacer()

            Color.clear.frame(width: 60, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Habit name")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            TextField("Read for 20 minutes", text: $name)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { isNameFocused = false }
                .onChange(of: name) { _, newValue in
                    if newValue.count > 30 {
                        name = String(newValue.prefix(30))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: AppConstants.Colors.cardSurface))
                )
                .warmCard(radius: 16, level: 1)
        }
    }

    private var duplicateHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text(AppCopy.Errors.duplicateHabit)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Color(hex: AppConstants.Colors.coral))
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Icon")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        iconName = icon
                    } label: {
                        Image(systemName: icon.validSFSymbolName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                Color(hex: iconName == icon ? AppConstants.Colors.cardSurface : AppConstants.Colors.textPrimary)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        Color(
                                            hex: iconName == icon
                                                ? AppConstants.Colors.primaryOrange
                                                : AppConstants.Colors.cardElevated
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.pressable(scale: 0.92))
                    .sensoryFeedback(.selection, trigger: iconName)
                }
            }
            .padding(12)
            .warmCard(radius: 20, level: 1)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))

            HStack(spacing: 12) {
                ForEach(colorOptions, id: \.self) { option in
                    Button {
                        colorHex = option
                    } label: {
                        Circle()
                            .fill(Color(hex: option))
                            .frame(width: 34, height: 34)
                            .overlay(
                                ZStack {
                                    Circle()
                                        .stroke(
                                            Color(
                                                hex: colorHex == option
                                                    ? AppConstants.Colors.textPrimary
                                                    : AppConstants.Colors.cardSurface
                                            ),
                                            lineWidth: colorHex == option ? 2 : 1
                                        )
                                    if colorHex == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                                    }
                                }
                            )
                    }
                    .buttonStyle(.pressable(scale: 0.88))
                    .sensoryFeedback(.selection, trigger: colorHex)
                }
            }
            .padding(12)
            .warmCard(radius: 16, level: 1)
        }
    }

    private var previewRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))

            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        HabitIconView(
                            iconName: iconName,
                            size: 18,
                            foreground: Color(hex: AppConstants.Colors.cardSurface)
                        )
                    )

                Text(trimmedName.isEmpty ? "Your habit" : trimmedName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: AppConstants.Colors.cardSurface))
            )
            .warmCard(radius: 16, level: 1)
        }
    }

    private var activeToggle: some View {
        Toggle("Active", isOn: $isActive)
            .tint(Color(hex: AppConstants.Colors.primaryOrange))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
            .padding(14)
            .warmCard(radius: 16, level: 1)
    }

    private var saveButton: some View {
        Button {
            onSave(trimmedName, iconName, colorHex, isActive)
            close()
        } label: {
            Text("Save")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: AppConstants.Colors.primaryOrange))
                )
                .shadow(color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.24), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.pressable)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.55)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: canSave)
    }

    private func close() {
        isNameFocused = false
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    HabitFormView(
        existingHabits: [],
        habitToEdit: nil,
        onSave: { _, _, _, _ in }
    )
    .modelContainer(for: [Habit.self, SpinResult.self], inMemory: true)
}
