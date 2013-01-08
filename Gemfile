source 'https://rubygems.org'

# Specify your gem's dependencies in conjur.gemspec
gemspec

parent_dir, src_dir = if Pathname.new(__FILE__).parent.basename.to_s == "workspace"
  [ "..", "workspace" ]
else
  [ ".", "." ]
end

gem 'conjur-api', path: [ parent_dir, '..', 'conjur-api', src_dir ].join('/')
gem 'slosilo', path: [ parent_dir, '..', 'slosilo', src_dir ].join('/')
