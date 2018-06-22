#!/usr/bin/perl

# use v5.010; # for 'state'
# use v5.10; #for 'say'
use v5.10; 
use strict;
use warnings;
use JSON;
use Path::Tiny;
use Mojo::UserAgent;
use Try::Tiny;

sub get_dashboard {
	my ($cookie, $player_id) = @_;

	return trivia_make_request();
}

sub password_login {
	my ($auth_file) = @_;
	say "\nPlease login via email and password";
	say "Email: ";
	chomp (my $email = <STDIN>);
	say "Password: ";
	chomp (my $password = <STDIN>);
	try {
		my $data = trivia_do_login($auth_file, $email, $password);
		if (defined decode_json($data)->{'session'}->{'session'}) {
			say 'Successfully logged into account';
			my $json = path($auth_file)->slurp;
			$json = decode_json($json);
			$json->{'cookie'} = $data->{'session'}->{'session'}; 
			$json->{'id'} = $data->{'id'};
			# $json = encode_json($json);
			path($auth_file)->spew($json);
		}
		else {
			# not reachable
		}
	}
	catch {
		say $_;
		say "Unable to login, please try again";
		password_login($auth_file);
	};
}

sub login {
	my ($auth_file) = @_;
	my $auth_data = decode_json(path($auth_file)->slurp);
	my $cookie = $auth_data->{cookie};
	my $player_id = $auth_data->{id};
	if ($cookie eq '' || $player_id eq '') {
		say "No cookie found.";
		password_login($auth_file);
	}
	else {
		try {
			my @path = ('dashboard');
			my @param = ('app_config_version=0');
			if (decode_json(trivia_make_request('get', $cookie, $player_id, \@path, \@param))->{'level_data'}->{'level'} >= 1) {
				return 'Successfully logged into account';
			}
		}
		catch {
			say "Unable to login with cookies\n";
			password_login($auth_file);
		};
	}
}

sub trivia_do_login {
	my ($auth_file, $email, $password) = @_;
	say "IS LOGGING IN AGAIN.";
    my $useragent = 'Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)';
    my $ether_agent = '1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1';
	my $base_url = 'https://api.preguntados.com/api/login';
    my $host = 'api.preguntados.com';
    my $ua = Mojo::UserAgent->new;
	my %headers = (
		'Eter-Agent' 		=> $ether_agent,
		'Accept' 			=> '*/*',
		'Cookie' 			=> 'ap_session=',
		'User-Agent' 		=> $useragent,
		'Host' 				=> $host,
		'Accept-Language' 	=> 'en-us',
		'Content-Type'		=> 'application/json; charset=utf-8',
	);
	my $data = $ua->post($base_url => \%headers => json => {
		password => $password,
		language => 'en',
		email => $email,
		user_device => {
			device => 'iphone',
			notification_id => '',
			account_type => 'default',
			installation_id => '00000000-0000-0000-0000-000000000000'
		}
	})->result->body;
	say $data;
	return $data;
}

sub trivia_make_request {
	my ($type, $cookie, $id, $path, $param) = @_;
	$path = parse_path_array($path);
	$param = parse_param_array($param);
    my $useragent = 'Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)';
    my $ether_agent = '1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1';
	my $base_url = 'https://api.preguntados.com/api/users/' . $id . $path . $param;
    my $host = 'api.preguntados.com';
    my $ua = Mojo::UserAgent->new;
	my %headers = (
		'Eter-Agent' 		=> $ether_agent,
		'Accept' 			=> '*/*',
		'Cookie' 			=> 'ap_session=' . $cookie,
		'User-Agent' 		=> $useragent,
		'Host' 				=> $host,
		'Accept-Language' 	=> 'en-us',
	);
	if ($type eq 'get') {
		return $ua->get($base_url => \%headers)->result->body;
	}
	elsif ($type eq 'post') {
		return $ua->post($base_url => \%headers)->result->body;
	}
	else {
		return 'Invalid request type';
	}
}

# => (method=something,action=else)
# <= (?method=something&action=else&cow=moo)
sub parse_param_array {
	my ($param) = @_;
	return '' if ($param eq '');
	my @param = @{$param};
	my $parameters;
	foreach (@param) {
		state $i++;
		if ($i eq 1) {
			$parameters .= '?' . $_;
		}
		else {
			$parameters .= '&' . $_;
		}
	}
	return $parameters;
}

# => (users,somethings,else) 
# <= (/users/somethings/else)
sub parse_path_array {
	my ($path) = @_;
    return '' if ($path eq '');
	my @path = @{$path};
	my $full_path;
	foreach (@path) {
		$full_path .= '/' . $_;
	}
	return $full_path;
}

BEGIN {
	say login('TriviaCrackAuth.json');
}
