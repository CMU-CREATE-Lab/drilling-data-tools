#include <assert.h>
#include <math.h>
#include <sys/stat.h>
#include <vw/Core/Utf8.h>

#include "common_utils.h"

using namespace std;

bool string_equal_case_insensitive(const std::string &a, const std::string &b)
{
#ifdef _WIN32
  return !stricmp(a.c_str(), b.c_str());
#else
  return !strcasecmp(a.c_str(), b.c_str());
#endif
}

std::string trim_whitespace(const std::string &in)
{
  size_t left = in.find_first_not_of(" \t\r\n");
  size_t right = in.find_last_not_of(" \t\r\n");
  if (right != in.npos) right++;
  if (right > left) return in.substr(left,right);
  return "";
}


// Take the string passed in in src, removes any white space or
// carriage returns from either end, and returns the resulting
// substring.  This does not modify src.
string string_trim(const string &src, const string &trimchars)
{
  size_t start, end;

  // Find start and end of good stuff
  start = src.find_first_not_of(trimchars);
  end = src.find_last_not_of(trimchars);

  if (start == string::npos || end == string::npos) return "";
  return src.substr(start, (end-start)+1);
}

// Take the string passed in in src, removes any white space or
// carriage returns from the front, and returns the resulting
// substring.  This does not modify src.
string string_trim_front(const string &src, const string &trimchars)
{
  size_t start;

  // Find start of good stuff
  start = src.find_first_not_of(trimchars);

  if (start == string::npos) return "";
  return src.substr(start);
}

// Take the string passed in in src, removes any white space or
// carriage returns from the end, and returns the resulting substring.
// This does not modify src.
string string_trim_back(const string &src, const string &trimchars)
{
  size_t end;

  // Find end of good stuff
  end = src.find_last_not_of(trimchars);

  if (end == string::npos) return "";
  return src.substr(0, end+1);
}

void string_chomp(string &src) {
  string::size_type idx = src.find_first_of("\n\r");
  if (idx != string::npos) src.resize(idx);
}

// string_remove_token takes the src string, removes leading delimeters
// and the first token in it, modifying it in the process, and returns
// the resulting token.  It does this by first skipping over the
// delimiter characters from delims (defaults to whitespace and
// carriage returns), then takes the characters in tokchars for the
// return string.  By default tokchars will match anything not in
// delims.  It modifies src to remove both the ignored and token
// characters.
string string_remove_token(string &src, const string &delimchars,
                           const string& tokchars)
{
  string argtrim, firstarg;
  size_t start, end;

  // Throw away leading comma or whitespace
  start = src.find_first_not_of(delimchars);

  if (start == string::npos) {
    // The string only contains delmeters, set src and return value to
    // be the empty string
    src = "";
    return "";
  }
  argtrim = src.substr(start);

  // Check if first character of argtrim is a quote, and get quoted if so
  if (argtrim[0]=='\"') {    //"
    // Value is a string, get quoted string
    string tok;
    tok = string_get_quoted(argtrim);
    src = argtrim;
    return(tok);
  }
  else if (argtrim[0]=='\'') {
    // Value is a single quoted string, get single quoted string
    string tok;
    tok = string_get_quoted(argtrim, '\'');
    src = argtrim;
    return(tok);
  }

  // Find first character not in tokchars, or if tokchars is empty
  // find the first delimeter in the trimped string.
  if (tokchars.length()>0) {
    // tokchars was provided, find last character in that set starting
    // at the first non-delimeter
    end = argtrim.find_first_not_of(tokchars);
  }
  else {
    // Find first delimeter (ones from front of source string already
    // removed)
    end = argtrim.find_first_of(delimchars);
  }

  if (end == string::npos) {
    // no more delimeters, return the rest of the string and set src
    // to be the empty string
    src = string("");
    return(argtrim);
  }

  // There is a token and delimeters, remove the token and return the
  // rest of the string.
  string ret = argtrim.substr(0, end);
  src = argtrim.substr(end);
  return(ret);
}

