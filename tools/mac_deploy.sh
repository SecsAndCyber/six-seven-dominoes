
VERSION=${VERSION:="1.0.7"}
PROJECT="67Dominos"

FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
EXPORT_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/../exports")"
ROOT_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/../")"

IOS_DIRECTORY="$(realpath "${EXPORT_DIRECTORY}/iOS")"
MAC_DIRECTORY="$(realpath "${EXPORT_DIRECTORY}/macOS")"

pushd $IOS_DIRECTORY
zip -r $EXPORT_DIRECTORY/releases/${PROJECT}.iOS.${VERSION}.zip ./*
ls -hal $EXPORT_DIRECTORY/releases/${PROJECT}.iOS.${VERSION}.zip || exit 1
rm -rf ./${PROJECT}*
popd