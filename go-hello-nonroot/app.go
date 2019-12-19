package main

import (
	"crypto/rand"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os/user"
	"time"
)

var id string

func main() {
	id = generateID()
	http.HandleFunc("/coffee", cafeHandler)
	http.HandleFunc("/tea", cafeHandler)
	http.ListenAndServe(":8080", nil)
}

func generateID() string {
	buf := make([]byte, 6)
	_, err := rand.Read(buf)
	if err != nil {
		fmt.Println("error:", err)
		return "nil"
	}
	buf[0] |= 2
	return fmt.Sprintf("%02x%02x%02x%02x%02x%02x", buf[0], buf[1], buf[2], buf[3], buf[4], buf[5])
}

func cafeHandler(w http.ResponseWriter, r *http.Request) {
	ip, err := externalIP()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Fprintf(w, "Server address: "+ip+"\nServer name: "+id+
		"\nDate: "+time.Now().Format(time.RFC3339)+"\nURI: "+
		r.URL.String()+"\nCurrent System User: "+currentUser()+"\n")
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
		fmt.Println(err)
		return "nil!"
	}
	return fmt.Sprintf("username=" + user.Username + " uid=" + user.Uid)
}
