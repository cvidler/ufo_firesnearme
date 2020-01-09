# ufo_firesnearme
Uses NSW Rural Fire Service API event data to report local bush fires on your Dynatrace UFO.

Uses data from NSW RFS Fires Near Me - https://www.rfs.nsw.gov.au/fire-information/fires-near-me

Configuration:
  * Add the IP/fqdn for your Dyntrace UFO (https://github.com/Dynatrace/ufo) in the ``$ufoaddr`` variable.
  * Specify how large a radius you care about in kilometers in the ``$radius`` variable.
  * Schedule the script to run periodically, I recommend every 15 minutes.

Only the top ring of the UFO is used, so another data source can make use of the bottom ring to show other data/status infomation.
