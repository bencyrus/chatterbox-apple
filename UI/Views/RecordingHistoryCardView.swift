import SwiftUI

struct RecordingHistoryCardView: View {
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Cue title
            Text(recording.cue.content.title)
                .font(Typography.body.weight(.medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recording metadata
            HStack(spacing: Spacing.md) {
                // Date badge
                Badge(
                    text: formattedDate,
                    icon: "calendar",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )
                
                Spacer()
                
                // Duration badge
                Badge(
                    text: formattedDuration,
                    icon: "clock",
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.textQuaternary
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: recording.createdAt) else {
            return recording.createdAt
        }
        
        let calendar = Calendar.current
        
        // Check if today
        if calendar.isDateInToday(date) {
            return Strings.Common.today
        }
        
        // Check if yesterday
        if calendar.isDateInYesterday(date) {
            return Strings.Common.yesterday
        }
        
        // Otherwise show day month year (e.g., "7 Dec 2025")
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d MMM yyyy"
        return displayFormatter.string(from: date)
    }
    
    private var formattedDuration: String {
        // Get duration from file metadata, or show "--:--" if not available
        guard let duration = recording.file.metadata.duration else {
            return "--:--"
        }
        
        let durationInSeconds = Int(duration.rounded())
        return formatDuration(durationInSeconds)
    }
    
    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            // Show hours: h:mm:ss or hh:mm:ss
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            // No hours: just show mm:ss
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}


