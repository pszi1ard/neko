#ifndef __NEKO_LOG_H
#define __NEKO_LOG_H

/**
 * Neko log interface (log.f90)
 */

/** Write a message to a neko_log */
extern void log_message(char *msg);

/** Write an error to a neko_log */
extern void log_error(char *msg);

/** Write a warning to a neko_log */
extern void log_warning(char *msg);

#endif