build:
	docker build -t konradmalik/deenv .
buildx:
	docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t konradmalik/deenv .