// string_get_quoted takes the src string, removes a quoted string,
// modifying it in the process, and returns the resulting quoted
// string.  It does this by first skipping over everything until the
// first '"', removes it, then takes all the characters until the
// ending quote or the end of the string if no end quote present,
// skipping any escaped quotes (quote preceeded by \ in the string.
// If the string was originally part of a compiled C/C++ program, then
// you would have needed to do '\\\"' in order for the resulting
// string to contain a literal backslash followed by a literal quote.
// It modifies src to remove the initial quote, the contents of the
// string, and the final quote, if there was one.  (There is currently
// no way for the user to tell the difference between a string with an
// end quote at the end, and a string with no end quote.)  If you want
// to have the same behavior for something other than ", you can set
// another value for quotechar.

string string_get_quoted(string &src, int quotechar)
{
  string argtrim, firstarg;
  size_t start, end;

  // Throw away everything leading up to first quote
  start = src.find(quotechar);

  if (start == string::npos) {
    // The string does not contain a start quote, return empty.
    src = string("");
    return(string(""));
  }
  argtrim = src.substr(start+1);

  // Look for the end quote, skipping over any escaped quotes
  for (end=0; end!=string::npos; end++) {
    end = argtrim.find(quotechar, end);
    if (argtrim[end-1] != '\\') {
      // This is the final quote, break out of the loop
      break;
    }
    // Otherwise, it was an escaped quote, remove the escaping
    argtrim.erase(end-1, 1);
  }

  if (end == string::npos) {
    // no end quote, return the rest of the string and set src to be
    // the empty string
    src = string("");
    return(argtrim);
  }

  // There is a quoted string, remove it and return the rest of the
  // string, including the final quote
  string ret = argtrim.substr(0, end);
  src = argtrim.substr(end+1);
  return(ret);
}

string string_quote(const string &src, int quotechar)
{
  string ret;
  size_t end;

  if (src == "") {
    ret += quotechar;
    ret += quotechar;
    return ret;
  }

  // Check if any whitespace, if not just leave it alone
  if (src.find_first_of(" \t\n\r") == string::npos) {
    // No white space, leave it alone
    return(src);
  }

  // There is whitespace, so quote it
  ret = quotechar;    // Put first quote
  ret += src;     // Put unmodified source string after quote
  // Replace internal quotes with escaped quote
  end = 1;
  while ((end = ret.find(quotechar, end)) != string::npos) {
    if (ret[end-1] != '\\') {
      // It's an unescaped internal quote, escape it
      ret.insert(end, "\\");
      end++;
    }
    else {
      // It's an escaped internal quote, add two escapes, one
      // to be escaped by the first escape, and one to escape the
      // quote itself
      ret.insert(end, "\\\\");
      end += 2;
    }
    end++;
  }

  // Add the final quote
  ret += quotechar;
  return(ret);
}

// string_get_tokens takes the src string and separates into tokens that
// match the characters in delims and tokchars.  At the point where
// the next character in the string matches neither of these, it stops
// and returns

void string_get_tokens(const string &src,
                       vector<string> &ret,
                       const string &delimchars,
                       const string &tokchars)
{
  string tmp = src;
  ret.clear();
  string newtok;

  while (1) {
    newtok = string_remove_token(tmp, delimchars, tokchars);
    if (newtok.length()==0) break;
    // Got a valid token, add to return vector
    ret.push_back(newtok);
  }
}

#include <cctype>
#include <algorithm>
std::string string_to_lower(const std::string &src) {
  std::string tmp(src);
  std::transform(tmp.begin(), tmp.end(), tmp.begin(), ::tolower);
  return tmp;
}

std::string string_to_upper(const std::string &src) {
  std::string tmp(src);
  std::transform(tmp.begin(), tmp.end(), tmp.begin(), ::toupper);
  return tmp;
}

// string_get_double takes the src string and tries to parse the first
// token as a double.  If successful it modifies src to remove the
// double token, parses into d, and returns true.  If not successful
// it leaves src and d unmodified and returns false.  If ignore is not
// specified, defaults to whitespace.
bool string_remove_double(string &src, double &d, const string &ignore)
{
  string copy(src);

  // Try to get the
  string ftok = string_remove_token(copy, ignore, "-+0123456789.e");

  if (ftok.length()==0) {
    // src string does not have a number at the front
    return(false);
  }
  else {
    // src string does not have a number at the front, parse ftok as a
    // double and set src to what's left in copy.
    src = copy;
    d = atof(ftok.c_str());
    return(true);
  }
}

