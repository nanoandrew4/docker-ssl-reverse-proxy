# About docker-ssl-reverse-proxy

My situation was this:
I had multiple Docker containers serving websites on port 80.
I wanted a single reverse proxy with SSL powered by
[Let's Encrypt](https://letsencrypt.org/)
in front of them that keeps certificates fresh and supports
multiple domain names per website (e.g. with `www.` subdomain and without).
Plain HTTP should be redirected to HTTPS on the master domain for each website,
alias domains should redirect to the master domain for both HTTP and HTTPS.
And that reverse proxy should also run in a Docker container.

This repository has all of that.  The heavy lifting is done by
[Caddy](https://caddyserver.com/)
and there's a [small tool](Caddyfile.generate) to generate Caddy configuration
from a minimal
[ini-like](https://docs.python.org/2/library/configparser.html)
`sites.cfg` file for you ([see example](sites.cfg.EXAMPLE.gentoo-ev)).

Thanks to Abiola Ibrahim ([@abiosoft](https://github.com/abiosoft))
for sharing his
[Caddy 1.x.x Docker images](https://github.com/abiosoft/caddy-docker)
that I build upon prior to switching to
[official Caddy 2.x.x Docker images](https://hub.docker.com/_/caddy).


# Getting Started

  1. Create a simple `sites.cfg` file manually
     as seen in the [example](sites.cfg.EXAMPLE.gentoo-ev).

  2. Create Docker network `ssl-reverse-proxy` for the reverse proxy
     and its backends to talk:<br>
     `docker network create --internal ssl-reverse-proxy`

  3. Spin up the container and mount your sites.cfg file to `/etc/caddy/sites.cfg`:<br>
     ``docker run --restart=always --user=65534 -d -p 80:80 -p 443:443 --cap-add=NET_BIND_SERVICE --cap-drop=ALL -v "`pwd`/sites.cfg:/etc/caddy/sites.cfg" nanoandrew4/ssl-reverse-proxy``

  4. Have backend containers join network `ssl-reverse-proxy`:<br>
     `docker network connect ssl-reverse-proxy <your-container>`

# How to write the `sites.cfg` file

The format is rather simple and has three options only.
Let's look at this example:

    [example.org]
    backend = example-org:80
    aliases =
        www.example.org
            example.net
        www.example.net

Section name `example.org` sets the master domain name that all alias domains
redirect to.  `backend` points to the hostname and port that serves actual
content.  Here, `example-org` is the name of the Docker container that
Docker DNS will let us access because we made both containers join external
network `ssl-reverse-proxy`.
`aliases` is an optional list of domain names to have both HTTP and HTTPS
redirect to master domain `example.org`.  That's it.

The `Caddyfile` generated from that very `sites.cfg` would read:

    # NOTE: This file has been generated, do not edit
    (common) {
        log {
            output stdout
        }
    }

    example.org {
        import common
        reverse_proxy example-org:80
    }

    example.net {
        import common
        redir https://example.org{uri}
    }

    www.example.net {
        import common
        redir https://example.org{uri}
    }

    www.example.org {
        import common
        redir https://example.org{uri}
    }


# Support and Contributing

If you run into issues or have questions, please
[open an issue ticket](https://github.com/hartwork/docker-ssl-reverse-proxy/issues)
for that.

Please know that `sites.cfg` and [`Caddyfile.generate`](Caddyfile.generate)
are not meant to cover much more than they already do.  If it grows as powerful
as `Caddyfile` we have failed.
