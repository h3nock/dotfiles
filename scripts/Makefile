CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -std=c11

BIN_DIR := scripts
SRC_DIR := src

.PHONY: all clean test

all: $(BIN_DIR)/yabai-focus-history

$(BIN_DIR)/yabai-focus-history: $(SRC_DIR)/yabai-focus-history.c
	$(CC) $(CFLAGS) -o $@ $<

test: $(BIN_DIR)/yabai-focus-history
	@tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	root="$$tmp/yabai-focus-history"; \
	mkdir -p "$$root"; \
	printf '4\n' > "$$root/current-space"; \
	XDG_STATE_HOME="$$tmp" $(BIN_DIR)/yabai-focus-history window 111; \
	printf '5\n' > "$$root/current-space"; \
	XDG_STATE_HOME="$$tmp" $(BIN_DIR)/yabai-focus-history window 111; \
	space4="$$root/spaces/4"; \
	space5="$$root/spaces/5"; \
	if [ -f "$$space4" ] && grep -qx '111' "$$space4"; then \
		echo "window remained in old space"; \
		exit 1; \
	fi; \
	if ! grep -qx '111' "$$space5"; then \
		echo "window missing from new space"; \
		exit 1; \
	fi; \
	XDG_STATE_HOME="$$tmp" $(BIN_DIR)/yabai-focus-history remove-window 111; \
	if grep -qrx '111' "$$root/spaces" 2>/dev/null; then \
		echo "remove-window left stale id"; \
		exit 1; \
	fi; \
	XDG_STATE_HOME="$$tmp" $(BIN_DIR)/yabai-focus-history remove-space 5; \
	if [ -e "$$space5" ]; then \
		echo "remove-space left history file"; \
		exit 1; \
	fi; \
	printf 'yabai-focus-history tests passed\n'

clean:
	rm -f $(BIN_DIR)/yabai-focus-history
