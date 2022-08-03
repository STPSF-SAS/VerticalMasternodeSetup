## Vertical Vnode Installation

**NOTE:** This installation guide is provided as is with no warranties of any kind. This script absolutely ONLY works with Ubuntu 16.04. Do not attempt to insall with any other OS!

**NOTE:** This newer version of the script (v1.1) does not ask for IP address or masternode genkey anymore. Instead the __script will detect VPS IP Address and generate Masternode Private Key (genkey) automatically__. It will also create a 2GB swap file.

If you follow the steps and use a newly installed Ubuntu 16.04 VPS, it will automatically configure and start your  VNode. Ubuntu 17.10 and other Linux distros ate not currently supported.

Steps:

**0) Create a new VPS** or use existing one. Recommended VPS resource configuration is similar to the vultr's $5/mo (25GB SSD/1xCPU/1GB RAM, Ubuntu 16.04). It can handle several MNs running simultaneously on the same public IP address but they have to use dirfferent ports. Therefore you cannot easily run more than one Virtical vnode on the same box. Different coins are fine.

**1)** In Windows wallet, **create a new receiving address** and name it **vn1** for example.

**2) Send exactly 3750 VTL to this new address**. NOTE: if you are setting up many msternodes and wish to perform multiple 3750 payments in a row before following through steps (3)-(6), make sure you select correct __inputs__ for each payment or __lock__ your 3750 coins manually after each payment using Coin Control Features, otherwise your coins may get reused and only last payment will yield valid vnode output. The wallet will lock your payments automatically after you restart it in step (6).

**3) View vnode outputs** - output transaction ID and transaction index in wallet Debug Console (Tools -> Debug console) by typing:

```bash
vnode outputs
```

Copy it somewhere safe. You will use these in the masternode.conf file for your wallet later.

**4) Connect to your VPS server console** using PuTTY terminal program, login as root and clone the setup script and wallet binaries from github repository.
(NOTE: Currently this script repo contains Linux wallet binaries wich are necessary to run master node on VPS. The location of these binaries will be changed to the official release github folder at a later date)

To download (clone) the script and binaries to your VPS, use the following command in VPS Linux console:

```bash
cd ~
git clone https://github.com/Dwigt007/VerticalMasternodeSetup.git
```

__NOTE:__ in case if you will need to re-download this setup script or binaries from github repo, use the following git command:
```bash
cd ~/VerticalMasternodeSetup
git reset --hard
git pull
```

**5) Run the install script** which will install and configure your masternode with all necessary options.

```bash
cd ~/VerticalMasternodeSetup
bash vnode-setup.sh
```
__NOTE:__ This process may take anywhere from 5 to 20 minutes, depending on your VPS HW specs. If it's not your very first ever masternode setup, you may want to speed up the process by doing things in parallel. While the MN setup script is running on the VPS, you can spend this time getting ready to start your new masternode from your Hot Wallet (also referred to as Control Wallet) by following instructions in next step (6).

Once the script completes, it will output your VPS Public IP Address and vnode Private Key which it generated for this vnode. Detailed instructions on what to do next will be provided on the VPS console.

**6) Prepare your Hot Wallet and start the new masternode**. In this step you will introduce your new vnode to the Vertical network by issuing a vnode start command from your wallet, which will broadcast information proving that
the collateral for this masternode is secured in your wallet. Without this step your new vnode will function as a regular Vertical node (wallet) and will not yield any rewards. Usually you keep your Hot Wallet on your Windows machine where you securely store your funds for the MN collateral.

Basically all you need to do is just edit the __vnode.conf__ text file located in your hot wallet __data directory__ to enter a few masternode parameters, restart the wallet and then issue a start command for this new vnode.

There is only one way to edit __vnode.conf__. You can open it from the wallet data folder directly by navigating to the %appdata%/roaming/verticalcoin. Just hit Win+R, paste %appdata%/roaming/verticalcoin, hit Enter and then open **vnode.conf** with Notepad for editing. 

You will need to restart your wallet when you are done in order for it to pickup the changes you made in the file. Make sure to save it before you restart your wallet.

__Here's what you need to do in vnode.conf file__. For each masternode you are going to setup, you need to enter one separate line of text  which will look like this:

```bash
mn1 231.321.11.22:54111 27KTCRKgqjBgQbAS2BN9uX8GHBu16wXfr4z4hNDZWQAubqD8fr6 5d46f69f1770cb051baf594d011f8fa5e12b502ff18509492de28adfe2bbd229 0
```

