#! /usr/bin/perl -s

use v5.10;
use strict;
use warnings;
use File::Path;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

our ($opt_u,$opt_p,$opt_t);
getopts("u:p:t:");

my $vusers_file = "/etc/vusers.txt";
my $allowed_file = "/etc/allowed_users";

my $usage =<<"EOU";
usage : [-u=username] [-p=passwd] [-t=fullpath]
    -u:username ftp user name
    -p:passwd ftp user password
    -t:fullpath ftp user full path
EOU

unless($opt_u or $opt_p or $opt_t){
   print $usage;
   exit;
}

my $name = $opt_u;
my $passwd = $opt_p;
my $ftppath = $opt_t;

&ModifyConfig();

sub ModifyConfig{
    open my $fh,">>",$vusers_file;
    print $fh $name,"\n";
    print $fh $passwd,"\n";
    close $fh;
    `db_load -T -t hash -f /etc/vusers.txt /etc/vsftpd_login.db`;

    my $userfile = "/etc/vsftpd_user_conf/$name";

    my $userfile_content = "";
    $userfile_content .= "anon_world_readable_only=NO\n";
    $userfile_content .= "anon_upload_enable=YES\n";
    $userfile_content .= "anon_mkdir_write_enable=YES\n";
    $userfile_content .= "anon_other_write_enable=YES\n";
    $userfile_content .= "local_root=$ftppath\n";

    open my $fh1,">",$userfile;
    print $fh1 $userfile_content;
    close $fh1;

    open my $fh2,">>",$allowed_file;
    print $fh2 "$name\n";
    close $fh2;

    mkpath($ftppath) unless -e $ftppath;
    `service vsftpd restart`;
}
