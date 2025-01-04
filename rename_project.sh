#!/bin/bash

# Rename directories
mv JumpMan FrogMan
cd FrogMan
mv JumpMan FrogMan

# Rename .xcodeproj
mv JumpMan.xcodeproj FrogMan.xcodeproj

# Update project.pbxproj
sed -i '' 's/JumpMan/FrogMan/g' FrogMan.xcodeproj/project.pbxproj

# Update Info.plist
sed -i '' 's/JumpMan/FrogMan/g' FrogMan/Info.plist

# Update bundle identifier in project settings
sed -i '' 's/com\.yourcompany\.JumpMan/com.yourcompany.FrogMan/g' FrogMan.xcodeproj/project.pbxproj 