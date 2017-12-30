
// MT, 2016mar19

#include <stdlib.h>
#include <limits.h>
#include <assert.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include "Deb.h"
#include "FileSys.h"

static char const * const _dir_separator = "/";
static size_t const _file_copy_buffer_size = 16*1024*1024; // 16 MB

char * FileSys_GetFullPath(char const * const inPath, char const * const inName)
{
    assert((inPath!=NULL)&&(inPath[0]!='\0'));
    assert((inName!=NULL)&&(inName[0]!='\0'));

    char * retVal = NULL;
    size_t const folderPathLen = strlen(inPath),
        pathLen = (folderPathLen+1+strlen(inName)+1)*(sizeof *retVal);

    retVal = malloc(pathLen);
    assert(retVal!=NULL);

    retVal[0] = '\0';
    strncat(retVal, inPath, pathLen);
    strncat(retVal, _dir_separator, pathLen);
    strncat(retVal, inName, pathLen);

    return retVal;
}

char * FileSys_GetAbsPath(char const * const inPath)
{
    char * retVal = malloc(PATH_MAX*(sizeof *retVal));

    assert(retVal!=NULL);

    if(realpath(inPath, retVal)==NULL)
    {
        free(retVal);
        retVal = NULL;
    }

    return retVal;
}

enum FileSys_EntryType FileSys_GetEntryType(char const * const inPath, off_t * const inOutFileSize)
{
    enum FileSys_EntryType retVal = FileSys_EntryType_Invalid;
    struct stat s;

    assert(inPath!=NULL);

    if(lstat(inPath, &s)==0) // Because entry->d_type may not work on all platforms.
    {
        if(S_ISDIR(s.st_mode))
        {
            retVal = FileSys_EntryType_Dir;
        }
        else
        {
            if(S_ISREG(s.st_mode))
            {
                retVal = FileSys_EntryType_File;

                if(inOutFileSize!=NULL)
                {
                    *inOutFileSize = s.st_size;
                }
            }
            else // Add more types, here..
            {
                retVal = FileSys_EntryType_Unsupported;
            }
        }
    }
    else
    {
        Deb_line("lstat() ERROR: %d!", errno);
        errno = 0;
    }

    return retVal;
}

/** Source: http://stackoverflow.com/questions/8236/how-do-you-determine-the-size-of-a-file-in-c
 */
off_t FileSys_GetFileSize(char const * const inPath)
{
    struct stat s;

    assert(inPath!=NULL);

    if(stat(inPath, &s)==0)
    {
        return s.st_size; // *** RETURN ***
    }

    return -1;
}

bool FileSys_arePathsToSameFile(char const * const inA, char const * const inB, bool * const inOutSame)
{
    bool retVal = true; // Indicates no error (true = no error).
    struct stat sA;

    assert(inA!=NULL);
    assert(inB!=NULL);
    assert(inOutSame!=NULL);

    *inOutSame = false;

    if(lstat(inA, &sA)==0)
    {
        struct stat sB;

        if(lstat(inB, &sB)==0)
        {
            assert(sA.st_ino!=0);
            assert(sA.st_dev!=0);
            assert(sB.st_ino!=0);
            assert(sB.st_dev!=0);

            if((sA.st_dev==sB.st_dev)&&(sA.st_ino==sB.st_ino))
            {
                *inOutSame = true;
            }
            //
            // Otherwise: Different files.
        }
        else
        {
            Deb_line("lstat() ERROR: %d!", errno);
            errno = 0;
            retVal = false; // Error!
        }
    }
    else
    {
        Deb_line("lstat() ERROR: %d!", errno);
        errno = 0;
        retVal = false; // Error!
    }

    return retVal;
}

bool FileSys_exists(char const * const inPath, bool * const inOutExists)
{
    bool retVal = true; // Indicates no error (true = no error).
    struct stat s;

    assert(inPath!=NULL);
    assert(inOutExists!=NULL);

    *inOutExists = false;

    if(lstat(inPath, &s)==0)
    {
        *inOutExists = true;
    }
    else
    {
        if(errno!=ENOENT)
        {
            Deb_line("lstat() ERROR: %d!", errno);
            retVal = false; // Unexpected error!
        }
        //
        // Otherwise: Does not exist.

        errno = 0;
    }

    return retVal;
}

