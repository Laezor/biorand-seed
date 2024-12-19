# BIORAND Randomizer Seed Generator

#### This PowerShell script automates the process of generating and downloading randomized seeds for Resident Evil 4 Remake.
---

## Features
- Support for various randomizer profiles:
  - **Main Game - Balanced Combat Randomizer** by 7rayD
  - **Main Game - Challenging Randomizer** by 7rayD
  - **Separate Ways - Challenging (WIP)** by 7rayD
  - **Separate Ways - Balanced (WIP)** by 7rayD
- Automatic configuration management.
- Seed generation and downloading.
- Automatic unzipping.

---

## Prerequisites
- PowerShell 5.1 or higher.
- A Biorand account.
- Resident Evil 4 Remake Game.

---

## Usage

1. **Clone/Download and Run the Script**
   ```powershell
   .\biorand-seed.ps1
   ```
2. **Login to Biorand**
   - If no API token is found in the configuration file, the script will prompt you to log in using your Biorand email and verification code.

3. **Select a Randomizer Profile**
   - Choose a profile from the displayed list by entering its ID.

4. **Generate and Download a Seed**
   - The script will generate a random seed, query its status, and download the seed zip file upon completion.

5. **Unzip and Install the Seed**
   - The script will automatically unzip the seed into the specified Resident Evil 4 installation directory.

---

## Profiles and IDs
| Profile Name                                       | ID    |
|---------------------------------------------------|-------|
| Main Game - Balanced Combat Randomizer by 7rayD   | 7     |
| Main Game - Challenging Randomizer by 7rayD       | 455   |
| Separate Ways - Challenging (WIP) by 7rayD        | 9919  |
| Separate Ways - Balanced (WIP) by 7rayD           | 10415 |

---

## Configuration File
The `reseed-config.json` file contains the following fields:
```json
{
    "RE4InstallPath": "C:\\Path\\To\\RE4\\Install",
    "BiorandToken": ""
}
```
- **`RE4InstallPath`**: The full path to your Resident Evil 4 Remake installation directory.
- **`BiorandToken`**: Your API token for the Biorand service.


---

## License
This project is licensed under the MIT License. See the script header for details.

---

## Credits
- Script Author: Laezor
- Contact: Laezor#5385 on Discord
- Source Site: https://re4r.biorand.net/ (without this it wouldn't be possible to create this!)

---

## Notes
- Ensure your Resident Evil 4 Remake installation is valid and accessible (verify your game files through steam).
- Have fun exploring new randomized experiences in Resident Evil 4 Remake!

