BEGIN { chdir 't' if -d 't' }

### add ../lib to the path
BEGIN { use File::Spec;
        use lib 'inc';
        use lib File::Spec->catdir(qw[.. lib]);
}

BEGIN { require 'conf.pl' }

use strict;

### load the appropriate modules
use_ok( $DIST );
use_ok( $CLASS );
use_ok( $CONST );

my @BUILDERS = qw( MM Build );
my @TYPE     = qw( xs noxs );

### run only one particular combination
my @TESTS;
if( @ARGV ) {
    @TESTS =
        map {
            my ( $builder, $type ) = split m{/};
            [ $builder, $type ];
        }
            @ARGV;
} else {
    @TESTS =
        map {
            my $builder = $_;
            map [ $builder, $_ ],
                @TYPE;
        }
            @BUILDERS;
}

local %ENV = %ENV;
delete @ENV{qw/
  PERL_MM_OPT MODULEBUILDRC
/};

### create a debian dist using EU::MM and no XS files
for my $test ( @TESTS ) {
    my ( $builder, $type ) = @$test;

    diag("Taking care of $builder / $type");

    my $mod     = $FAKEMOD->clone;
    my $name    = $mod->module;
    my $distdir = File::Spec->rel2abs(
                                      File::Spec->catdir( 'src', $builder, $type)
                                     );

    ### point it to your dummy dir
    $mod->status->extract( File::Spec->catdir(  $distdir,
                                                $mod->package_name ) );

    ### to avoid refetching
    $mod->status->fetch( File::Spec->catfile(   $distdir,
                                                $mod->package ) );

    ### skip tests to avoid testcounter mismatch warnings
    my $rv = $mod->install( format      => $CLASS,
                            target      => 'create',
                            skiptest    => 1 );

    ok( $rv,                        "$CLASS package created" );

    my $dist = $mod->status->dist;
    ok( $dist,                      "Dist object retrieved" );
    isa_ok( $dist,                  $CLASS );

    ### check out the file
    my $deb = $dist->status->dist;
    ok( $deb,                       "   Deb written to '$deb'" );
    ok( -e $deb,                    "       File exists " );
    ok( -s $deb,                    "       File has size" );

    ### check the --info on the file
    {   my $out = join '', `$DPKG --info $deb`;
        ok( $out,                   "   Deb --info retrieved" );
        like( $out, qr/Package: $CPANDEB/,
              "       Package: ok" );
        like( $out, qr/Section: perl/,
              "       Section: ok" );

        # Dawg, this is contradictory. If we are system perl, we must Provide system libs.
        # If we are not system perl, we must *not* provide system libs.
        if ( CPANPLUS::Dist::Deb::Constants::IS_SYSTEM_PERL ) {
            like( $out, qr/Provides: $DEBMOD/,
                  "       Provides: ok" );
        } else {
            unlike( $out, qr/Provides: $DEBMOD/,
                    "       Provides: ok" );
        }

        unlike( $out, qr/Replaces: $DEBMOD/,
                "       Replaces: not mentioned" );
        like( $out, qr/Description: $name/,
              "       Description: ok" );
        like( $out, qr/Maintainer: \S+/,
              "       Maintainer: ok" );
    }

    ### check out the --contents on the file
    {   my $out = join '', `$DPKG --contents $deb`;
        my ($need,$omit) = @{$CONTENTS->{$type}};

        ok( $out,                   "   Deb --contents retrieved" );

        for my $entry ( sort @$need ) {
            my $re = qr/.$entry$/m;
            like( $out, $re,        "       Contains $entry" );
        }
        for my $entry ( sort @$omit ) {
            my $re = qr/$entry$/m;
            unlike( $out, $re,      "       Doesn't contain $entry" );
        }
    }

    ### install tests
  SKIP: {
        my ($need) = @{$CONTENTS->{$type}};
        my $to_skip = 3 + 2 * scalar @$need;

        skip "Can not (un)install -- no superuser privileges",
            $to_skip if ($> and not
                         $CB->configure_object->get_program('sudo'));

        ok( $dist->install,         "   Dist installed" );

        my $out = join '', `$DPKG -L $CPANDEB`;
        ok( $out,                   "       Deb files retrieved" );

        ### check out if all got installed ok
        for my $entry ( sort @$need ) {
            ok( -e $entry,          "       File $entry installed" );
        }

        ok( $dist->uninstall,       "   Dist uninstalled" );

        ### check out if all got removed ok
        for my $entry ( sort @$need ) {
            ok( !-e $entry,         "       File $entry uninstalled");
        }

    }

    {   my $files = $dist->status->files;
        ok( $files,                 "   Files for this package" );

      SKIP: {
            skip( 'Missing files', 5 ) if ! $files;

            is( scalar(@$files), 5,     "       All Files found" );

            for ( sort @$files ) {
                ok( -e $_,              "       File '$_' exists" );
                1 while unlink $_;
                ok( !-e $_,             "       File '$_' removed" );
            }
        }
    }

    ### check out the naming
    like( $deb, qr/$DEBMOD/,        "   Deb is called '$DEBMOD'" );

    if ( $type eq 'xs' ) {
        my $arch = DEB_ARCHITECTURE->()->();
        like( $deb, qr/$arch/,      "       Arch dependant ($arch)" );
    } else {
        like( $deb, qr/all/,        "       Is platform independant");
    }

    ### checking some constants that require dist objects and the like
    {   ### output path
        my $path = DEB_DISTDIR->()->( $dist, 'x-' );
        is( $path, 'main/pool/x-lib/f/cpan-libfoo-bar-perl',
            "Output path constructed OK" );
    }

    ### see if we can write some package files
    if ( $DO_META ) {
        ok( $DO_META,           "Testing meta files" );

        for my $mtype (qw[sources packages]) {
            my $loc = $dist->write_meta_files( type => $mtype );

            ok( $loc,           "File '$loc' written" );
            ok( -e $loc,        "   File exists" );
            ok( -s $loc,        "   File has size" );

            ### st00pit vms
            1 while unlink $loc;

            ok( !-e $loc,       "   File got deleted" );
        }
    }

    # Moar st00pit vms
    1 while unlink $deb;
    ok( !-e $deb, "'$deb' got deleted" );
}
