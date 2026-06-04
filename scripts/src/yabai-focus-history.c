#define _POSIX_C_SOURCE 200809L

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

#define YABAI_PATH "/opt/homebrew/bin/yabai"
#define MAX_PATH_LEN 4096
#define MAX_LINE_LEN 128
#define MAX_HISTORY 16
#define QUERY_BUF_SIZE 16384

static int join_path(char *out, size_t out_size, const char *a, const char *b) {
    int written = snprintf(out, out_size, "%s/%s", a, b);
    return written > 0 && (size_t)written < out_size ? 0 : -1;
}

static int ensure_dir(const char *path) {
    if (mkdir(path, 0700) == 0 || errno == EEXIST) {
        return 0;
    }
    return -1;
}

static int state_root(char *out, size_t out_size, int create) {
    const char *xdg = getenv("XDG_STATE_HOME");
    const char *home = getenv("HOME");
    char base[MAX_PATH_LEN];

    if (xdg && xdg[0] != '\0') {
        if (snprintf(base, sizeof(base), "%s", xdg) >= (int)sizeof(base)) {
            return -1;
        }
    } else {
        if (!home || home[0] == '\0') {
            return -1;
        }
        if (snprintf(base, sizeof(base), "%s/.local/state", home) >= (int)sizeof(base)) {
            return -1;
        }
    }

    if (create && ensure_dir(base) != 0) {
        return -1;
    }

    if (join_path(out, out_size, base, "yabai-focus-history") != 0) {
        return -1;
    }

    if (create && ensure_dir(out) != 0) {
        return -1;
    }

    return 0;
}

static int current_space_path(char *out, size_t out_size, int create) {
    char root[MAX_PATH_LEN];
    if (state_root(root, sizeof(root), create) != 0) {
        return -1;
    }
    return join_path(out, out_size, root, "current-space");
}

static int histories_dir_path(char *out, size_t out_size, int create) {
    char root[MAX_PATH_LEN];
    if (state_root(root, sizeof(root), create) != 0) {
        return -1;
    }
    if (join_path(out, out_size, root, "spaces") != 0) {
        return -1;
    }
    if (create && ensure_dir(out) != 0) {
        return -1;
    }
    return 0;
}

static int history_path(char *out, size_t out_size, const char *space_id, int create) {
    char histories[MAX_PATH_LEN];
    if (histories_dir_path(histories, sizeof(histories), create) != 0) {
        return -1;
    }
    return join_path(out, out_size, histories, space_id);
}

static int write_text_file(const char *path, const char *text) {
    char tmp[MAX_PATH_LEN];
    int written = snprintf(tmp, sizeof(tmp), "%s.tmp.%ld", path, (long)getpid());
    if (written <= 0 || (size_t)written >= sizeof(tmp)) {
        return -1;
    }

    FILE *file = fopen(tmp, "w");
    if (!file) {
        return -1;
    }
    if (fputs(text, file) == EOF || fclose(file) != 0) {
        unlink(tmp);
        return -1;
    }
    if (rename(tmp, path) != 0) {
        unlink(tmp);
        return -1;
    }
    return 0;
}

static int read_first_line(const char *path, char *out, size_t out_size) {
    FILE *file = fopen(path, "r");
    if (!file) {
        return -1;
    }
    if (!fgets(out, (int)out_size, file)) {
        fclose(file);
        return -1;
    }
    fclose(file);
    out[strcspn(out, "\r\n")] = '\0';
    return out[0] != '\0' ? 0 : -1;
}

static int valid_id(const char *id) {
    if (!id || id[0] == '\0') {
        return 0;
    }
    for (const char *p = id; *p; p++) {
        if (!isdigit((unsigned char)*p)) {
            return 0;
        }
    }
    return 1;
}

static int capture_command(const char *command, char *out, size_t out_size) {
    FILE *pipe = popen(command, "r");
    size_t used = 0;
    int status;

    if (!pipe) {
        return -1;
    }
    while (used + 1 < out_size) {
        size_t read_count = fread(out + used, 1, out_size - used - 1, pipe);
        used += read_count;
        if (read_count == 0) {
            break;
        }
    }
    out[used] = '\0';
    status = pclose(pipe);
    return status == 0 ? 0 : -1;
}

