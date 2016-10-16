package MQ::MSMQ;

use v5.10;
use Win32::OLE;

my $computer_name = Win32::NodeName() if(Win32::NodeName());

sub new{
    my $class = shift;
    my $mq = {};

    $mq->{qinfo} = Win32::OLE->new('MSMQ.MSMQQueueInfo') 
	or die "create msmq obj error: ", Win32::OLE->LastError;

    bless $mq, $class;    
}

sub release{
    my $self = shift;
    $self->{qinfo}->Close();
    $self = {};
}

sub open_queue{
    my $self = shift;
    my $qname = shift;
    my $FormatName = "direct=os:$computer_name\\Private\$\\$qname";
    $self->{qinfo}->{FormatName} = $FormatName;

    $self->{$qname} = $self->{qinfo}->Open(1,0) or die "the MSMQ Open Error: ", Win32::OLE->LastError;
}

sub recv_msg{
    my $self = shift;
    my $qname = shift;
    
    my $msg = $self->{$qname}->Receive();
    return $msg;
}

sub send_msg{
    my $self = shift;
    my($qname,$msgheader,$msgbody) = @_;
    my $msg = Win32::OLE->new('MSMQ.MSMQMessage') or die "can not create MSMQ.MSMQMESSAGE: " , Win32::OLE->LastError;
    my $dest = Win32::OLE->new('MSMQ.MSMQDestination') or die "can not create MSMQ.MSMQDestination: " , Win32::OLE->LastError;

    $dest->{FormatName} = "direct=os:$computer_name\\Private\$\\" . $qname;
    $msg->{Label} = $msgheader;
    $msg->{Body} = $msgbody;
    $msg->Send($dest);
    $dest->Close();    
}

sub type{
    my $self = shift;
    return "MSMQ";
}

# 以下是单元测试内容
# use strict;
# use warnings;
# use MQ::MSMQ;

# use Test::Simple tests => 200;

# my $q = MQ::MSMQ->new();

# my $msg_header = "Hello";
# my $msg_body = "this is a test case.";
# my $qname = "test_msmq";
# my $msg;
# $q->open_queue($qname);

# for (1..100){
#     &input();
#     &output();
#     ok($msg_header eq $msg->{Label});
#     ok($msg_body eq $msg->{Body});
# }

# $q->release();

# sub input{  
#     $q->send_msg($qname,$msg_header,$msg_body);
# }

# sub output{
#     $msg = $q->recv_msg($qname);
# }
1;