/** Original source: http://stackoverflow.com/questions/6383584/check-if-a-directory-is-empty-using-c-on-linux
 */
bool FileSys_isDirEmpty(char const * const inPath, bool * const inOutEmpty)
{
    bool retVal = true; // Indicates no error (true = no error).
    DIR* d = NULL;

    assert(inPath!=NULL);
    assert(inOutEmpty!=NULL);

    *inOutEmpty = false;

    d = opendir(inPath);
    if(d!=NULL)
    {
        int n = 0;
        struct dirent * e = readdir(d);

        while(e!=NULL)
        {
            ++n;
            if(n==3) // "." & ".." are OK to be found as "entries" of an empty array.
            {
                break;
            }

            e = readdir(d);
        }
        if(errno==0)
        {
            if(n<3)
            {
                *inOutEmpty = true;
            }
        }
        else
        {
            Deb_line("readdir() ERROR: %d!", errno);
            errno = 0;
            retVal = false;
        }

        closedir(d); // (return value ignored..)
        errno = 0;
        d = NULL;
    }
    else
    {
        Deb_line("opendir() ERROR: %d!", errno);
        errno = 0;
        retVal = false;
    }

    return retVal;
}

bool FileSys_delete(char const * const inPath)
{
    bool retVal = false;

    switch(FileSys_GetEntryType(inPath, NULL))
    {
        case FileSys_EntryType_File:
            if(unlink(inPath)==0)
            {
                retVal = true;
            }
#ifndef NDEBUG
            else
            {
                Deb_line("Error: Failed to remove file \"%s\" (error %d)!", inPath, errno);
            }
#endif //NDEBUG
            errno = 0;
            break;

        case FileSys_EntryType_Dir:
        {
            DIR * const d = opendir(inPath);

            if(d!=NULL)
            {
                bool errOcc = false;
                struct dirent * e = readdir(d);

                while(e!=NULL)
                {
                    if((strcmp(e->d_name, ".")!=0)&&(strcmp(e->d_name, "..")!=0))
                    {
                        char * const fullPath = FileSys_GetFullPath(inPath, e->d_name);

                        if(!FileSys_delete(fullPath)) // *** RECURSION ***
                        {
                            errOcc = true;
                            free(fullPath);
                            break;
                        }
                        free(fullPath);
                    }

                    e = readdir(d);
                }
                if(errOcc)
                {
                    break;
                }
                if(errno==0) // For readdir().
                {
                    if(rmdir(inPath)==0)
                    {
                        retVal = true;
                    }
#ifndef NDEBUG
                    else
                    {
                        Deb_line("Error: Failed to remove folder \"%s\" (error %d)!", inPath, errno);
                    }
#endif //NDEBUG
                    errno = 0;
                }
#ifndef NDEBUG
                else
                {
                    Deb_line("Error: Failed to read an entry of folder \"%s\" (error %d)!", inPath, errno);
                }
#endif //NDEBUG
                errno = 0;

                closedir(d); // (return value ignored..)
            }
#ifndef NDEBUG
            else
            {
                Deb_line("Error: Failed to open folder \"%s\" (error %d)!", inPath, errno);
            }
#endif //NDEBUG
            errno = 0;
            break;
        }

        case FileSys_EntryType_Unsupported:
            Deb_line("Warning: Unsupported entry type received for \"%s\".", inPath);
            break;

        case FileSys_EntryType_Invalid:
            Deb_line("Error: Invalid entry type received for \"%s\".", inPath);
            break;
        default:
            Deb_line("Error: Unknown entry type received for \"%s\"!", inPath);
            break;
    }

    return retVal;
}

/** Original source: http://stackoverflow.com/questions/29079011/copy-file-function-in-c
 */
