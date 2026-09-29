GDK-Proton based off of https://github.com/Weather-OS/GDK-Proton with custom WineGDK patches from https://github.com/LukasPAH/WineGDK.

**Improvements over GDK-Proton:**
- Stubs for the windows application runtime for games that require the bootstrap and no major sdk calls.
- libcurl-4.dll bundled and renamed as XCurl.dll for games needing patched XCurl.
- Build script for generating Proton.
- Additional GDK component stubs.

**Steps for games needing a XCurl.dll replacement (example: Minecraft):**

1: Locate where your game has been downloaded.

2: Remove XCurl.dll.

**For Minecraft Bedrock builds:**

- Be sure to delete the bundled Microsoft.WindowsAppRuntime.Bootstrap.dll.
- Prior to signing in:
    - In the game files, locate MicrosoftGame.Config. Open it in a text editor.
    - Locate the TitleId and MSAAppId tags in the XML. Change TitleId to be 67b57dac, and change MSAAppID to be 0000000048183522 (these are the title ID and the application ID of Android Minecraft which allow the bundled xgameruntime to interact with online services; you do not need to own the Android version to use this).

**Signing in:**
- Obtain SSL certificates from https://curl.se/ca/cacert.pem and rename this file to ca-bundle.crt
- Locate your game's executable.
- Create a folder named etc, and under that folder create another folder named ssl, and under the ssl folder, create a certs folder.
- Move ca-bundle.crt to this new certs folder. if you've done everything correctly, your file structure should look a bit like the following image:
<img width="772" height="240" alt="image" src="https://github.com/user-attachments/assets/4169461e-627e-4808-bed5-cb28206f3229" />

- The first time you launch the game and attempt to sign in using the in-game user interface, a JSON file will be written to disk at the same directory where the etc folder exists that contain your ssl certificates. Open this JSON file. If you are unable to find this file, you can also open the proton log and find the trace that contains the url and user code (the line will contain the text OnRemoteConnectShow).
- In a web browser, navigate to the url listed in verification_url in the JSON file. Enter the user_code in the box at the following screen and login as normal.
- When finished, you should be authenticated and allowed to use online services.
