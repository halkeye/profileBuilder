package profileBuilder::Auth;

use Dancer ':syntax';

use Net::OpenID::Consumer;
use LWPx::ParanoidAgent;
use Cache::File;
use Data::GUID;

use constant OPENID_NS_SREG_1_0 => "http://openid.net/sreg/1.0";
use constant OPENID_NS_SREG_1_1 => "http://openid.net/extensions/sreg/1.1";
use constant OPENID_NS_AX_1_0 => "http://openid.net/srv/ax/1.0";

sub getConsumer
{
    my ($params) = @_;
    my $cache = Cache::File->new( cache_root => '/tmp/openid');
    my $secret = $cache->get('openidSecret');
    if (!defined $secret)
    {
        $secret = Data::GUID->new->as_string();
        $cache->set('openidSecret', $secret);
    }

    my $csr = Net::OpenID::Consumer->new(
        ua    => LWPx::ParanoidAgent->new,
        cache => $cache,
        args => \%{params()},# $params,
        consumer_secret => $secret,
        required_root => request()->uri_for('/'),
        debug => 1,
    );
    return $csr;
}


get '/auth/openid/return' => sub {
    my $csr = getConsumer();
    # Either use callback-based API (recommended)...
    $csr->handle_server_response(
        not_openid => sub {
            die "Not an OpenID message";
        },
        setup_required => sub {
            my $setup_url = shift;
            redirect($setup_url);
        },
        cancelled => sub {
            # Do something appropriate when the user hits "cancel" at the OP
            template 'cancel';
        },
        verified => sub {
            my $vident = shift;
            # Do something with the VerifiedIdentity object $vident
            my $extinfo = $vident->extension_fields(&OPENID_NS_AX_1_0);
            session("openid_email", $extinfo->{'value.email'} || $vident->display);
            redirect('/');
        },
        error => sub {
            my ($err,$txt) = shift;
            $csr->_debug("MEssage version: " . $csr->_message_version);
            die("Error: $txt($err)");
        },
    );
};

get '/auth/openid/google' => sub {
    my %params = params;
    my $csr = getConsumer();

    my $claimed_identity = $csr->claimed_identity("https://www.google.com/accounts/o8/id");
    $claimed_identity or die $csr->err;

    $claimed_identity->set_extension_args(&OPENID_NS_AX_1_0, {
            mode => 'fetch_request',
            #"type.nickname" => "http://schema.openid.net/namePerson/friendly",
            "type.email" => "http://schema.openid.net/contact/email",
            #"type.firstname" => "http://schema.openid.net/namePerson/first",
            #"type.lastname" => "http://schema.openid.net/namePerson/last",
            #required => 'nickname,email,firstname,lastname',
            required => 'email',
    });

    my $check_url = $claimed_identity->check_url(
            delayed_return => 1,
            return_to  => request->uri_for('/auth/openid/return'),
            trust_root => request->uri_for('/'),
    );
    redirect($check_url);
};


true;
