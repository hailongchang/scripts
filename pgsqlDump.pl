use v5.10;
use strict;
use warnings;
use Expect;


my $host = "10.0.0.10";
my $port = 5432;
my $dbname = "test";
my $username = "postgres";
my $password = "postgres";


&main();

sub main(){
    my $timestamp = &GetLocalTime();

    my $dbfilename = $timestamp . ".tar";

    my $pgdump = "pg_dump --host $host --port $port --dbname $dbname --format tar --section pre-data --section data --section post-data --file $dbfilename --verbose --username $username --password";

    my $cmd = Expect->new;
    $cmd->raw_pty(1);
    $cmd->spawn($pgdump);
    $cmd->expect(
    	undef,[
    	    qr/Password/i,
    	    sub{
    		$cmd->send($password);
    		$cmd->send("\n");
    		exp_continue;
    	    }]);
}

sub GetLocalTime{    
    my($delimiter) = @_;

    $delimiter = '' unless defined $delimiter;
    my($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time);

    return(
	($year + 1900) . $delimiter . 
	(((++$mon) < 10) ? ("0" . $mon) : ($mon)) . $delimiter . 
	((($mday) < 10 ) ? ("0" . $mday) : ($mday)) .

	((($hour) < 10 ) ? ("0" . $hour) : ($hour)) . "" . 
	((($min) < 10 ) ? ("0" . $min) : ($min)) . "" .
	((($sec) < 10 ) ? ("0" . $sec) : ($sec))
	);
}




