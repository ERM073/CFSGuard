# CFSGuard DDoS Protection Script

This script enables CloudFlare UAM (Under Attack Mode) to provide DDoS protection for your domain and server. When the script detects high traffic volume surpassing a threshold, it automatically activates UAM mode to mitigate potential DDoS attacks. Once the attack subsides, UAM mode is disabled.

## Prerequisites

- [tcpdump](https://www.tcpdump.org/)
- [jq](https://stedolan.github.io/jq/)
- [curl](https://curl.se/)

Ensure these command-line tools are installed on your system before running the script. You can install them using the package manager specific to your operating system.

## Setup

1. Clone the repository or copy the script to your local machine.
2. Open the script file in a text editor.
3. Set the `api_key` and `zone_id` variables to your CloudFlare Global API key and Zone ID, respectively.
4. Change the conditions and thresholds for enabling UAM as needed.
5. Save the changes.

By default, UAM mode is turned on when traffic exceeds 50 per second for more than 10 seconds.
After UAM is turned on, stop UAM mode 600 seconds later to see if the attack continues.

## Usage

1. Open a terminal and navigate to the directory where the script is located.
2. Run the script using the following command:

   ```bash
   chmod +x CFSGuard-en.sh
   ./CFSGuard-en.sh
   ```
   
3. The script will continuously monitor the traffic and activate UAM mode if the threshold is exceeded. You can leave the script running in the background to maintain DDoS protection.
4.To stop the script, press Ctrl + C in the terminal.

## Important Note
Closing this script will remove the DDoS protection provided by CFSGuard. Ensure that the script is running to maintain the protection.