static int parse_json_number(const char *json, const char *key, char *out, size_t out_size) {
    char pattern[64];
    const char *found;
    const char *cursor;
    size_t len = 0;

    if (snprintf(pattern, sizeof(pattern), "\"%s\"", key) >= (int)sizeof(pattern)) {
        return -1;
    }

    found = strstr(json, pattern);
    if (!found) {
        return -1;
    }
    cursor = strchr(found, ':');
    if (!cursor) {
        return -1;
    }
    cursor++;
    while (*cursor && isspace((unsigned char)*cursor)) {
        cursor++;
    }
    while (isdigit((unsigned char)cursor[len])) {
        len++;
    }
    if (len == 0 || len + 1 > out_size) {
        return -1;
    }
    memcpy(out, cursor, len);
    out[len] = '\0';
    return 0;
}

static int query_current_space(char *out, size_t out_size) {
    char buffer[QUERY_BUF_SIZE];
    if (capture_command(YABAI_PATH " -m query --spaces --space", buffer, sizeof(buffer)) != 0) {
        return -1;
    }
    return parse_json_number(buffer, "id", out, out_size);
}

static int query_current_window(char *out, size_t out_size) {
    char buffer[QUERY_BUF_SIZE];
    if (capture_command(YABAI_PATH " -m query --windows --window", buffer, sizeof(buffer)) != 0) {
        return -1;
    }
    return parse_json_number(buffer, "id", out, out_size);
}

static int write_current_space(const char *space_id) {
    char path[MAX_PATH_LEN];
    char contents[MAX_LINE_LEN];
    if (!valid_id(space_id) || current_space_path(path, sizeof(path), 1) != 0) {
        return -1;
    }
    if (snprintf(contents, sizeof(contents), "%s\n", space_id) >= (int)sizeof(contents)) {
        return -1;
    }
    return write_text_file(path, contents);
}

static int read_current_space(char *out, size_t out_size) {
    char path[MAX_PATH_LEN];
    if (current_space_path(path, sizeof(path), 0) != 0 || read_first_line(path, out, out_size) != 0) {
        if (query_current_space(out, out_size) != 0) {
            return -1;
        }
        (void)write_current_space(out);
    }
    return valid_id(out) ? 0 : -1;
}

static int read_history(const char *space_id, char lines[MAX_HISTORY][MAX_LINE_LEN]) {
    char path[MAX_PATH_LEN];
    FILE *file;
    int count = 0;

    if (history_path(path, sizeof(path), space_id, 0) != 0) {
        return 0;
    }

    file = fopen(path, "r");
    if (!file) {
        return 0;
    }

    while (count < MAX_HISTORY && fgets(lines[count], MAX_LINE_LEN, file)) {
        lines[count][strcspn(lines[count], "\r\n")] = '\0';
        if (valid_id(lines[count])) {
            count++;
        }
    }

    fclose(file);
    return count;
}

static int write_history(const char *space_id, char lines[MAX_HISTORY][MAX_LINE_LEN], int count) {
    char path[MAX_PATH_LEN];
    char contents[MAX_HISTORY * MAX_LINE_LEN];
    size_t used = 0;

    if (history_path(path, sizeof(path), space_id, 1) != 0) {
        return -1;
    }

    contents[0] = '\0';
    for (int i = 0; i < count; i++) {
        int written = snprintf(contents + used, sizeof(contents) - used, "%s\n", lines[i]);
        if (written <= 0 || (size_t)written >= sizeof(contents) - used) {
            return -1;
        }
        used += (size_t)written;
    }

    return write_text_file(path, contents);
}

static int remove_window_from_history(const char *space_id, const char *window_id) {
    char lines[MAX_HISTORY][MAX_LINE_LEN];
    char updated[MAX_HISTORY][MAX_LINE_LEN];
    int count;
    int out_count = 0;
    int removed = 0;

    if (!valid_id(space_id) || !valid_id(window_id)) {
        return -1;
    }

    count = read_history(space_id, lines);
    for (int i = 0; i < count; i++) {
        if (strcmp(lines[i], window_id) == 0) {
            removed = 1;
            continue;
        }
        snprintf(updated[out_count++], MAX_LINE_LEN, "%s", lines[i]);
    }

    if (!removed) {
        return 0;
    }
    return write_history(space_id, updated, out_count);
}

