# Pastis

Pastis is a MacRuby script that fetches a torrent RSS feed and check against 
your filters to know if a torrent should be added to Transmission's queue.

## Requirement:

* MacRuby 0.6+ must be installed http://macruby.org

* Transmission (http://www.transmissionbt.com/) must be installed and running.
Remote access must also be enabled and password access is not yet supported.

## Usage:
    Pastis.new.check(http://www.ezrss.it/feed/)

## Notes:

All torrents get downloaded to a torrents folder (by default: ~/torrents/).
A log of the downloaded files is saved in ~/.pastis-rsslog allowing to avoid
downloading the same file twice, even if it's deleted.
Torrents found needed to be added to the Transmission queue are saved in a different
path, by default: "~/torrents/to\_download".