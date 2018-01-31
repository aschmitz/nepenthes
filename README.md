# Nepenthes

Nepenthes is an open-source tool for managing network penetration tests, with a focus on external tests with large numbers of hosts; in particular web-heavy networks. Nepenthes can manage different network based scans in parallel; anything from grabbing SSL information and taking screenshots to standard nmap scans. It uses a queueing and scheduling system to allow off-hours scans, scheduled from anywhere around the world. Scans can be performed from as many hosts as desired, including using public clouds. With a web frontend, Nepenthes makes it easy for multiple team members to collaborate on a test, allowing for easy extraction of desired information. A flexible worker system and easy Rails extensibility make Nepenthes easy to modify, as has been done for several tests at Matasano. These features are usually included in future tests to make the experience even better.

## Install
The only officially supported way to run Nepenthes is using two (or more) separate Ubuntu VMs. One VM will be dedicated to managing everything (storing the database, handling user requests, etc.), and the remaining VM(s) will be dedicated to scanning. For our purposes, we'll call the manager VM `sprout`, and assume that there is one scanning VM, called `tendril`. Note that the setup instructions for multiple scanning VMs are exactly the same as for the first one, simply repeat the same steps.

Please note: You will be best served by using the most recent LTS version of Ubuntu. Currently, that is 16.04. In particular, some gems required by Nepenthes no longer support Ruby 1.9, which means Ubuntu 14.04 is no longer usable.

### Scanner (`tendril`)

We will install `tendril` first, as `sprout` connects to the scanner. However, you can perform `tendril` and `sprout` installation in parallel.

* Install a fresh Ubuntu VM. Ubuntu Server 16.04.3 LTS is a good choice, but later versions should still work.
* On the VM, run the following commands in your user's home directory:
    * `wget https://raw.githubusercontent.com/aschmitz/nepenthes/master/script/install-nepenthes-worker.sh`
    * `chmod +x install-nepenthes-worker.sh`
    * `sudo ./install-nepenthes-worker.sh`

### Manager (`sprout`)

* Install a fresh Ubuntu VM. Ubuntu Server 16.04.3 LTS is a good choice, but later versions should still work.
* Note that this server will be installed with a MySQL server with a root password of "root", and should under no circumstances be exposed to the Internet. (This should be changed in Nepenthes soon.)
* On the VM, run the following commands:
    * `wget https://raw.githubusercontent.com/aschmitz/nepenthes/master/script/install-nepenthes-server.sh`
    * `chmod +x install-nepenthes-server.sh`
    * `sudo ./install-nepenthes-server.sh`
        * *Note* the password it gives you, you'll need it to log in to the web interface.
    * `sudo ./start-nepenthes-server.sh`
* For each tendril server, do the following (note that you may wish to run these in `screen` or `tmux`, as they will need to continue running as long as the worker is running):
    * `ssh -R 127.0.0.1:6379:127.0.0.1:6379 user@tendril-host` (log in to your remote VM, and forward your local Redis connection)
    * Inside the SSH session, run `sudo ./start-nepenthes-worker.sh`

## Usage
* Add a region via http://localhost:3000/regions . The start and end test times must be numbers, and will be used to restrict scans to starting between the given hours (in UTC). Using "0" for each number will allow scans to run at any time. Note that a patch for this functionality is pending, and it does not work at the moment.
* Go to http://localhost:3000/ip_addresses and add IP addresses. You can use single IP addresses (one per line, don't comma-separate them), ranges (192.168.1.0 - 192.168.5.255), or CIDR notation (10.0.0.0/24). If you want to tag all of the ranges you're entering at a time in some way (hosting facility, country, whatever), you can add tags for all of them (space-separated) in the appropriate field. To tag just addresses in a specific range, you can put them space-separated after the range, on the same line. Adding thousands of IP addresses will be a bit slow.

## Scanning

There is a web interface for this. It isn't quite as configurable for some scans, but *check it out first*. That's just at http://localhost:3000/ . The instructions below assume you aren't using the web interface, so pick and choose as you go if you want more power than you can extract from the web interface.

### Again, use the web interface home page first

If you need configurability that it doesn't give you, here's a way to run scans manually.

* `rails c`
* Specify some nmap options, such as `opts = ['-Pn', '-p', '80,443,22,25,21,8080,23,3306,143,53', '-sV', '--version-light']`
    * Note: Spaces in the options aren't treated they way you might expect; if the commandline would be `--scan-delay 250ms`, you need to add it as `['--scan-delay', '250ms']`
* `IpAddress.includes(:scans).where(:scans => {:ip_address_id => nil}).each {|ip| ip.queue_scan!(opts) }`
* Note that the `.where(:scans => {:ip_address_id => nil})` portion only queues scans for IP addresses without existing scans. You can modify the conditions if you want, or remove them to scan all IP addresses.
* Wait for a bit while every IP address has a scan queued.
* You can follow progress on http://localhost:3000/sidekiq/ .

## Results

* You can view results while scans are still going on. http://localhost:3000/ports will give a listing of ports found and the number of each, you can click on a port to get a list of hosts, click on a host to get a list of ports for that host, etc.
* There are a bunch of features lurking around that need better documentation. You can add .csv to the end of the URL for any(?) /ports page and get a .csv of the applicable hosts, ports, versions (if applicable), and such.
* http://localhost:3000/ip_addresses.xml will give a combined XML output as if all of the scans were done in one nmap run with XML output. This is handy for importing to Nessus.

## Extending

You can add your own workers to Nepenthes to gather additional information, scan other things, or do whatever you need. Check out `HACKING.md` for information on running Nepenthes on one computer, or writing your own worker.

If you have any problems, feel free to submit an issue. Pull requests welcome.
