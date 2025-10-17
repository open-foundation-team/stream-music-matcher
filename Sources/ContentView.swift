import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Music Stream Matcher")
                .font(.title)
                .padding()
            
            Text("This app runs in the menu bar")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}