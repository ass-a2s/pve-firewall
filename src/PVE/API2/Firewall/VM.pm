package PVE::API2::Firewall::VM;

use strict;
use warnings;
use PVE::JSONSchema qw(get_standard_option);
use PVE::Cluster;
use PVE::Firewall;

use Data::Dumper; # fixme: remove

use base qw(PVE::RESTHandler);

__PACKAGE__->register_method({
    name => 'index',
    path => '',
    method => 'GET',
    permissions => { user => 'all' },
    description => "Directory index.",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	    vmid => get_standard_option('pve-vmid'),
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => {},
	},
	links => [ { rel => 'child', href => "{name}" } ],
    },
    code => sub {
	my ($param) = @_;

	my $result = [
	    { name => 'rules' },
	    { name => 'options' },
	    ];

	return $result;
    }});

__PACKAGE__->register_method({
    name => 'get_rules',
    path => 'rules',
    method => 'GET',
    description => "List VM firewall rules.",
    proxyto => 'node',
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	    vmid => get_standard_option('pve-vmid'),
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => {},
	},
    },
    code => sub {
	my ($param) = @_;

	my $vmid = $param->{vmid};

	my $vmlist = PVE::Cluster::get_vmlist();

	die "no such VM ('$vmid')\n" 
	    if !($vmlist && $vmlist->{ids} && defined($vmlist->{ids}->{$vmid}));

	my $vmfw_conf = PVE::Firewall::load_vmfw_conf($vmid);

	my $rules = $vmfw_conf->{rules} || [];

	my $digest = $vmfw_conf->{digest};

	my $res = [];
	
	my $ind = 0;
	foreach my $rule (@$rules) {
	    push @$res, PVE::Firewall::cleanup_fw_rule($rule, $digest, $ind++);
	}

	return $res;
    }});

__PACKAGE__->register_method({
    name => 'get_options',
    path => 'options',
    method => 'GET',
    description => "Get host firewall options.",
    proxyto => 'node',
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	    vmid => get_standard_option('pve-vmid'),
	},
    },
    returns => {
	type => "object",
	properties => {},
    },
    code => sub {
	my ($param) = @_;

	my $vmid = $param->{vmid};

	my $vmlist = PVE::Cluster::get_vmlist();

	die "no such VM ('$vmid')\n" 
	    if !($vmlist && $vmlist->{ids} && defined($vmlist->{ids}->{$vmid}));

	my $vmfw_conf = PVE::Firewall::load_vmfw_conf($vmid);

	my $options = $vmfw_conf->{options} || {};

	my $digest = $vmfw_conf->{digest};

	$options->{digest} = $digest;

	return $options;
    }});

1;
