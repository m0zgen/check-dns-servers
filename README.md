# Check DNS Servers

You can add dns servers domain names in to `domains.txt` and add checking ports to `ports.txt`
and then run `./check.sh` script will resolve all IP addresses from DNS servers list and then check every IP on:

* Port available or not
* Check certificate dates (start, end dates)
* If script will detect 53 port, then try to resolve Google DNS name from DNS IP 

# Example

`domains.txt` list:
```
$ cat domains.txt
cloudflare-dns.com
dns.google
```

`ports.txt` list:
```
$ cat ports.txt
443
8443
853
53
```

Result:
```
./check.sh                                                                                                                      0 ms

----------------------- Working with domain name: cloudflare-dns.com -----------------------

----------------------- Starting from IP: 104.16.248.249 -----------------------
Port: 443. Cert info - Start: Oct 25 00:00:00 2021 GMT / End: Oct 25 23:59:59 2022 GMT
Port: 8443. Cert info - Start: Oct 25 00:00:00 2021 GMT / End: Oct 25 23:59:59 2022 GMT
Port: 853. Not available.

DNS Port detected. Try to resolve Google DNS IP:
Empty reply from 104.16.248.249 :(

,,,

----------------------- Working with domain name: dns.google -----------------------

----------------------- Starting from IP: 8.8.8.8 -----------------------
Port: 443. Not available.
Port: 8443. Not available.
Port: 853. Not available.

DNS Port detected. Try to resolve Google DNS IP:
142.250.181.206

...
```

## Additional options

* `-r` - Custom resolver
* `-l` - Custom list
* `-d` - Max days for SSL certificate expires

Example:
```
./check.sh -d 10 -l lists/my.txt -r 8.8.8.8
...
Linux platform detected...

Checking from DNS server: 8.8.8.8

...
Port: 443. Cert info - Start: Sep 20 00:00:00 2022 GMT / End: Dec 19 23:59:59 2022 GMT
[✓] Max days: 10. Left days: 50. OK
...
```