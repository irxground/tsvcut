#include <stdio.h>
#include <string.h>

int find_index(char *heystack, char *needle) {
	int index = 0;
	size_t needle_len = strlen(needle);
	size_t len = strlen(heystack);
	while (1) {
		char *pos = (char*)memchr(heystack, '\t', len);
		if (pos == NULL) {
			if (heystack[len - 1] == '\n') len--;
			if (heystack[len - 1] == '\r') len--;
			if (needle_len == len && strncmp(needle, heystack, needle_len) == 0) {
				return index;
			}
			break;
		}
		size_t diff = pos - heystack;
		if (diff == needle_len && strncmp(needle, heystack, needle_len) == 0) {
			return index;
		}
		index++;
		diff++;
		len -= diff;
		heystack += diff;
	}
	return -1;
}

char buff[1024 * 1024];
int main(int argc, char** argv) {
	if (argc <= 1) {
		fprintf(stderr, "Field name is required.\n");
		return 1;
	}
	char *field = argv[1];
	if (fgets(buff, sizeof(buff), stdin) == NULL) {
		fprintf(stderr, "Fail to read first line.\n");
		return 1;
	}
	char c = buff[sizeof(buff) - 2];
	if (c != '\0' && c != '\n') {
		fprintf(stderr, "First line is too long.\n");
		return 1;
	}
	int index = find_index(buff, field);
	if (index < 0) {
		fprintf(stderr, "Field name `%s` is not found.\n", field);
		return 1;
	}
	fputs(field, stdout);
	fputc('\n', stdout);
	while (1) {
		if (fgets(buff, sizeof(buff), stdin) == NULL) {
			break;
		}
		char *heystack = buff;
		size_t len = strlen(heystack);
		for (int i = 0; i < index; i++) {
			char *pos = memchr(heystack, '\t', len);
			if (pos == NULL) {
				heystack = NULL;
				break;
			}
			pos++;
			len -= (pos - heystack);
			heystack = pos;
		}
		if (heystack != NULL) {
			char* pos = memchr(heystack, '\t', len);
			if (pos == NULL) {
				if (heystack[len - 1] == '\n') len--;
				if (heystack[len - 1] == '\r') len--;
			} else {
				len = (pos - heystack);
			}
			fwrite(heystack, 1, len, stdout);
		}
		fputc('\n', stdout);
	}
}
