# lapisbean

A way to run lapis apps on redbean(*).

## Caveats

I haven't stress-tested this; there might be some bugs here and there.

Randomly generated secrets may not be as secure under lapisbean as they would be under openresty or cqueues servers; ultimately, redbean lacks a CSPRNG function, so I've compromised by using `GetRandomBytes()`, which uses `getrandom()`.

## How to build

Run `make`. It'll download the latest redbean (and InfoZIP, if you don't have it) and create a `lapisbean.com` file with a demo app in it.

## How to use

Take a lapis app (not *all* lapis apps will work; only sqlite databases are implemented at the moment, for example). Place the files of the app in a `.lua` folder, and zip that folder into `lapisbean.com` (so `zip -r lapisbean.com .lua`). Then, just run `lapisbean.com` and your app should be running on `localhost:8080`. To configure lapisbean, you can use a `.args` file or command line arguments just like you would redbean.