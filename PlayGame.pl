#!/usr/bin/perl

# execute every ~10 min

use JSON;

our $cookie = "xx";
our $myPlayerID = "xx";

# DELETE FINISHED GAMES
system(`curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X DELETE --compressed https://api.preguntados.com/api/users/$myPlayerID/games`);

my $dashboard = `curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed https://api.preguntados.com/api/users/$myPlayerID/dashboard?app_config_version=0`;
$dashboard = decode_json($dashboard);
NewGame($dashboard);

#re-get dashboard after using any of our lives
$dashboard = `curl -s -H "Host: api.preguntados.com" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Accept-Language: en-us" --data-binary "" -X GET --compressed https://api.preguntados.com/api/users/$myPlayerID/dashboard?app_config_version=0`;
$dashboard = decode_json($dashboard);

my @games = @{$dashboard->{list}};
my $gameCount = scalar @games;


print "Amount of 'games': " . $gameCount . "\n";

foreach my $game (@games) {
	# if game is my turn, play it
	if ($game->{my_turn}) {
		#print "Playing game ID: " . $game->{id} . "\n";
		#print "This is my turn\n";
		my @spins = @{$game->{spins_data}{spins}};
		my @questions = @{$spins[0]->{questions}};

		my $questionID = $questions[0]->{question}{id};
		my $category = $questions[0]->{question}{category};
		my $answer = $questions[0]->{question}{correct_answer};

		PlayTurn($game->{id}, $questionID, $category, $answer, $spins[0]->{type});
	}
	else {
		#print "This is not my turn\n";
	}
}

sub PlayTurn {
	my ($gameID, $questionID, $category, $answer, $type) = @_;
	if ($type eq "NORMAL" || $type eq "CROWN") {
		my $nextMove = `curl -s -H "Host: api.preguntados.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" --data-binary '{"answers":[{"id":$questionID,"category":"$category","answer":$answer}],"type":"$type"}' --compressed https://api.preguntados.com/api/users/$myPlayerID/games/$gameID/answers`;
		$nextMove = decode_json($nextMove);
		
		# beep boop I am not a robot
		#sleep(5);
		
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
		system(`curl -s -H "Host: api.preguntados.com" -H "Content-Type: application/json; charset=utf-8" -H "Accept-Language: en-us" -H "Cookie: ap_session=$cookie" -H "Accept: */*" -H "User-Agent: Preguntados/2.37 (iPhone; iOS 10.3.1; Scale/2.00)" -H "Eter-Agent: 1|iOS-AppStr|iPhone7,2|0|iOS 10.3.1|0|2.37|en-US|en-US|US|1" --data-binary '{"opponent_selection_type":"RANDOM","language":"EN"}' --compressed https://api.preguntados.com/api/users/$myPlayerID/games`);
		sleep(1);
		NewGame($newGame);
	} 
}
