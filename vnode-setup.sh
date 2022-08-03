#!/bin/bash
# Vertical Vnode Setup Script V1.4 for Ubuntu 16.04 LTS
# (c) 2018 by Dwigt007 for Vertical Coin
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash vnode-setup.sh [Vnode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash vnode-setup.sh 27dSmwq9CabKjo2L3UD1HvgBP3ygbn8HdNmFiGFoVbN1STcsypy
#
# Example 2: Script will generate a new genkey automatically
# bash vnode-setup.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Vertical TCP port
PORT=54111

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'verticalcoind' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop verticalcoind${NC}"
        verticalcoin-cli stop
        delay 30
        if pgrep -x 'verticalcoind' > /dev/null; then
            echo -e "${RED}verticalcoind daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill verticalcoind
            delay 30
            if pgrep -x 'verticalcoind' > /dev/null; then
                echo -e "${RED}Can't stop verticalcoind! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}Vertical Vnode Setup Script V1.4 for Ubuntu 16.04 LTS${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
#kill Daemon
cd ~
pkill ./verticalcoind
pkill verticalcoind
cd VerticalMasternodeSetup

# update packages and upgrade Ubuntu
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev
sudo apt-get install zip unzip
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev

sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo apt-get update -y

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow $PORT/tcp
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"

#Generating Random Password for verticalcoind JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
cd ~
mkdir ~/VerticalMasternodeSetup/verticalcoin-Linux64-V1.2.1
sudo rm verticalcoin-v0.1-linux.zip
wget https://github.com/verticalcoin/verticalcoin/releases/download/V1.2.1/verticalcoin-Linux64-V1.2.1.zip
unzip verticalcoin-Linux64-V1.2.1.zip -d ~/VerticalMasternodeSetup/verticalcoin-Linux64-V1.2.1
rm -r verticalcoin-Linux64-V1.2.1.zip
stop_daemon

# Deploy binaries to /usr/bin
sudo cp VerticalMasternodeSetup/verticalcoin-Linux64-V1.2.1/verticalcoin* /usr/bin/
sudo chmod 755 -R ~/VerticalMasternodeSetup
sudo chmod 755 /usr/bin/verticalcoin*

# Deploy masternode monitoring script
cp ~/VerticalMasternodeSetup/nodemon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/nodemon.sh

#Create datadir
if [ ! -f ~/.verticalcoin/verticalcoin.conf ]; then 
	sudo mkdir ~/.verticalcoin
        
fi

echo -e "${YELLOW}Creating verticalcoin.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.verticalcoin/verticalcoin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.verticalcoin/verticalcoin.conf
 
    #Starting daemon first time just to generate Vnode private key
    verticalcoind --daemon
    delay 30

    #Generate Vnode private key
    echo -e "${YELLOW}Generating Vnode private key...${NC}"
    genkey=$(verticalcoin-cli vnode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR: Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create verticalcoin.conf
    stop_daemon
    delay 30
fi

# Create verticalcoin.conf
cat <<EOF > ~/.verticalcoin/verticalcoin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
txindex=1
vnode=1
externalip=$publicip:$PORT
vnodeprivkey=$genkey
addnode=seed1.vrtseed.ovh
addnode=H01.vrtnode.ovh
addnode=H02.vrtnode.ovh
addnode=H03.vrtnode.ovh
addnode=H04.vrtnode.ovh
addnode=H05.vrtnode.ovh
addnode=H06.vrtnode.ovh
addnode=H07.vrtnode.ovh
addnode=H08.vrtnode.ovh
addnode=H09.vrtnode.ovh
addnode=H10.vrtnode.ovh
EOF

#Finally, starting vertical daemon with new verticalcoin.conf
cd ~
verticalcoind --daemon
delay 5

#Setting auto star cron job for daemon
cronjob="@reboot sleep 30 && verticalcoind --daemon"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Vnode setup is complete!${NC}
========================================================================

Vnode was installed with VPS IP Address: ${YELLOW}$publicip${NC}

Vnode Private Key: ${YELLOW}$genkey${NC}

Now you can add the following string to the vnode.conf file
for your Hot Wallet (the wallet with your vertical collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================

Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}vnode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired vnode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from vnode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the vnode.conf and restart the wallet!

To introduce your new vnode to the Vertical network, you need to
issue a vnode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in vnode list${NC}, which is normal and expected.

2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}vnode start-alias mn1${NC}
    where ${YELLOW}vn1${NC} is the name of your vnodenode (alias)
    as it was entered in the vnode.conf file
    
or by using wallet GUI:
    vnodes -> Select vnode -> RightClick -> ${YELLOW}start alias${NC}

Once completed step (2), return to this VPS console and wait for the
vnode Status to change to: 'vnode successfully started'.
This will indicate that your vnode is fully functional and
you can celebrate this achievement!

Currently your vrnode is syncing with the Vertical network...

The following screen will display in real-time
the list of peer connections, the status of your vnode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}


Here are some useful commands and tools for masternode troubleshooting:

========================================================================
To view masternode configuration produced by this script in reden.conf:

${YELLOW}cat ~/.verticalcoin/verticalcoin.conf${NC}

Here is your verticalcoin.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.verticalcoin/verticalcoin.conf
echo -e "${NC}-------------------------------------------------

NOTE: To edit verticalcoin.conf, first stop the redend daemon,
then edit the verticalcoin.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the verticalcoind daemon back up:

to stop:   ${YELLOW}./verticalcoin-cli stop${NC}
to edit:   ${YELLOW}nano ~/.verticalcoin/verticalcoin.conf${NC}
to start:  ${YELLOW}./verticalcoind${NC}
========================================================================
To view Verticalcoind debug log showing all MN network activity in realtime:

${YELLOW}tail -f ~/.verticalcoin/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:

${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:

${YELLOW}nodemon.sh${NC}

or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================


Enjoy your Vertical Vnode and thanks for using this setup script!

If you found it helpful, please donate Vertical to:
VDjtpU5miHbtpS444u1bDWpZfdZWgX8kzF


...and make sure to check back for updates!

"
# Run nodemon.sh
nodemon.sh

# EOF
