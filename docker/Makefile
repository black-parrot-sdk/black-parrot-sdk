
# These are convenience targets because I can't be bothered to remember docker commands
# Change the hardcoded names if you want to use these for whatever reason

build:
	docker build -t registry.gitlab.com/dpetrisko/black-parrot-sdk .

push: build
	docker push registry.gitlab.com/dpetrisko/black-parrot-sdk

run:
	docker run -it registry.gitlab.com/dpetrisko/black-parrot-sdk
