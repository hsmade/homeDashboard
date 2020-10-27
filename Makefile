VERSION=$(shell grep "^version:" pubspec.yaml | cut -d' ' -f2)
.PHONY: build

build:
	flutter build apk ${VERSION}

release:
	git push
	git tag v${VERSION}
	git push --tags
