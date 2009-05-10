use ExtUtils::MakeMaker;
use strict;
use Config;

print << '.';

Note:   To use this module, a few command line utlities are required.
        They are provided by the following debian packages, which you
        will need to install:

            libc6-dev:  /usr/bin/gencat
            dpkg:       /usr/bin/dpkg
            debhelper:  /usr/bin/dh_perl
            gcc:        /usr/bin/gcc
            dpkg-dev:   /usr/bin/dpkg-buildpackage
            fakeroot:   /usr/bin/fakeroot
            findutils:  /usr/bin/find, /usr/bin/xargs

        To use the (optional) automatic creation of Sources.gz and 
        Packages.gz files, to use your locally created .debs as an 
        apt repository you need the following programs:
            
            apt-utils:  /usr/bin/apt-ftparchive

.

WriteMakefile (
    NAME            => 'CPANPLUS::Dist::Deb',
    VERSION_FROM    => 'lib/CPANPLUS/Dist/Deb.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean           => {
        FILES => fold( "
          t/dist/01mailrc.txt.gz
          t/dist/02packages.details.txt.gz
          t/dist/03modlist.data.gz
          t/dist/sourcefiles.2.18.stored
          t/src/Build/noxs/Foo-Bar/Build
          t/src/Build/noxs/Foo-Bar/_build/
          t/src/Build/noxs/Foo-Bar/blib/
          t/src/Build/noxs/Foo-Bar/build-stamp
          t/src/Build/noxs/Foo-Bar/install-stamp
          t/src/Build/xs/Foo-Bar/Build
          t/src/Build/xs/Foo-Bar/_build/
          t/src/Build/xs/Foo-Bar/blib/
          t/src/Build/xs/Foo-Bar/build-stamp
          t/src/Build/xs/Foo-Bar/debian/
          t/src/Build/xs/Foo-Bar/install-stamp
          t/src/Build/xs/Foo-Bar/lib/Foo/Bar.c
          t/src/Build/xs/Foo-Bar/lib/Foo/Bar$Config{obj_ext}
          t/src/Build/xs/cpan-libfoo-bar-perl_0.01-1.diff.gz
          t/src/Build/xs/cpan-libfoo-bar-perl_0.01-1.dsc
          t/src/Build/xs/cpan-libfoo-bar-perl_0.01.orig.tar.gz
          t/src/MM/noxs/Foo-Bar/Makefile
          t/src/MM/noxs/Foo-Bar/blib/
          t/src/MM/noxs/Foo-Bar/build-stamp
          t/src/MM/noxs/Foo-Bar/install-stamp
          t/src/MM/noxs/Foo-Bar/pm_to_blib
          t/src/MM/xs/Foo-Bar/Bar.bs
          t/src/MM/xs/Foo-Bar/Bar.c
          t/src/MM/xs/Foo-Bar/Bar$Config{obj_ext}
          t/src/MM/xs/Foo-Bar/Makefile
          t/src/MM/xs/Foo-Bar/blib/
          t/src/MM/xs/Foo-Bar/build-stamp
          t/src/MM/xs/Foo-Bar/install-stamp
          t/src/MM/xs/Foo-Bar/pm_to_blib
        " ) },


    PREREQ_PM       => { 
                        'Test::More'                => 0, 
                        'CPANPLUS'                  => '0.81', # dev version
                        'CPANPLUS::Dist::Build'     => '0.03',
                        'Locale::Maketext::Simple'  => 0,
                        'Params::Check'             => '0.23',
                        'Object::Accessor'          => '0.02',
                        'IPC::Cmd'                  => '0.23',
                        'Module::Load::Conditional' => '0.06',
                        'Module::Pluggable'         => '2.4',
                        'YAML'                      => 0,
                        'Package::Constants'        => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'CPANPLUS plugin to create debian packages on the fly'
);     

sub fold { join ' ', $_[0] =~ /(\S+)/g }
