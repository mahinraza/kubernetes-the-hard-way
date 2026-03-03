#!/bin/bash

# Enable password auth in sshd so we can use ssh-copy-id
sed -i --regexp-extended 's/#?PasswordAuthentication (yes|no)/PasswordAuthentication yes/' /etc/ssh/sshd_config
# #?                        # match optional # (commented or not)
# PasswordAuthentication    # find this setting
# (yes|no)                  # whether it's yes or no currently
# PasswordAuthentication yes # replace with — always set to yes

sed -i --regexp-extended 's/#?Include \/etc\/ssh\/sshd_config.d\/\*.conf/#Include \/etc\/ssh\/sshd_config.d\/\*.conf/' /etc/ssh/sshd_config
#Comments out the Include line — prevents other config files from overriding the password auth setting:

sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
#Enables keyboard interactive authentication (needed for password login)

systemctl restart sshd

if [ ! -d /home/vagrant/.ssh ]
then
    mkdir /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    chown -R vagrant:vagrant /home/vagrant/.ssh
fi

echo "vagrant ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/vagrant
sudo chmod 440 /etc/sudoers.d/vagrant

if [ "$(hostname)" = "jumphost" ]
then
    sh -c 'sudo apt update' &> /dev/null
    sh -c 'sudo apt-get install -y sshpass' &> /dev/null
fi
#sshpass lets you provide SSH password non-interactively

