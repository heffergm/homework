# Solution Comments

Cloning this repository and running `./provision.sh` will yield a PASS for all the requirements.

### General Playbook Comments

Modified existing `include: tasks/deps.yml` to be `include_tasks`, to resolve deprecation warning.
In keeping with the separation of various tasks in individual include files, I broke out the
installation and configuration of runit, the application and nginx into individual include files.

### Runit Playbook Comments

Ansible friendly setup using `yum_repository` to the repos, as curl'ing a script off the internet and piping it to `sudo bash` isn't the best.

### Application Playbook Comments

I stuck with ansible friendly declarative syntax for all the things, including unpacking the app,
setting up any required directory structure, etc. I spent an extra couple minutes doing the
following:

- created a logging configuration, mainly as a slave to habit and general good practice
- updated the app run script to run it as `nobody`. Outside of docker, don't like to run services as root.

### Nginx Playbook Comments

Installs nginx via EPEL. Copies in required files with strict perms for SSL related items.

I didn't bother creating an init or runit script for nginx and just let it daemonize itself. Were this
something that ended up being used in an environment where it mattered, I'd use runit simply to
maintain commonality among all services related to the application.

### Nginx Config Comments

Creates an upstream backend for the application, then sets up a listener on :80, which redirects
everything back to https. Then the server on 443 configures ssl. Here it's worth noting I'm not
an expert on SSL ciphers, and tend to favor SSL termination at the load balancer whenever possible,
but a little Google'ing seems to suggest these settings are sane.

Finally I set x-forwarded-for and x-real-ip headers and pass any incoming requests to our upstream.
