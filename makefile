SRC = StayPut/AppDelegate.swift \
      StayPut/ContentView.swift \
      StayPut/DisplayConfig.swift \
      StayPut/Info.plist \
      StayPut/Process.swift \
      StayPut/Window.swift \
      StayPut/Assets.xcassets/AppIcon.appiconset/Contents.json \
      $(wildcard StayPut/Assets.xcassets/AppIcon.apiconset/*.png) \
      StayPut/Assets.xcassets/Icon.imageset/Contents.json \
      $(wildcard StayPut/Assets.xcassets/Icon.imageset/*.png)

build/Release/StayPut.app/Contents/MacOS/StayPut: $(SRC)
	xcodebuild
