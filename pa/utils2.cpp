// C
#include <sys/stat.h>
#include <sys/time.h>
#include <stdio.h>

// C++
#include <iostream>

// Self
#include "utils.h"

std::string string_vprintf(const char *fmt, va_list args)
{
  int size= 500;
  char *buf = (char*)malloc(size);
  while (1) {
    va_list copy;
    va_copy(copy, args);
#if defined(_WIN32)
    int nwritten= _vsnprintf(buf, size, fmt, copy);
#else
    int nwritten= vsnprintf(buf, size, fmt, copy);
#endif
    va_end(copy);
    // Some c libraries return -1 for overflow, some return
    // a number larger than size-1
    if (nwritten < 0) {
      size *= 2;
    } else if (nwritten >= size) {
      size = nwritten + 1;
    } else {
      if (nwritten && buf[nwritten-1] == 0) nwritten--;
      std::string ret(buf, buf+nwritten);
      free(buf);
      return ret;
    }
    buf = (char*)realloc(buf, size);
  }
}

std::string string_printf(const char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  std::string ret= string_vprintf(fmt, args);
  va_end(args);
  return ret;
}

#ifdef _WIN32
#define stat _stat
#define fstat _fstat
#endif

bool
filename_exists(const std::string &filename)
{
  struct stat statbuf;
  int ret= stat(filename.c_str(), &statbuf);
  return (ret == 0);
}

unsigned long long microtime() {
#ifdef WIN32
  return ((long long)GetTickCount() * 1000);
#else
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return ((long long) tv.tv_sec * (long long) 1000000 +
          (long long) tv.tv_usec);
#endif
}

unsigned long long millitime() { return microtime() / 1000; }

double doubletime() { return microtime() / 1000000.0; }

std::string rtrim(const std::string &x) {
  return x.substr(0, x.find_last_not_of(" \r\n\t\f")+1);
}

#ifdef _WIN32
// Windows                                                                                                                                                                                                 
#define ALLOWABLE_DIRECTORY_DELIMITERS "/\\"
#define DIRECTORY_DELIMITER '\\'
#define DIRECTORY_DELIMITER_STRING "\\"
#define FILENAMES_CASE_SENSITIVE 0
#elif defined(__MWERKS__)
// mac os <=9                                                                                                                                                                                              
#define ALLOWABLE_DIRECTORY_DELIMITERS ":"
#define DIRECTORY_DELIMITER ':'
#define DIRECTORY_DELIMITER_STRING ":"
#define FILENAMES_CASE_SENSITIVE 0
#else
// UNIX                                                                                                                                                                                                    
#define ALLOWABLE_DIRECTORY_DELIMITERS "/"
#define DIRECTORY_DELIMITER '/'
#define DIRECTORY_DELIMITER_STRING "/"
#define FILENAMES_CASE_SENSITIVE 1
#endif

std::string
filename_sans_directory(const std::string &filename)
{
  size_t lastDirDelim= filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);
  // No directory delimiter, so return filename                                                                                                                                                            
  if (lastDirDelim == std::string::npos) return filename;
  // Return everything after the delimiter                                                                                                                                                                 
  return filename.substr(lastDirDelim+1);
}

std::string
filename_directory(const std::string &filename)
{
  size_t lastDirDelim= filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);
  // No directory delimiter, so return nothing                                                                                                                                                             
  if (lastDirDelim == std::string::npos) return "";
  // Return everything up to just before the last delimiter                                                                                                                                                
  return filename.substr(0, lastDirDelim);
}

std::string
filename_sans_suffix(const std::string &filename)
{
  // Find the last '.'                                                                                                                                                                                     
  size_t lastDot= filename.find_last_of(".");
  if (lastDot == std::string::npos) return filename;

  // Find the last directory delimiter                                                                                                                                                                     
  size_t lastDirDelim= filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);

  if (lastDirDelim != std::string::npos &&
      lastDot < lastDirDelim) {
    // The last dot was inside the directory name, so return as is                                                                                                                                         
    return filename;
  }

  // Return everything up to the last dot                                                                                                                                                                  
  return filename.substr(0, lastDot);
}

std::string
filename_suffix(const std::string &filename)
{
  // Find the last '.'                                                                                                                                                                                     
  size_t lastDot= filename.find_last_of(".");
  if (lastDot == std::string::npos) return "";

  // Find the last directory delimiter                                                                                                                                                                     
  size_t lastDirDelim= filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);

  if (lastDirDelim != std::string::npos &&
      lastDot < lastDirDelim) {
    // The last dot was inside the directory name, so return as is                                                                                                                                         
    return "";
  }

  // Return everything after to the last dot                                                                                                                                                               
  return filename.substr(lastDot+1);
}
