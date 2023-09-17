#!/bin/bash
r4_state="./r4_state.dat"
r2_state="./r2_state.dat"
r4_cost=$(cat "$r4_state")
r2_cost=$(cat "$r2_state")

# Assume containers has been created
construct_topology() {
    sudo docker compose build
    sudo docker compose start a
    sudo docker compose start r1
    sudo docker compose start r2
    sudo docker compose start r3
    sudo docker compose start b
}

move_traffic() {
    if (($r4_cost>$r2_cost))
    then
    # Move traffic from r1 - r2 - r3 to r4
    new_cost=$(($r4_cost - 20))
    sudo docker exec cs6480lab1-r4-1 sed -i -e "s/$(($r4_cost))/$(($new_cost))/g" /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r4-1 service ospfd restart
    echo $(($new_cost)) > $r4_state
    echo "in"
    else
    new_cost=$(($r2_cost - 20))
    sudo docker exec cs6480lab1-r2-1 sed -i -e "s/$(($r2_cost))/$(($new_cost))/g" /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r2-1 service ospfd restart
    echo $(($new_cost)) > $r2_state
    fi
}

# Config and start the ospf
start_ospf(){
    # For r1
    sudo docker exec cs6480lab1-r1-1 touch /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r1-1 touch /etc/quagga/zebra.conf
    sudo docker exec cs6480lab1-r1-1 bash -c "printf 'hostname ospfd
password zebra
router ospf
  network 172.28.0.0/16 area 0.0.0.0
  network 172.27.0.0/16 area 0.0.0.0
  network 172.24.0.0/16 area 0.0.0.0' >> /etc/quagga/ospfd.conf"
    sudo docker exec cs6480lab1-r1-1 bash -c "printf 'hostname Router
password zebra
enable password zebra' >> /etc/quagga/zebra.conf"
    sudo docker exec cs6480lab1-r1-1 service zebra start
    sudo docker exec cs6480lab1-r1-1 service ospfd start

    # For r2
    sudo docker exec cs6480lab1-r2-1 touch /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r2-1 touch /etc/quagga/zebra.conf
    sudo docker exec cs6480lab1-r2-1 bash -c "printf 'hostname ospfd
password zebra
router ospf
  network 172.24.0.0/16 area 0.0.0.0
  network 172.25.0.0/16 area 0.0.0.0
interface eth0
  ip ospf cost 1090
interface eth1
  ip ospf cost 1090' >> /etc/quagga/ospfd.conf"
    sudo docker exec cs6480lab1-r2-1 bash -c "printf 'hostname Router
password zebra
enable password zebra' >> /etc/quagga/zebra.conf"
    sudo docker exec cs6480lab1-r2-1 service zebra start
    sudo docker exec cs6480lab1-r2-1 service ospfd start

    # For r3
    sudo docker exec cs6480lab1-r3-1 touch /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r3-1 touch /etc/quagga/zebra.conf
    sudo docker exec cs6480lab1-r3-1 bash -c "printf 'hostname ospfd
password zebra
router ospf
  network 172.23.0.0/16 area 0.0.0.0
  network 172.25.0.0/16 area 0.0.0.0
  network 172.26.0.0/16 area 0.0.0.0' >> /etc/quagga/ospfd.conf"
    sudo docker exec cs6480lab1-r3-1 bash -c "printf 'hostname Router
password zebra
enable password zebra' >> /etc/quagga/zebra.conf"
    sudo docker exec cs6480lab1-r3-1 service zebra start
    sudo docker exec cs6480lab1-r3-1 service ospfd start
}

bring_up_r4() {
     sudo docker compose start r4
    sudo docker exec cs6480lab1-r4-1 touch /etc/quagga/ospfd.conf
    sudo docker exec cs6480lab1-r4-1 touch /etc/quagga/zebra.conf
    sudo docker exec cs6480lab1-r4-1 bash -c "printf 'hostname ospfd
password zebra
router ospf
  network 172.26.0.0/16 area 0.0.0.0
  network 172.27.0.0/16 area 0.0.0.0
interface eth0
  ip ospf cost 1100
interface eth1
  ip ospf cost 1100' >> /etc/quagga/ospfd.conf"
    sudo docker exec cs6480lab1-r4-1 bash -c "printf 'hostname Router
password zebra
enable password zebra' >> /etc/quagga/zebra.conf"
    sudo docker exec cs6480lab1-r4-1 service zebra start
    sudo docker exec cs6480lab1-r4-1 service ospfd start
}

install_routes() {
    sudo docker exec cs6480lab1-a-1 route add -net 172.23.0.0/16 gw 172.28.2.1
    sudo docker exec cs6480lab1-b-1 route add -net 172.28.0.0/16 gw 172.23.2.1
}

while getopts 'hcmsifrx:' OPTION; do
    case "$OPTION" in
    h)
      printf "
      -c construct,
            create default topology.
      -m move,
            move traffic from north to south or from south to north.
      -s start,
            start ospf routing suite.
      -i install,
            install routes on a and b.
      -f,
            bring up r4.
      -r,
            remove r2.\n"
      ;;
    c)
      construct_topology
      ;;
    m)
      move_traffic
      ;;
    s)
      start_ospf
      ;;
    i)
      install_routes
      ;;
    f)
      bring_up_r4
      ;;
    r)
      sudo docker compose stop b
      ;;
    x)
      sudo docker compose stop
      sudo docker system prune --all
      ;;
    ?)
      echo "script usage: $(basename \$0) [-h] [-c] [-m] [-s] [-i] [-f] [-r] [-x]" >&2
      exit 1
      ;;
    esac
done