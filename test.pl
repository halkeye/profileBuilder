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

use CGI;
my $cgi = CGI->new;

  use Net::OpenID::Consumer;
  use LWPx::ParanoidAgent;
  use Cache::Null;

  my $csr = Net::OpenID::Consumer->new(
    ua    => LWPx::ParanoidAgent->new,
    cache => Cache::Null->new,
    args  => $cgi,
    consumer_secret => "abc123",
    required_root => "http://moocow.halkeye.net/",
  );

  # a user entered, say, "bradfitz.com" as their identity.  The first
  # step is to fetch that page, parse it, and get a
  # Net::OpenID::ClaimedIdentity object:

  my $claimed_identity = $csr->claimed_identity("bradfitz.com");

  # now your app has to send them at their identity server's endpoint
  # to get redirected to either a positive assertion that they own
  # that identity, or where they need to go to login/setup trust/etc.

  my $check_url = $claimed_identity->check_url(
    return_to  => "http://example.com/openid-check.app?yourarg=val",
    trust_root => "http://example.com/",
  );

  # so you send the user off there, and then they come back to
  # openid-check.app, then you see what the identity server said.

  # Either use callback-based API (recommended)...
  $csr->handle_server_response(
      not_openid => sub {
          die "Not an OpenID message";
      },
      setup_required => sub {
          my $setup_url = shift;
          # Redirect the user to $setup_url
      },
      cancelled => sub {
          # Do something appropriate when the user hits "cancel" at the OP
      },
      verified => sub {
          my $vident = shift;
          # Do something with the VerifiedIdentity object $vident
      },
      error => sub {
          my $err = shift;
          die($err);
      },
  );

  # ... or handle the various cases yourself
  if (my $setup_url = $csr->user_setup_url) {
       # redirect/link/popup user to $setup_url
  } elsif ($csr->user_cancel) {
       # restore web app state to prior to check_url
  } elsif (my $vident = $csr->verified_identity) {
       my $verified_url = $vident->url;
       print "You are $verified_url !";
  } else {
       die "Error validating identity: " . $csr->err;
  }
