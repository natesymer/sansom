#include "pcomp.h"

// TODO: Match last occurance of the 'succ' string when reading wildcards

//
// Public
//

bool pcomp::is_dynamic() {
  if (_wildcards.size() > 0) return true;
  if (_splat_indeces.size() > 0) return true;
  return false;
}

bool pcomp::matches(string comp) { 
  if (_pattern[0] == ':') return true;
  return _ptrncmp(_pattern.c_str(), comp.c_str());
}

map<string, string> pcomp::match_wildcards(string comp) {
  if (_pattern[0] == ':') {
    map<string, string> m;
    m[_pattern.substr(1, _pattern.length()-1)] = comp;
    return m;
  }
  
  return _match_wildcards(_pattern.c_str(), comp.c_str());
}

map<string, string> pcomp::_match_wildcards(char *pattern, char *str, int i = 0, int index_delta = 0) {
  unsigned idx = _wildcard_indeces[i]+index_delta;
  pattern += idx;
  string name = _read_until(pattern, '>');
  string succ = _read_until(pattern, '<');

  char *strtemp = str;

  // advance to start of last occurance of the succ string in str
  while (strncmp(succ.c_str(), strtemp, succ.length()) != 0) strtemp++;
  
  unsigned valuelen = (unsigned(strtemp-str);
  
  char *token = (char *)malloc(sizeof(char)*valuelen);
  strncpy(token,str,valuelen);
  string value(token);
  free(token);
  
  // TODO: Recursive call

  return _match_wildcards(pattern, str, idx+1, (value.length()-name.length()));
}

list<string> pcomp::match_splats(string comp) {
  for (size_t i = 0; i < _splat_indeces.size(); i++) {
    unsigned idx = _splat_indeces[i];
  }
}

//
// Private
//

void pcomp::create(string ptrn) {
  _splat_indeces = _get_splat_indeces(ptrn.c_str());
  _wildcard_indeces = _get_wildcard_indeces(ptrn.c_str());
  _pattern = ptrn;
}

void pcomp::_advance_to_wildcard(char *ptr, char c = '\0') {
  if (c == '\0') {
    while (*ptr != '*' && *ptr != '<' && *(ptr+1) != '\0') ptr++;
  } else {
    while (*ptr != c && *(ptr+1) != '\0') ptr++;
  }
}

unsigned pcomp::_advance_to_succ(char *ptr) {
  char *start = ptrl
  if (ptr[0] == '<') {
    while (*ptr != '>') ptr++; ptr++;
  } else if (ptr[0] == '*') {
    ptr++;
  }
  return (unsigned)(ptr-start);
}

bool pcomp::_ptrncmp(char *pattern, char *comp) {
  if (strlen(comp) == 0 && strlen(pattern) == 0) return true;
  
  if (_advance_to_succ(pattern) != 0) {
    char *succ = pattern;
    _advance_to_wildcard(pattern);
    unsigned succlen = (unsigned)(pattern-succ);

    if (strncmp(succ, comp, succlen) == 0)
      comp += succlen; // advance comp
    else
      return false;
  } else {
    if (pattern[0] != comp[0]) return false;
    return _ptrncmp(patern+1, comp+1);
  }
}

string _read_until(char *ptr, char c) {
  char *savedptr = ptr;
  while (*(ptr++) != c);
  unsigned len = ptr-savedptr;
  char *token = (char *)malloc(sizeof(char)*len);
  strncpy(token,savedptr,len);
  string read_str(token);
  free(token);
  return read_str;
}

list<unsigned> pcomp::_get_splat_indeces(char *str, char *ptr=NULL) {
  if (!ptr) ptr = str;
  if (str == ptr) return list<unsigned>();
  
  while (*(ptr++) != '*'); ptr++;
  
  list<unsigned> recursive = _get_splat_indeces(str, ptr+1);
  recursive.push_front((unsigned)(ptr-str));
  return recursive;
}

list<unsigned> pcomp::_get_wildcard_indeces(char *str, char *ptr=NULL) {
  if (!ptr) ptr = str;
  if (str == ptr) return list<unsigned>();
  
  _advance_to_wildcard(ptr, '<');
  unsigned idx = (unsigned)(ptr-str);
  _advance_to_succ(ptr,);
  
  list<unsigned> recursive = _get_wildcard_indeces(str, ptr);
  recursive.push_front(w);
  return recursive;
}

list<string> pcomp::_get_splats(char *pattern, char *comp) {
  
}

map<string, string> pcomp::_get_wildcards(char *pattern, char *comp) {
  
}
