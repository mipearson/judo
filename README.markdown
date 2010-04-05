# Judo

Judo is a tool for managing a cloud of ec2 servers.  It aims to be both simple
to get going and powerful.

## CONCEPTS

Config Repo: Judo keeps it configuration for each server group in a git repo.

State Database: Judo keeps cloud state and information on specific servers in SimpleDB.

Server: Judo does not track EC2 instances, but Servers, which are a collection
of state, such as EBS volumes, elastic IP addresses and a current EC2 instance
ID.  This allows you to abstract all the elastic EC2 concepts into a more
traditional concept of a static Server.

##	STARTING

You will need an AWS account with EC2, S3 and SDB all enabled.

Setting up a new judo repo named "my_cloud" would look like this:

    $ mkdir my_cloud
    $ cd my_cloud
    $ git init
    $ judo init

The 'judo init' command will make a .judo folder to store your EC2 keys and S3
bucket.  It will also make a folder named "default" to hold the default server
config.

To view all of the groups and servers running in those group you can type:

    $ judo list
      SERVER GROUPS
    default            0 servers

To launch a default server you need to cd into the default folder:

    $ cd default
    $ judo create my_server_1
    ---> Creating server my_server_1...     done (0.6s)
    $ judo list
      SERVER IN GROUP my_server_1
    my_server_1                       m1.small    ami-bb709dd2             0 volumes
    $ judo start my_server_1
    No config has been committed yet, type 'judo commit'

The server has now been created but cannot be launched because the config has
not been committed.  Committing the config loads the config.json and all of the
scripts and packages it needs to run into your S3 bucket.  The config probably
looks something like this:

    $ cat config.json
    {
        "key_name":"judo14",
        "instance_size":"m1.small",
        "ami32":"ami-bb709dd2", // public ubuntu 9.10 ami - 32 bit
        "ami64":"ami-55739e3c", // public ubuntu 9.10 ami - 64 bit
        "user":"ubuntu",
        "security_group":"judo",
        "availability_zone":"us-east-1d"
    }

The default config uses the public ubuntu 9.10 ami's.  It runs in the judo
security group and a judo key pair (which were made during the init process).
The user parameter is the user the 'judo ssh' command attempts to ssh in using
the keypair.  Other debian based distros can be used assuming they have current
enough installations of ruby (1.8.7) and rubygems (1.3.5).

    $ judo commit
    Compiling version 1
    a default
    a default/config.json
    Uploading to s3...
    $ judo start my_server_1
    ---> Starting server my_server_1... done (2.3s)
    ---> Acquire hostname...      ec2-1-2-3-4.compute-1.amazonaws.com (49.8s)
    ---> Wait for ssh...          done (9.8s)
    $ judo list
      SERVER IN GROUP default
    my_server_1       v1   i-80000000  m1.small    ami-bb709dd2  running    0 volumes  ec2-1-2-3-4.compute-1.amazonaws.com

We can now see that 'my_server_1' is running and running with version 1 of the
config.  We can create and start a server in one step with the launch command.

    $ judo launch my_server_2
    ---> Creating server my_server_2... done (0.6s)
    ---> Starting server my_server_2... done (1.6s)
    ---> Acquire hostname...      ec2-1-2-3-5.compute-1.amazonaws.com (31.1s)
    ---> Wait for ssh...          done (6.1s)

This will create and start two servers.  One named 'my_server_1' and one named
'my_server_2'.  You can ssh into 'my_server_1' you can type:

    $ judo ssh my_server_1

You can stop all the servers with:

    $ judo stop

Note that since no name was specified it will stop all servers in the group.
You could also have typed:

  $ judo stop my_server_1 my_server_2

##  COMMANDS

NOTE: many servers take an argument of "[SERVERS...]".  This indicates that the
command must be run in a group folder (specifying which group of servers to work
on). Zero or more server names can be used.  If no server is named, the
operation is run on all servers.  For instance:

    $ judo restart primary_db backup_db

This will restart only the servers named 'primary_db' and 'backup_db'.  Where as

    $ judo restart

will restart all servers in the group.

-------------------------------------------------------------------------------

    $ judo create NAME

Creates a new named server in the current group.  Will allocate EBS and Elastic
IP's as needed.

    $ judo create +N

Creates N new servers where N is an integer.  These servers have generic names
(group.N).  Note: servers with generic names AND no external resources (like
EBS Volumes or Elastic IPs) will be destroyed when stopped.

  $ judo destroy NAME