static int remove_window_from_all_histories(const char *window_id) {
    char histories[MAX_PATH_LEN];
    DIR *dir;
    struct dirent *entry;
    int result = 0;

    if (!valid_id(window_id)) {
        return -1;
    }
    if (histories_dir_path(histories, sizeof(histories), 0) != 0) {
        return -1;
    }

    dir = opendir(histories);
    if (!dir) {
        return errno == ENOENT ? 0 : -1;
    }

    while ((entry = readdir(dir)) != NULL) {
        if (!valid_id(entry->d_name)) {
            continue;
        }
        if (remove_window_from_history(entry->d_name, window_id) != 0) {
            result = -1;
        }
    }

    if (closedir(dir) != 0) {
        result = -1;
    }
    return result;
}

static int remove_space_history(const char *space_id) {
    char path[MAX_PATH_LEN];

    if (!valid_id(space_id) || history_path(path, sizeof(path), space_id, 0) != 0) {
        return -1;
    }
    if (unlink(path) == 0 || errno == ENOENT) {
        return 0;
    }
    return -1;
}

static int record_window(const char *window_id) {
    char space_id[MAX_LINE_LEN];
    char lines[MAX_HISTORY][MAX_LINE_LEN];
    char updated[MAX_HISTORY][MAX_LINE_LEN];
    int count;
    int out_count = 0;

    if (!valid_id(window_id) || read_current_space(space_id, sizeof(space_id)) != 0) {
        return -1;
    }

    if (remove_window_from_all_histories(window_id) != 0) {
        return -1;
    }

    count = read_history(space_id, lines);
    snprintf(updated[out_count++], MAX_LINE_LEN, "%s", window_id);

    for (int i = 0; i < count && out_count < MAX_HISTORY; i++) {
        if (strcmp(lines[i], window_id) != 0) {
            snprintf(updated[out_count++], MAX_LINE_LEN, "%s", lines[i]);
        }
    }

    return write_history(space_id, updated, out_count);
}

static int focus_window(const char *window_id) {
    pid_t pid;
    int status;
    char *argv[] = {
        (char *)YABAI_PATH,
        "-m",
        "window",
        (char *)window_id,
        "--focus",
        NULL,
    };

    if (posix_spawn(&pid, YABAI_PATH, NULL, NULL, argv, environ) != 0) {
        return -1;
    }
    if (waitpid(pid, &status, 0) < 0) {
        return -1;
    }
    return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
}

static int undo_focus(void) {
    char space_id[MAX_LINE_LEN];
    char lines[MAX_HISTORY][MAX_LINE_LEN];
    int count;

    if (read_current_space(space_id, sizeof(space_id)) != 0) {
        return -1;
    }

    count = read_history(space_id, lines);
    if (count < 2) {
        return -1;
    }

    for (int i = 1; i < count; i++) {
        if (strcmp(lines[i], lines[0]) == 0) {
            continue;
        }
        if (focus_window(lines[i]) == 0) {
            (void)record_window(lines[i]);
            return 0;
        }
        (void)remove_window_from_all_histories(lines[i]);
    }

    return -1;
}

static int set_current_space(const char *space_id) {
    char window_id[MAX_LINE_LEN];

    if (write_current_space(space_id) != 0) {
        return -1;
    }
    if (query_current_window(window_id, sizeof(window_id)) == 0) {
        return record_window(window_id);
    }
    return 0;
}

static int sync_state(void) {
    char space_id[MAX_LINE_LEN];
    char window_id[MAX_LINE_LEN];
    int result;

    if (query_current_space(space_id, sizeof(space_id)) != 0) {
        return -1;
    }
    result = write_current_space(space_id);

    if (query_current_window(window_id, sizeof(window_id)) == 0) {
        result = record_window(window_id) == 0 ? result : -1;
    }

    return result;
}

static void usage(const char *program) {
    fprintf(stderr, "Usage: %s sync | space <space-id> | window <window-id> | remove-window <window-id> | remove-space <space-id> | undo\n", program);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        usage(argv[0]);
        return 2;
    }

    if (strcmp(argv[1], "sync") == 0) {
        return sync_state() == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "space") == 0 && argc == 3) {
        return set_current_space(argv[2]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "window") == 0 && argc == 3) {
        return record_window(argv[2]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "remove-window") == 0 && argc == 3) {
        return remove_window_from_all_histories(argv[2]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "remove-space") == 0 && argc == 3) {
        return remove_space_history(argv[2]) == 0 ? 0 : 1;
    }
    if (strcmp(argv[1], "undo") == 0) {
        return undo_focus() == 0 ? 0 : 1;
    }

    usage(argv[0]);
    return 2;
}
