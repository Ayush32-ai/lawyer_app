# LawyerFinder App

A modern, user-friendly mobile application built with Flutter that helps users find and connect with lawyers quickly and easily.

## Features

### 🏠 Home/Splash Screen
- **Beautiful gradient design** with app logo and branding
- **Clear call-to-action buttons**:
  - "Find a Lawyer Now"
  - "Upload & Send Documents"
  - "Login / Sign Up" (optional)
- **Modern UI** with smooth animations

### 📍 Location Input
- **GPS Integration**: Automatically detect user's current location
- **Manual Entry**: Option to enter address manually
- **Permission Handling**: Proper location permission requests
- **Clean Interface**: Easy-to-use location selection

### 🏢 Main Dashboard
- **Two main action cards**:
  - **Find a Lawyer**: Search by specialty and availability
  - **Upload Documents**: Secure document sharing
- **Location Display**: Shows current selected location
- **Quick Actions**: Recent activity and saved lawyers

### 🔍 Lawyer Search Interface
- **Dual View Options**:
  - **List View**: Detailed lawyer cards with ratings and info
  - **Map View**: Geographic lawyer locations (placeholder)
- **Advanced Filtering**:
  - Filter by legal specialization
  - Filter by availability status
- **Lawyer Information Display**:
  - Name, specialty, experience
  - Distance from user location
  - Availability status
  - Star ratings and reviews
  - Consultation fees

### 👨‍💼 Lawyer Profile & Contact
- **Comprehensive Profile Display**:
  - Professional photo placeholder
  - Years of experience
  - Detailed bio and background
  - Specializations and expertise areas
  - Client ratings and reviews
- **Multiple Contact Options**:
  - **Phone Call**: Direct calling functionality
  - **Chat**: In-app messaging (placeholder)
  - **Video Call**: Video consultation (placeholder)
  - **Appointment Booking**: Schedule meetings
- **Document Upload**: Send documents before consultation

### 📄 Document Upload Interface
- **Secure File Upload**:
  - Support for PDF, DOC, DOCX, JPG, PNG
  - Multiple document slots
  - File size and type validation
- **Document Management**:
  - Add descriptions and notes
  - Remove uploaded files
  - Add additional document slots
- **Progress Tracking**: Upload progress indication

### 📅 Booking & Confirmation
- **Smart Scheduling**:
  - Calendar date selection
  - Available time slots
  - Appointment type selection (Video/Phone/In-person)
- **Booking Summary**:
  - Complete appointment details
  - Lawyer information
  - Fee breakdown
- **Document Upload Prompt**: Option to upload documents before meeting

### 🙏 Thank You & Feedback
- **Success Confirmation**: Animated success screen
- **Rating System**: 5-star rating for lawyer/service
- **Feedback Collection**: Optional text feedback
- **Return Navigation**: Easy return to home screen

## Technical Features

### 🛠️ Built With
- **Flutter**: Cross-platform mobile development
- **Google Fonts**: Beautiful typography (Roboto, Montserrat)
- **Material Design**: Modern, clean UI components

### 📱 Dependencies
- `geolocator`: GPS location services
- `permission_handler`: Runtime permission management
- `file_picker`: Document file selection
- `url_launcher`: Phone calls and email integration
- `google_fonts`: Custom font integration

### 🎨 UI/UX Features
- **Consistent Design**: Material Design 3 principles
- **Responsive Layout**: Works on all screen sizes
- **Smooth Animations**: Loading states and transitions
- **Intuitive Navigation**: Clear user flow
- **Accessibility**: Proper color contrast and touch targets

### 🔒 Security & Privacy
- **Secure Document Upload**: Safe file handling
- **Permission Management**: Proper location and file permissions
- **Data Validation**: Input validation and error handling

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / Xcode for device testing

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd lawyer_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
- Update `android/app/src/main/AndroidManifest.xml` for location permissions
- Configure file provider for document uploads

#### iOS
- Update `ios/Runner/Info.plist` for location and photo permissions
- Configure camera and photo library usage descriptions

## App Architecture

### Directory Structure
```
lib/
├── main.dart              # App entry point
├── models/
│   └── lawyer.dart        # Lawyer data model
├── screens/
│   ├── splash_screen.dart           # Home/Splash screen
│   ├── location_input_screen.dart   # Location selection
│   ├── dashboard_screen.dart        # Main dashboard
│   ├── lawyer_search_screen.dart    # Search interface
│   ├── lawyer_profile_screen.dart   # Lawyer details
│   ├── document_upload_screen.dart  # File upload
│   ├── booking_confirmation_screen.dart # Appointments
│   └── thank_you_screen.dart        # Success/Feedback
└── widgets/
    └── custom_card.dart     # Reusable components
```

### User Flow
1. **Splash Screen** → Location Input
2. **Location Input** → Main Dashboard
3. **Dashboard** → Find Lawyer OR Upload Documents
4. **Find Lawyer** → Search Results → Lawyer Profile → Contact/Book
5. **Upload Documents** → File Selection → Submission → Thank You
6. **Booking** → Date/Time Selection → Confirmation → Thank You

## Features in Development
- 🔐 User authentication and profiles
- 💬 Real-time chat messaging
- 📹 Video calling integration
- 🗺️ Interactive map with lawyer locations
- 💳 Payment processing
- 📊 Advanced analytics and reporting
- 🔔 Push notifications
- 📱 Offline mode support

## Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

---

**LawyerFinder** - Find a Lawyer Fast, Anytime, Anywhere 🏛️⚖️