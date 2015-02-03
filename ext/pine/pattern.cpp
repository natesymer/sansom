#include "pattern.h"

namespace lpm {
  bool pattern::operator==(const string &rhs) const { return matches(rhs); }
  bool pattern::operator==(const pattern &rhs) const { return rhs._pattern == _pattern; }
  bool pattern::operator!=(const string &rhs) const { return !(*this == rhs); }
  
  bool pattern::is_dynamic() const { return (_index.size() > 0); }
  string pattern::pattern_str() const { return _pattern; }

  bool pattern::matches(string cppstr) const {
    if (_pattern[0] == ':') return true;
    if (_pattern == cppstr) return true;
    
    char *pattern = (char *)_pattern.c_str();
    char *str = (char *)cppstr.c_str();
    int index_delta = 0;

    for (auto i = _index.begin(); i != _index.end(); i++) {
      unsigned idx = i->first;
      string token = i->second;
      
      char *vptr = str+idx+index_delta;
      char *succ = pattern+idx+token.length();
      unsigned succlen = (i == _index.end()) ? 0 : next(i)->first-(idx+token.length());
      unsigned vlen = _advance_to_str(vptr, succ, succlen);
      if (strncmp(succ, vptr, succlen) != 0) return false;

      index_delta += vlen;
      index_delta -= token.length();
    }
    
    return true;
  }
  
  map<string, string> pattern::extract_mappings(string cppstr) const  {
    map<string,string> m;
    char *pattern = (char *)_pattern.c_str();
    char *str = (char *)cppstr.c_str();
    int index_delta = 0;

    for (auto i = _index.begin(); i != _index.end(); i++) {
      unsigned idx = i->first;
      string token = i->second;
      
      char *vptr = str+idx+index_delta;
      char *succ = pattern+idx+token.length();
      unsigned succlen = (i == _index.end()) ? 0 : next(i)->first-(idx+token.length());
      string value(vptr, _advance_to_str(vptr, succ, succlen));
      
      index_delta += value.length();
      index_delta -= token.length();
            
      if (token[0] == '<' && token[token.length()-1] == '>') {
        m[token.substr(1, token.length()-2)] = value;
      }
    }
     
    return m;
  }
   
  list<string> pattern::extract_splats(string cppstr) const {
    list<string> splats;
    char *pattern = (char *)_pattern.c_str();
    char *str = (char *)cppstr.c_str();
    int index_delta = 0;
   
    for (auto i = _index.begin(); i != _index.end(); i++) {
      unsigned idx = i->first;
      string token = i->second;
       
      char *vptr = str+idx+index_delta;
      char *succ = pattern+idx+token.length();
      unsigned succlen = (i == _index.end()) ? 0 : next(i)->first-(idx+token.length());
      string value(vptr, _advance_to_str(vptr, succ, succlen));
     
      index_delta += value.length();
      index_delta -= token.length();
       
      if (token[0] == '*') splats.push_back(value);
    }
    return splats;
  }
  
  void pattern::create(string ptrn) {
    _pattern = ptrn;
    char *cptrn = (char *)_pattern.c_str();
    _index = _gen_indeces(cptrn,cptrn);
  }
 
  unsigned pattern::_advance_to_str(char *&ptr, char *str, unsigned n) const {
    char *start = ptr;
    while (*ptr != '\0' && (*str == '\0' || strncmp(ptr, str, n) != 0)) ptr++;
    return (unsigned)(ptr-start);
  }
 
  map <unsigned, string> pattern::_gen_indeces(char *str, char *ptr) const {
    // advance to wildcard
    while (*ptr != '\0' && !at_wildcard(ptr)) ptr++;

    if (*ptr == '\0') return map <unsigned, string>();
    unsigned idx = ptr-str;
    
    // advance to characters after the pattern
    char *start = ptr;
    advance_past_wildcard(ptr);
    unsigned token_len = (unsigned)(ptr-start);
    
    map <unsigned, string> recursive = _gen_indeces(str, ptr);
    recursive[idx] = string(str+idx,token_len);
    return recursive;
  }
  
  //
  // overrideable functions
  //
  
  bool pattern::at_wildcard(char * ptr) const {
    return (*ptr == '*' || *ptr == '<');
  }
  
  void pattern::advance_past_wildcard(char *&ptr) const {
    switch (*ptr) {
      case '<': while (*ptr != '>') ptr++; ptr++; break;
      case '*': ptr++; break;
      default: break;
    }
  }
}
