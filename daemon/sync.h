#ifndef SYNC_H
#define SYNC_H

#include <time.h>

#define TIME_MS (1000000L)
#define TIME_S (1000*(TIME_MS))

#define WAIT_TIMEOUT ((struct timespec){1, 500L*TIME_MS})

void abs_wait_timeout(struct timespec *abs_timeout);

void wait_read_barrier(void);
void notify_read_barrier(void);
void notify_data_available(void);
void notify_data_unavailable(void);

time_t wait_data_available(time_t last_data);
void notify_data_available(void);

void inc_available_handlers(void);
void dec_available_handlers(void);
unsigned int get_available_handlers(void);

void reset_ready_handlers(void);

#endif
