#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Gavin Mogan (Gavin), <gavin@kodekoan.com>
#      COMPANY:  KodeKoan
#      VERSION:  1.0
#      CREATED:  10-06-17 09:59:04 PM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);

use CGI;
my $cgi = CGI->new;

use Data::Dumper;
  use Net::OpenID::Consumer;
  use LWPx::ParanoidAgent;
  use Cache::File;

  my $csr = Net::OpenID::Consumer->new(
    ua    => LWPx::ParanoidAgent->new,
    cache => Cache::File->new( cache_root => '/tmp/openid') ,
    args  => $cgi,
    consumer_secret => "abc123",
    #required_root => "http://localhost/",
    debug => 1,
  );

  # a user entered, say, "bradfitz.com" as their identity.  The first
  # step is to fetch that page, parse it, and get a
  # Net::OpenID::ClaimedIdentity object:

  # now your app has to send them at their identity server's endpoint
  # to get redirected to either a positive assertion that they own
  # that identity, or where they need to go to login/setup trust/etc.

  # so you send the user off there, and then they come back to
  # openid-check.app, then you see what the identity server said.
  if (($cgi->param('yourarg')||'') ne 'val')
  {
      my $claimed_identity = $csr->claimed_identity("https://www.google.com/accounts/o8/id");
      $claimed_identity or die $csr->err;


      my $check_url = $claimed_identity->check_url(
        delayed_return => 1,
        return_to  => "http://localhost/cgi-bin/test.cgi?yourarg=val",
        trust_root => "http://localhost/",
      );
      $csr->_debug("sending off to $check_url");
      print "Location: $check_url\n\n";
      exit();
  }

  # Either use callback-based API (recommended)...
  $csr->handle_server_response(
      not_openid => sub {
          die "Not an OpenID message";
      },
      setup_required => sub {
          my $setup_url = shift;
          die("setup is required @ $setup_url");
          # Redirect the user to $setup_url
          print "Location: $setup_url\n\n";
          exit();
      },
      cancelled => sub {
          # Do something appropriate when the user hits "cancel" at the OP
      },
      verified => sub {
          my $vident = shift;
          # Do something with the VerifiedIdentity object $vident
          print $cgi->header;
          print "Hey there sucka";
      },
      error => sub {
          my ($err,$txt) = shift;
          $csr->_debug("MEssage version: " . $csr->_message_version);
          die("Error: $txt($err)");
      },
  );

