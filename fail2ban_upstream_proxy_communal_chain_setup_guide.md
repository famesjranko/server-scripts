## Fail2Ban Setup for Using a Communal `iptables` Chain on an Upstream Server

### Prerequisites:
- **Fail2Ban** is installed and configured on your local server (where the services such as Jellyfin, Nginx, etc. are running).
- **SSH key-based access** is configured from your Fail2Ban server to the upstream server, which will execute the `iptables` rules.
- **iptables** is installed and configured on the upstream reverse proxy server.

### Step 1: Set Up SSH Key-Based Authentication

Ensure the Fail2Ban server can SSH into the upstream server without needing a password. This is crucial for automating the IP ban/unban process.

1. **Generate SSH Key (if not already done):**

   ```bash
   ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa
   ```

2. **Copy the SSH Key to the Upstream Server:**

   ```bash
   ssh-copy-id -i /root/.ssh/id_rsa.pub root@<upstream-server-ip>
   ```

   Replace `<upstream-server-ip>` with the actual IP address of the upstream server.

3. **Test SSH Access:**

   Ensure the SSH connection works without needing a password:

   ```bash
   ssh -i /root/.ssh/id_rsa root@<upstream-server-ip>
   ```

### Step 2: Create a Communal `iptables` Chain on the Upstream Server

We’ll use a single `iptables` chain named `f2b-communal` on the upstream server to handle bans from all Fail2Ban jails.

1. **Log in to the Upstream Server:**

   ```bash
   ssh root@<upstream-server-ip>
   ```

2. **Create the Communal Chain:**

   Create the chain and ensure it is linked to the `INPUT` chain:

   ```bash
   iptables -N f2b-communal
   iptables -C INPUT -j f2b-communal || iptables -I INPUT -j f2b-communal
   ```

3. **Automate Chain Creation at Boot (Cron Job):**

   To ensure the communal chain exists after every reboot, add the following cron job:

   ```bash
   sudo crontab -e
   ```

   Add this line:

   ```bash
   @reboot sleep 30 && ( /usr/sbin/iptables -N f2b-communal 2>/dev/null; /usr/sbin/iptables -C INPUT -j f2b-communal || /usr/sbin/iptables -I INPUT -j f2b-communal )
   ```

This ensures that the chain is automatically created and linked to `INPUT` after every reboot.

### Step 3: Configure the Fail2Ban Action to Use the Communal Chain

We’ll configure Fail2Ban to use the communal chain for both banning and unbanning IPs. This action will be shared by all jails.

1. **Create the Fail2Ban Action File**:

   On the Fail2Ban server, create a new action file at `/etc/fail2ban/action.d/proxy-iptables-communal.conf`:

   ```bash
   sudo nano /etc/fail2ban/action.d/proxy-iptables-communal.conf
   ```

2. **Add the Following Configuration**:

   This action will ban and unban IPs on the upstream server using the communal chain:

   ```ini
   [Definition]

   # No need for actionstart or actionstop since we're using a communal chain

   # Option: actionban
   # Add the IP to the communal chain
   actionban = ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@<upstream-server-ip> "iptables -I f2b-communal 1 -s <ip> -j DROP" && echo "Banned <ip>" >> /var/log/fail2ban.log

   # Option: actionunban
   # Remove the IP from the communal chain
   actionunban = ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@<upstream-server-ip> "iptables -D f2b-communal -s <ip> -j DROP" && echo "Unbanned <ip>" >> /var/log/fail2ban.log
   ```

   Replace `<upstream-server-ip>` with the actual IP address of your upstream server.

### Step 4: Configure Fail2Ban Jails to Use the Communal Chain

Now, modify the Fail2Ban jails to use the communal action for banning and unbanning IPs.

1. **Edit Jail Configuration**:

   Open your jail configuration file, usually located at `/etc/fail2ban/jail.local`:

   ```bash
   sudo nano /etc/fail2ban/jail.local
   ```

2. **Update the Jails to Use the Communal Action**:

   Here’s an example configuration for two jails (`jellyfin` and `nginx-http-auth`):

   ```ini
   [jellyfin]
   enabled  = true
   filter   = jellyfin
   logpath  = /path/to/jellyfin/log
   maxretry = 3
   bantime  = 3600
   action   = proxy-iptables-communal  # Use the communal action

   [nginx-http-auth]
   enabled  = true
   filter   = nginx-http-auth
   logpath  = /var/log/nginx/error.log
   maxretry = 5
   bantime  = 600
   action   = proxy-iptables-communal  # Use the communal action
   ```

   You can add as many jails as you need, all sharing the same communal action.

### Step 5: Restart Fail2Ban and Test the Setup

1. **Restart Fail2Ban**:

   After making the configuration changes, restart Fail2Ban to apply the new settings:

   ```bash
   sudo systemctl restart fail2ban
   ```

2. **Check Jail Status**:

   Verify the status of your jails:

   ```bash
   sudo fail2ban-client status jellyfin
   sudo fail2ban-client status nginx-http-auth
   ```

3. **Test a Ban**:

   Trigger a ban by performing invalid login attempts or by manually banning an IP. For example:

   ```bash
   sudo fail2ban-client set jellyfin banip 192.168.1.100
   ```

   Check if the IP is banned in the communal chain on the upstream server:

   ```bash
   ssh root@<upstream-server-ip> "iptables -L f2b-communal"
   ```

   You should see the IP in the communal chain.

4. **Test Unbanning**:

   To test unbanning, manually unban the IP:

   ```bash
   sudo fail2ban-client set jellyfin unbanip 192.168.1.100
   ```

   Verify that the IP is removed from the communal chain:

   ```bash
   ssh root@<upstream-server-ip> "iptables -L f2b-communal"
   ```

### Step 6: Monitor Logs

You can monitor the Fail2Ban log to ensure everything is working as expected:

```bash
tail -f /var/log/fail2ban.log
```

This log will show messages whenever an IP is banned or unbanned, ensuring the actions are being executed properly.

### Conclusion

You now have a fully functioning Fail2Ban setup that uses a communal `iptables` chain on an upstream reverse proxy server. This setup simplifies the configuration and management of IP banning across multiple Fail2Ban jails, while keeping all bans centralized in a single chain.
