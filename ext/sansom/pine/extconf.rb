require "mkmf"

$libs += "-lstdc++"
with_cppflags("-std=c++0x") { true }

create_makefile "sansom/pine/matcher"