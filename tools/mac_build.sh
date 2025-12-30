godotPath="/Applications/Godot4.5.app/Contents/MacOS/Godot"

FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
ROOT_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/../")"

exportIOSDir="$ROOT_DIRECTORY/exports/iOS"
if [ -d "$exportIOSDir" ]; then
    rm -rf "${exportIOSDir:?}"/*
fi

$godotPath --editor --path $ROOT_DIRECTORY --export-release "iOS" $exportIOSDir/67dominos.ipa