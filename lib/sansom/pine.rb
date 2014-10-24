#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It is capable of matching both wildcards
# and semiwildcards.
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup. You could say it matches a route in
# something resembling logarithmic time, but really is linear time
# due to child lookups (Children are just iterated over)

require_relative "./pine/tree"
require_relative "./pine/node"