#!/bin/bash

# Check if a root directory argument was provided
if [ -z "$1" ]; then
    echo "Error: Root directory argument is required."
    exit 1
fi

ROOT_DIR=$1

# Ensure the script is being run from the root of the Flutter project
if [ ! -d "$ROOT_DIR/ios" ]; then
    echo "Error: This script must be run from the root of your Flutter project."
    exit 1
fi

# Path to the Runner scheme file
SCHEME_FILE="$ROOT_DIR/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"

if [ ! -f "$SCHEME_FILE" ]; then
    echo "Error: Runner.xcscheme file not found. Please ensure you have opened the iOS project in Xcode at least once."
    exit 1
fi

# Add pre-actions build script to the Runner scheme
if ! grep -q "entry_decode" "$SCHEME_FILE"; then
    echo "Adding pre-actions build script to Runner scheme..."

    # Backup the original file
    cp "$SCHEME_FILE" "$SCHEME_FILE.bak"

    # Insert the PreActions block after <BuildAction> tag
    awk '
    /<\/BuildAction>/ {
        print "      <PreActions>"
        print "         <ExecutionAction"
        print "            ActionType = \"Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction\">"
        print "            <ActionContent"
        print "               title = \"Run Script\""
        print "               scriptText = \"#!/bin/sh&#10;&#10;function entry_decode() { echo &quot;${*}&quot; | base64 --decode; }&#10;&#10;IFS=&apos;,&apos; read -r -a define_items &lt;&lt;&lt; &quot;$DART_DEFINES&quot;&#10;&#10;for index in &quot;${!define_items[@]}&quot;&#10;do&#10;    define_items[$index]=$(entry_decode &quot;${define_items[$index]}&quot;);&#10;done&#10;&#10;printf &quot;%s\\n&quot; &quot;${define_items[@]}&quot; &gt; ${SRCROOT}/Flutter/Environment.xcconfig&#10;\">"
        print "               <EnvironmentBuildable>"
        print "                  <BuildableReference"
        print "                     BuildableIdentifier = \"primary\""
        print "                     BlueprintIdentifier = \"\""
        print "                     BuildableName = \"Runner.app\""
        print "                     BlueprintName = \"Runner\""
        print "                     ReferencedContainer = \"container:Runner.xcodeproj\">"
        print "                  </BuildableReference>"
        print "               </EnvironmentBuildable>"
        print "            </ActionContent>"
        print "         </ExecutionAction>"
        print "      </PreActions>"
    }
    { print $0 }
    ' "$SCHEME_FILE.bak" > "$SCHEME_FILE"

    echo "Pre-actions build script added successfully."
else
    echo "Pre-actions build script already exists in Runner scheme."
fi

# Add include statement to Debug.xcconfig and Release.xcconfig
for CONFIG in Debug Release; do
    CONFIG_FILE="$ROOT_DIR/ios/Flutter/${CONFIG}.xcconfig"
    if [ -f "$CONFIG_FILE" ]; then
        if ! grep -q "#include \"Environment.xcconfig\"" "$CONFIG_FILE"; then
            echo "#include \"Environment.xcconfig\"" >> "$CONFIG_FILE"
            echo "Added include statement to $CONFIG_FILE."
        else
            echo "Include statement already exists in $CONFIG_FILE."
        fi
    else
        echo "Error: $CONFIG_FILE not found."
    fi
done

echo "iOS environment setup completed."