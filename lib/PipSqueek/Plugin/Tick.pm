package PipSqueek::Plugin::Tick;
use base qw(PipSqueek::Plugin);


sub plugin_initialize 
{
    my $self = shift;
    
    $self->plugin_handlers([
        'multi_tick', # starts the delay loop
        'pipsqueek_once_a_sec', # has to start with pipsqueek_
        'multi_tock', # stops the delay loop
    ]);
}


sub multi_tick
{
    my ($self, $message) = @_;

    $self->respond($message, 'tick started');

    $self->client()->kernel()->delay('pipsqueek_once_a_sec', 1, $message, 0);

    return;
}


sub pipsqueek_once_a_sec
{
    my ($self, $message, $x) = @_;

    $self->respond($message, $x);

    $self->client()->kernel()->delay('pipsqueek_once_a_sec', 1, $message, $x+1);
}


sub multi_tock
{
    my ($self, $message) = @_;

    $self->client()->privmsg('shaun', 'tick stopped');

    $self->client()->kernel()->delay('pipsqueek_once_a_sec'); # clears timer

    return;
}


1;


__END__
