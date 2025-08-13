/* Minimal ltdl.h stub for Android builds */
#ifndef LTDL_H
#define LTDL_H

typedef void* lt_dlhandle;
typedef void* lt_ptr;

#define LTDL_SHLIB_EXT ".so"

int lt_dlinit(void);
int lt_dlexit(void);
lt_dlhandle lt_dlopen(const char *filename);
lt_dlhandle lt_dlopenext(const char *filename);
int lt_dlclose(lt_dlhandle handle);
void* lt_dlsym(lt_dlhandle handle, const char *name);
const char* lt_dlerror(void);
int lt_dladdsearchdir(const char *search_dir);
int lt_dlforeachfile(const char *search_path, int (*func)(const char *filename, lt_ptr data), lt_ptr data);

#endif /* LTDL_H */