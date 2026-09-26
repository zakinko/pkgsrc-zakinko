#include <c-stdaux.h>
#if !defined(C_OS_BSD)
#error "C_OS_BSD is not defined"
#endif
#if !defined(C_MODULE_UNIX)
#error "C_MODULE_UNIX is not defined"
#endif
int main(void) {
        int fd = -1;
        DIR *d = NULL;
        fd = c_close(fd);
        d = c_closedir(d);
        return (fd == -1 && d == NULL) ? 0 : 1;
}
