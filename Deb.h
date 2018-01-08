
// MT, 2016feb29

#ifndef MT_DEB
#define MT_DEB

#include <stdio.h>

#ifdef NDEBUG
    #define MT_DEB_ACTIVE 0
#else
    #define MT_DEB_ACTIVE 1
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Original source code: http://stackoverflow.com/questions/1644868/c-define-macro-for-debug-printing
//
#define Deb_line(fmt, ...) \
    do \
    { \
        if(MT_DEB_ACTIVE) \
        { \
            fprintf( \
                stderr, \
                "DEBUG: %s, %d, %s() : " fmt "\n", \
                __FILE__, \
                __LINE__, \
                __func__, \
                ##__VA_ARGS__); \
        } \
    }while(0);

#ifdef __cplusplus
}
#endif

#endif // MT_DEBUG
