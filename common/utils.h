#ifndef UTILS_H
#define UTILS_H

ssize_t full_write(int fd, const char *buf, size_t count);
ssize_t full_read(int fd, char *buf, size_t count);

#endif
