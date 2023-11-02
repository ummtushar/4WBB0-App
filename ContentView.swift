import SwiftUI
import WebKit
import UserNotifications

struct ContentView: View {
    @State private var responseText = ""
    @State private var humidityThresholdString = "50"
    let arduinoIPAddress = "http://..../"
    
    let weatherAppURL = URL(string: "http://..../")!
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("Background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4, x: 0, y: 0)

                    Spacer()

                    Text(responseText)
                        .font(.title)
                        .padding()
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4, x: 0, y: 0)

                    Spacer()

                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)

                        TextField("Enter Humidity Threshold", text: $humidityThresholdString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.75)
                            .padding(.horizontal)
                            .accentColor(.blue)

                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                    }

                    Text("Humidity Threshold: \(humidityThresholdString)%")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4, x: 0, y: 0)

                    Spacer()

                    WebView(urlString: arduinoIPAddress, initialScrollOffsetX: 200)
                        .frame(height: 300)
                        .cornerRadius(10)
                }
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }
            .onAppear(perform: {
                // Monitor humidity level and send notifications
                monitorHumidity()
            })
            .statusBar(hidden: true)
        }
    }

    // Function to monitor humidity and send notifications
    func monitorHumidity() {
        guard let url = URL(string: arduinoIPAddress) else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                return
            }

            // Define the HTML patterns to extract the humidity value
            let humidityPattern = "Humidity: [0-9.]+%"
            if let range = htmlString.range(of: humidityPattern, options: .regularExpression) {
                let humidityValueString = htmlString[range]
                    .replacingOccurrences(of: "Humidity: ", with: "")
                    .replacingOccurrences(of: "%", with: "")
                if let humidityValue = Double(humidityValueString),
                   let threshold = Double(humidityThresholdString) {
                    // Update the UI on the main thread
                    DispatchQueue.main.async {
                        responseText = "Humidity: \(humidityValue)%"
                        if humidityValue > threshold {
                            sendNotification()
                        }
                    }
                } else {
                    print("Error converting humidity values to Double")
                } 
            }
        }

        task.resume()
    }

    // Function to send a notification
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Humidity Alert"
        content.body = "The humidity level has surpassed the threshold."

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    let initialScrollOffsetX: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Scroll the WebView to the initialScrollOffsetX
            let scrollPoint = CGPoint(x: parent.initialScrollOffsetX, y: 0)
            webView.scrollView.setContentOffset(scrollPoint, animated: true)
        }
    }
}
