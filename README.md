# **🚕 Cab Aggregator \- Flutter Frontend**

This is the mobile application client built using Flutter/Dart for the Cab Aggregator project. It consumes data from a separate Spring Boot backend service to compare real-time fare estimates from various ride-sharing providers (Uber, Ola, Rapido, etc.).

## **✨ Features**

* **Location Picker:** Seamlessly select pickup and drop-off locations.  
* **Fare Comparison:** Sends coordinates to the backend API and displays a list of aggregated fare quotes.  
* **Provider Filtering:** Displays ride types, estimated fares, distance, and duration for multiple providers.  
* **Responsive UI:** Designed for modern Android and iOS devices.

## **⚙️ Prerequisites**

Before you begin, ensure you have the following installed on your machine:

* **Flutter SDK:** Latest Stable Channel.  
* **Dart SDK:** Included with Flutter.  
* **Git:** For cloning the repository.  
* **VS Code or IntelliJ IDEA:** With the Flutter/Dart plugins installed.  
* **Spring Boot Backend:** The associated backend application must be running locally on port 8080 (or the port specified in your .env file).

## **🚀 Setup and Run Locally**

Follow these steps to get your local development environment running.

### **1\. Clone the Repository**

git clone \<your-frontend-repo-url\>  
cd cab-aggregator-flutter-app

### **2\. Install Dependencies**

Install all necessary Dart packages defined in pubspec.yaml:

flutter pub get

### **3\. Configure the Backend API URL**

The application expects the backend API URL to be set in a local environment file.

1. Create a file named **.env** in the root directory of this Flutter project.  
2. Add the BACKEND\_URL variable to this file. The value depends on your testing environment:

| Testing Environment | BACKEND\_URL Value |
| :---- | :---- |
| **Android Emulator** | http://10.0.2.2:8080 |
| **Physical Android Device** | http://\[Your-Local-IPv4-Address\]:8080 |

**Example .env file content (for Android Emulator):**

BACKEND\_URL=\[http://10.0.2.2:8080\](http://10.0.2.2:8080)  
\# Optional: Set this to 'true' to use the mock data instead of calling the API  
USE\_MOCK=false

### **4\. Run the Application**

Ensure your Spring Boot backend is already running (e.g., using mvn spring-boot:run).

Start the Flutter application on your target device or emulator:

flutter run

## **📦 API Communication Details**

The application uses an **HTTP POST** request to communicate with the backend, sending coordinates in a JSON body.

* **Endpoint:** /api/v1/compare  
* **Method:** POST  
* **Request Body (JSON):**  
  {  
      "fromLat": 12.9716,  
      "fromLon": 77.5946,  
      "toLat": 13.0475,  
      "toLon": 77.6067  
  }

* **Timeout:** The client is configured with a **20-second timeout** to accommodate multiple simultaneous third-party API calls made by the Spring Boot service.