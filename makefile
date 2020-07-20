build:
	rdmd --build-only -of=main *.d && mv main html-parser

test: build
	./html-parser tests/new-tab.html

debug:
	ldc -g *.d -of main && mv main html-parser-debug
