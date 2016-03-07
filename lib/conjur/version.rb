#
# Copyright (C) 2014-2016 Conjur Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Conjur
  VERSION = "4.31.0"
  ::Version=VERSION
  
  class << self
    # http://www.rubydoc.info/github/rubygems/rubygems/Gem/Version
    def rubygems_semantic_version
      git_version, match = parse_git_version
      major, minor, build = VERSION.split('.')
      pre = match[4]
      if pre == "0"
        [ major, minor, build ].join('.')
      else
        # This is about the best we can do.
        # In branched development, we don't know which version is the "latest". So 
        # when installing from an apt repository, it's essential to publish 
        # different branches to different apt components, and the downstream 
        # apt 'clients' need to know which component to install from.
        [ major, minor, build, pre ].join('.')
      end
    end

    def semver_semantic_version
      git_version, match = parse_git_version
      major, minor, build = VERSION.split('.')
      pre = match[4]
      revision = match[5]
      if pre == "0"
        [ major, minor, build ].join('.')
      else
        [ major, minor, "#{build}-pre.#{pre}+revision.#{revision}" ].join('.')
      end
    end
    
    def parse_git_branch
      ENV['GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip
    end
    
    def parse_git_version
      git_version = `git describe --long --tags --abbrev=7 --match 'v*.*'`.strip
      raise "Can't detect git version from #{version}" unless match = git_version.match(/^v(\d+)\.(\d+)\.(\d+)-(\d+)-g([0-9a-f]+)$/)
      [ git_version, match ]
    end
  end
end
