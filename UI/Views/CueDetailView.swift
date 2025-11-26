import SwiftUI

struct CueDetailView: View {
    let cue: Cue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(cue.content.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(cue.content.details.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                        let trimmed = line.trimmingCharacters(in: .whitespaces)

                        if trimmed.hasPrefix("### ") {
                            // Heading level 3
                            Text(String(trimmed.dropFirst(4)))
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                        } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
                            // Bullet item
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.body)
                                Text(String(trimmed.dropFirst(2)))
                                    .font(.body)
                            }
                            .foregroundColor(AppColors.textPrimary)
                        } else if trimmed.isEmpty {
                            // Preserve spacing between paragraphs
                            Spacer().frame(height: 4)
                        } else {
                            // Regular paragraph
                            Text(trimmed)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(AppColors.darkBeige)
            .cornerRadius(12)
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.CueDetail.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
