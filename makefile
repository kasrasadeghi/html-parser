build:
	rdmd --build-only main.d; mv main html-parser

test:
	rdmd main.d tests/new-tab.html
