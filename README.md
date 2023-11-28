# writefreely-blog-dev-ops#
- DESC : 
 Containerized Infrastructure with LXD/LXC for WriteFreely and MySQL

## Install lxd lxc : 

***Documentation for lxd*** lxc https://doc.ubuntu-fr.org/lxd

+ snap install lxd
+ sudo gpasswd --add (insert name here) lxd : for example: ***--add user***
+ user id
+ lxd init --minimal or lxd init
+ lxc launch ubuntu:22.04 insert name container : select ubuntu or ( something else from the list: ***lxc image list images:*** ) for example:  ***lxc launch ubuntu:22.04 my-container***
+ lxc list : look in the list of your containers
+ go inside the container:  lxc exec name of your container :  ***lxc exec my-first-container***
+ use the container's activity and status:  ***lxc start,stop,status,reload,restart containername***


## Install mysql in the container : 

- follow the documentation:
***https://mariadb.org/documentation/***
  
***commands for installation***:
  ```
sudo apt update
sudo apt install mariadb-server or mysql
sudo mysql -u root -p

Create a new user:CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
Assign user permissions to the database:
GRANT all_permissions ON database_name.* THEN 'username'@'localhost';
Update permissions:
FLUSH PRIVILEGES;


SHOW DATABASES;
USE database_name;
SHOW TABLES;
Execute SQL query: SELECT * FROM table;
REATE DATABASE new_database;

```

## Install writefreely in the container for writefreely:

***Documentation for writefreely: https://github.com/writefreely/writefreely***
+ download writefreely ***command : wget***
+ unpacking the writefreely package: ***command : tar*** in the var/www/writefreely
+ creating a service in the ***/etc/systemd/system*** file for writefreely ***name.service***
  
***par example***
  ```
  [Unit]
Description=Write Freely Instance
After=network.target

[Service]
Type=simple
StandardOutput=journal
StandardError=journal
WorkingDirectory=/var/www/writefreely
ExecStart=/var/www/writefreely/writefreely

Restart=always

[Install]
WantedBy=multi-user.target
```

## writefreely configuration in var/www/writefreely = run command:

 ***./writefreely config start***

1. select production, standalone
2. port: 80
3. mysql
4. username database, the same as you selected in MySQL during installation
5. select a password, the same as you selected in MySQL during installation
6. database name : also the same as when creating the database for writefreely
7. port 306 unchanged
8. single user blog
9. admin et Password username: for blog
10. blog name: 
11. public URL: http://localhost:8080

- this will create a config.init file
the configuration file should be located in the writfreely directory
***depending on your needs, you can configure it and see the connection to the database***

- next step :
***./writefreely --gen-keys***

- is used to generate keys needed to securely sign sessions and other information in WriteFreely.

- If you have configured your files correctly, writefreely should work :

- enter the command manually in the writefreely folder :
***./writefreely***

## creating the configuration in the apache2 server:

***documentation:***

***https://doc.ubuntu-fr.org/apache2***

-After installation you will find the file in:
-/etc/apache2/sites-available/writefreely.conf
- here you can create a configuration file for writfreely

***commands:***
  ```
sudo apt update
sudo apt install apache2
systemctl start, stop, status apache2
sudo a2dissite name.conf
sudo a2ensite name.conf
  ```



# firewall configuration:
***doc***
***https://doc.ubuntu-fr.org/iptables***

-configuration in file for lxd outside the container to change the default ip for individual containers

-accepts traffic on the lxdbr0 interface and the other accepts traffic on the loop (lo) interface.

***table commands:***
  ```
***Check what bridges are available on your system by using***

lxc network list

---------------------------------------------


iptables -I INPUT -i lxdbr0 -j ACCEPT
iptables -I INPUT -i lo -j ACCEPT
iptables -t nat -A PREROUTING -i ens5 -p tcp --dport 80 -j DNAT --to-destination ip number:80
iptables -t nat -nvL

***Rules in the INPUT chain:***

iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT allows accepting packets arriving on port 80.
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT allows accepting packets arriving on port 80.


***to restore rules without restarting the system:***

netfilter-persistent reload
netfilter-persistent save


***other useful commands:***

iptables -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED -j ACCEPT
ifdown eth0
ifup eth0
ip a 

```


## assigning a new IP to the network for lxc containers

*** outside the container in the lxd configuration file we change the default IP address to another one ***


## DNS server installation for local zone : adding names for ip in containers
***creating another container:***

1. installation: bind9
```
sudo apt-get update
sudo apt-get install bind9
sudo systemctl restart bind9
```
2. dns file configuration:

Open the BIND9 configuration file /etc/bind/named.conf.local and add an entry for your local zone. For example:
```
zone "mydomain.local" {
     typemaster;
     file "/etc/bind/zones/mydomain.local";
};
```
3. Create the /etc/bind/zones/ directory and the mydomain.local file defined in the above fragment. Below you will find a simple example of a local zone file:
```
$TTL 604800
@ IN SOA mydomain.local. root.mydomain.local. (
                                2; Series
                           604800 ; Refresh
                            86400 ; Retry
                          2419200 ; Expire
                           604800 ) ; Negative Cache TTL

@ IN NS mydomain.local.
***container ip names***
new-name-containerA IN A ip-container
new-name-containerB IN A ip-container
```
  ***service bind9 restart***

4. Container configuration:

Within each container, add an entry to the ***/etc/hosts*** file to define their names:
```
***new-name-containerA IN A ip-container***
***new-name-containerB IN A ip-container***
- example :
- my-container 10.10.288.02 
```
5. enter the writefreely container and change host configuration:
host = new name for dns from etc/hosts file

6. Check if the containers recognize the new hostname:

go to the container a , container b and enter:
```
*** ip container lxc *** 
echo "ip new container name" | sudo tee -a /etc/hosts
echo "nameserver ip" | sudo tee /etc/resolv.conf

***Test dns Locally:***
Try querying the DNS server directly in the DNS container:

nslookup writefreely.local localhost
nslookup mysql.local localhost
```

##  DNS to perform recursion

**Enable packet forwarding:**

- configuration file /etc/sysctl.conf
**net.ipv4.ip_forward = 1**
```
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination CONTAINER_ADDRESS:80
iptables -A FORWARD -p tcp --dport 3306 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
s iptables -t nat -A POSTROUTING -j MASQUERADE
```

  - load new configuration:
***sudo sysctl -p***

```
adding configuration in /etc/bind/named.conf.options
  forwarders {
                 8.8.8.8;
                 8.8.4.4;
          };
```

***sudo service bind9 start***

***[!IMPORTANT]***

important commands:


```
systemctl start application.service

systemctl stop application.service

sudo systemctl restart application.service

sudo systemctl reload application.service

sudo systemctl reload-or-restart application.service

sudo systemctl enable application.service

systemctl status application.service

systemctl list-units

systemctl daemon-reload

sudo reboot

```



***github actions runner and adding containers:***

***download the repo to vm or locally***
***on github:***
***follow the installation instructions:***
```
setting = runners = action

important command that will start actions runner and create the service:

sudo ./svc.sh install

ready!

go to github and press the action button!
```
