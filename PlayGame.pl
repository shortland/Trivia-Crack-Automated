#!/usr/bin/perl

use JSON;
use File::Slurp;

my $game_email = 'YOUR_EMAIL_HERE@MAIL.COM';
my $game_password = 'PASSWORD_HERE';

my $authorize_data = decode_json(read_file("TriviaCrackAuth.persistent"));

my $cookie = $authorize_data->{cookie};
my $myPlayerID = $authorize_data->{id};

if ($cookie eq "" || $myPlayerID eq "") {
	print "need to login: $game_email ...\n";
	write_cookie_id($authorize_data, $game_email, $game_password);
}

sub write_cookie_id {
	my ($authorize_data, $email, $password) = @_;

	print "Re-writing cookie & id\n";
	my $requestData = `curl -s -H 'Host: api.preguntados.com' -H 'Accept: */*' -H 'Content-Type: application/json; charset=utf-8' -H 'Eter-Agent: 1|iOS-AppStr|iPad 4 (WiFi)|1|iOS 7.0.4|0|2.20|en|en|US|1' -H 'Accept-Language: en-us' -H 'Cookie: ap_session=' -H 'User-Agent: Preguntados/2.20 (iPad; iOS 7.0.4; Scale/2.00)' --data-binary '{"password":"$password","language":"en","email":"$email","user_device":{"device":"iphone","notification_id":"","account_type":"default","installation_id":"00000000-0000-0000-0000-000000000000"}}' --compressed 'https://api.preguntados.com/api/login'`;

	$cookie = $authorize_data->{cookie} = decode_json($requestData)->{session}{session};
	$myPlayerID = $authorize_data->{id} = decode_json($requestData)->{id};

	if (!$cookie || !$myPlayerID) {
		die "Please make sure your email and password are correct\n";
	}

	write_file("TriviaCrackAuth.persistent", encode_json($authorize_data));
}

# DELETE FINISHED GAMES
# this isn't necessary.
system(`curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X DELETE --compressed https://api.preguntados.com/api/users/$myPlayerID/games`);

my $dashboard = `curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed https://api.preguntados.com/api/users/$myPlayerID/dashboard?app_config_version=0`;

if ($dashboard =~ m/^\s$/) {
	print "Error: Invalid cookie/user login?\nTrying to re-get cookie from email&pass login...\n";
	write_cookie_id($authorize_data, $game_email, $game_password);
	$dashboard = `curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed https://api.preguntados.com/api/users/$myPlayerID/dashboard?app_config_version=0`;

	if ($dashboard =~ m/^\s$/) {
		die "Please make sure your email and password are correct\n";
	}
	sleep(1);
}

$dashboard = decode_json($dashboard);
NewGame($dashboard);

$dashboard = `curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed https://api.preguntados.com/api/users/$myPlayerID/dashboard?app_config_version=0`;
$dashboard = decode_json($dashboard);

my @games = @{$dashboard->{list}};
my $gameCount = scalar @games;


print "Amount of open games: " . $gameCount . "\n";
my $turn;
foreach my $game (@games) {
	if ($game->{my_turn}) {
		my @spins = @{$game->{spins_data}{spins}};
		my @questions = @{$spins[0]->{questions}};

		my $questionID = $questions[0]->{question}{id};
		my $category = $questions[0]->{question}{category};
		my $answer = $questions[0]->{question}{correct_answer};

		PlayTurn($game->{id}, $questionID, $category, $answer, $spins[0]->{type});
	}
	else {
		$turn++;
	}
}

if ($turn eq $gameCount) {
	print "None of the open games are your turn\n";
}

sub PlayTurn {
	my ($gameID, $questionID, $category, $answer, $type) = @_;
	if ($type eq "NORMAL" || $type eq "CROWN") {
		my $nextMove = `curl -s -H "Host: api.preguntados.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" --data-binary '{"answers":[{"id":$questionID,"category":"$category","answer":$answer}],"type":"$type"}' --compressed https://api.preguntados.com/api/users/$myPlayerID/games/$gameID/answers`;
		$nextMove = decode_json($nextMove);
		
		my @spins = @{$nextMove->{spins_data}{spins}};
		my @questions = @{$spins[0]->{questions}};

		my $questionID = $questions[0]->{question}{id};	
		my $category = $questions[0]->{question}{category};
		my $answer = $questions[0]->{question}{correct_answer};

		my $type = $spins[0]->{type};
		my $opponentName = $nextMove->{opponent}{username};

		if ($nextMove->{game_status} eq "ACTIVE" || $nextMove->{game_status} eq "PENDING_APPROVAL") {
			print "Recursively vs $opponentName\n";
			sleep(0.1);
			PlayTurn($gameID, $questionID, $category, $answer, $type);
		}
	}
	elsif ($type eq "ENDED") {
		#print "That game ended! $type \n";
	}
	else {
		#print "Unknown: $type \n";
	}
}

sub NewGame {
	my ($dashboard) = @_;
	print $dashboard->{lives}{quantity} . " lives\n";
	if ($dashboard->{lives}{quantity} > 0) {
		print "Making new game\n";
		`curl -s -H "Host: api.preguntados.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" --data-binary '{"opponent_selection_type":"RANDOM","language":"EN"}' --compressed https://api.preguntados.com/api/users/$myPlayerID/games`;
		sleep(1);
		NewGame($newGame);
	} 
}
