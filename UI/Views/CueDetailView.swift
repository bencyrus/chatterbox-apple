import SwiftUI

struct CueDetailView: View {
    let cue: Cue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(cue.content.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(cue.content.details)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(Strings.CueDetail.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


