# Gem2Pkg

Gem2Pkg bundles a ruby gem into a Mac OSX package structure to be installed on other machines without needing to use 'gem'.  This is handy for gems whose primary purpose is to expose a binary for the user to run, when the user may not be a developer and know how to deal with 'gem install' yadda yadda.

My primary motivation for creating this was to bundle the 'chef' gem and its dependencies up as an installer so that Mac OSX computers could be easily bootstrapped with chef without needing to install XCode, etc.

## Requirements

This gem requires rubygems 1.3.6 to be installed.  While it will probably work with older versions of rubygems, and hasn't been tested with them yet, so the requirement is set high for now

If rvm is installed, use gem2pkg with the system ruby (rvm use system).  Since we're building packages to be installed on OSX systems that do not not have RVM installed, we want to be safe and use the same environment to build the package.

## Usage

Installation:

	gem install gem2pkg

If you wanted to make an installer for the 'chef' gem.  First, install chef:

	gem install chef

You might want to also make sure all the supporting gems that chef uses are up to date, as gem2pkg uses the newest installed version of each gem that satisfies the dependency requirements:

	gem update

Then, build your installer with gem2pkg:

	gem2pkg chef

The package will be outputted in the current folder, named chef-0.10.4.pkg (if the latest installed chef version were 0.10.4)

## Known Issues

* Does not build flat packages
* Only tested so far on OSX Lion