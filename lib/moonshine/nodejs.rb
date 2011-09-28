require 'pathname'

#
# Define options for this plugin via the <tt>configure</tt> method
# in your application manifest:
#
#    configure(:nodejs => { :version => '0.5.4' })
#
# Moonshine will autoload plugins, just call the recipe(s) you need in your
# manifests:
#
#    recipe :nodejs
#

module Moonshine
  module Nodejs
    def nodejs(user_options = {})
      options = { :version => '0.4.11' }.merge(user_options)

      # dependecies for install
      package 'wget',         :ensure => :installed
      package 'curl',         :ensure => :installed
      package 'cmake',        :ensure => :installed
      file '/usr/local',      :ensure => :directory
      file "/usr/local/src",  :ensure => :directory
      file '/var/log/nodejs', :ensure => :directory
      
      configure_command = "sh ./configure --prefix=/usr/local"
      make_command = 'make'
      install_command = 'sudo make install'
      test_command = 'make test'
      
      version = Gem::Version.new(options[:version])
      nodejs_tarball = "node-v#{ version }.tar.gz"
      nodejs_srcdir = /([A-Za-z0-9\.\-]+).tar.gz/.match(nodejs_tarball)[1]
      nodejs_url = version >= Gem::Version.new('0.5.1') ? "http://nodejs.org/dist/v#{ version }/#{ nodejs_tarball }" : "http://nodejs.org/dist/#{ nodejs_tarball }"
      
      exec 'download node.js',
        :require    => package('wget'),
        :cwd        => "/usr/local/src",
        :command    => "wget #{ nodejs_url }",
        :creates    => "/usr/local/src/#{ nodejs_tarball }",
        :logoutput  => true,
        :unless     => "test \"`node --version`\" = \"v#{ version }\""

      exec 'untar node.js',
        :require    => exec('download node.js'),
        :cwd        => '/usr/local/src',
        :command    => "tar xzf #{ nodejs_tarball }",
        :creates    => "/usr/local/src/#{ nodejs_srcdir }",
        :logoutput  => true

      exec 'configure node.js',
        :require    => exec('untar node.js'),
        :cwd        => "/usr/local/src/#{ nodejs_srcdir }",
        :command    => configure_command,
        :logoutput  => true,
        :unless     => "test \"`node --version`\" = \"v#{ version }\""

      exec 'make node.js',
        :require    => exec('configure node.js'),
        :cwd        => "/usr/local/src/#{ nodejs_srcdir }",
        :command    => make_command,
        :logoutput  => true,
        :creates    => "/usr/local/src/#{ nodejs_srcdir }/build",
        :unless     => "test \"`node --version`\" = \"v#{ version }\""
      
      exec 'make install node.js',
        :require    => exec('make node.js'),
        :cwd        => "/usr/local/src/#{ nodejs_srcdir }",
        :command    => install_command,
        :creates    => '/usr/local/node/bin',
        :logoutput  => true,
        :creates    => '/usr/local/lib/node',
        :unless     => "test \"`node --version`\" = \"v#{ version }\""
    end
  end
end
