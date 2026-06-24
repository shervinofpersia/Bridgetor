#!/bin/bash

# Color Palette
ORANGE='\033[38;5;208m'
GRAY='\033[90m'
WHITE='\033[97m'
RESET='\033[0m'

clear
echo -e "${ORANGE}[*] Checking prerequisites...${RESET}"

# Auto-install Python if missing
if ! command -v python &> /dev/null; then
    echo -e "${GRAY}[!] Python not found. Installing automatically...${RESET}"
    pkg update -y && pkg install python -y
fi

# Auto-request storage permission if not granted
if [ ! -w "/storage/emulated/0/Download" ]; then
    echo -e "${ORANGE}[!] Requesting storage access... Please grant it on your phone popup.${RESET}"
    termux-setup-storage
    sleep 3
fi

# Execute embedded Python script
python -c '
import urllib.request
import socket
import re
import os

# Terminal Colors
O = "\033[38;5;208m" # Orange
G = "\033[90m"       # Gray
W = "\033[97m"       # White
R = "\033[0m"        # Reset

SOURCES = [
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/obfs4_tested.txt",
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/webtunnel_tested.txt",
    "https://raw.githubusercontent.com/Delta-Kronecker/Tor-Bridges-Collector/main/vanilla_tested.txt"
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
        with urllib.request.urlopen(req, timeout=15) as response:
            return response.read().decode("utf-8")
    except Exception as e:
        print(f"{O}❌ Error fetching {b_type}: {e}{R}")
        return ""

def test_tcp_connection(ip, port, timeout=5, retries=2):
    for _ in range(retries):
        try:
            with socket.create_connection((ip, port), timeout=timeout):
                return True
        except (socket.timeout, socket.error):
            continue
    return False

def main():
    print_banner()
    working_bridges = []
    
    for source in SOURCES:
        data = fetch_bridges(source)
        if not data:
            continue

        b_type = source.split("/")[-1].replace("_tested.txt", "").upper()
        print(f"{W}🔍 Testing {O}{b_type}{W} connections...{R}")
        
        for line in data.strip().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
                
            match = re.search(r"\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)\b", line)
            if match:
                ip, port = match.groups()
                port = int(port)
                
                if test_tcp_connection(ip, port):
                    print(f"{W}   [{O}ACTIVE{W}] {G}{ip}:{port}{R}")
                    working_bridges.append(line)

        print(f"{G}-------------------------------------------------{R}")

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
        print(f"{O}⚠️ No active bridges found.{R}\n")

if __name__ == "__main__":
    main()
'
