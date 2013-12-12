# Nepenthes

# This README is actually informative. Please read it before starting to use Nepenthes.

## Install
* `brew install phantomjs coreutils` or `sudo apt-get install phantomjs`, depending on your OS.
* `bundle install`
* `cp config/database.yml.example config/database.yml` 
* `cp config/auth.yml.example config/auth.yml`
* Edit config/database.yml. Set it up with MySQL or MariaDB, please. You'll be happy you did. SQLite, in particular, is problematic.
* Edit config/auth.yml. Pick a username and password. You'll be using HTTP Basic auth, with the same username/password for everybody.
* `echo "Nepenthes::Application.config.secret_token = \"``rake secret``\"" > config/initializers/secret_token.rb` (Note that you need backticks around "rake secret", but our GH markdown doesn't seem to tolerate double backticks well.)
* Make sure that your database is running (MySQL - `mysql.server start` - or SQLite)
* Edit the `config/database.yml` to have the correct connection info for your database
* `rake db:create` to create the netpen database.
* `rake db:migrate`
* If you're not already running Redis, run it. (`redis-server` in a new terminal window is fine, as is running it as a daemon.) Be warned that Redis listens on all interfaces by default. Nepenthes only needs to access it via localhost, so feel free to lock down Redis' configuration.
* `rails s`
* In another terminal window on your local computer, run `sidekiq -c 4 -r . -q results -v`. (If you are using SQLite, you *must not* use more than one thread here. Other databases can use more, but it won't help much: this isn't a very slow step.)
* Visit http://localhost:3000/regions

If you want to run Nepenthes workers locally:
* First, reconsider. You *should not* do this from inside a NAT if you're scanning anything public. If you're fully inside a VPN, it *might* work, but may also crash the VPN. The reasoning here is that you're running a lot of nmap scans and will quickly fill up NAT tables and related resources. Doing this will make your sysadmin sad.
* Second, if you've decided to go for it anyway and not blame any Nepenthes authors, make sure you have local copies of whatever tools you might use. This includes nmap for scans, phantomjs for screenshots, and nikto for Nikto scans.
* Finally, you will want to run the two `sidekiq` commands from the second below on your local machine. You may need to adjust the `~/nepenthes` directory to suit your environment. You do not need to play with editing the database.yml file, installing the bundle without the local group, or anything else. Your machine likely has more than 0.5 GB of RAM, so consider increasing the thread count if you have sufficient bandwidth to your target.

For remote workers (highly recommended, VPSes are cheap and many allow scanning if you only scan ranges you have permission to scan):

* Get something running *Ubuntu 12.10 or newer* (older versions have severely outdated copies of some packages, and errors will result).
* From your local Nepenthes directory, run `rsync -a --exclude log --exclude log --exclude config/database.yml --exclude .bundle --exclude Gemfile.lock . tendril:~/nepenthes` (where `tendril` is your host, consider adding it to your `.ssh/config`)
* `ssh -R 127.0.0.1:6379:127.0.0.1:6379 tendril` (log in to your remote VM, and forward your local Redis connection)
* The rest is on the remote VM:
* `sudo apt-get install ruby1.9.1 ruby1.9.1-dev libsqlite3-dev libxslt1-dev nmap phantomjs nikto`
* `sudo gem install --no-rdoc --no-ri bundler`
* `cd ~/nepenthes`
* `cp config/database.yml.example config/database.yml` (you don't need to edit it this time, the in-memory SQLite3 is fine for remote workers: they don't store data.)
* `bundle install --without local`
* You'll probably want to run these in two `screen` windows (or at the very least, two terminal windows, as they should be run concurrently):
* `sidekiq -e sidekiq -c 2 -r ~/nepenthes -q himem_fast -q himem_slow -v` and `sidekiq -e sidekiq -c 20 -r ~/nepenthes -q lomem_fast -q lomem_slow -v`. These settings work well for 512 MB of RAM. You can add more threads (under the -c parameter) as desired, and you will want way more of the "lomem" workers for large sets of scans. Consider getting more RAM or more VMs if this is the case, or the OS will OOM kill your nmap processes, and nothing will get done. One user noted that 150 lomem threads worked for him with 1 GB of RAM.

Feel free to repeat the "for remote workers" section on as many VMs as you want. You will get more mileage out of additional RAM before you get help from multiple VMs, but multiple VMs isn't a bad thing.

## Usage
* Add a region via http://localhost:3000/regions . The start and end test times must be numbers, but don't actually matter at the moment.
* Go to http://localhost:3000/ip_addresses and add IP addresses. You can use single IP addresses (one per line, don't comma-separate them) or ranges (192.168.1.0 - 192.168.5.255). CIDR support doesn't currently work, but I think that's a matter of changing a regex. If you want to tag all of the ranges you're entering at a time in some way (hosting facility, country, whatever), you can add tags for all of them (space-separated) in the appropriate field. To tag just addresses in a specific range, you can put them space-separated after the range, on the same line. Adding thousands of IP addresses will be a bit slow.

## Scanning

There is now a web interface for this. It isn't quite as configurable for some scans, but *check it out first*. That's just at http://localhost:3000/ . The instructions below assume you aren't using the web interface, so pick and choose as you go if you want more power than you can extract from the web interface.

### Again, use the web interface home page first. If you need configurability that it doesn't give you, here's a way to run them manually.

* `rails c`
* Specify some nmap options, such as `opts = ['-Pn', '-p', '80,443,22,25,21,8080,23,3306,143,53', '-sV', '--version-light']`
** Note: Spaces in the options aren't treated they way you might expect; if the commandline would be `--scan-delay 250ms`, you need to add it as `['--scan-delay', '250ms']`
* `IpAddress.includes(:scans).where(:scans => {:ip_address_id => nil}).each {|ip| ip.queue_scan!(opts) }`
* Wait for a bit while every IP address has a scan queued.
* You can follow progress on http://localhost:3000/sidekiq/ .

For full scans:

* After you've done your lighter scans (and ideally after they've actually returned results - full scans are queued first for hosts with open ports), schedule full scans in the console: `IpAddress.queue_full_scans!`

Once your scans are done:

* To check whether ports are using *SSL* or not: `Port.check_all_ssl!`.
* To get *screenshots* of applicable webpages (including on all ports), do `Port.take_all_screenshots!`. This is on the `screenshot` queue, and requires PhantomJS on the worker. (Packages exist in most OS's package managers, any recent version is fine.) `sidekiq -c [number of threads] -r . -q screenshot -v` will get it running.
* To process the results, you'll want to keep a results processor going. `sidekiq -c 4 -r . -q results -v` if you didn't still have it running.

## Results

* You can view results while scans are still going on. http://localhost:3000/ports will give a listing of ports found and the number of each, you can click on a port to get a list of hosts, click on a host to get a list of ports for that host, etc.
* There are a bunch of features lurking around that need better documentation. You can add .csv to the end of the URL for any(?) /ports page and get a .csv of the applicable hosts, ports, versions (if applicable), and such.
* http://localhost:3000/ip_addresses.xml will give a combined XML output as if all of the scans were done in one nmap run with XML output. This is handy for importing to Nessus.

## Extending

You can add your own workers to Nepenthes to gather additional information, scan other things, or do whatever you need. Check out `HACKING.md` for information on writing your own worker.

If you have any problems, feel free to submit an issue. Pull requests welcome.