// string_get_double takes the src string and tries to parse the first
// token as a double.  If successful it modifies src to remove the
// double token, parses into d, and returns true.  If not successful
// it leaves src and d unmodified and returns false.  If ignore is not
// specified, defaults to whitespace.
bool string_remove_long(string &src, long &d, const string &ignore)
{
  string copy(src);

  // Try to get the
  string ftok = string_remove_token(copy, ignore, "-+0123456789xoXOabcdefABCDEF");

  if (ftok.length()==0) {
    // src string does not have a number at the front
    return(false);
  }
  else {
    // src string does not have a number at the front, parse ftok as a
    // double and set src to what's left in copy.
    src = copy;
    d = strtol(ftok.c_str(),NULL,0);
    return(true);
  }
}

// string_get_bool takes the src string and tries to parse the first
// token as a bool.  If successful it modifies src to remove the
// double token, parses into d, and returns true.  If not successful
// it leaves src and d unmodified and returns false.  If ignore is not
// specified, defaults to whitespace.
bool string_remove_bool(string &src, bool &d, const string &/*ignore*/)
{
  string copy(src);

  // Try to get the
  string ftok = string_remove_token(copy);

  if (ftok.length()==0) {
    // src string does not have a token in it
    return(false);
  }
  else {
    src = copy;

    if (ftok.find_first_of("yYtT1") == 0) {
      // true value
      d = true;
      return(true);
    }
    if (ftok.find_first_of("nNfF0") == 0) {
      // false value
      d = false;
      return(true);
    }
    // Did not start with a recognized value
    return(false);
  }
}

bool string_is_flag(const string &x)
{
  return (x.length() >= 2 && x[0] == '-' && (isalpha(x[1]) || x[1] == '-'));
}

string string_right(const string &src, size_t len) {
  size_t src_len = src.length();
  int idx = src_len - len;
  if (idx <= 0) return src;
  return src.substr(idx);
}

string string_left(const string &src, size_t len) {
  size_t src_len = src.length();
  if (len >= src_len) return src;
  return src.substr(0, len);
}

string string_find_and_replace_1(const string &src,
                                     const string &from,
                                     const string &to)
{
  return string_find_and_replace_n(src, from, to, 1);
}

string string_find_and_replace_all(const string &src,
                                   const string &from,
                                   const string &to)
{
  return string_find_and_replace_n(src, from, to, src.length());
}

string string_find_and_replace_n(const string &src,
                                 const string &from,
                                 const string &to,
                                 int max_replacements)
{
  string ret = src;
  string::size_type idx = 0;
  for (int i=0; i<max_replacements; i++) {
    idx = ret.find(from, idx);
    if (idx == string::npos) break;
    ret.replace(idx, from.length(), to);
    idx += to.length();
  }
  return ret;
}

///////////////////////////////////////////////////

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

string
filename_sans_directory(const string &filename)
{
  size_t lastDirDelim = filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);
  // No directory delimiter, so return filename
  if (lastDirDelim == string::npos) return filename;
  // Return everything after the delimiter
  return filename.substr(lastDirDelim+1);
}

string
filename_directory(const string &filename)
{
  size_t lastDirDelim = filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);
  // No directory delimiter, so return nothing
  if (lastDirDelim == string::npos) return "";
  // Return everything up to just before the last delimiter
  return filename.substr(0, lastDirDelim);
}

string
filename_sans_suffix(const string &filename)
{
  // Find the last '.'
  size_t lastDot = filename.find_last_of(".");
  if (lastDot == string::npos) return filename;

  // Find the last directory delimiter
  size_t lastDirDelim = filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);

  if (lastDirDelim != string::npos &&
      lastDot < lastDirDelim) {
    // The last dot was inside the directory name, so return as is
    return filename;
  }

  // Return everything up to the last dot
  return filename.substr(0, lastDot);
}

