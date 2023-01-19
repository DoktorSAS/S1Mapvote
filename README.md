
# IW6: Call of duty: Ghost Mapvote
Developed by [@DoktorSAS](https://twitter.com/DoktorSAS)

![Preview](https://pbs.twimg.com/media/FgLjl0OWIAAOcLN?format=jpg&name=large)

### Requirements

- The script can only work on Server's, It will not work in private games.
- Server must be hosted on Plutonium client, the script works only on Plutonium client.

#### How to setup the mapvote step by step 

 1) Copy the file in your Directory %localappdata%\xlabs\data\iw6\data\
 3) Copy the Content of the mapvote.cfg in your .cfg (Exemple: server.cfg, dedicated_mp.cfg, dedicated.cfg, etc ) file that manages the Server.
 4) Edit the Dvars to setup the Server, many Dvars are only for Aesthetic Parameters.
    - set the Dvar mv_maps to decide the maps that will be shown in mapvote, Example:
        - set mv_maps "mp_prisonbreak mp_dart mp_lonestar mp_frag mp_snow mp_fahrenheit"
    - set the dvar mv_enable to 1 if you want have it active on your server.
    - If you want random gametypes you have to set the dvar mp_gametypes specifying the gametype id (dm, war, sd, etc) and the file to run if necessary. Exemple:
        - set mv_gametypes "dm@freeforall.cfg war@mycustomtdm.cfg"
 5) Run the Server and have fun. Done!
