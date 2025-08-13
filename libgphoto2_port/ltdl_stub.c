/* Minimal ltdl implementation stub for Android builds */
#include "ltdl.h"
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>

static const char* last_error = NULL;

int lt_dlinit(void) {
    return 0;
}

int lt_dlexit(void) {
    return 0;
}

lt_dlhandle lt_dlopen(const char *filename) {
    if (!filename) return NULL;
    void* handle = dlopen(filename, RTLD_LAZY);
    if (!handle) {
        last_error = dlerror();
    }
    return (lt_dlhandle)handle;
}

lt_dlhandle lt_dlopenext(const char *filename) {
    if (!filename) return NULL;
    
    // First try as-is
    void* handle = dlopen(filename, RTLD_LAZY);
    if (handle) return (lt_dlhandle)handle;
    
    // Try with .so extension
    char buf[256];
    snprintf(buf, sizeof(buf), "%s.so", filename);
    handle = dlopen(buf, RTLD_LAZY);
    if (!handle) {
        last_error = dlerror();
    }
    return (lt_dlhandle)handle;
}

int lt_dlclose(lt_dlhandle handle) {
    if (!handle) return -1;
    return dlclose((void*)handle);
}

void* lt_dlsym(lt_dlhandle handle, const char *name) {
    if (!handle || !name) return NULL;
    void* sym = dlsym((void*)handle, name);
    if (!sym) {
        last_error = dlerror();
    }
    return sym;
}

const char* lt_dlerror(void) {
    return last_error;
}

int lt_dladdsearchdir(const char *search_dir) {
    // For Android, we don't dynamically add search directories
    // This is a no-op stub
    (void)search_dir;
    return 0;
}

int lt_dlforeachfile(const char *search_path, int (*func)(const char *filename, lt_ptr data), lt_ptr data) {
    if (!search_path || !func) return -1;
    
    DIR *dir = opendir(search_path);
    if (!dir) {
        last_error = "Cannot open directory";
        return -1;
    }
    
    struct dirent *entry;
    char filepath[512];
    int result = 0;
    
    while ((entry = readdir(dir)) != NULL && result == 0) {
        // Skip . and ..
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        
        snprintf(filepath, sizeof(filepath), "%s/%s", search_path, entry->d_name);
        
        struct stat st;
        if (stat(filepath, &st) == 0 && S_ISREG(st.st_mode)) {
            // Check if it's a .so file
            const char *ext = strrchr(entry->d_name, '.');
            if (ext && strcmp(ext, ".so") == 0) {
                result = func(filepath, data);
            }
        }
    }
    
    closedir(dir);
    return result;
}