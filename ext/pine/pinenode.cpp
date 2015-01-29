/*
  
  pinenode.cpp
  
  Implementation of a specialized tree node
*/

#include "pinenode.h"

using namespace std;

pinenode::pinenode(string name) {
  _name = name;
}

// copy constructor
pinenode::pinenode(pinenode *p) {
  destroy();
  
  // do the copying
}

// destructor
pinenode::~pinenode() {
  destroy();
}

void pinenode::destroy() {
  // destroy shit
}

bool operator==(pinenode *rhs) {
  return _name == rhs._name && _parent == rhs._parent;
}

//
// Node methods
//

bool pinenode::root() {
  return !_parent;
}

bool pinenode::leaf() {
  return /* determine this*/ true;
}

list<pinenode *> pinenode::children() {
  return list<pinenode *>();
}

// potential - potential ancestor
// (test - the node to test against potential)
bool pinenode::is_ancestor(pinenode *potential, pinenode *test = this) {
  if (target.root()) return false;
  if (potential == c) return true;
  return is_ancestor(potential, test._parent);
}

void pinenode::add_child(pinenode *n) {
    if (n->component.is_dynamic()) {
        
    } else {
        _children[n->name] = 
    }
}

pinenode * get_child(std::string component) {
    pinenode *n = _children[component];
    if (n) return n;
    
    for (size_t i = 0; i < _wildchildren.size(); i++) {
        if (_wildchildren[i]->matches(component)) {
            return n;
        }
    }
    
    return NULL;
}

bool matches(std::string component) {
  return _component.matches(component);
}
