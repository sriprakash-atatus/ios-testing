#!/bin/bash

if [ ! -f "Package.swift" ]; then
    echo "\`install-xcode-templates.sh\` must be run in repository root folder: \`./tools/xcode-templates/install-xcode-templates.sh\`"
    exit 1
fi

SOURCE_TEMPLATES_LOCATION="./tools/xcode-templates/Atatus/"
TARGET_TEMPLATES_LOCATION="$HOME/Library/Developer/Xcode/Templates/File Templates/Atatus"

rm -r "$TARGET_TEMPLATES_LOCATION" 2> /dev/null
mkdir -p "$TARGET_TEMPLATES_LOCATION"
cp -R "$SOURCE_TEMPLATES_LOCATION" "$TARGET_TEMPLATES_LOCATION"

echo "✅ Atatus templates copied to: $TARGET_TEMPLATES_LOCATION"

exit 0
