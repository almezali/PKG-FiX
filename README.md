# Arch Linux Package Repair Script 🛠️

## Overview
A sophisticated Bash script designed to repair and reinstall broken or failed packages on Arch Linux systems.

## Features
- 🔍 Comprehensive package failure analysis
- 🚀 Automatic official package installation
- 📋 Detailed reporting system
- 🌈 Colorful console output
- 📝 Comprehensive logging capabilities

## How It Works

### Workflow Stages
1. **Environment Setup**
   - Creates working and log directories
   - Defines storage paths

2. **Package Analysis**
   - Scans failed packages
   - Categorizes packages into:
     * Official repositories
     * AUR packages
     * Packages not found in repositories
     * Packages with conflicts

3. **Package Installation**
   - Attempts automatic installation of official packages
   - Intelligently handles package conflicts

4. **Reporting**
   - Displays installation statistics
   - Identifies packages requiring manual intervention

## System Requirements
- Arch Linux
- sudo privileges
- pacman package manager
- (Optional) yay for AUR package handling

## Usage
```bash
# Requires a pkg_error.log file with list of failed packages
./package-repair-script.sh
```

## Output Details
- Creates `~/pkg_repair` directory for file storage
- Logs stored in `~/pkg_repair/logs`
- Final report displayed at script completion

## Key Technical Features
- Detailed event logging
- Progress tracking
- Automatic generation of manual installation script for AUR packages

## Contribution
Contributions, issues, and feature requests are welcome!

## License
[Free]
