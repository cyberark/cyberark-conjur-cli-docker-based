require 'English'

module Overcommit::GitHook
  # Try to avoid commiting code which breaks specs.
  # Install the hook with `overcommit .` in the top directory.
  class SpecsPass < HookSpecificCheck
    include HookRegistry
    file_types :rb

    def run_check
      unless in_path?('rspec')
        return :warn, 'rspec not installed -- run `gem install rspec`'
      end

      output = `rspec 2>&1`
      if $CHILD_STATUS.exitstatus == 0
        return :good
      else
        return :bad, output
      end
    end
  end
end
