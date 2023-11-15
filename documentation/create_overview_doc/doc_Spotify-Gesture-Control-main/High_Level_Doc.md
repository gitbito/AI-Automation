# Introduction :

Our system is composed of three primary modules: gesture_recognition.py, main.py, and spotify_functions.py. 

The gesture_recognition.py module is the heart of our system, designed to interpret hand gestures as commands for controlling Spotify. It leverages the power of a webcam to capture video input, and identifies hand gestures using a machine learning solution called MediaPipe. The gestures are then mapped to various Spotify functions such as play, pause, volume control, and song navigation.

The main.py module serves as the initiating point for gesture control for a Spotify user. It integrates the capabilities of gesture recognition and Spotify control to provide a seamless user experience. 

Finally, the spotify_functions.py module is the bridge to the Spotify API. It has a suite of functions for managing user interactions with Spotify. These functions range from gathering user information to controlling playback (play, pause, next song, previous song) and adjusting the volume. 

In summary, our system is a gesture-controlled Spotify interface, designed to make the user's interaction with Spotify more intuitive and hands-free. It leverages cutting-edge machine learning techniques to recognize hand gestures, and a robust API interface to control Spotify.

# Full System Overview

# Module Overview
## Module: gesture_recognition.py
- **Module Name**: The module name is `gesture_recognition.py`.

- **Primary Objectives**: The main purpose of this module is to use hand gestures to control Spotify. It uses a webcam to capture video input, identifies hand gestures using MediaPipe, and then uses these gestures to control Spotify functions such as play/pause, volume control, and song navigation.

- **Critical Functions**: 
    - `start_capture()`: This function starts the webcam capture, processes the images, identifies hand gestures, and controls Spotify accordingly.
    - `sf.adjust_volume(vol_percent)`: Adjusts the volume of Spotify.
    - `sf.play_pause()`: Toggles play/pause on Spotify.
    - `sf.next_song()` and `sf.prev_song()`: Navigates to the next or previous song on Spotify.

- **Key Variables**: 
    - `mediaCap`: Captures video input from the webcam.
    - `max_distance`: Used for volume control.
    - `play_pause_active`, `next_prev_active`: Used to avoid repeated play/pause and song navigation actions.
    - `finger_up`: Dictionary used to detect if a finger is up or down.
    - `thumb_index_distance`: Calculates the distance between the thumb and index finger tips.
    - `volume_control_enabled`, `play_pause_gesture`, `next_song_gesture`, `previous_song_gesture`: Variables used to identify specific gestures.

- **Interdependencies**: This module interacts with the `mediapipe` library for hand gesture recognition and a `spotify_functions` module for Spotify control.

- **Core vs. Auxiliary Operations**: 
    - Core operations include capturing video input, processing the images, identifying hand gestures, and controlling Spotify.
    - Auxiliary operations include drawing hand landmarks and managing the UI (e.g., displaying volume level, showing play/pause status, etc.).

- **Operational Sequence**: The module starts by initializing the webcam capture. It then enters a loop where it reads frames from the webcam, processes the images to identify hand gestures, and uses these gestures to control Spotify. The loop continues until the 'q' key is pressed.

- **Performance Aspects**: The module's performance is largely dependent on the accuracy of the `mediapipe` hand gesture recognition and the responsiveness of the `spotify_functions` module. It also requires a webcam with good resolution and frame rate for accurate gesture recognition.

- **Reusability**: The module is specific to Spotify control, but the hand gesture recognition part can be reused for other applications. The Spotify control functions could also be replaced with other functions to control different applications.
## Mermaid Diagram
![diagram](./High_Level_Doc-1.svg)
## Module: main.py
- **Module Name**: The module is `main.py`.

- **Primary Objectives**: The primary purpose of this module is to initiate gesture control for a Spotify user. It uses gesture recognition to control the Spotify account of the user. 

- **Critical Functions**: 
  - `sf.get_user()`: This function is used to get the username and trigger account authentication.
  - `gr.start_capture()`: This function starts the gesture capturing process.

- **Key Variables**: 
  - `username`: This variable stores the username returned by the `sf.get_user()` function.

- **Interdependencies**: This module depends on two other modules: `gesture_recognition` and `spotify_functions`. It uses functions from these modules to authenticate the user and start gesture recognition.

- **Core vs. Auxiliary Operations**: 
  - Core Operations: The core operations of this module are user authentication (`sf.get_user()`) and starting the gesture capturing process (`gr.start_capture()`).
  - Auxiliary Operations: Printing the username and the statement "Starting gesture control for user: " is an auxiliary operation.

- **Operational Sequence**: The module first imports the required packages. It then uses the `get_user()` function from the `spotify_functions` module to authenticate the user and store the username. After that, it prints a statement indicating the start of the gesture control for the user. Finally, it starts the gesture capturing process using the `start_capture()` function from the `gesture_recognition` module.

- **Performance Aspects**: The performance of this module primarily depends on the efficiency of the `gesture_recognition` and `spotify_functions` modules. The speed and accuracy of the gesture recognition process and the Spotify user authentication process can affect the overall performance.

- **Reusability**: This module is quite reusable. The method of obtaining the user and starting the gesture capture can be applied to any user and any application that requires gesture recognition, not just Spotify. However, the specific functions `sf.get_user()` and `gr.start_capture()` might need to be replaced or modified based on the requirements of the new use case.
## Mermaid Diagram
![diagram](./High_Level_Doc-2.svg)
## Module: spotify_functions.py
- **Module Name**: spotify_functions.py

- **Primary Objectives**: This module's purpose is to manage Spotify user interactions through the Spotify API. It includes functions for getting user information, adjusting volume, controlling playback (play, pause, next song, previous song), and more.

- **Critical Functions**:
    - `get_user()`: Retrieves the Spotify username of the connected user.
    - `adjust_volume(vol_percent)`: Adjusts the volume to a given percentage value between 0-100.
    - `play_pause()`: Checks the user's playback status and either plays or pauses the music based on the current status.
    - `next_song()`: Skips to the next song in the queue.
    - `prev_song()`: Goes back to the previous song.

- **Key Variables**:
    - `SPOTIPY_CLIENT_ID`: The client ID for the Spotify API.
    - `SPOTIPY_CLIENT_SECRET`: The client secret for the Spotify API.
    - `SPOTIPY_REDIRECT_URI`: The redirect URI for the Spotify API.
    - `scope`: The scope defines the level of access that the app has to the user's Spotify data.

- **Interdependencies**: This module relies on the `spotipy` library, which is a lightweight Python library for the Spotify Web API.

- **Core vs. Auxiliary Operations**: Core operations include getting user information, controlling playback, and adjusting the volume. The creation of the Spotipy object and defining the scope are auxiliary operations that support the core functionality.

- **Operational Sequence**: First, the Spotipy object is created with the required credentials and scope. Then, the module provides various functions to control the user's Spotify experience, such as adjusting the volume or controlling playback.

- **Performance Aspects**: The performance of this module largely depends on the response time of the Spotify API. Efficient use of API calls and handling responses can improve the performance.

- **Reusability**: This module is highly reusable. The functions defined in this module can be reused in any application that requires control over Spotify's music playback. However, the client ID, client secret, and redirect URI must be replaced with the actual values for the application using this module.
## Mermaid Diagram
![diagram](./High_Level_Doc-3.svg)
