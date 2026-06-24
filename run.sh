#!/bin/bash

# Color Palette
ORANGE='\033[38;5;208m'
GRAY='\033[90m'
WHITE='\033[97m'
RESET='\033[0m'

clear
echo -e "${ORANGE}[*] Checking prerequisites...${RESET}"

if ! command -v python &> /dev/null; then
    echo -e "${GRAY}[!] Python not found. Installing automatically...${RESET}"
    pkg update -y && pkg install python -y
fi

if [ ! -w "/storage/emulated/0/Download" ]; then
    echo -e "${ORANGE}[!] Requesting storage access... Please grant it on your phone popup.${RESET}"
    termux-setup-storage
    sleep 3
fi

python -c '
import urllib.request
import socket
import re
import sys
import concurrent.futures

# Terminal Colors
O = "\033[38;5;208m"
G = "\033[90m"
W = "\033[97m"
R = "\033[0m"

# Corrected Paths (added /bridge/ folder)
SOURCES = [
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/bridge/obfs4_tested.txt",
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/bridge/webtunnel_tested.txt",
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/bridge/vanilla_tested.txt"
]

OUTPUT_FILE = "/storage/emulated/0/Download/active_bridges.txt"

def print_banner():
    print(f"\n{G}================================================={R}")
    print(f"{W}          TOR BRIDGES TESTER & COLLECTOR         {R}")
    print(f"{G}            Code & Signature: {O}S.O.P{G} (SHERVIN)    {R}")
    print(f"{G}================================================={R}\n")

def fetch_bridges(url):
    b_type = url.split("/")[-1].replace("_tested.txt", "").upper()
    print(f"{G}📥 Fetching {W}{b_type}{G} bridges...{R}")
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.read().decode("utf-8")
    except Exception as e:
        print(f"{O}❌ Error fetching {b_type}: {e}{R}")
        return ""

def test_connection(line):
    match = re.search(r"\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)\b", line)
    if not match:
        return None
    ip, port = match.groups()
    
    # Fast 3-second test
    try:
        with socket.create_connection((ip, int(port)), timeout=3):
            return line, ip, port
    except:
        return None

def main():
    print_banner()
    all_lines = []
    
    for source in SOURCES:
        data = fetch_bridges(source)
        if data:
            all_lines.extend([l.strip() for l in data.splitlines() if l.strip() and not l.startswith("#")])

    if not all_lines:
        print(f"\n{O}⚠️ No bridges fetched. Please check your internet connection.{R}\n")
        return

    total = len(all_lines)
    print(f"\n{W}🚀 Fetched {O}{total}{W} bridges. Starting Multi-Threaded tests...{R}\n")
    
    working_bridges = []
    done_count = 0

    # Multi-threading for maximum speed (40 concurrent threads)
    with concurrent.futures.ThreadPoolExecutor(max_workers=40) as executor:
        futures = {executor.submit(test_connection, line): line for line in all_lines}
        
        for future in concurrent.futures.as_completed(futures):
            done_count += 1
            
            # Dynamic Loading Indicator (\r\033[K clears the current line to prevent visual bugs)
            sys.stdout.write(f"\r\033[K{G}⏳ Progress: [{O}{done_count}{G}/{total}] Testing in parallel...{R}")
            sys.stdout.flush()
            
            result = future.result()
            if result:
                line, ip, port = result
                working_bridges.append(line)
                # Print the active bridge above the loading bar
                sys.stdout.write(f"\r\033[K{W}   [{O}ACTIVE{W}] {G}{ip}:{port}{R}\n")
                sys.stdout.write(f"\r\033[K{G}⏳ Progress: [{O}{done_count}{G}/{total}] Testing in parallel...{R}")
                sys.stdout.flush()

    print(f"\r\033[K{G}-------------------------------------------------{R}")

    # Output to Raw Text
    if working_bridges:
        try:
            with open(OUTPUT_FILE, "w") as f:
                for b in working_bridges:
                    f.write(b + "\n")
            print(f"{W}🎉 Done! {O}{len(working_bridges)}{W} active bridges saved.{R}")
            print(f"{G}📂 Output: {O}{OUTPUT_FILE}{R}\n")
        except PermissionError:
            print(f"\n{O}❌ Error: Storage permission denied.{R}")
    else:
        print(f"{O}⚠️ No active bridges found on your network.{R}\n")

if __name__ == "__main__":
    main()
'
