# Introduction :

The system is a comprehensive, user-friendly, and highly interactive program designed to provide a seamless gesture-controlled interface for Spotify. It is composed of several modules, each with a specific function, working in harmony to deliver a superior user experience.

The first module, gesture_recognition.py, is the heart of the system. It uses advanced algorithms to recognize a user's hand gestures. The gestures can be used to perform a variety of functions, such as adjusting the volume, playing or pausing songs, and navigating between songs. This provides a hands-free and intuitive way for users to control their Spotify playback.

The second module, main.py, serves as the gateway to the system. It is responsible for authenticating the user and initiating the gesture control process. Once the user is authenticated, it captures the user's gestures and sends them to the gesture_recognition.py module for interpretation.

The third module, spotify_functions.py, is the bridge between the system and the Spotify API. It contains a set of functions that interact with the Spotify API to control the user's playback based on the interpreted gestures. These functions include adjusting the volume, playing or pausing music, skipping to the next song, and going back to the previous song.

In essence, this system is a blend of cutting-edge technology and user-centric design, aimed at enhancing the Spotify experience by introducing a novel, gesture-based control mechanism.

# Full System Overview

![diagram](./High_Level_Doc-1.svg)
# Module Overview
## Module: gesture_recognition.py
- **Module Name**: gesture_recognition.py

- **Primary Objectives**: This module is designed to recognize hand gestures and perform various functions, such as adjusting the volume, playing or pausing songs, and navigating between songs in Spotify.

- **Critical Functions**: 
  - `start_capture()`: This is the main function in the module. It starts capturing video from the webcam, detects hand landmarks using the MediaPipe library, interprets the hand gestures, and performs the corresponding Spotify functions.

- **Key Variables**: 
  - `mp_hand_drawing`, `mp_hands`: Used for drawing hand landmarks and hand tracking.
  - `mediaCap`: Captures video feed from the webcam.
  - `max_distance`, `play_pause_active`, `next_prev_active`: Used for volume control and to avoid repeated play/pause and next/prev song actions.
  - `finger_tip_ids`, `finger_count`, `finger_up`: Used to track the position and movement of fingers.
  - `thumb_tip_x`, `thumb_tip_y`, `index_tip_x`, `index_tip_y`, `thumb_index_distance`: Used to calculate the distance between thumb and index finger for volume control.

- **Interdependencies**: This module interacts with the `mediapipe` library for hand tracking and the `spotify_functions` module for controlling Spotify.

- **Core vs. Auxiliary Operations**: 
  - Core operations include capturing video from the webcam, detecting hand landmarks, interpreting hand gestures, and performing corresponding Spotify functions.
  - Auxiliary operations include drawing hand landmarks on the captured video and displaying the video with overlaid information.

- **Operational Sequence**: The module starts by capturing video from the webcam. It then processes each frame to detect hand landmarks. Based on the detected landmarks, it interprets the hand gestures and performs the corresponding Spotify functions. It also overlays the video with hand landmarks and other information before displaying it.

- **Performance Aspects**: The performance of this module largely depends on the accuracy of the hand tracking and gesture recognition, the responsiveness of the Spotify functions, and the processing speed of the video frames.

- **Reusability**: This module can be adapted for use with other applications that can be controlled through hand gestures. However, the gesture interpretation and the corresponding functions would need to be modified accordingly.

- **Usage**: This module is used to control Spotify through hand gestures. It can be run as a standalone script that starts when the user wants to control Spotify using hand gestures.

- **Assumptions**: 
  - It assumes that the webcam is working properly and can capture video.
  - It assumes that the MediaPipe library can accurately track hand landmarks.
  - It assumes that the user's hand gestures follow the pre-defined patterns for the Spotify functions.
## Mermaid Diagram
![diagram](./High_Level_Doc-2.svg)
## Module: main.py
- **Module Name**: The module is main.py.

