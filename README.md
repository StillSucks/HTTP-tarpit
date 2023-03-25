# HTTP-tarpit, a proof-of-concept

Inspired by other 'tarpit' projects, this is an example on how to establish a HTTP tarpit (optionally with nginx).

## Conceptual Idea
The basis of this approach is piping `pv` into `nc` (netcat), which allows a custom 'response speed' to a HTTP request.  
see: serveDefaultHtmlViaNc.sh

However, wheras `pv` terminates at some point, netcat terminates only after closing a connection.
If a client connects to netcat after `pv` has terminated, the response will be sent without delay.
Therefore, a 'supervising' script restarts the main process after a defined duration.  
see: loopTheScript_serveDefaultHtmlViaNc.sh

As practical application (nginx webserver), multiple processes are initialized and encapsuled by a systemd unit.
Here, nginx acts as a reverse proxy, that can differenciate between 'allowed' and 'illegal' requests.  
see: exemplary_nginx-defaultsite, exemplary_httptarpit.service

## Usage
The easiest way to use this PoC, is the following setup:
1. Login to a (new) (Ubuntu) Linux Server
2. Install nginx (netcat should be installed by default)
3. Change `WorkingDirectory` variable in `exemplary_httptarpit.service` to an absolute path of this directory
    ```
    escapedPWD=$(echo "$PWD" | sed 's/\//\\\//g')
    sed -Ei "s/(WorkingDirectory\s*=\s*)[\w\/\.]+/\1$escapedPWD/" exemplary_httptarpit.service
    ```
4. Make .sh files executeable by user `` from `exemplary_httptarpit.service`
    ```
    chown www-data serveDefaultHtmlViaNc.sh loopTheScript_serveDefaultHtmlViaNc.sh
    chmood 744 serveDefaultHtmlViaNc.sh loopTheScript_serveDefaultHtmlViaNc.sh
    ```
5. Move / Sym-Link example files to current system (optionally backing up existing files)
    ```
    mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    cp exemplary_nginx-defaultsite /etc/nginx/sites-available/default
    cp exemplary_httptarpit.service /usr/lib/systemd/system/httptarpit.service
    ```
6. Reload the systemd daemon (to detect httptarpit.service)
    ```
    systemctl daemon-reload
    ```
7. Restart both nginx and httptarpit
    ```
    systemctl restart nginx
    systemctl restart httptarpit
    ```
8. Optional: Create DNS entry (and use it in nginx), implement HTTPS via `certbot`, change whitelist/blacklist in nginx config file according to 'allowed' URLs
