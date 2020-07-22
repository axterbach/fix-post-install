#!/usr/bin/env bash

### Harden OpenSSH Server
### https://www.tecmint.com/secure-openssh-server/
#
# Local host:    192.168.1.10
# Remote server: 192.168.1.50

# 1. Setup SSH Passwordless Authentication
#
# Generate SSH keys on local host
ssh-keygen -t rsa -b 2048
# Create .ssh dir on server
ssh cober@192.168.1.50 "mkdir -p .ssh"
# Upload Generated Public Keys to server
cat .ssh/id_rsa.pub | ssh cober@192.168.1.50 'cat >> .ssh/authorized_keys'
# Set Permissions
ssh cober@192.168.1.50 'chmod 0700 .ssh; chmod 0640 .ssh/authorized_keys'
# Login to server without password
ssh cober@192.168.1.50
# Disable password authentication on server
sudo nano /etc/ssh/sshd_config
...
PasswordAuthentication no
...
# Restart SSH damon.
sudo systemctl restart sshd

# 2. Disable User SSH Passwordless Connection Requests
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
PermitEmptyPasswords no
...
# Restart SSH damon.
sudo systemctl restart sshd

# 3. Disable SSH Root Logins
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
PermitRootLogin no
...
# Restart SSH damon.
sudo systemctl restart sshd

# 4. Use SSH Protocol 2
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
Protocol 2
...
# Restart SSH damon.
sudo systemctl restart sshd
# Logout and test new protocol.
exit
ssh -1 cober@192.168.1.20
ssh -2 cober@192.168.1.20

# 5. Set SSH Connection Timeout Idle Value
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
# Timeout value = ClientAliveInterval * ClientAliveCountMax
# 9 min = 180 sec * 3  
ClientAliveInterval 180
ClientAliveCountMax 3
...
# Restart SSH damon.
sudo systemctl restart sshd

# 6. Limit SSH Access to Certain Users
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
AllowUsers cober
...
# Restart SSH damon.
sudo systemctl restart sshd

# 7. Configure a Limit for Password Attempts
#
# Edit sshd_config file
sudo nano /etc/ssh/sshd_config
...
MaxAuthTries 3
...
# Restart SSH damon.
sudo systemctl restart sshd


exit 0
