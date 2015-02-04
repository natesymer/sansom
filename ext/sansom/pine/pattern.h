#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <iostream>
#include <list>
#include <map>

// TODO:
//       1. write an iterator (exposes a value and a token)
//       2. make more extensible
//       3. improve _advance_to_str function to 

namespace lpm {
  using namespace std;
  
  class pattern {
  public:
    pattern(const char *ptrn) { create(ptrn); }
    pattern(string ptrn) { create(ptrn); }
    
    bool operator==(const string &rhs) const;
    bool operator==(const pattern &rhs) const;
    bool operator!=(const string &rhs) const;
  
    // returns true if there are any wilcards/splats/etc in this
    bool is_dynamic() const;
    
    // returns the pattern used
    string pattern_str() const;
    
    // check if a string matches the this pattern
    bool matches(string comp) const;
    
    // extracts all mappings from cppstr
    map<string, string> extract_mappings(string cppstr) const;
    
    // extracts all splats from cppstr
    list<string> extract_splats(string cppstr) const;
  protected:
    string _pattern;
    map<unsigned, string> _index;
    
    void create(string ptrn);

    // return true if ptr is at a wildcard sequence
    virtual bool at_wildcard(char *ptr) const;
    
    // advance ptr to the character beyond a wildcard sequence.
    virtual void advance_past_wildcard(char *&ptr) const;
  private:
    // advance ptr to the next occurance of str
    unsigned _advance_to_str(char *&ptr, char *str, unsigned len) const;
    map <unsigned, string> _gen_indeces(char *str, char *ptr) const;
  };
}
