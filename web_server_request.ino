#include <WiFiS3.h>
#include <DHT.h>

const char ssid[] = "TP-Link_3934";  // Change your network SSID (name)
const char pass[] = "123456";      // Change your network password (use for WPA, or use as a key for WEP)

int status = WL_IDLE_STATUS;
WiFiServer server(80);

#define DHTPIN 2       // Define the pin where the DHT22 sensor is connected
#define DHTTYPE DHT22  // DHT 22 (AM2302)

DHT dht(DHTPIN, DHTTYPE);
unsigned long previousMillis = 0;
const long interval = 7000; // Update every 7 seconds (7000 milliseconds)

void setup() {
  // Initialize serial and wait for port to open:
  Serial.begin(9600);

  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION)
    Serial.println("Please upgrade the firmware");

  // Attempt to connect to the WiFi network:
  while (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network. Change this line if using an open or WEP network:
    status = WiFi.begin(ssid, pass);

    // Wait 10 seconds for connection:
    delay(10000);
  }
  server.begin();
  dht.begin();
  // You're connected now, so print out the status:
  printWifiStatus();
}

void loop() {
  // Check if it's time to update the sensor values
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    // Save the last time the values were updated
    previousMillis = currentMillis;

    // Read sensor values
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();

    // Print to Serial Monitor
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.print("°C, Humidity: ");
    Serial.print(humidity);
    Serial.println("%");

    // Listen for incoming clients
    WiFiClient client = server.available();
    if (client) {
      // Read the HTTP request header line by line
      while (client.connected()) {
        if (client.available()) {
          String HTTP_header = client.readStringUntil('\n');  // Read the header line of the HTTP request

          if (HTTP_header.equals("\r"))  // The end of the HTTP request
            break;
        }
      }

      // Send the HTTP response
      // Send the HTTP response header
      client.println("HTTP/1.1 200 OK");
      client.println("Content-Type: text/html");
      client.println("Connection: close");  // The connection will be closed after the completion of the response
      client.println("Refresh: 7");         // Auto-refresh the page every 7 seconds
      client.println();                     // The separator between HTTP header and body
      // Send the HTTP response body
      client.println("<!DOCTYPE HTML>");
      client.println("<html>");
      client.println("<head>");
      client.println("<link rel=\"icon\" href=\"data:,\">");
      client.println("</head>");

      client.println("<p>");

      client.print("Temperature: <span style=\"color: red;\">");
      client.print(temperature, 2);
      client.println("&deg;C</span>");
      client.print("<br>Humidity: <span style=\"color: blue;\">");
      client.print(humidity, 2);
      client.print("%</span>");

      client.println("</p>");
      client.println("</html>");
      client.flush();

      // Give the web browser time to receive the data
      delay(10);

      // Close the connection:
      client.stop();
    }
  }
}

void printWifiStatus() {
  // Print your board's IP address:
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  // Print the received signal strength:
  Serial.print("Signal strength (RSSI):");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
}
