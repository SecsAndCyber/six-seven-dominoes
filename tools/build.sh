#! /bin/bash

scriptDir=$(dirname "$0")
rootDir=$(realpath "$scriptDir/..")

exportHtml5Dir="$rootDir/exports/HTML5"
exportAndroidDir="$rootDir/exports/Android"

mkdir -p "$exportHtml5Dir"
mkdir -p "$exportAndroidDir"

godot4.5 --editor --path $rootDir --export-release "Web" $exportHtml5Dir/index.html
godot4.5 --editor --path $rootDir --export-release "Android" $exportAndroidDir/67Dominos.aab