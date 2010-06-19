package profileBuilder;
use Dancer ':syntax';

our $VERSION = '0.1';
  
use Net::OpenID::Consumer;
use LWPx::ParanoidAgent;
use Cache::File;
use Data::GUID;

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
        consumer_secret => "abc123",
        #required_root => "http://localhost/",
        debug => 1,
    );
    return $csr;
}

my $main = get '/' => sub {
    template 'index';
    my $email = session('openid_email');
    return redirect('/auth/openid/google') unless $email;
};

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
            $main->();
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

    my $check_url = $claimed_identity->check_url(
            delayed_return => 1,
            return_to  => request->uri_for('/auth/openid/return'),
            trust_root => request->uri_for('/'),
    );
    redirect($check_url);
};

true;
