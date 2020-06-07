setup:
	mkdir -p build
	shards

compile:
	crystal build ./src/poddodger.cr -o build/poddodger

run:
	./build/poddodger

sample-run:
	./build/poddodger -f http://pft.libsyn.com/rss