- **Primary Objectives**: The main purpose of this module is to authenticate the user, start the gesture control and capture the user's gestures.

- **Critical Functions**: 
  - `sf.get_user()`: This function is used to get the username and trigger account authentication.
  - `gr.start_capture()`: This function is used to start capturing the user's gestures.

- **Key Variables**: 
  - `username`: This variable stores the username returned by the `sf.get_user()` function.

- **Interdependencies**: This module depends on two other modules: 
  - `gesture_recognition` module for capturing the user's gestures.
  - `spotify_functions` module for getting the user's username and triggering account authentication.

- **Core vs. Auxiliary Operations**: 
  - Core Operations: Getting the username, triggering account authentication, and starting gesture capture.
  - Auxiliary Operations: Printing the username.

- **Operational Sequence**: The module first imports the necessary modules. It then triggers account authentication by getting the username using the `sf.get_user()` function. After that, it starts capturing the user's gestures using the `gr.start_capture()` function.

- **Performance Aspects**: Performance considerations would primarily be the efficiency and accuracy of the gesture recognition and the speed of the authentication process.

- **Reusability**: The gesture recognition and spotify functions are encapsulated in their respective modules, which makes them reusable. The main module can also be adapted to use different recognition or function modules.

- **Usage**: This module is used to authenticate a user and start capturing their gestures for control purposes.

- **Assumptions**: 
  - The `sf.get_user()` function will successfully authenticate the user and return a valid username.
  - The `gr.start_capture()` function will successfully start capturing the user's gestures.
  - The necessary modules `gesture_recognition` and `spotify_functions` are correctly implemented and imported.
## Mermaid Diagram
![diagram](./High_Level_Doc-3.svg)
## Module: spotify_functions.py
- **Module Name**: The module name is `spotify_functions.py`.

- **Primary Objectives**: The module's purpose is to interact with the Spotify API to manage and control a user's Spotify playback. It provides functions to adjust volume, play or pause music, skip to the next song, and go back to the previous song.

- **Critical Functions**:
    - `get_user()`: Retrieves the current user's Spotify username.
    - `adjust_volume(vol_percent)`: Adjusts the volume of the user's Spotify playback.
    - `play_pause()`: Toggles between playing and pausing the user's Spotify playback based on the current playback status.
    - `next_song()`: Skips to the next song in the user's Spotify queue.
    - `prev_song()`: Returns to the previous song in the user's Spotify queue.

- **Key Variables**:
    - `SPOTIPY_CLIENT_ID`: The Spotify API client ID.
    - `SPOTIPY_CLIENT_SECRET`: The Spotify client secret.
    - `SPOTIPY_REDIRECT_URI`: The redirect URI for Spotify OAuth.
    - `scope`: The scope of permissions for the Spotify API.
    - `sp`: The Spotipy object used to interact with the Spotify API.

- **Interdependencies**: This module depends on the Spotipy library to interact with the Spotify API.

- **Core vs. Auxiliary Operations**: Core operations include adjusting volume, playing/pausing music, and navigating through songs. Auxiliary operations include getting the current user's Spotify username.

- **Operational Sequence**: The Spotipy object is first created with the necessary credentials and scope. Then, the various functions can be called as needed to control the user's Spotify playback.

- **Performance Aspects**: Performance is largely dependent on the responsiveness of the Spotify API. Proper handling of API responses and errors can improve performance.

- **Reusability**: This module is highly reusable as it encapsulates the Spotify API's functionality into distinct functions. As long as the necessary credentials are provided, these functions can be imported and used in any other Python script.

- **Usage**: This module can be used in any Python application that needs to control Spotify playback for a user. The functions can be called directly with the necessary parameters.

- **Assumptions**: The module assumes that valid Spotify API credentials are provided and that the user has granted the necessary permissions in the defined scope. It also assumes that the user is currently playing music on Spotify for some functions to work correctly.
## Mermaid Diagram
![diagram](./High_Level_Doc-4.svg)
