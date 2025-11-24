import SwiftUI

struct RootTabView: View {
    let settingsViewModel: SettingsViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .navigationTitle(Strings.Home.title)
            }
            .tabItem {
                Image(systemName: "house")
                Text(Strings.Tabs.home)
            }

            NavigationStack {
                SettingsView(viewModel: settingsViewModel)
                    .navigationTitle(Strings.Settings.title)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text(Strings.Tabs.settings)
            }
        }
        .tint(.white)
    }
}


