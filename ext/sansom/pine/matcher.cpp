#include <iostream>
#include "pattern.h"
#include "ruby.h" // ruby header

using namespace std;

extern "C" void Init_matcher();
static lpm::pattern * getPattern(VALUE self);
static void matcher_gc_free(lpm::pattern *p);
static VALUE matcher_allocate(VALUE klass);
static VALUE matcher_initialize(VALUE self, VALUE rb_pattern);
static VALUE matcher_matches(VALUE self, VALUE rb_str);
static VALUE matcher_is_dynamic(VALUE self);
static VALUE matcher_splats(VALUE self, VALUE rb_str);
static VALUE matcher_mappings(VALUE self, VALUE rb_str);

VALUE rb_cPine = Qnil;
VALUE p_cMatcher = Qnil;

void Init_matcher() {
  rb_cPine = rb_define_class("Pine", rb_cObject);
  p_cMatcher = rb_define_class_under(rb_cPine, "Matcher", rb_cObject);
  rb_define_alloc_func(p_cMatcher, matcher_allocate);
  rb_define_method(p_cMatcher, "initialize", RUBY_METHOD_FUNC(matcher_initialize), 1);
  rb_define_method(p_cMatcher, "matches?", RUBY_METHOD_FUNC(matcher_matches), 1);
  rb_define_method(p_cMatcher, "dynamic?", RUBY_METHOD_FUNC(matcher_is_dynamic), 0);
  rb_define_method(p_cMatcher, "splats", RUBY_METHOD_FUNC(matcher_splats), 1);
  rb_define_method(p_cMatcher, "mappings", RUBY_METHOD_FUNC(matcher_mappings), 1);
}

static lpm::pattern * getPattern(VALUE self) {
    lpm::pattern *p;
    Data_Get_Struct(self, lpm::pattern, p);
    return p;
}

static void matcher_gc_free(lpm::pattern *p) {
    if (p) delete p;
    p = NULL;
    ruby_xfree(p);
}

static VALUE matcher_allocate(VALUE klass) {
    return Data_Wrap_Struct(klass, NULL, matcher_gc_free, ruby_xmalloc(sizeof(lpm::pattern)));
}

static VALUE matcher_initialize(VALUE self, VALUE rb_pattern) {
    lpm::pattern *p = getPattern(self);
    new (p) lpm::pattern(StringValueCStr(rb_pattern));
    return Qnil;
}

static VALUE matcher_matches(VALUE self, VALUE rb_str) {
  return *(getPattern(self)) == string(StringValueCStr(rb_str)) ? Qtrue : Qfalse;
}

static VALUE matcher_is_dynamic(VALUE self) {
  return getPattern(self)->is_dynamic() ? Qtrue : Qfalse;
}

static VALUE matcher_splats(VALUE self, VALUE rb_str) {
  lpm::pattern *p = getPattern(self);
  list<string> splats = p->extract_splats(StringValueCStr(rb_str));
  VALUE ary = rb_ary_new2(splats.size());
  for (list<string>::iterator i = splats.begin(); i != splats.end(); i++) {
    rb_ary_push(ary, rb_str_new2((*i).c_str()));;
  }
  return ary;
}

static VALUE matcher_mappings(VALUE self, VALUE rb_str) {
  lpm::pattern *p = getPattern(self);
  map<string, string> mappings = p->extract_mappings(StringValueCStr(rb_str));
  VALUE hsh = rb_hash_new();
  for (map<string, string>::iterator i = mappings.begin(); i != mappings.end(); i++) {
    rb_hash_aset(hsh, rb_str_new2(i->first.c_str()),rb_str_new2(i->second.c_str()));
  }
  return hsh;
}