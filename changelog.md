Changelog
=

0.0.1

(yanked due to bad name in Gemfile)

0.0.2

- Initial release

0.0.3

- Wrote custom tree implementation called Pine to replace RubyTree
- Added `before` block

Here's an example

    s = Sansom.new

    s.before do |r|
      # Caveat: routes are mapped before this block is called
      # Code executed before mapped route
    end
    
    s.get "/" do |r|
      [200, {}, ["Hello!"]]
    end
    
    s.start 2000

0.0.4

- Fixed bug with with requiring pine

0.0.5

- Parameterized URLs!!! (Stuff like `/user/:id/profile`)
	* Parameterized URLs work with mounted Rack/Sansom apps
- Improved matching efficiency

0.0.6

- Before block response checking

0.0.7

- Fixed bug where a wilcard path component would be ignored if it came last in the URL
- Fixed a bug where async responses would be marked as bad by the fastlinter.

0.1.0

- PUBLIC RELEASE!
- After block added
- Improved routing behavior & speed