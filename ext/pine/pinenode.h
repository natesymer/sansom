/*
  
  pinenode.h
  
  Implementation of a specialized tree node
*/

#include <iostream>
#include <string>
#include <map>
#include <list>
#include "pcomp.h"

class pinenode {
public:
  pinenode(std::string name);
  pinenode(pinenode p);
  ~pinenode();
  
private:
  map<string, pinenode *> _children;
  list<pinenode *> _wildchildren;
  pcomp _component;
  pinenode *_parent;
  std::string _name;
};