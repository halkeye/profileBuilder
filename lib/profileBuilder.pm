package profileBuilder;
use Dancer ':syntax';
use profileBuilder::Auth;

our $VERSION = '0.1';
  
before sub {
    print STDERR "Path info is: ", request()->path_info(), "\n";
    if (request()->path_info() !~ m{^/auth/})
    {
        redirect('/auth/openid/google') unless session('openid_email');
    }
};

get '/' => sub {
    template('index', { email => session('openid_email') });
};

true;