string
filename_suffix(const string &filename)
{
  // Find the last '.'
  size_t lastDot = filename.find_last_of(".");
  if (lastDot == string::npos) return "";

  // Find the last directory delimiter
  size_t lastDirDelim = filename.find_last_of(ALLOWABLE_DIRECTORY_DELIMITERS);

  if (lastDirDelim != string::npos &&
      lastDot < lastDirDelim) {
    // The last dot was inside the directory name, so no suffix
    return "";
  }

  // Return everything after the last dot
  return filename.substr(lastDot+1);
}

string
filename_canonicalize_directory_delims(const string &filename)
{
  string ret = filename;
  for (size_t i=0; i<ret.length(); i++) {
    if (ret[i] != DIRECTORY_DELIMITER &&
        strchr(ALLOWABLE_DIRECTORY_DELIMITERS, ret[i])) {
      ret[i] = DIRECTORY_DELIMITER;
    }
  }
  return ret;
}

string
filename_canonicalize(const string &filename)
{
  string ret;
  for (size_t i=0; i<filename.length(); i++) {
    if (filename[i] != DIRECTORY_DELIMITER &&
        strchr(ALLOWABLE_DIRECTORY_DELIMITERS, filename[i])) {
      ret += DIRECTORY_DELIMITER;
    } else if (!FILENAMES_CASE_SENSITIVE && isupper(filename[i])) {
      ret += tolower(filename[i]);
    } else {
      ret += filename[i];
    }
  }
  return filename_simplify(filename);
}

string
filename_remove_trailing_directory_delim(const string &filename)
{
  if (filename.length() &&
      strchr(ALLOWABLE_DIRECTORY_DELIMITERS, filename[filename.length()-1])) {
    // Trim trailing /
    return filename.substr(0, filename.length()-1);
  }
  return filename;
}

string
filename_simplify(const string &filename)
{
  if (filename == "") return filename;
  string prefix;
  if (strchr(ALLOWABLE_DIRECTORY_DELIMITERS, filename[0])) {
    prefix = DIRECTORY_DELIMITER_STRING;
  }
  vector<string> original;
  string_get_tokens(filename, original, ALLOWABLE_DIRECTORY_DELIMITERS);
  vector<string> simplified;

  for (unsigned int i=0; i<original.size(); i++) {
    if (original[i] == ".") continue;
    if (original[i] == ".." && simplified.size()
        && simplified.back() != "..") {
      simplified.pop_back();
      continue;
    }
    simplified.push_back(original[i]);
  }

  return prefix + string_join(simplified.begin(), simplified.end(),
                              DIRECTORY_DELIMITER_STRING);
}

#ifndef _WIN32
#define STRICMP strcasecmp
#else
#define STRICMP stricmp
#endif

bool
filenames_equal(const string &f1, const string &f2)
{
  return filename_canonicalize(f1) == filename_canonicalize(f2);
}

#ifdef _WIN32
#define stat _stat
#define fstat _fstat
#endif

#ifdef FILENAME_EXISTS
bool
filename_exists(const string &filename)
{
  struct stat statbuf;
  // TODO: make this code international; for UTF8, use boost::filesystem::exists() instead?
  int ret = stat(filename.c_str(), &statbuf);
  return (ret == 0);
}
#endif

string
make_filename(const string &directory, const string &filename)
{
  if (filename_is_absolute(filename)) return filename;
  string prefix = directory;
  if (directory.length() != 0 &&
      !strchr(ALLOWABLE_DIRECTORY_DELIMITERS,
              directory[directory.length()-1])) {
    prefix += DIRECTORY_DELIMITER;
  }
  return filename_simplify(prefix + filename);
}

bool
filename_is_absolute(const string &filename)
{
#ifdef _WIN32
  if (filename.length() >= 2 &&
      isalpha(filename[0]) &&
      filename[1] == ':') {
    return true;
  }
#endif
  if (filename.length() &&
      strchr(ALLOWABLE_DIRECTORY_DELIMITERS, filename[0])) {
    return true;
  }
  return false;
}

bool
filename_is_directory(const string &filename)
{
  struct stat file_stat;

#ifdef _WIN32
  if (filename.length() &&
      isalpha(filename[0]) &&
      (!strcmp(filename.c_str()+1, ":/") ||
       !strcmp(filename.c_str()+1, ":\\") ||
       !strcmp(filename.c_str()+1, ":")))     return true;
#endif

  if (stat(filename.c_str(), &file_stat) < 0) return false;
  return !!(file_stat.st_mode & S_IFDIR);
}

