package PipSqueek::Plugin::URLShortener;
use base qw(PipSqueek::Plugin);

use JSON::XS qw( decode_json );
use URI::Find;
use warnings;

my $title;
my $key = 'AIzaSyCdUmsLwCWdxVH0C1uHu2oiN7qPjV7v_tg';

sub config_initialize {
    my $self = shift;
}

sub plugin_initialize {
    my $self = shift;

	warn "Loaded plugin!";

    $self->plugin_handlers([
        'irc_public',
    ]);
}

sub irc_public {
    my ($self,$message) = @_;

    my $text = $message->message();
	$title = '';

	my $short_url = '';
	my $finder = URI::Find->new(sub {
		my($uri, $obj) = @_;

		if (length($obj) >= 30) {
			my ($status, $short_url) = &shorten($obj);

			if ($status == 200) {
				$title = &title($obj);
				$short_url .= ' (' . $title . ')';
				return $self->respond ( $message, $short_url );
			}
		} else {
			$short_url = $obj . ' -- ' . &title($obj, 1);
		}
		return $short_url;
	});

	$how_many_found = $finder->find(\$text);
	return $self->respond ( $message, $short_url ) if $short_url;
}


sub irc_private {
    my ($self,$message) = @_;

    my $text = $message->message();

	my $response = $text;
	return $self->respond ( $message, $response );
}

sub start_handler {
	return if shift ne "title";
	my $self = shift;
	$self->handler(text => sub { $title = shift }, "dtext");
	$self->handler(end  => sub { shift->eof if shift eq "title"; }, "tagname,self");
}

sub shorten {
	my ($obj) = @_;

	warn "Fetching a shorter $obj";

	use LWP::UserAgent;
	$userAgent = new LWP::UserAgent;
	$userAgent->timeout(5); # if we can't fetch data within 5 seconds, it's not worth it
	$request = new HTTP::Request POST => 'https://www.googleapis.com/urlshortener/v1/url?key=' . $key;
	# $request = new HTTP::Request POST => 'http://ln-s.net/home/api.jsp';
	# $request->content_type('application/x-www-form-urlencoded');
	$request->content_type('application/json');

	use Data::Dumper;

	$url = $obj;
	# $url = URI::Escape::uri_escape($url);
	$request->content(sprintf('{"longUrl":"%s"}', $url));

	$response = $userAgent->request($request);

	# handle the response
	if ($response->is_success) {
		my $reply = decode_json $response->content;
		$status = $response->code;
		$short_url = $reply->{'id'};

		# 1 while(chomp($reply));
		# ($status, $short_url) = split(/ /,$reply, 2);
	} else {
		($status, $short_url) = split(/ /,$response->status_line, 2);
	}

	return ($status, $short_url);
}

sub title {
	my ($obj, $opt) = @_;

	warn "Fetching the title of $obj";
	if ($opt) {
		warn "Fetching without shortening";
	}

	use LWP::UserAgent;
	$userAgent = new LWP::UserAgent;
	$userAgent->timeout(5); # if we can't fetch data within 5 seconds, it's not worth it

	$request = new HTTP::Request GET => $obj;
	$response = $userAgent->request($request);
	if ($response->is_success) {
		my $reply = $response->content;

		$p = HTML::Parser->new();
		$p->handler( start => \&start_handler, "tagname,self");
		$p->parse($reply);

		$title =~ s/^ | $//g;
		$title =~ s/[^A-Z0-9 ()\[\],\$'.-]/ /gi;
		$title =~ s/  / /g;
		$title =~ s/\s+/ /g;

		return $title;
	} else {
		warn $response->status_line;
		return '';
	}
}

1;


__END__

