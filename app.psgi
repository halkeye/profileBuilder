# PSGI application bootstraper for Dancer
BEGIN {
	use File::Basename ();
	use lib File::Basename::dirname(__FILE__)."/lib";
}
use Dancer;

load_app 'profileBuilder';

use Dancer::Config 'setting';
setting apphandler  => 'PSGI';
Dancer::Config->load;

my $handler = sub {
    my $env = shift;
    my $request = Dancer::Request->new($env);
    Dancer->dance($request);
};
