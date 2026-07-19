# TuneSpace

TuneSpace is a Flutter booking app for music studios. The app helps users find studio spaces, make bookings, upload payment proof, and track booking status in one place.

## Features

- Browse available studios with pricing and details
- Book studio sessions by selecting date, time, and duration
- Upload payment proof directly from the app
- View booking status and history
- Separate experience for admin users and normal users

## Run the app

1. Install Flutter and required tools.
2. Open the project in your IDE.
3. Run `flutter pub get`.
4. Start the app with `flutter run`.

## Notes

The app uses Supabase for authentication, profile management, and booking storage. Make sure the Supabase configuration in `lib/core/config/supabase_config.dart` is set correctly before running.
