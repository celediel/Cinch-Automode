
# -*- encoding: utf-8 -*-
$LOAD_PATH.push('lib')
require 'cinch/plugins/automode/version'

Gem::Specification.new do |s|
  s.name     = 'Cinch-Automode'
  s.version  = Cinch::Automode::VERSION.dup
  s.date     = '2016-02-28'
  s.summary  = 'Cinch plugin to automatically apply modes to people on join'
  s.email    = 'lilian.jonsdottir@gmail.com'
  s.homepage = 'https://github.com/lilyseki/Cinch-Automode'
  s.authors  = ['Lily Jónsdóttir']
  s.license  = 'MIT'

  s.description = <<-EOF
Automatically apply a mode to a user based on nick!user@host when they join a
channel. Also has commands to add and delete users, and apply mode to anyone
that joins a channel.
EOF

  dependencies = [
    [:runtime, 'sequel', '~> 4.31'],
  ]

  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ['lib']

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = '2.5.1'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version

  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
