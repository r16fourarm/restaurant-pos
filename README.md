<!-- # restaurant_pos

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference. -->
# Restaurant POS

A cross-platform Point of Sale (POS) system for restaurants, built with Flutter.  
Supports **Windows** and **Android**. Includes product management, order handling, billing, and export features.  
Currently in beta testing.

---

## Features

- Product & category management
- Add-on (extra item) integration for products
- Cart & order workflow (add, edit, checkout)
- Bill/history management with filtering/grouping
- Daily recap/export to CSV
- User-friendly interface
- Beta feedback integration

---

## Screenshots

<!-- Add screenshots here (optional) -->
![Order Screen](screenshots/order_screen.png)
![Cart Screen](screenshots/cart_screen.png)

---

## Installation

### Windows

1. Download and extract the provided Release zip **or** run the installer.
2. Open the `Release` folder and double-click `restaurant_pos.exe`.
3. For beta: Run as normal user (no need for admin rights).
4. If SmartScreen blocks, click "More info" > "Run anyway".

### Android

1. Download `app-release.apk` from the shared link or release page.
2. Copy the APK to your Android device.
3. Tap to install (enable "Install from unknown sources" if prompted).
4. Open the app from your app drawer.

---

## Usage

1. **Add products:**  
   Use the product management menu to create/edit/delete products and categories.

2. **Create orders:**  
   Add items to cart, apply add-ons if needed, and proceed to checkout.

3. **Manage bills/history:**  
   View paid/unpaid orders, filter and group by date or status.

4. **Export daily recap:**  
   Use the recap feature to export sales data to CSV for reporting.

5. **Feedback:**  
   Fill out the [Google Feedback Form](https://docs.google.com/forms/d/e/1FAIpQLSfBFYPHooDOInXRSlnc0bhfbAzWIQXpfPP2dHOL54UBXyKmTw/viewform) after testing.

---

## Requirements

- Flutter SDK (2.x or newer recommended)
- Dart SDK
- Hive (for local storage)
- (For Windows) Windows 10 or newer
- (For Android) Android 7.0 (Nougat) or newer

---

## Development

**Run locally (for developers):**
```sh
flutter pub get
flutter run
