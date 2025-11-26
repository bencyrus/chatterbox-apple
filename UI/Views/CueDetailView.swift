import SwiftUI

struct CueDetailView: View {
    let cue: Cue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(cue.content.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(cue.content.details)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
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
