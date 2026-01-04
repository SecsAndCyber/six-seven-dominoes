HOST=${HOST:="molyett.com"}
DEST=${DEST:='~/www/jjg/67Dominos/'}
VERSION=${VERSION:="1.0.6"}
PROJECT="67Dominos"

FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
EXPORT_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/../exports")"
ROOT_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/../")"

HTML5_DIRECTORY="$(realpath "${EXPORT_DIRECTORY}/HTML5")"
ANDROID_DIRECTORY="$(realpath "${EXPORT_DIRECTORY}/Android")"

pushd $HTML5_DIRECTORY
zip -r $EXPORT_DIRECTORY/Releases/${PROJECT}.html5.${VERSION}.zip ./*
rsync -av ./* "$HOST:$DEST"
popd

pushd $ANDROID_DIRECTORY
mv $PROJECT.aab $EXPORT_DIRECTORY/Releases/${PROJECT}.android.${VERSION}.aab
popd