#ifdef _WIN32
#define getcwd _getcwd
#include <direct.h>
#endif

string
get_current_working_directory()
{
  int dirlen = 1000;
  char *dir = (char*)malloc(dirlen);
  assert(dir);
  while (1) {
    if (getcwd(dir, dirlen-1)) break;
    if (errno != ERANGE) {
      free(dir);
      return "";
    }
    dirlen *= 2;
    dir = (char*)realloc(dir, dirlen);
  }
  string ret = dir;
  free(dir);
  return ret;
}

#if DIRECTORY_GET_FILENAMES
void
directory_get_filenames(const string &directory, vector<string> &ret,
                        bool recurse)
{
  vector<string> todo;
  ret.clear();

  todo.push_back(filename_remove_trailing_directory_delim(directory));

  while (todo.size()) {
    string current = todo.back();
    todo.pop_back();

    DIR *d = opendir(current.c_str());

    if (!d) continue;

    struct dirent *ent;
    while ((ent = readdir(d))) {
      string fullname = current + DIRECTORY_DELIMITER + ent->d_name;
      if (!strcmp(ent->d_name, ".")) continue;
      if (!strcmp(ent->d_name, "..")) continue;

      ret.push_back(fullname);
      if (recurse && filename_is_directory(fullname))
        todo.push_back(fullname);
    }
    closedir(d);
  }
}
#endif

#ifdef FILENAME_EXISTS
string
find_exe_filename(const string &argv_0,
                  const string &initial_working_directory)
{
  // If argv_0 is absolute, we're done
  if (filename_is_absolute(argv_0)) {
    return argv_0;
  }

  // If argv_0 is relative, it's relative to the initial working directory
  size_t delim = argv_0.find_first_of(ALLOWABLE_DIRECTORY_DELIMITERS);
  if (delim != string::npos) {
    return make_filename(initial_working_directory,
                         argv_0);
  }

  // Search the path
  const char *path = getenv("PATH");
  if (!path) return "";
  vector<string> path_items;
  string_get_tokens(path, path_items, ":");
  for (unsigned int i=0; i<path_items.size(); i++) {
    string candidate = make_filename(path_items[i], argv_0);
    if (!filename_is_absolute(candidate)) {
      candidate = make_filename(initial_working_directory, candidate);
    }
    if (filename_exists(candidate)) return candidate;
  }
  return "";
}
#endif

#if defined(_WIN32)
string
filename_follow_symlinks(const string &file)
{
  return file;
}

#else
string
filename_follow_symlinks(const string &file)
{
  char buf[1000];
  int len = readlink(file.c_str(), buf, sizeof(buf)-1);
  if (len < 0) return file;
  buf[len] = 0;
  return buf;
}
#endif

// to find memory use on Windows, Linux, OSX, this is a good reference:
// http://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process

#if defined(_WIN32)

#include <windows.h>
#include <psapi.h>

unsigned int ram_usage_kilobytes() {
  PROCESS_MEMORY_COUNTERS pmc;
  if (!GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof pmc)) {
    fprintf(stderr, "GetProcessMemoryInfo failed\n");
    return 0;
  }
  return pmc.WorkingSetSize / 1024;
  // return pmc.PagefileUsage / 1024;  // before 2011/6
}

#if 0

static std::string ram_check() {
  PROCESS_MEMORY_COUNTERS_EX pmce;
  if (!GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS *)&pmce, sizeof pmce)) {
    fprintf(stderr, "GetProcessMemoryInfo failed\n");
    return 0;
  }

  // PROCESS_MEMORY_COUNTERS fields (from the MS documentation):
  //   WorkingSetSize is "The current working set size, in bytes." = PM used by current process
  //   PagefileUsage is "The current space allocated for the pagefile, in bytes.
  //     Those pages may or may not be in memory."
  // PROCESS_MEMORY_COUNTERS_EX fields (also in PMC):
  //   PrivateUsage is "The current amount of memory that cannot be shared with other processes,
  //     in bytes ..." = VM used by current process
  return string_printf("VM=%.0f PM=%.0f PagefileUsage=%.0f [MB]",
      pmce.PrivateUsage/1048576., pmce.WorkingSetSize/1048576., pmce.PagefileUsage/1048576.);
}