Destroy the named server.  De-allocates any elastic IP's and destroys the EBS
volumes.

    $ judo start [SERVERS...]
    $ judo stop [SERVERS...]
    $ judo restart [SERVERS...]

Starts stops or restarts then starts the given servers.

    $ judo launch NAME
    $ judo launch +N

Performs a 'judo create' and a 'judo start' in one step.

    $ judo ssh [SERVERS...]

SSH's into the servers given.

    $ judo list

At the top level it will list all of the groups and how many servers are in
each group.  Within a group it will list each server and its current state.

    $ judo commit

Commits the current group config and files to S3.  New servers launched will
use this new config.

    $ judo console [SERVERS...]

See the AWS console output for the given servers.

    $ judo ips

This command gives you a top down view of all elastic IP addresses allocated
for the AWS account and what servers or instances they are attached to.

    $ judo volumes

This command gives you a top down view of all EBS volumes allocated for the AWS
account and what servers or instances they are attached to.

## EXAMPLES

An example is worth a thousand words.

A couchdb server:

### ./couchdb/config.json

    {
        // dont repeat yourself - import the basic config
        "import" : "default",
        // its a db so we're going to want to have a static ip
        "elastic_ip" : true,
        // only need 1 package
        "packages" : "couchdb",
        "volumes" : { "device" : "/dev/sde1",
                      "media"  : "ebs",
                      "size"   : 64,
                      "format" : "ext3",
                      // this is where couchdb looks for its data by default
                      "mount"  : "/var/lib/couchdb/0.10.0",
                      // make sure the data is owned by the couchdb user
                      "user"   : "couchdb",
                      "group"  : "couchdb",
                      // bounce couch since the data dir changed
                      "after"  : "#!/bin/bash\n service couchdb restart\n" }
    }

A memcached server:

