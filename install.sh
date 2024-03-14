#!/bin/bash
set -e

# Constants
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly WHITE=$(tput setaf 7)
readonly RESET=$(tput sgr0)
readonly CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
readonly X_MARK="\033[0;31m\xE2\x9C\x98\033[0m"

# Status Codes
readonly EXIT_COMMAND_NOT_FOUND=127
readonly EXIT_VERSION_FETCH_FAILED=3

print_color() {
  local color=$1
  local message=$2
  echo -ne "${color}${message}${RESET}"
}

overwrite_color() {
  local color=$1
  local message=$2
  tput cr
  tput el
  echo -e "${color}${message}${RESET}"
}

ensure_command_exists() {
  local command=$1
  local error_message=$2

  if ! command -v "$command" &>/dev/null; then
    print_color "$RED" "$X_MARK $error_message"
    exit $EXIT_COMMAND_NOT_FOUND
  fi
}

fetch_url() {
  local url=$1
  curl --silent --fail "$url"
}

download_file() {
  local url=$1
  local output_file=$2
  local pre_message=$3
  local success_message=$4
  local error_message=$5

  print_color "$WHITE" "$pre_message"
  curl -LJs --location "$url" --output "$output_file" >/dev/null 2>&1 &
  
  local curl_pid=$!

  while kill -0 $curl_pid >/dev/null 2>&1; do
    echo -n "."
    sleep 0.5
  done
  
  wait "$curl_pid"

  overwrite_color "$GREEN" "$CHECK_MARK $success_message"
}

unzip_file() {
  local zip_file=$1
  local destination_dir=$2
  local pre_message=$3
  local success_message=$4
  local error_message=$5

  print_color "$WHITE" "$pre_message"
  unzip -o -q "$zip_file" -d "$destination_dir"
  overwrite_color "$GREEN" "$CHECK_MARK $success_message"
}

cleanup() {
  rm -f "$HOME/hydrogen.zip"
  rm -rf "$HOME/hydrogen_unzip"
  rm -rf "$HOME/roblox_unzip"
  [ -d "Hydrogen.app" ] && rm -rf "Hydrogen.app"
  [ -d "Roblox.app" ] && rm -rf "Roblox.app"
}

main() {
  trap cleanup EXIT

  if [ "$(id -u)" -eq 0 ]; then print_color "$RED" "$X_MARK Please do not run as root!" >&2; exit 1; fi

  ensure_command_exists "curl" "Curl could not be found! This should never happen. Open a ticket."
  ensure_command_exists "unzip" "Unzip could not be found! This should never happen. Open a ticket."

  pkill -9 Roblox || true
  pkill -9 Hydrogen || true

  rm -rf "/Desktop/Roblox.app"
  rm -rf "/Desktop/Hydrogen.app"

  local current_version="version-2178d23686534193"
  local download_url="https://setup.rbxcdn.com/mac/version-2178d23686534193-RobloxPlayer.zip"
  print_color "$GREEN" "$CHECK_MARK Got latest version of Roblox! $download_url\n"
  local output_file="$current_version-RobloxPlayer.zip"

  download_file "$download_url" "$HOME/$output_file" "Downloading Roblox (this might take awhile)..." "Roblox has been downloaded!" "Failed to download the latest Roblox version. Please check your internet connection and try again."

  unzip_file "$output_file" "$HOME/roblox_unzip" "Unzipping Roblox..." "Unzipped Roblox!" "Failed to unzip Roblox."

  rm "$HOME/$output_file"
  #############################################################################################################################
  current_hydrogen_exec="https://github.com/retguard/bug-free-doodle/raw/main/Hydrogen.app.zip"
  #############################################################################################################################

  download_file "$current_hydrogen_exec" "$HOME/hydrogen.zip" "Downloading Hydrogen..." "Hydrogen has been downloaded!" "Failed to download the latest Hydrogen version. Please check your internet connection and try again."

  unzip_file "$HOME/hydrogen.zip" "$HOME/hydrogen_unzip" "Unzipping Hydrogen..." "Unzipped Hydrogen!" "Failed to unzip Hydrogen."

  local hydrogen_app_path="/Users/USERHERE/Desktop/Hydrogen.app"
  local roblox_app_path="/Users/USERHERE/Desktop/Roblox.app"

  [ -d "$hydrogen_app_path" ] && rm -rf "$hydrogen_app_path"
  [ -d "$roblox_app_path" ] && rm -rf "$roblox_app_path"
  
  mv "$HOME/roblox_unzip/RobloxPlayer.app" "Roblox.app"

  mv "Roblox.app" "$roblox_app_path"
  chmod -R 777 "$roblox_app_path"

  cp "$HOME/hydrogen_unzip/Hydrogen.app/Contents/Resources/libHydrogen.dylib" "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/libHydrogen.dylib"
  cp "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/RobloxPlayer" "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/.RobloxPlayer"

  "$HOME/hydrogen_unzip/Hydrogen.app/Contents/Resources/insert_dylib" --strip-codesig --all-yes "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/libHydrogen.dylib" "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/.RobloxPlayer" "/Users/USERHERE/Desktop/Roblox.app/Contents/MacOS/RobloxPlayer" >/dev/null 2>&1

  mv "$HOME/hydrogen_unzip/Hydrogen.app" "$hydrogen_app_path"
  chmod -R 777 "$hydrogen_app_path"

  mkdir -p "$HOME/Hydrogen/autoexec" "$HOME/Hydrogen/workspace" "$HOME/Hydrogen/ui/themes"
  chmod -R 777 "$HOME/Hydrogen"

  print_color "$GREEN" "Hydrogen has been installed! Enjoy!\n"
}

main "$@"
