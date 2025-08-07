# Animation Assets

## Adding Your Lottie JSON File

1. **Place your Lottie JSON file** in this directory (`assets/animations/`)
2. **Update the file path** in `chat_loading_animation.dart`:
   ```dart
   'assets/animations/your_animation_file.json'
   ```

## Current Setup

- **Fallback Animation**: If the Lottie file is not found, a custom animated chat bubble will be shown
- **Loading States**: The animation will be shown while chat data is being loaded
- **Smooth Transitions**: Beautiful fade and scale animations

## File Structure

```
assets/
  animations/
    your_animation_file.json  ← Add your Lottie file here
    README.md
```

## Features

✅ **Lottie Support**: Beautiful vector animations  
✅ **Fallback Animation**: Custom animation if Lottie file is missing  
✅ **Loading States**: Shows while fetching chat data  
✅ **Smooth Transitions**: Professional loading experience  
✅ **Error Handling**: Graceful fallback if file not found  

## Usage

The animation will automatically be used when:
- Chat data is being loaded initially
- User names are being fetched from Firestore
- Any loading state in the chat feature 