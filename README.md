# Route-converter
Convert windows route notation in isc-dhcp-server route notation in aim to facilitate route writing for dhcp server.

## Usage 
This tiny script is here to formulate the route you want to push with a DHCP server to the client. Because of the ugly notation, the DHCP server require, it's not very really funny to do that. Now with this script all you need is to fill a routes.txt file with the following format:

``` <network> <mask> <gateway> ```

Then when your file is complete, all you need to do is launch the script. The script will generate one file with two parts, the first one which gives you the translation of each route and the second one a one line format of your route.

## Example

> routes file

*routes.txt*

```
192.168.10.0 255.255.255.0 10.0.0.5
20.240.0.0 255.255.128.0 10.0.0.6
```

> Results

*equivalence.txt*
```
192.168.10.0 255.255.255.0 10.0.0.5 => 24, 192, 168, 10, 10, 0, 0, 5
20.240.0.0 255.255.128.0 10.0.0.6 => 17, 20, 240, 0, 10, 0, 0, 6

option rfc3442-classless-static-routes 24, 192, 168, 10, 10, 0, 0, 5, 17, 20, 240, 0, 10, 0, 0, 6;
option ms-classless-static-routes 24, 192, 168, 10, 10, 0, 0, 5, 17, 20, 240, 0, 10, 0, 0, 6;
```
## Improvements

- Make the script robust
- Enable option for input and output file
- Option which print help about the script
