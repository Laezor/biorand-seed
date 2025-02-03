# BIORAND Randomizer Seed Generator

#### This PowerShell script automates the process of generating and downloading randomized seeds for Resident Evil games.

---

## Features

- Support for multiple Resident Evil games:
  - **Resident Evil 4 Remake**
  - **Resident Evil 2 Remake**
- Multiple randomizer profiles for each game
- Automatic configuration management
- Seed generation and downloading
- Automatic unzipping to correct game directory
- Running latest version every time through run-online.ps1

---

## Prerequisites

- PowerShell 5.1 or higher (recommended to have powershell 7)
- A Biorand account
- Resident Evil game(s):
  - Resident Evil 4 Remake
  - Resident Evil 2 Remake (Must have Early Access to generate seeds)

---

## Usage

1. **Run the Script**

   [⬇️ Download run-online.bat](https://raw.githubusercontent.com/Laezor/biorand-seed/refs/heads/main/run-online.bat)

   Simply download and double-click `run-online.bat` (Recommended)

   ```batch
   run-online.bat
   ```

   or manually run the PowerShell script:

   ```powershell
   .\biorand-seed.ps1
   ```

2. **Login to Biorand**

   - If no API token is found in the configuration file, the script will prompt you to log in using your Biorand email and verification code.

3. **Select Game and Profile**

   - Choose which game you want to randomize (RE4R or RE2R)
   - Select from available randomizer profiles for the chosen game
   - The script will handle downloading and installing to the correct game directory

4. **Configuration**

   The script will create a `biorand-config.json` file to store:
   - Your Biorand API token
   - RE4 Remake installation path
   - RE2 Remake installation path

---

## Support

For help and updates, visit:
- RE4R: https://re4r.biorand.net
- RE2R: https://re2r.biorand.net

---

## License

MIT License - see LICENSE file for details.

---

## Credits

- Script Author: Laezor
- Contact: Laezor#5385 on Discord
- Source Site: https://re4r.biorand.net/ (without this it wouldn't be possible to create this!)

---

## Notes

- Ensure your Resident Evil game installations are valid and accessible (verify your game files through steam).
- Have fun exploring new randomized experiences in Resident Evil games!
