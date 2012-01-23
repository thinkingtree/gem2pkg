#!/usr/bin/ruby

require 'yaml'
require 'rubygems'
require 'rubygems/dependency_installer'
require 'erb'
require 'tmpdir'

class Gem2Pkg
  def gather_dependencies(specs)
    dependency_list = Gem::DependencyList.new
    dependency_list.add(*specs)

    to_do = specs.dup
    seen = {}

    until to_do.empty? do
      spec = to_do.shift
      next if spec.nil? or seen[spec.name]
      seen[spec.name] = true

      deps = spec.runtime_dependencies
      deps.each do |dep|
        result = dep.to_spec
        if result == nil
          puts "Could not find local gem to satisfy dependency #{dep.name} (#{dep.requirement})"
          next
        end
        next if seen[result.name]
        to_do.push(result)
        dependency_list.add result
      end
    end

    dependency_list.dependency_order.reverse
  end


  def build(gemname)
    if gemname == nil
      puts "Please specify the name of the gem to package."
      return -1
    end

    gembin = `which gem`.strip
    if gembin != '/usr/bin/gem'
      puts "This tool is meant to make gem packages for the Mac OSX system installed ruby.  If you are using RVM, please switch to the system ruby first by running: 'rvm use system'"
      return -2
    end

    if Gem::VERSION < "1.8.0"
      puts "You have rubygems #{Gem::VERSION} installed-- gem2pkg requires rubygems >= 1.8.0"
      return -3
    end

    gemspec = Gem::Specification.find_by_name(gemname)
    if gemspec == nil
      dep = Gem::Dependency.new(gemname)
      matches = Gem::SpecFetcher.fetcher.fetch dep
      if matches.length == 0
        puts "Gem #{gemname} was not found!"
        return -4
      end
      gemspec = matches.first.first

      puts "Gem is not installed locally-- install with:"
      puts "gem install #{gemname} -v #{gemspec.version}"
      return -5
    end

    puts "Making installer for gem #{gemname} (#{gemspec.version})"

    #inst = Gem::DependencyInstaller.new
    #inst.install gemspec.name, gemspec.version

    puts "Building dependency list from dependency tree..."

    puts "We will be bundling up the following gems into our installer:"
    dependencies = gather_dependencies([gemspec])
    dependencies.each do |dependency|
      puts "#{dependency.name} (#{dependency.version}) from '#{dependency.full_gem_path}'"
    end

    pkg_name = "#{gemspec.name}-#{gemspec.version}"
    installed_size = nil
    Dir.mktmpdir(pkg_name) do |payload_staging_dir|
      dependencies.each do |dependency|
        `mkdir -p #{payload_staging_dir}#{dependency.full_gem_path}`
        `cp -r #{dependency.full_gem_path}/ #{payload_staging_dir}#{dependency.full_gem_path}/`
        `mkdir -p #{payload_staging_dir}#{File.dirname(dependency.loaded_from)}`
        `cp #{dependency.loaded_from} #{payload_staging_dir}#{dependency.loaded_from}`
      end

      # write BOM
      `rm -rf #{pkg_name}.pkg` if File.exists?("#{pkg_name}.pkg")
      `mkdir -p #{pkg_name}.pkg/Contents/Resources`

      puts "Generating BOM..."
      `mkbom #{payload_staging_dir} #{pkg_name}.pkg/Contents/Archive.bom`

      puts "Archiving payload..."
      `cd #{payload_staging_dir} && pax -wz -x cpio . > Archive.pax.gz`
      `cp #{payload_staging_dir}/Archive.pax.gz #{pkg_name}.pkg/Contents/Archive.pax.gz`

      installed_size = (`/usr/bin/du -k -s #{payload_staging_dir}`.split(' ')[0]).to_i * 1024
    end

    puts "Generating postflight script..."
    File.open("#{pkg_name}.pkg/Contents/Resources/postflight", "w") do |file|
      file.puts '#!/bin/sh'
      dependencies.each do |dependency|
        # make symbolic links to executables
        dependency.executables.each do |exe|
          file.puts "ln -f -s #{dependency.full_gem_path}/#{dependency.bindir}/#{exe} /usr/bin/#{exe}"
        end
      end
    end

    puts "Generating package info..."
    erb_path = File.join(File.dirname(__FILE__), "..", "resources", "Info.plist.erb")

    src = File.read erb_path
    erb = ERB.new(src)
    File.open("#{pkg_name}.pkg/Contents/Info.plist", "w") do |file|
      package_name = pkg_name
      package_info = gemspec.summary
      package_identifier = "org.rubygems.gems.#{gemspec.name}"
      package_version = gemspec.version
      file.puts erb.result(binding)
    end

    `echo pmkrpkg1 > "#{pkg_name}.pkg/Contents/PkgInfo"`

    puts "Setting permissions..."
    `chmod 444 #{pkg_name}.pkg/Contents/Archive.bom`
    `chmod 444 #{pkg_name}.pkg/Contents/Archive.pax.gz`
    `chmod 444 #{pkg_name}.pkg/Contents/PkgInfo`
    `chmod 444 #{pkg_name}.pkg/Contents/Info.plist`
    `chmod 555 #{pkg_name}.pkg/Contents/Resources/postflight`

    puts "Done.  Package has been saved as '#{pkg_name}.pkg'"
    # flatten package
    #puts "Flattening package..."
    #`pkgutil --flatten #{pkg_name}.pkg #{pkg_name}.flat.pkg`
  
    return 0
  end
end