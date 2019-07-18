.PHONY: build
build: cuttsv

cuttsv:	cut.c
	gcc -Wall -std=c99 -O3 -o $@ $^


.PHONY: clean
clean:
	rm -f cuttsv