bool FileSys_copyFile(char const * const inInputPath, char const * const inOutputPath)
{
    bool retVal = false,
        outputExists = false;

    assert(inInputPath!=NULL);
    assert(inOutputPath!=NULL);

    if(FileSys_exists(inOutputPath, &outputExists))
    {
        bool sameFile = false;

        if((!outputExists)||FileSys_arePathsToSameFile(inInputPath, inOutputPath, &sameFile))
        {
            if(!sameFile)
            {
                FILE * const sRead = fopen(inInputPath, "r");

                if(sRead!=NULL)
                {
                    FILE * const sWrite = fopen(inOutputPath, "w");

                    if(sWrite!=NULL)
                    {
                        bool errOcc = false;
                        char * const buf = malloc(_file_copy_buffer_size*(sizeof *buf));
                        assert(buf!=NULL);

                        while(!feof(sRead))
                        {
                            size_t const byteCount = fread(buf, sizeof *buf, _file_copy_buffer_size, sRead);

                            if(ferror(sRead)!=0)
                            {
                                errOcc = true;
                                break;
                            }

                            if (byteCount>0)
                            {
                                if(fwrite(buf, sizeof *buf, byteCount, sWrite)!=byteCount)
                                {
                                    errOcc = true;
                                    break;
                                }
                            }
                        }
                        if(!errOcc)
                        {
                            retVal = true;
                        }

                        free(buf);
                    }
                    fclose(sWrite);
                }
                fclose(sRead);
            }
            //
            // Otherwise: Defined as error.
        }
        //
        // Otherwise: Error!
    }
    //
    // Otherwise: Error!

    return retVal;
}

bool FileSys_copy(char const * const inInputPath, char const * const inOutputPath)
{
    bool retVal = false;

    assert(inInputPath!=NULL);
    assert(inOutputPath!=NULL);

    switch(FileSys_GetEntryType(inInputPath, NULL))
    {
        case FileSys_EntryType_File:
            retVal = FileSys_copyFile(inInputPath, inOutputPath);
            break;

        case FileSys_EntryType_Dir:
        {
            bool outputFolderExists = false;
            DIR* d = NULL;

            if(!FileSys_exists(inOutputPath, &outputFolderExists))
            {
                break;
            }

            if(!outputFolderExists)
            {
                if(mkdir(inOutputPath, S_IRWXU|S_IRWXG|S_IROTH|S_IXOTH)!=0) // MT_TODO: TEST: Better use exact permissions to be read from input folder?
                {
                    Deb_line("Error: Failed to create folder \"%s\" (error %d)!", inOutputPath, errno);
                    errno = 0;
                    break;
                }
            }

            d = opendir(inInputPath);
            if(d!=NULL)
            {
                bool errOcc = false;
                struct dirent * e = readdir(d);

                while(e!=NULL)
                {
                    if((strcmp(e->d_name, ".")!=0)&&(strcmp(e->d_name, "..")!=0))
                    {
                        char * const fullInputPath = FileSys_GetFullPath(inInputPath, e->d_name),
                            * const fullOutputPath = FileSys_GetFullPath(inOutputPath, e->d_name);

                        if(!FileSys_copy(fullInputPath, fullOutputPath)) // *** RECURSION ***
                        {
                            errOcc = true;
                            free(fullInputPath);
                            free(fullOutputPath);
                            break;
                        }
                        free(fullInputPath);
                        free(fullOutputPath);
                    }

                    e = readdir(d);
                }
                if(errOcc)
                {
                    break;
                }
                if(errno==0)
                {
                    retVal = true;
                }
#ifndef NDEBUG
                else // For readdir().
                {
                    Deb_line("Error: Failed to read an entry of folder \"%s\" (error %d)!", inInputPath, errno);
                }
#endif //NDEBUG
                errno = 0;

                closedir(d); // (return value ignored..)
            }
#ifndef NDEBUG
            else
            {
                Deb_line("Error: Failed to open folder \"%s\" (error %d)!", inInputPath, errno);
            }
#endif //NDEBUG
            errno = 0;
            break;
        }

        case FileSys_EntryType_Unsupported:
            Deb_line("Warning: Unsupported entry type received for \"%s\".", inInputPath);
            break;

        case FileSys_EntryType_Invalid:
            Deb_line("Error: Invalid entry type received for \"%s\".", inInputPath);
            break;
        default:
            Deb_line("Error: Unknown entry type received for \"%s\"!", inInputPath);
            break;
    }

    return retVal;
}

