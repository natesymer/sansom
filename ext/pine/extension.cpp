#include "ruby.h" // ruby header

extern "C" void Init_pine_node();

VALUE rb_mPine = Qnil;

void Init_pine_node() {
  rb_mPine = rb_define_module("Pine");
  m_cPostgres = rb_define_class_under(rb_mPine, "Node", rb_cObject);
}