#endif

unsigned int num_cpus(void) {
  SYSTEM_INFO siSysInfo;

  GetSystemInfo(&siSysInfo);

  return siSysInfo.dwNumberOfProcessors;
}

unsigned int total_ram_kilobytes(void) {
  MEMORYSTATUSEX statex;

  statex.dwLength = sizeof(statex);
  if (!GlobalMemoryStatusEx(&statex)) {
  fprintf(stderr, "GetMemoryStatusEx failed\n");
    return 0;
  }

  return (unsigned int)(statex.ullTotalPhys / 1024);
}

#elif defined(__APPLE__)

#include <sys/resource.h>
#include <mach/task.h>
#include <mach/mach.h>
#include <mach/mach_init.h>
// Return ram usage, in kilobytes
unsigned int ram_usage_kilobytes() {
  // Mac OS X only

//  struct rusage usage;
//  usage.ru_idrss = 1;
//  int ret = getrusage(0, &usage);
//  if (ret == -1) {
//    perror("getrusage");
//    exit(1);
//  }
//  //printf("ru_maxrss: %ld\n", usage.ru_maxrss);
//  //printf("ru_ixrss: %ld\n", usage.ru_ixrss);
//  //printf("ru_idrss: %ld\n", usage.ru_idrss);
//  //printf("ru_isrss: %ld\n", usage.ru_isrss);
//  //printf("ru_utime: %ld\n", usage.ru_utime);

  task_t task = mach_task_self();
  mach_msg_type_number_t count = TASK_BASIC_INFO_COUNT;
  struct task_basic_info tbi;
  kern_return_t kr = task_info(task, TASK_BASIC_INFO, (task_info_t) &tbi, &count);
  if (kr != KERN_SUCCESS) {
    fprintf(stderr, "task_info returns error %d\n", kr);
    exit(1);
  }

  //printf("virtual_size: %d\n", tbi.virtual_size);
  //printf("resident_size: %d\n", tbi.resident_size);
  return tbi.resident_size / 1024;
}

unsigned int total_ram_kilobytes() {
  kern_return_t           kr; // the standard return type for Mach calls
  host_name_port_t        myhost;
  kernel_version_t        kversion;
  host_basic_info_data_t  hinfo;
  mach_msg_type_number_t  count;
  char                   *cpu_type_name, *cpu_subtype_name;

  // get send rights to the name port for the current host
  myhost = mach_host_self();

  kr = host_kernel_version(myhost, kversion);
  assert(kr == KERN_SUCCESS);

  count = HOST_BASIC_INFO_COUNT;      // size of the buffer
  kr = host_info(myhost,              // the host name port
                 HOST_BASIC_INFO,     // flavor
                 (host_info_t)&hinfo, // out structure
                 &count);             // in/out size
  assert(kr == KERN_SUCCESS);

  // the slot_name() library function converts the specified
  // cpu_type/cpu_subtype pair to a human-readable form
  slot_name(hinfo.cpu_type, hinfo.cpu_subtype, &cpu_type_name,
            &cpu_subtype_name);

  //printf("cpu              %s (%s, type=0x%x subtype=0x%x "
  //       "threadtype=0x%x)\n", cpu_type_name, cpu_subtype_name,
  //       hinfo.cpu_type, hinfo.cpu_subtype, hinfo.cpu_threadtype);
  //printf("max_cpus         %d\n", hinfo.max_cpus);
  //printf("avail_cpus       %d\n", hinfo.avail_cpus);
  //printf("physical_cpu     %d\n", hinfo.physical_cpu);
  //printf("physical_cpu_max %d\n", hinfo.physical_cpu_max);
  //printf("logical_cpu      %d\n", hinfo.logical_cpu);
  //printf("logical_cpu_max  %d\n", hinfo.logical_cpu_max);
  //printf("memory_size      %u MB\n", (hinfo.memory_size >> 20));
  //printf("max_mem          %llu MB\n", (hinfo.max_mem >> 20));

  return (unsigned int)(hinfo.max_mem / 1024);
  return 0;
}