The format for this string is as follow:
```bash
vnodealias publicipaddress:54111 vnodeprivatekey output-tx-ID output-tx-index
```

Where:
__masternodealias__ - your human readable masternode name (alias) which you use to identify the masternode. It can be any unique name as long as you can recognize it. It exists only in your wallet and has no impact on the masternode functionality.

__publicipaddress:54111__ - this must be your masternode public IP address, which is usually the IP address of your VPS, accessible from the Internet. The new script (v1.1) will detect your IP address automatically. The __:54111__ suffix is the predefined and fixed TCP port which is being used in Vertical network for node-to-node and wallet-to-node communications. This port needs to be opened on your VPS server firewall so that others can talk to your masternode. The setup script takes care of it. NOTE: some VPS service providers may have additional firewall on their network which you may need to configure to open TCP port 54111. Vultr does not require this.

__vnodeprivatekey__ - this is your masternode private key which script will generate automatically. Each masternode will use its own unique private key to maintain secure communication with your Hot Wallet. You will have to generate a new key for each masternode you are setting up. Only your masternode and your hot wallet will be in possession of this private key. In case if you will need to change this key later for some reason, you will have to update it in your __vnode.conf__ in Hot Wallet as well as in the reden.conf in data directory on the masternode VPS.

__output-tx-ID__ - this is your collateral payment Transaction ID which is unique for each masternode. It can be easily located in the transaction details (Transactions tab) or in the list of your **vnode outputs**. This TxID also acts as unique vnode ID on the Reden network.

__output-tx-index__ - this is a single-digit value (0 or 1) which is shown in the **masternode outputs**

**NOTE:** The new MN setup script will provide this configuration string for your convenience.
You just need to replace:
```bash
	vn1 - with your desired vnode name (alias)

	TxId - with Transaction Id from vnode outputs

	TxIdx - with Transaction Index (0 or 1)

```

Use only one space between the elements in each line, don't use TABs.

Once you think you are all done editing vnode.conf file, please make sure you save the changes!

IMPORTANT: Spend some time and double check each value you just entered. Copy/paste mistakes will cause your vnode (or other nodes) to behave erratically and will be extremely difficult to troubleshoot. Make sure you don't have any duplicates in the list of masternodes. Often people tend to speed up the process and copy the previous line and then forget to modify the IP address or copy the IP address partially. If anything goes wrong with the masternode later, the vnode.conf file should be your primary suspect in any investigation.

Finally, you need to either __restart__ the wallet app, unlock it with your encryption password. At this point the wallet app will read your __vnode.conf__ file and populate the Masternodes tab. Newly added nodes will show up as MISSING, which is normal.

Once the wallet is fully synchronized and your masternode setup script on VPS has finished its synchronization with the network, you can **issue a start broadcast** from your hot wallet to tell the others on Vertical network about your new vnode.

Todo so you can either run a simple command in Debug Console (Tools -> Debug console):

```bash
vnode start-alias <vnodename>
```

Example:
```bash
vnode start-alias mn1
```

Or, as an alternative, you can issue a start broadcast from the wallet vnodes tab by right-clicking on the node:

```bash
vnodes -> Select vnode -> RightClick -> start alias
```

The wallet should respond tith **"vnode started successfully"** as long as the vnode collateral payment was done correctly in step (2) and it had at least 15 confirmations. This only means that the conditions to send the start broadcast are satisfied and that the start command was communicated to peers.

Go back to your VPS and wait for the status of your new masternode to change to "vnode successfully started". This may take some time and you may need to wait for several hours until your new masternode completes sync process.

Finally, to **monitor your vnode status** you can use the following commands in Linux console of your masternode VPS:

```bash
./verticalcoin-cli vnode status
```

If you are really bored waiting for the sync to complete, you can watch what your masternode is doing on the network at any time by using tail to **monitor the debug.log** file in realtime:

```bash
sudo tail -f ~/.verticalcoin/debug.log
```

And for those who wonder what does **verticalcoin.conf** file looks like for a typical masternode which the setup script generates, here's an example below...

Note that both, the __externalip__ should match the IP address and __vnodeprivkey__ should math the private key in your  __vnode.conf__ of your hot wallet in order for the masternode to function properly. If any of these two parameters change, they must be changed in both, the verticalcoin.conf file on the masternode VPS (located in /root/.verticalcoin directory) and vnode.conf on Hot Wallet PC (located in %appdata%/verticalcoin folder).

Example: 

