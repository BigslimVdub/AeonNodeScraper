#!/bin/bash
#Gingeropolous Open node checker

# This is the directory where files are written to.
# If you run as a cronjob, you have to use the full path
DIR=/home/ubuntu/nodelogs

# This is the path for your monerod binary.
aeond=/home/ubuntu/aeon/build/release/bin/aeond

# This is the ip of your local daemon. If you're not running an open node, 127.0.0.1 is fine.
daemon=0.0.0.0

#Where you're going to dump the file that will be published
html_dir=/home/ubuntu/nodelogs/logs

# Bound rpc port
bport=11181

#Port to sniff for
port=11181

echo $aeond
echo $daemon

###

mkdir $DIR
cp /home/ubuntu/moneriote/*.html $DIR
cd $DIR
rm open_nodes.txt
rm nodes.html
cp nodes_base.html nodes.html

### Begin header of random thinger

cp base.html node_script.html

echo "##############"
echo "Check network white nodes for domains to add"

#launch a local daemon instance which will connect to another running daemon and request the current peer list
#note that if the other daemon is running with the "restricted-rpc option", it will ignore "print_pl"
white=$($aeond --rpc-bind-ip $daemon --rpc-bind-port $bport print_pl | grep white | awk '{print $3}' | cut -f 1 -d ":")


white_a=($white)
echo ${white_a[@]}
echo "################"
echo ${#white_a[@]}

echo "#############"
echo "Starting loop"

ctr=0

echo "Number of nodes: "${#white_a[@]} >> moneriote.log


#Comment out to check within the loop, and uncomment the one below
l_hit="$(curl -X POST http://$daemon:$bport/getheight -H 'Content-Type: application/json' | grep height | cut -f 2 -d : | cut -f 1 -d ,)"

for i in "${white_a[@]}"
do
   : 
	echo "Checking ip: "$i
	#Uncomment the below to check within the loop
	#l_hit="$(curl -X POST http://$daemon:$bport/getheight -H 'Content-Type: application/json' | grep height | cut -f 2 -d : | cut -f 1 -d ,)"
  #attempt to connect to each node, allowing 0.5 seconds for connection
	r_hit="$(curl -m 0.5 -X POST http://$i:$port/getheight -H 'Content-Type: application/json' | grep height | cut -f 2 -d : | cut -f 1 -d ,)"
	echo "Local Height: "$l_hit
	echo "Remote Height: "$r_hit
        mini=$(( $l_hit-10 ))
        echo "minimum is " $mini
        maxi=$(( $l_hit+10 ))
        echo "max is " $maxi
        if [[ "$r_hit" ==  "$l_hit" ]] || [[ "$r_hit" > "$mini" && "$r_hit" < "$maxi" ]] && [[ -n $r_hit ]] && [[ -n $l_hit ]]
        then
        echo "################################# Daemon $i is good" 
        ### Time to write these good ips to a file of some sort!
        ### Apparently javascript needs some weird format in order to randomize, so I'll make two outputs
        echo $i >> open_nodes.txt
	echo "myarray[$ctr]= \"$i\";" >> node_script.html
	let ctr=ctr+1
	elif [[ $r_hit ]] || [[ $l_hit ]]; then
	echo "Either the local or remote is dead"
	else
	echo "$i is closed"
	fi
done

cat bottom.html >> node_script.html
cat node_script.html >> nodes.html

echo `date` "The script finished" >> moneriote.log

sudo cp nodes.html $html_dir/
#copy list of nodes to web directory
sudo cp open_nodes.txt $html_dir/

#have a nice day and let others know about these open nodes if they ask. Re-run the tool to get "current" open nodes. 