int FileSys_getContentCount(char const * const inPath, off_t * const inOutSize, void (*inIncrementFunc)(void))
{
    int retVal = 0;
    bool errOcc = false;
    DIR * const d = opendir(inPath);

    if(d!=NULL)
    {
        struct dirent * e = readdir(d);

        while(e!=NULL)
        {
            if((strcmp(e->d_name, ".")!=0)&&(strcmp(e->d_name, "..")!=0))
            {
                char * const fullPath = FileSys_GetFullPath(inPath, e->d_name);
                off_t fileSize = -1;

                switch(FileSys_GetEntryType(fullPath, &fileSize))
                {
                    case FileSys_EntryType_File:
                        ++retVal;
                        if(inIncrementFunc!=NULL)
                        {
                            (*inIncrementFunc)();
                        }
                        if(fileSize==-1)
                        {
                            errOcc = true;
                            break;
                        }
                        if(inOutSize!=NULL)
                        {
                            *inOutSize += fileSize;
                        }
                        break;

                    case FileSys_EntryType_Dir:
                    {
                        int const subCount = FileSys_getContentCount(fullPath, inOutSize, inIncrementFunc); // *** RECURSION ***

                        if(subCount<0)
                        {
                            errOcc = true;
                            break;
                        }

                        ++retVal; // For the folder.
                        if(inIncrementFunc!=NULL)
                        {
                            (*inIncrementFunc)();
                        }
                        retVal += subCount; // For the content of the folder.
                        break;
                    }

                    case FileSys_EntryType_Unsupported:
                        Deb_line("Warning: Unsupported entry type received for \"%s\".", inPath);
                        errOcc = true;
                        break;

                    case FileSys_EntryType_Invalid:
                        Deb_line("Error: Invalid entry type received for \"%s\".", inPath);
                        errOcc = true;
                        break;
                    default:
                        Deb_line("Error: Unknown entry type received for \"%s\"!", inPath);
                        errOcc = true;
                        break;
                }
                free(fullPath);
                if(errOcc)
                {
                    break;
                }
            }

            e = readdir(d);
        }
        if(errno!=0) // For readdir().
        {
            Deb_line("Error: Failed to read an entry of folder \"%s\" (error %d)!", inPath, errno);
            errOcc = true;
        }
        errno = 0;

        closedir(d); // (return value ignored..)
    }
    else
    {
        Deb_line("Error: Failed to open folder \"%s\" (error %d)!", inPath, errno);
        errOcc = true;
    }
    errno = 0;

    if(errOcc)
    {
        retVal = -1;
    }
    return retVal;
}

unsigned char * FileSys_loadFile(
    char const * const inPath, off_t * const inOutSize)
{
    *inOutSize = -1;

    off_t const signed_size = FileSys_GetFileSize(inPath);

    if(signed_size==-1)
    {
        Deb_line("Error: Failed to get size of file \"%s\"!", inPath)
        return NULL;
    }

    FILE * const file = fopen(inPath, "rb");

    if(file==NULL)
    {
        Deb_line("Error: Failed to open source file \"%s\"!", inPath)
        return NULL;
    }

    size_t const size = (size_t)signed_size;
    unsigned char * const buf = malloc(size*sizeof(*buf));

    if(fread(buf, sizeof(*buf), size, file)!=size)
    {
        Deb_line("Error: Failed to completely load character ROM file content!")
        return NULL;
    }

    fclose(file);
    *inOutSize = signed_size;
    return buf;
}