unsigned int num_cpus()
{
  kern_return_t           kr; // the standard return type for Mach calls
  host_name_port_t        myhost;
  kernel_version_t        kversion;
  host_basic_info_data_t  hinfo;
  mach_msg_type_number_t  count;

  // get send rights to the name port for the current host
  myhost = mach_host_self();

  kr = host_kernel_version(myhost, kversion);
  assert(kr == KERN_SUCCESS);

  count = HOST_BASIC_INFO_COUNT;      // size of the buffer
  kr = host_info(myhost,              // the host name port
                 HOST_BASIC_INFO,     // flavor
                 (host_info_t)&hinfo, // out structure
                 &count);             // in/out size
  assert(kr == KERN_SUCCESS);

  return hinfo.physical_cpu_max;
}

#else // linux

#include <fstream>

unsigned int ram_usage_kilobytes() {
  char stat_filename[100];
  sprintf(stat_filename, "/proc/%d/stat", getpid());
  // could also use /proc/self/status
  FILE *in = fopen(stat_filename, "r");  // an ASCII path, so regular fopen() is ok
  if (!in) return 0;
  char buf[1000];
  buf[0] = 0;
  fgets(buf, sizeof(buf), in);
  fclose(in);
  vector<string> tokens;
  string_get_tokens(buf, tokens, " \t\n\r");
  if (tokens.size() > 22) {
    // TODO: don't we really want physical memory, here?
    long long vsize = atoll(tokens[22].c_str());
    //long long rss = atoll(tokens[23].c_str());
    return (unsigned int)(vsize / 1024);
  } else {
    return 0;
  }
}

unsigned int num_cpus() {
  int numcpus = 0;

  fstream filestr;
  filestr.open("/proc/cpuinfo", fstream::in);
  if (!filestr)
    return 0;

  string cpustr;
  while (filestr >> cpustr) {
    if (!cpustr.compare("processor"))
      numcpus++;
  }
  filestr.close();
  return numcpus;
}

unsigned int total_ram_kilobytes()
{
  int memKb = 0;

  fstream filestr;
  filestr.open("/proc/meminfo", fstream::in);
  if (!filestr)
    return 0;

  string memstr;
  while (filestr >> memstr) {
    if (!memstr.compare("MemTotal:")) {
      filestr >> memstr;
      memKb = atoi(memstr.c_str());
    }
  }
  filestr.close();
  return memKb;
}


#endif

#ifdef WIN32
#include <Windows.h>

bool disk_free_space(const std::string &filename, unsigned long &mb_free) {
  unsigned __int64 free_bytes_to_caller;
  unsigned __int64 total_bytes;
  unsigned __int64 free_bytes;

  BOOL retval = GetDiskFreeSpaceExW(Utf8(filename).to_utf16(),
      (PULARGE_INTEGER) &free_bytes_to_caller,
      (PULARGE_INTEGER) &total_bytes,
      (PULARGE_INTEGER) &free_bytes);
  if (retval == 0) {
    return false;
  }

  mb_free = unsigned long(free_bytes_to_caller / (1024 * 1024));

  return true;
}

#elif defined(__APPLE__)
#include <sys/param.h>
#include <sys/mount.h>

bool disk_free_space(const std::string &filename, unsigned long &mb_free) {
  struct statfs buf;

  int ret_val = statfs(filename.c_str(), &buf);
  if (ret_val < 0) {
    return false;
  }

  // Bytes to MB
  mb_free = buf.f_bavail * (buf.f_bsize / 1024) / 1024;
  return true;
}

#else

bool disk_free_space(const std::string &/*filename*/, unsigned long &/*mb_free*/) {
  // TODO: fix this to do something reasonable on linux
  return false;
}

#endif

double significant_figures(double x, int ndigits) {
  if (x==0) return 0;
  int sign = x<0 ? -1 : 1;
  double mant = x*sign;
  int exp = int(floor(log(mant)/log(10.))) - ndigits + 1;
  double scale = pow(10., exp);
  return sign * scale * floor(mant/scale + .5);
}
