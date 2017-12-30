
// MT, 2016mar19

#ifndef MT_FILESYS
#define MT_FILESYS

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

enum FileSys_EntryType
{
    FileSys_EntryType_Invalid = -1,
    FileSys_EntryType_Unsupported = 0,
    FileSys_EntryType_File = 1,
    FileSys_EntryType_Dir = 2
};

/** Concatenates given strings and adds directory separator between them
 *  (e.g.: inPath=="/home/marc", inName=="readme.txt" => return value "/home/marc/readme.txt").
 *
 *  - Caller takes ownership of returned value.
 */
char * FileSys_GetFullPath(char const * const inPath, char const * const inName);

/** Get absolute path (e.g. inPath=="../some_folder" => return value "/home/marc/some_folder").
 *
 * - If realpath() is not found, try to disable __STRICT_ANSI__ (e.g. by setting compiler parameter -std=gnu11).
 * - Caller takes ownership of returned pointer.
 */
char * FileSys_GetAbsPath(char const * const inPath);

/** Return entry type.
 *
 * - If optional inOutFileSize pointer given is not NULL and entry type is FileSys_EntryType_File,
 *   it will be filled with the file's size.
 */
enum FileSys_EntryType FileSys_GetEntryType(char const * const inPath, off_t * const inOutFileSize);

off_t FileSys_GetFileSize(char const * const inPath);

/** Sets given bool pointer's value to true,
 *  if the file at both paths given is the same (not a copy, actually the same entry in file system).
 *
 *  - Returns true, if no error occurred, false otherwise.
 *  * Differentiates between links and files!
 */
bool FileSys_arePathsToSameFile(char const * const inA, char const * const inB, bool * const inOutSame);

bool FileSys_exists(char const * const inPath, bool * const inOutExists);

bool FileSys_isDirEmpty(char const * const inPath, bool * const inOutEmpty);

/** Deletes what is found at given path.
 *
 *  - Removes folder with its content (recursively), if given path is a directory.
 */
bool FileSys_delete(char const * const inPath);

/** Copy file at given input path to output path.
 *
 *  * Overwrites existing file.
 *  - Returns false, if given paths lead to the same file.
 *  - Output path must already include the destination file's name.
 */
bool FileSys_copyFile(char const * const inInputPath, char const * const inOutputPath);

/** Copy what is found at given input to given output path.
 *
 *  - If there is a folder at given input path, this folder and its content (recursively) will be created at output path.
 *  - Returns false, if given paths lead to the same file/folder.
 *  - Output path must already include the destination file's/folder's name.
 */
bool FileSys_copy(char const * const inInputPath, char const * const inOutputPath);

/** Return count of files and folder inside directory at given path.
 *
 * * Make sure that optionally given pointer to full size count variable is set to 0.
 * - Optionally given increment function pointer will be called each time the content count gets incremented.
 * - Returns -1 on error.
 */
int FileSys_getContentCount(char const * const inPath, off_t * const inOutSize, void (*inIncrementFunc)(void));

/** Return content of file at given path.
 *
 *  - Returns NULL on error.
 *  - Caller takes ownership of return value.
 */
unsigned char * FileSys_loadFile(
    char const * const inPath, off_t * const inOutSize);

#ifdef __cplusplus
}
#endif

#endif // MT_FILESYS
