
// MT, 2015oct26

#ifndef MT_SYS
#define MT_SYS

#include <stdbool.h>
#include <stdint.h>

#ifdef	__cplusplus
extern "C" {
#endif //__cplusplus

bool Sys_is_big_endian();

uint64_t Sys_get_posix_clock_time_ms();

/** Return "time" string.
 *
 * - Caller takes ownership of return value.
 */
char* Sys_create_time_str(bool const inDate, bool const inSeconds);

/** Return what is entered into stdin up to ENTER keypress.
 *
 * - Caller takes ownership of return value.
 */
char* Sys_get_stdin();

/** Print given (maybe formatted) string to stdout with leading time (and data and/or seconds, if wanted).
 *
 * - Automatically add '\n' ("line"..).
 */
void Sys_log_line(bool const inDate, bool const inSeconds, char const * const inStr, ...);

#ifdef	__cplusplus
}
#endif //__cplusplus

#endif //MT_SYS
