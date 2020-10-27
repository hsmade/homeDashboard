.PHONY: build

build:
	flutter build apk $(grep "^version:" pubspec.yaml | cut -d' ' -f2)

release:
	git push
	git tag v$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
	git push --tags