### ./memcache/config.json
    {
        // dont repeat yourself - import the basic config
        "import" : "default",
        // its a data store so we're going to want to have a static ip
        "elastic_ip" : true,
        // only need 1 package
        "packages" : "memcached",
        "instance_size" : "m1.xlarge",
        "files" : [
          { "file"     : "/etc/memcached.conf",
            "template" : "memcached.conf.erb" },
          { "file"     : "/etc/default/memcached",
            "source"   : "memcached-default" },
        "after" : "#!/bin/bash\n service memcached start\n"
    }

### ./memcache/files/memcached-default

    # Set this to yes to enable memcached.
    ENABLE_MEMCACHED=yes

### ./memcache/templates/memcached.conf.erb

    -d
    logfile /var/log/memcached.log
    ## ohai gives memory in Kb so div by 1024 to get megs
    ## use 75% of total ram (* 0.75)
    -m <%= (@system.memory["total"].to_i / 1024 * 0.75).to_i %>
    -u nobody

A redis server with a 2 disk xfs raid 0:

### ./redis/config.json

    {
        // dont repeat yourself - import the basic config
        "import" : "default",
        "elastic_ip" : true,
        "instance_size" : "m2.xlarge",
        "local_packages" : { "package" : "redis-server_1.2.5-1", "source" : "http://http.us.debian.org/debian/pool/main/r/redis/" },
        "volumes" : [{ "device" : "/dev/sde1",
                       "media"  : "ebs",
                       "scheduler" : "deadline",
                       "size"   : 16 },
                     { "device" : "/dev/sde2",
                       "media"  : "ebs",
                       "scheduler" : "deadline",
                       "size"   : 16 },
                     { "device"    : "/dev/md0",
                      "media"     : "raid",
                      "mount"     : "/var/lib/redis",
                      "drives"    : [ "/dev/sde1", "/dev/sde2" ],
                      "user"      : "redis",
                      "group"     : "redis",
                      "level"     : 0,
                      "format"    : "xfs" }]
    }

## CONFIG - LAUNCHING THE SERVER

The easiest way to make a judo config is to start with a working example and
build from there.  Complete documentation of all the options are below.  Note:
you can add keys and values NOT listed here and they will not harm anything, in
fact they will be accessible (and useful) in the erb templates you may include.

    "key_name":"judo123",

This specifies the name of the EC2 keypair passed to the EC2 instance on
launch.  Normally you never need to set this up as it is setup for you in the
default config.  The system is expecting a registered keypair in this case
named "keypair123" with a "keypair123.pem" file located in a subfolder named
"keypairs".

    "instance_size":"m1.small",

Specify the instance size for the server type here. See:
http://aws.amazon.com/ec2/instance-types/

  "ami32":"ami-bb709dd2",
  "ami64":"ami-55739e3c",
  "user":"ubuntu",

This is where you specify the AMI's to use.  The defaults (above) are the
ubuntu 9.10 public AMI's.  The "user" value is which user has the keypair
bound to it for ssh'ing into the server.

  "security_group":"judo",

What security group to launch the server in.  A judo group is created for you
which only has port 22 access.  Manually create new security groups as needed
and name them here.

  "availability_zone":"us-east-1d"

What zone to launch the server in.

    "elastic_ip" : true,

If this is true, an elastic IP will be allocated for the server when it is
created.  This means that if the server is rebooted it will keep the same IP
address.

    "import" : "default",

This command is very import and allows you inherit the configurations and files
from other groups.  If you wanted to make a group called 'mysql' that was
exactly like the default group except it installed the mysql package and ran on
a m2.4xlarge instance type you could specify it like this:
	{ "import : "default", "packages" : [ "mysql" ], "instance_size" : "m2.4xlarge" }
and save yourself a lot of typing.  You could further subclass by making a new
group and importing this config.

    "volumes" : [ { "device" : "/dev/sde1", "media" : "ebs", "size" : 64 } ],

You can specify one or more volumes for the group.  If the media is of type
"ebs" judo will create an elastic block device with a number of gigabytes
specified under size.  AWS currently allows values from 1 to 1000.  If the
media is anything other than "ebs" judo will ignore the entry.  The EBS drives
are tied to the server and attached as the specified device when started.  Only
when the server is destroyed are the EBS drives deleted.

## CONFIG - CONTROLLING THE SERVER

Judo uses kuzushi (a ruby gem) to control the server once it boots and will
feed the config and files you have committed with 'judo commit' to it.  At its
core, kuzushi is a tool to run whatever custom scripts you need in order to put
the server into the state you want.  If you want to use puppet or chef to
bootstrap your server.  Put the needed commands into a script and run it.  If
you just want to write your own shell script, do it.  Beyond that kuzushi has
an array of tools to cover many of the common setup steps to prevent you from
having to write scripts to reinvent the wheel.  The hooks to run your scripts
come in three forms.

    "before" : "script1.sh",   // a single script
    "init"   : [ "script2.rb", "script3.pl" ], // an array of scripts
    "after"  : "#!/bin/bash\n service restart mysql\n",  // an inline script

Each of the hooks can refer to a single script (located in the "scripts" subfolder),
or a list of scripts, or an inline script which can be embedded in the config data.
Inline scripts are any string beginning with the magic unix "#!".

The "before" hook runs before all other actions.  The "after" hook runs after
all other actions.  The "init" hook runs right before the "after" hook but only
on the server's very first boot.  It will be skipped on all subsequent boots.

These three hooks can be added to to any hash '{}' in the system.

    "files" : [ { "file"   : "/etc/apache2/ports.conf" ,
                "before" : "stop_apache2.sh",
                "after"  : "start_apache2.sh" } ],

This example runs the "stop_apache2.sh" script before installing the ports.conf
file and runs 'start_apach2.sh" after installing it.  If there was some one time
formatting to be done we could add an "init" hook as well.

After running "before" and before running "init" and "after" the following
hooks will run in the following order:

    "packages" : [ "postgresql-8.4", "postgresql-server-dev-8.4", "libpq-dev" ],

Packages listed here will be installed via 'apt-get install'.

    "local_packages" : [ "fathomdb_0.1-1" ],
    "local_packages" : [{ "package" : "redis-server_1.2.5-1", "source" : "http://http.us.debian.org/debian/pool/main/r/redis/" }],

The "local_packages" hook is for including debs.  Either hand compiled ones you
have included in the git repo, or ones found in other repos.  Judo will include
both the i386 and amd64 versions of the package in the commit.

In the first case judo will look in the local packages subfolder for
"fathomdb_0.1-1_i386.deb" as well as "fathomdb_0.1-1_amd64.deb".  In the second
case it will attempt to use curl to fetch the following URLs.

http://http.us.debian.org/debian/pool/main/r/redis/redis-server-1.2.5-1_i386.deb
http://http.us.debian.org/debian/pool/main/r/redis/redis-server-1.2.5-1_amd64.deb

Both types of local packages can be intermixed in config.

    "gems" : [ "thin", "rake", "rails", "pg" ],

The "gems" hook lists gems to be installed on the system on boot via "gem install ..."

    "volumes" : [ { "device"    : "/dev/sde1",
                  "media"     : "ebs",
                  "size"      : 64,
                  "format"    : "ext3",
                  "scheduler" : "deadline",
                  "label"     : "/wal",
                  "mount"     : "/wal",
                  "mount_options" : "nodev,nosuid,noatime" },
                { "device"    : "/dev/sdf1",
                  "media"     : "ebs",
                  "size"      : 128,
                  "scheduler" : "cfq" },
                { "device"    : "/dev/sdf2",
                  "media"     : "ebs",
                  "size"      : 128,
                  "scheduler" : "cfq" },
                { "media"     : "tmpfs",
                  "options"   : "size=500M,mode=0744",
                  "mount"     : "/var/lib/stats",
                  "user"      : "stats",
                  "group"     : "stats" },
                { "device"    : "/dev/md0",
                  "media"     : "raid",
                  "mount"     : "/database",
                  "drives"    : [ "/dev/sdf1", "/dev/sdf2" ],
                  "level"     : 0,
                  "chunksize" : 256,
                  "readahead" : 65536,
                  "format"    : "xfs",
                  "init"      : "init_database.sh" } ],

The most complex and powerful hook is "volumes".  While volumes of media type
"ebs" are created when the server is created the media types of "raid" and
"tmpfs" are also supported.  If a format is specified, kuzushi will format the
volume on the server's very first boot.  Currently "xfs" and "ext3" are the
only formats supported.  Using "xfs" will install the "xfsprogs" package
implicitly. If a label is specified it will be set at format time.  If "mount"
is specified it will be mounted there on boot, with "mount_options" if
specified. A "readahead" can be set to specify the readahead size, as well as
a scheduler which can be "noop", "cfq", "deadline" or "anticipatory".  Volumes
of type "raid" will implicitly install the "mdadm" package and will expect a
list of "drives", a "level" and a "chunksize".

Kuzushi will wait for all volumes of media "ebs" to attach before proceeding
with mounting and formatting.

    "files" : [ { "file"     : "/etc/postgresql/8.4/main/pg_hba.conf" },
                { "file"     : "/etc/hosts",
                   "source"   : "hosts-database" },
                { "file"     : "/etc/postgresql/8.4/main/postgresql.conf",
                   "template" : "postgresql.conf-8.4.erb" } ],

The "files" hook allows you to install files in the system. In the first example
it will install a ph_hba.conf file.  Since no source or template is given it will
look for this file in the "files" subdirectory by the same name.

The second example will install "/etc/hosts" but will pull the file
"hosts-database" from the "files" subfolder.

The third example will dynamically generate the postgresql.conf file from an erb
template.  The erb template will have access to two special variables to help
it fill out its proper options. The variable "@config" will have the hash of data
contained in json.conf including the data imported in via the "import" hook. There
will also be a "@system" variable which will have all the system info collected by
the ruby gem "ohai".

    "crontab" : [ { "user" : "root", "file" : "crontab-root" } ],

The "crontab" hook will install a crontab file from the "crontabs" subfolder with
a simple "crontab -u #{user} #{file}".

-------------------------------------------------------------------------------
	CONFIG - DEBUGGING KUZUSHI
-------------------------------------------------------------------------------

If something goes wrong its good to understand how judo uses juzushi to manage
the server.  First, judo sends a short shell script in the EC2 user_data in to
launch kuzushi.  You can see the exact shell script sent by setting the
environment variable "JUDO_DEBUG" to 1.

    $ export JUDO_DEBUG=1
    $ judo launch +1

This boot script will fail if you choose an AMI that does not execute the ec2
user data on boot, or use apt-get, or have rubygems 1.3.5 or higher in its
package repo.

You can log into the server and watch kuzushi's output in /var/log/kuzushi.log

    $ judo start my_server
    ...
    $ judo ssh my_server
    ubuntu:~$ sudo tail -f /var/log/kuzushi.log

If you need to re-run kuzushi manually, the command to do so is either (as root)

    # kuzushi init S3_URL

or

    # kuzushi start S3_URL

Kuzushi "init" if for a server's first boot and will run "init" hooks, while
"start" is for all other boots.  The S3_URL is the url of the config.json and
other files commited for this type of server.  To see exactly what command
was run on this specific server boot check the first line of kuzushi.log.

    ubuntu:~$ sudo head -n 1 /var/log/kuzushi.log


== Meta

Created by Orion Henry and Adam Wiggins. Forked from the gem 'sumo'.

Patches contributed by Blake Mizerany, Jesse Newland, Gert Goet, and Tim Lossen

Released under the MIT License: http://www.opensource.org/licenses/mit-license.php

http://github.com/orionz/judo