**nano /root/.verticalcoin/verticalcoin.conf**

```bash
rpcuser=HGDNJICUndjdinc8327y809492hnjfs
rpcpassword=APQsN6waRANDOMPASSWORDYaFGhecQiAn
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=256
externalip=144.202.92.85
vnode=1
vnodeprivkey=2333H9uMa8wrYGb1hNotRealPKey64vr8BRYjPZP3LAR6WFGg
seednode=seed1.vrtseed.ovh
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
```

**In conclusion**

The script adds a cron job which starts verticalcoind daemon upon reboot. Try restarting your VPS server (just type reboot in Linux console) and see if your vnode comes back online automatically in a few minutes. Log back in using PuTTY and run the following command to monitor your masternode status:

```
watch -n 10 'verticalcoin-cli vnode status'
```

The expected output for a functioning vnode will eventually look like this:

```
{
  "vin": "CTxIn(COutPoint(cbe3c99bed2c874a14675c54004a5b5bfda8473b98bfbd80a15743c2a1117d4f, 1), scriptSig=)",
  "service": "104.207.157.213:54111",
  "payee": "ZN3ZoisQkdsCuXj7799kEcvJkWk6Bhc4uJ",
  "status": "vnode successfully started"
}
{
  "AssetID": 999,
  "AssetName": "VNODE_SYNC_FINISHED",
  "Attempt": 0,
  "IsBlockchainSynced": true,
  "IsMasternodeListSynced": true,
  "IsWinnersListSynced": true,
  "IsSynced": true,
  "IsFailed": false
}

```

**Advanced masternode monitoring script: nodemon.sh**

The main purpose of this simple script is to monitor **vnode status and peer connections** in real-time. It will display all current __outbound__ connections of your masternode with great amount of statistis which can be used for troubleshooting of sync issues.

Typically you should see more than a few nodes listed in the table and the amount of data sent/received should be updating every several seconds on a healthy masternode.

Currently Vertical nodes will display most (if not all) peers with IPv6 addresses. This is normal as long as the data is being transferred and peers stay connected for a long time. Initially, when the node is just started, the outbound connection table may not show any peers for quite some time. It may take several hours to build up a healthy and stable list of peers.

Sample output of the script from node 45.76.12.139 on May 18, 2018:
```
===========================================================================
Outbound connections to other Vertical nodes [vertical datadir: /root/.verticalcoin]
===========================================================================
Node IP               Ping    Rx/Tx     Since  Hdrs   Height  Time   Ban
Address               (ms)   (KBytes)   Block  Syncd  Blocks  (min)  Score
===========================================================================
95.171.6.105:54111    118   6818/7929  2586   3706   3706    2361   0
24.176.52.93:54111    37    5770/6829  2614   3706   3706    2301   0
38.103.14.19:54111     8     9787/8024  2657   3706   3706    2208   0
===========================================================================
 22:14:21 up 3 days, 22:59,  3 users,  load average: 0.01, 0.03, 0.00
===========================================================================
Vnode Status:
# verticalcoin-cli -datadir=/root/.verticalcoin vnode status
{
  "vin": "CTxIn(COutPoint(0a5afa9e8c41d003c4399f089bc54880e05ce8a051d30932d236ba12b5d1040b, 0), scriptSig=)",
  "service": "45.76.12.139:54111",
  "payee": "ZXzYZLmj9D6o6XtdK3M3xY2xCfNTSW464m",
  "status": "Vnode successfully started"
}
===========================================================================
Masternode Information:
# verticalcoin-cli -datadir=/root/.verticalcoin getinfo
{
  "version": 2000001,
  "protocolversion": 70206,
  "walletversion": 61000,
  "balance": 0.00000000,
  "privatesend_balance": 0.00000000,
  "blocks": 370,
  "timeoffset": 0,
  "connections": 14,
  "proxy": "",
  "difficulty": 394.7427119361897,
  "testnet": false,
  "keypoololdest": 1524361411,
  "keypoolsize": 1001,
  "paytxfee": 0.00000000,
  "relayfee": 0.00010000,
  "errors": ""
}
===========================================================================
Usage: nodemon.sh [refresh delay] [datadir index]
Example: nodemon.sh 10 22 will run every 10 seconds and query redend in /root/.verticalcoin22


Press Ctrl-C to Exit...

```

* * *



If you found this script and masternode setup guide helpful...

...please donate Vertical to: **VDjtpU5miHbtpS444u1bDWpZfdZWgX8kzF**


--Dwigt007
