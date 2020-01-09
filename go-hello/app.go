package main

import (
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os/user"
	"syscall"
	"time"
)

var id, ip, userInfo string

func main() {
	var err error

	id, err = generateID()
	if err != nil {
		log.Fatal(err)
	}

	ip, err = externalIP()
	if err != nil {
		log.Fatal(err)
	}

	userInfo = currentUser()

	http.HandleFunc("/coffee", cafeHandler)
	http.HandleFunc("/tea", cafeHandler)

	log.Fatal(http.ListenAndServe(":8080", nil))
}

func generateID() (string, error) {
	buf := make([]byte, 6)
	_, err := rand.Read(buf)
	if err != nil {
		return "", err
	}
	buf[0] |= 2
	return fmt.Sprintf("%02x%02x%02x%02x%02x%02x", buf[0], buf[1], buf[2], buf[3], buf[4], buf[5]), nil
}

func cafeHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Server address: %v\nServer name: %v\nDate: %v\nURI: %s\nCurrent System User: %v\n",
		ip, id, time.Now().Format(time.RFC3339), r.URL, userInfo)
}

func externalIP() (string, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "", err
	}
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 {
			continue // interface down
		}
		if iface.Flags&net.FlagLoopback != 0 {
			continue // loopback interface
		}
		addrs, err := iface.Addrs()
		if err != nil {
			return "", err
		}
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			ip = ip.To4()
			if ip == nil {
				continue // not an ipv4 address
			}
			return ip.String(), nil
		}
	}
	return "", errors.New("are you connected to the network?")
}

func currentUser() string {
	user, err := user.Current()
	if err != nil {
		return fmt.Sprintf("uid=%v", syscall.Getuid())
	}
	return fmt.Sprintf("username=%s uid=%s", user.Username, user.Uid)
}
