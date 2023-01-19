#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\_gamelogic;

/*
	Plutonium IW6 Mapvote
	Developed by DoktorSAS
	Version: v1.0.0

	1.0.0:
	- 3 maps support
	- Credits, sentence and social on bottom left
*/

init()
{
	preCacheShader("gradient_fadein");
	preCacheShader("gradient");
	preCacheShader("white");
	preCacheShader("line_vertical");

	level thread onPlayerConnected();
	level thread mv_Config();

	level.startmapvote = ::startMapvote;
}

startMapvote()
{
	if (wasLastRound())
	{
		mv_Begin();
	}
}

mv_Config()
{
	SetDvarIfNotInizialized("mv_enable", 1);
	if (getDvarInt("mv_enable") != 1) // Check if mapvote is enable
		return;						  // End if the mapvote its not enable

	level.__mapvote = [];
	SetDvarIfNotInizialized("mv_time", 20);
	level.__mapvote["time"] = getDvarInt("mv_time");
	SetDvarIfNotInizialized("mv_maps", "mp_prisonbreak mp_dart mp_lonestar mp_frag mp_snow mp_fahrenheit mp_hashima mp_warhawk mp_sovereign mp_zebra mp_skeleton mp_chasm mp_flooded mp_strikezone mp_descent_new mp_dome_ns mp_ca_impact mp_ca_behemoth mp_battery3 mp_dig mp_favela_iw6 mp_pirate mp_conflict mp_mine mp_shipment_ns mp_zerosub mp_boneyard_ns mp_ca_red_river mp_ca_rumble mp_swamp");

	SetDvarIfNotInizialized("mv_credits", 1);
	SetDvarIfNotInizialized("mv_socials", 1);
	SetDvarIfNotInizialized("mv_socialname", "Discord");
	SetDvarIfNotInizialized("mv_sociallink", "Discord.gg/^3xlabs^7");
	SetDvarIfNotInizialized("mv_sentence", "Thanks for Playing by @DoktorSAS");
	SetDvarIfNotInizialized("mv_votecolor", "5");
	SetDvarIfNotInizialized("mv_blur", "3");
	SetDvarIfNotInizialized("mv_scrollcolor", "cyan");
	SetDvarIfNotInizialized("mv_selectcolor", "lightgreen");
	SetDvarIfNotInizialized("mv_backgroundcolor", "grey");
	SetDvarIfNotInizialized("mv_gametypes", "dm;dm.cfg tdm;tdm.cfg dm;dm.cfg tdm;tdm.cfg sd;sd.cfg sd;sd.cfg");
	setDvarIfNotInizialized("mv_excludedmaps", "");
}

// Mapvote Logic
mv_Begin()
{
	level endon("mv_ended");

	if (getDvarInt("mv_enable") != 1) // Check if mapvote is enable
		return;						  // End if the mapvote its not enable

	if (!isDefined(level.mapvote_started))
	{
		level.mapvote_started = 1;

		mapsIDs = [];
		mapsIDs = strTok(getDvar("mv_maps"), " ");
		mapschoosed = mv_GetRandomMaps(mapsIDs);

		level.__mapvote["map1"] = spawnStruct();
		level.__mapvote["map2"] = spawnStruct();
		level.__mapvote["map3"] = spawnStruct();

		level.__mapvote["map1"].mapname = maptoname(mapschoosed[0]);
		level.__mapvote["map1"].mapid = mapschoosed[0];
		level.__mapvote["map2"].mapname = maptoname(mapschoosed[1]);
		level.__mapvote["map2"].mapid = mapschoosed[1];
		level.__mapvote["map3"].mapname = maptoname(mapschoosed[2]);
		level.__mapvote["map3"].mapid = mapschoosed[2];

		gametypes = strTok(getDvar("mv_gametypes"), " ");
		g1 = gametypes[randomIntRange(0, gametypes.size)];
		g2 = gametypes[randomIntRange(0, gametypes.size)];
		g3 = gametypes[randomIntRange(0, gametypes.size)];

		level.__mapvote["map1"].gametype = g1;
		level.__mapvote["map2"].gametype = g2;
		level.__mapvote["map3"].gametype = g3;

		foreach (player in level.players)
		{
			if (!is_bot(player))
				player thread mv_PlayerUI();
		}
		wait 0.2;
		level thread mv_ServerUI();

		mv_VoteManager();
	}
}

ArrayRemoveIndex(array, index)
{
	new_array = [];
	for (i = 0; i < array.size; i++)
	{
		if (i != index)
			new_array[new_array.size] = array[i];
	}
	array = new_array;
	return new_array;
}

mv_GetRandomMaps(mapsIDs) // Select random map from the list
{
	mapschoosed = [];
	for (i = 0; i < 3; i++)
	{
		index = randomIntRange(0, mapsIDs.size);
		map = mapsIDs[index];
		mapsIDs = ArrayRemoveIndex(mapsIDs, map);
		mapschoosed[i] = map;
	}

	return mapschoosed;
}

is_bot(entity) // Check if a players is a bot
{
	return isDefined(entity.pers["isBot"]) && entity.pers["isBot"];
}

mv_PlayerUI()
{
	// self endon("disconnect");
	level endon("game_ended");

	self SetBlurForPlayer(getDvarFloat("mv_blur"), 1.5);

	scroll_color = getColor(getDvar("mv_scrollcolor"));
	bg_color = getColor(getDvar("mv_backgroundcolor"));
	self freezeControlsWrapper(1);
	boxes = [];
	boxes[0] = self createRectangle("center", "center", -220, -452, 205, 133, scroll_color, "white", 1, .7);
	boxes[1] = self createRectangle("center", "center", 0, -452, 205, 133, bg_color, "white", 1, .7);
	boxes[2] = self createRectangle("center", "center", 220, -452, 205, 133, bg_color, "white", 1, .7);

	self thread mv_PlayerFixAngle();

	level waittill("mv_start_animation");

	boxes[0] affectElement("y", 1.2, -50);
	boxes[1] affectElement("y", 1.2, -50);
	boxes[2] affectElement("y", 1.2, -50);
	self thread destroyBoxes(boxes);

	self notifyonplayercommand("left", "+attack");
	self notifyonplayercommand("right", "+speed_throw");
	self notifyonplayercommand("left", "+moveright");
	self notifyonplayercommand("right", "+moveleft");
	self notifyonplayercommand("select", "+usereload");
	self notifyonplayercommand("select", "+activate");
	self notifyonplayercommand("select", "+gostand");

	self.statusicon = "veh_hud_target_chopperfly"; // Red dot
	level waittill("mv_start_vote");

	index = 0;
	isVoting = 1;
	while (level.__mapvote["time"] > 0 && isVoting)
	{
		command = self waittill_any_return("left", "right", "select", "done");
		if (command == "right")
		{
			index++;
			if (index == boxes.size)
				index = 0;
		}
		else if (command == "left")
		{
			index--;
			if (index < 0)
				index = boxes.size - 1;
		}

		if (command == "select")
		{
			self.statusicon = "compass_icon_vf_active"; // Green dot
			vote = "vote" + (index + 1);
			level notify(vote);
			select_color = getColor(getDvar("mv_selectcolor"));
			boxes[index] affectElement("color", 0.2, select_color);
			isVoting = 0;
		}
		else
		{
			for (i = 0; i < boxes.size; i++)
			{
				if (i != index)
					boxes[i] affectElement("color", 0.2, bg_color);
				else
					boxes[i] affectElement("color", 0.2, scroll_color);
			}
		}
	}
}

destroyBoxes(boxes)
{
	level endon("game_ended");
	level waittill("mv_destroy_hud");
	foreach (box in boxes)
	{
		box affectElement("alpha", 0.5, 0);
	}
}

mv_PlayerFixAngle()
{
	self endon("disconnect");
	level endon("game_ended");
	level waittill("mv_start_vote");
	angles = self getPlayerAngles();

	self waittill_any("left", "right");
	if (self getPlayerAngles() != angles)
		self setPlayerAngles(angles);
}

mv_VoteManager()
{
	level endon("game_ended");
	votes = [];
	votes[0] = spawnStruct();
	votes[0].votes = level createServerFontString("objective", 2);
	votes[0].votes setPoint("center", "center", -220 + 70, -325);
	votes[0].votes.label = &"^" + getDvar("mv_votecolor");
	votes[0].votes.sort = 4;
	votes[0].value = 0;
	votes[0].map = level.__mapvote["map1"];

	votes[1] = spawnStruct();
	votes[1].votes = level createServerFontString("objective", 2);
	votes[1].votes setPoint("center", "center", 0 + 70, -325);
	votes[1].votes.label = &"^" + getDvar("mv_votecolor");
	votes[1].votes.sort = 4;
	votes[1].value = 0;
	votes[1].map = level.__mapvote["map2"];

	votes[2] = spawnStruct();
	votes[2].votes = level createServerFontString("objective", 2);
	votes[2].votes setPoint("center", "center", 220 + 70, -325);
	votes[2].votes.label = &"^" + getDvar("mv_votecolor");
	votes[2].votes.sort = 4;
	votes[2].value = 0;
	votes[2].map = level.__mapvote["map3"];

	votes[0].votes setValue(0);
	votes[1].votes setValue(0);
	votes[2].votes setValue(0);

	votes[0].votes affectElement("y", 1, 0);
	votes[1].votes affectElement("y", 1, 0);
	votes[2].votes affectElement("y", 1, 0);

	votes[0].hideWhenInMenu = 1;
	votes[1].hideWhenInMenu = 1;
	votes[2].hideWhenInMenu = 1;

	isInVote = 1;
	index = 0;
	while (isInVote)
	{
		notify_value = level waittill_any_return("vote1", "vote2", "vote3", "mv_destroy_hud");

		if (notify_value == "mv_destroy_hud")
		{
			isInVote = 0;

			votes[0].votes affectElement("alpha", 0.5, 0);
			votes[1].votes affectElement("alpha", 0.5, 0);
			votes[2].votes affectElement("alpha", 0.5, 0);

			break;
		}
		else
		{
			switch (notify_value)
			{
			case "vote1":
				index = 0;
				break;
			case "vote2":
				index = 1;
				break;
			case "vote3":
				index = 2;
				break;
			}
			votes[index].value++;
			votes[index].votes setValue(votes[index].value);
		}
	}

	winner = mv_GetMostVotedMap(votes);
	map = winner.map;
	mv_SetRotation(map.mapid, map.gametype);

	wait 1.2;
}

mv_GetMostVotedMap(votes)
{
	winner = votes[0];
	for (i = 1; i < votes.size; i++)
	{
		if (isDefined(votes[i]) && votes[i].value > winner.value)
		{
			winner = votes[i];
		}
	}

	return winner;
}
mv_SetRotation(mapid, gametype)
{
	array = strTok(gametype, ";");
	str = "";
	if (array.size > 1)
	{
		str = "gametype " + array[1];
	}
	logPrint("mapvote//gametype//" + array[0] + "//executing//" + str + "\n");
	setdvar("g_gametype", array[0]);
	setdvar("sv_currentmaprotation", str + " map " + mapid);
	setdvar("sv_maprotationcurrent", str + " map " + mapid);
	setdvar("sv_maprotation", str + " map " + mapid);
	level notify("mv_ended");
}

mv_ServerUI()
{
	level endon("game_ended");

	buttons = level createServerFontString("objective", 1.6);
	buttons setText("^3[{+speed_throw}]              ^7Press ^3[{+gostand}] ^7or ^3[{+activate}] ^7to select              ^3[{+attack}]");
	buttons setPoint("center", "center", 0, 80);
	buttons.hideWhenInMenu = 0;

	mv_votecolor = getDvar("mv_votecolor");

	mapUI1 = level createString("^7" + level.__mapvote["map1"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map1"].gametype, ";")[0]), "objective", 1.1, "center", "center", -220, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);
	mapUI2 = level createString("^7" + level.__mapvote["map2"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map2"].gametype, ";")[0]), "objective", 1.1, "center", "center", 0, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);
	mapUI3 = level createString("^7" + level.__mapvote["map3"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map3"].gametype, ";")[0]), "objective", 1.1, "center", "center", 220, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);

	mapUIBTXT1 = level createRectangle("center", "center", -220, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);
	mapUIBTXT2 = level createRectangle("center", "center", 0, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);
	mapUIBTXT3 = level createRectangle("center", "center", 220, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);

	level notify("mv_start_animation");
	mapUI1 affectElement("y", 1.2, -6);
	mapUI2 affectElement("y", 1.2, -6);
	mapUI3 affectElement("y", 1.2, -6);
	mapUIBTXT1 affectElement("alpha", 1.5, 0.8);
	mapUIBTXT2 affectElement("alpha", 1.5, 0.8);
	mapUIBTXT3 affectElement("alpha", 1.5, 0.8);

	/*mv_arrowcolor = GetColor(getDvar("mv_arrowcolor"));

	arrow_right = drawshader("arrow_left", 200, 290, 25, 25, mv_arrowcolor, 100, 2, "center", "center", 1);
	arrow_left = drawshader("arrow_right", -200, 290, 25, 25, mv_arrowcolor, 100, 2, "center", "center", 1);*/

	wait 1;
	level notify("mv_start_vote");

	mv_sentence = getDvar("mv_sentence");
	mv_socialname = getDvar("mv_socialname");
	mv_sociallink = getDvar("mv_sociallink");
	credits = level createServerFontString("objective", 1.2);
	credits setPoint("center", "center", -300, 150);
	credits setText(mv_sentence + "\nDeveloped by @^5DoktorSAS ^7\n" + mv_socialname + ": " + mv_sociallink);

	timer = level createServerFontString("objective", 2);
	timer setPoint("center", "center", 0, -140);
	timer setTimer(level.__mapvote["time"]);
	wait level.__mapvote["time"];
	level notify("mv_destroy_hud");

	credits affectElement("alpha", 0.5, 0);
	buttons affectElement("alpha", 0.5, 0);
	mapUI1 affectElement("alpha", 0.5, 0);
	mapUI2 affectElement("alpha", 0.5, 0);
	mapUI3 affectElement("alpha", 0.5, 0);
	mapUIBTXT1 affectElement("alpha", 0.5, 0);
	mapUIBTXT2 affectElement("alpha", 0.5, 0);
	mapUIBTXT3 affectElement("alpha", 0.5, 0);
	// arrow_right affectElement("alpha", 0.5, 0);
	// arrow_left affectElement("alpha", 0.5, 0);
	timer affectElement("alpha", 0.5, 0);

	foreach (player in level.players)
	{
		player notify("done");
		player SetBlurForPlayer(0, 0);
	}
}

onPlayerConnected()
{
	level endon("game_ended");
	for (;;)
	{
		level waittill("connected", player);
		player thread FixBlur();
	}
}
FixBlur() // Patch blur effect
{
	self endon("disconnect");
	level endon("game_ended");
	self waittill("spawned_player");
	self SetBlurForPlayer(0, 0);
}

main()
{
	// replacefunc do not work as intended once patched remove // in front of one of the next 2 lines

	// replacefunc( maps\mp\gametypes\_gamelogic::endgame_regularmp, ::stub_endgame_regularmp);
	// replacefunc( getfunction("maps/mp/gametypes/_gamelogic", "endgame_regularmp"), ::stub_endgame_regularmp);
}

stub_endgame_regularmp(var_0, var_1, var_2)
{
	if (!isdefined(var_2))
		var_2 = 0;

	if (game["state"] == "postgame" || level.gameended && (!isdefined(level.gtnw) || !level.gtnw))
		return;

	setomnvar("ui_pause_menu_show", 0);
	game["state"] = "postgame";
	setdvar("ui_game_state", "postgame");
	level.gameendtime = gettime();
	level.gameended = 1;
	level.ingraceperiod = 0;
	level notify("game_ended", var_0);
	maps\mp\_utility::levelflagset("game_over");
	maps\mp\_utility::levelflagset("block_notifies");
	common_scripts\utility::waitframe();
	setgameendtime(0);
	var_3 = getmatchdata("gameLength");
	var_3 += int(maps\mp\_utility::getsecondspassed());
	setmatchdata("gameLength", var_3);
	maps\mp\gametypes\_playerlogic::printpredictedspawnpointcorrectness();

	if (isdefined(var_0) && isstring(var_0) && var_0 == "overtime")
	{
		level.finalkillcam_winner = "none";
		endgameovertime(var_0, var_1);
		return;
	}

	if (isdefined(var_0) && isstring(var_0) && var_0 == "halftime")
	{
		level.finalkillcam_winner = "none";
		endgamehalftime();
		return;
	}

	if (isdefined(level.finalkillcam_winner))
		level.finalkillcam_timegameended[level.finalkillcam_winner] = maps\mp\_utility::getsecondspassed();

	game["roundsPlayed"]++;

	if (level.teambased)
	{
		if (var_0 == "axis" || var_0 == "allies")
			game["roundsWon"][var_0]++;

		maps\mp\gametypes\_gamescore::updateteamscore("axis");
		maps\mp\gametypes\_gamescore::updateteamscore("allies");
	}
	else if (isdefined(var_0) && isplayer(var_0))
		game["roundsWon"][var_0.guid]++;

	maps\mp\gametypes\_gamescore::updateplacement();
	rankedmatchupdates(var_0);

	foreach (var_5 in level.players)
	{
		var_5 setclientdvar("ui_opensummary", 1);

		if (maps\mp\_utility::wasonlyround() || maps\mp\_utility::waslastround())
			var_5 maps\mp\killstreaks\_killstreaks::clearkillstreaks();
	}

	setdvar("g_deadChat", 1);
	setdvar("ui_allow_teamchange", 0);
	setdvar("bg_compassShowEnemies", 0);
	freezeallplayers(1.0, "cg_fovScale", 1);

	if (!var_2)
		visionsetnaked("mpOutro", 0.5);

	if (!maps\mp\_utility::wasonlyround() && !var_2)
	{
		displayroundend(var_0, var_1);

		if (isdefined(level.finalkillcam_winner))
		{
			foreach (var_5 in level.players)
				var_5 notify("reset_outcome");

			level notify("game_cleanup");
			waittillfinalkillcamdone();
		}

		if (!maps\mp\_utility::waslastround())
		{
			maps\mp\_utility::levelflagclear("block_notifies");

			if (checkroundswitch())
				displayroundswitch();

			foreach (var_5 in level.players)
				var_5.pers["stats"] = var_5.stats;

			level notify("restarting");
			game["state"] = "playing";
			setdvar("ui_game_state", "playing");
			map_restart(1);
			return;
		}

		if (!level.forcedend)
			var_1 = updateroundendreasontext(var_0);
	}

	if (!isdefined(game["clientMatchDataDef"]))
	{
		game["clientMatchDataDef"] = "mp/clientmatchdata.def";
		setclientmatchdatadef(game["clientMatchDataDef"]);
	}

	maps\mp\gametypes\_missions::roundend(var_0);

	if (level.teambased && maps\mp\_utility::isroundbased() && level.gameended && !maps\mp\_utility::ismoddedroundgame())
	{
		if (game["roundsWon"]["allies"] == game["roundsWon"]["axis"])
			var_0 = "tie";
		else if (game["roundsWon"]["axis"] > game["roundsWon"]["allies"])
		{
			level.finalkillcam_winner = "axis";
			var_0 = "axis";
		}
		else
		{
			level.finalkillcam_winner = "allies";
			var_0 = "allies";
		}
	}

	victim = level.finalKillCam_victim[level.finalkillcam_winner];
	attacker = level.finalKillCam_attacker[level.finalkillcam_winner];

	// --------------------------------------------------------------------------------------------------------------
	wait 2;
	killcamExist = 1;
	if (!IsDefined(victim) ||
		!IsDefined(attacker))
	{
		killcamExist = 0;
	}

	if (killcamExist && isdefined(level.finalkillcam_winner) && maps\mp\_utility::wasonlyround())
	{
		displaygameend(var_0, var_1);
		foreach (var_5 in level.players)
			var_5 notify("reset_outcome");

		level notify("game_cleanup");
		waittillfinalkillcamdone();
	}

	maps\mp\_utility::levelflagclear("block_notifies");

	[[level.startmapvote]] ();
	if (!killcamExist)
	{
		displaygameend(var_0, var_1);
	}
	// --------------------------------------------------------------------------------------------------------------

	level.intermission = 1;
	level notify("start_custom_ending");
	level notify("spawning_intermission");

	foreach (var_5 in level.players)
	{
		var_5 notify("reset_outcome");
		var_5 thread maps\mp\gametypes\_playerlogic::spawnintermission();
	}

	processlobbydata();
	wait 1.0;
	checkforpersonalbests();

	if (level.teambased)
	{
		if (var_0 == "axis" || var_0 == "allies")
			setmatchdata("victor", var_0);
		else
			setmatchdata("victor", "none");

		setmatchdata("alliesScore", getteamscore("allies"));
		setmatchdata("axisScore", getteamscore("axis"));
	}
	else
		setmatchdata("victor", "none");

	foreach (var_5 in level.players)
	{
		var_5 setcommonplayerdata("round", "endReasonTextIndex", var_1);

		if (var_5 maps\mp\_utility::rankingenabled() && !maps\mp\_utility::is_aliens())
			var_5 maps\mp\_matchdata::logfinalstats();
	}

	setmatchdata("host", level.hostname);

	if (maps\mp\_utility::matchmakinggame())
	{
		setmatchdata("playlistVersion", getplaylistversion());
		setmatchdata("playlistID", getplaylistid());
		setmatchdata("isDedicated", isdedicatedserver());
	}

	sendmatchdata();

	foreach (var_5 in level.players)
		var_5.pers["stats"] = var_5.stats;

	if (!var_2 && !level.postgamenotifies)
	{
		if (!maps\mp\_utility::wasonlyround())
			wait 6.0;
		else
			wait(min(10.0, 4.0 + level.postgamenotifies));
	}
	else
		wait(min(10.0, 4.0 + level.postgamenotifies));

	maps\mp\_utility::levelflagwaitopen("post_game_level_event_active");

	setnojipscore(0);
	setnojiptime(0);
	level notify("exitLevel_called");
	exitlevel(0);
}

// Utils

maptoname(mapid)
{
	mapid = tolower(mapid);
	if (mapid == "mp_prisonbreak")
		return "Prision Break";
	if (mapid == "mp_dart")
		return "Octane";
	if (mapid == "mp_lonestar")
		return "Tremor";
	if (mapid == "mp_frag")
		return "Freight";
	if (mapid == "mp_snow")
		return "Whiteout";
	if (mapid == "mp_fahrenheit")
		return "Stormfront";
	if (mapid == "mp_hashima")
		return "Siege";
	if (mapid == "mp_warhawk")
		return "Warhawk";
	if (mapid == "mp_sovereign")
		return "Sovereign";
	if (mapid == "mp_zebra")
		return "Overload";
	if (mapid == "mp_skeleton")
		return "Stonehaven";
	if (mapid == "mp_chasm")
		return "Chasm";
	if (mapid == "mp_flooded")
		return "Flooded";
	if (mapid == "mp_strikezone")
		return "Strikezone";
	if (mapid == "mp_descent_new")
		return "Free Fall";

	if (mapid == "mp_dome_ns")
		return "Unearthed";
	if (mapid == "mp_ca_impact")
		return "Collision";
	if (mapid == "mp_ca_behemoth")
		return "Behemoth";
	if (mapid == "mp_battery3")
		return "Ruins";

	if (mapid == "mp_dig")
		return "Pharaoh";
	if (mapid == "mp_favela_iw6")
		return "Favela";
	if (mapid == "mp_pirate")
		return "Mutiny";
	if (mapid == "mp_zulu")
		return "Departed";

	if (mapid == "mp_conflict")
		return "Dynasty";
	if (mapid == "mp_mine")
		return "Goldrush";
	if (mapid == "mp_shipment_ns")
		return "Showtime";
	if (mapid == "mp_zerosub")
		return "Subzero";

	if (mapid == "mp_boneyard_ns")
		return "Ignition";
	if (mapid == "mp_ca_red_river")
		return "Containment";
	if (mapid == "mp_ca_rumble")
		return "Bayview";
	if (mapid == "mp_swamp")
		return "Fog";

	return mapid;
}

maptoname(mapid)
{
	mapid = tolower(mapid);
	if (mapid == "mp_prisonbreak")
		return "Prision Break";
	if (mapid == "mp_dart")
		return "Octane";
	if (mapid == "mp_lonestar")
		return "Tremor";
	if (mapid == "mp_frag")
		return "Freight";
	if (mapid == "mp_snow")
		return "Whiteout";
	if (mapid == "mp_fahrenheit")
		return "Stormfront";
	if (mapid == "mp_hashima")
		return "Siege";
	if (mapid == "mp_warhawk")
		return "Warhawk";
	if (mapid == "mp_sovereign")
		return "Sovereign";
	if (mapid == "mp_zebra")
		return "Overload";
	if (mapid == "mp_skeleton")
		return "Stonehaven";
	if (mapid == "mp_chasm")
		return "Chasm";
	if (mapid == "mp_flooded")
		return "Flooded";
	if (mapid == "mp_strikezone")
		return "Strikezone";
	if (mapid == "mp_descent_new")
		return "Free Fall";

	if (mapid == "mp_dome_ns")
		return "Unearthed";
	if (mapid == "mp_ca_impact")
		return "Collision";
	if (mapid == "mp_ca_behemoth")
		return "Behemoth";
	if (mapid == "mp_battery3")
		return "Ruins";

	if (mapid == "mp_dig")
		return "Pharaoh";
	if (mapid == "mp_favela_iw6")
		return "Favela";
	if (mapid == "mp_pirate")
		return "Mutiny";
	if (mapid == "mp_zulu")
		return "Departed";

	if (mapid == "mp_conflict")
		return "Dynasty";
	if (mapid == "mp_mine")
		return "Goldrush";
	if (mapid == "mp_shipment_ns")
		return "Showtime";
	if (mapid == "mp_zerosub")
		return "Subzero";

	if (mapid == "mp_boneyard_ns")
		return "Ignition";
	if (mapid == "mp_ca_red_river")
		return "Containment";
	if (mapid == "mp_ca_rumble")
		return "Bayview";
	if (mapid == "mp_swamp")
		return "Fog";

	return mapid;
}
SetDvarIfNotInizialized(dvar, value)
{
	if (!IsInizialized(dvar))
		setDvar(dvar, value);
}
IsInizialized(dvar)
{
	result = getDvar(dvar);
	return result != "";
}

gametypeToName(gametype)
{
	switch (tolower(gametype))
	{
	case "dm":
		return "Free for all";

	case "tdm":
		return "Team Deathmatch";

	case "sd":
		return "Search & Destroy";

	case "conf":
		return "Kill Confirmed";

	case "ctf":
		return "Capture the Flag";

	case "dom":
		return "Domination";

	case "dem":
		return "Demolition";

	case "gun":
		return "Gun Game";

	case "hq":
		return "Headquaters";

	case "koth":
		return "Hardpoint";

	case "oic":
		return "One in the chamber";

	case "oneflag":
		return "One-Flag CTF";

	case "sas":
		return "Sticks & Stones";

	case "shrp":
		return "Sharpshooter";
	}
	return "invalid";
}

// UI Utils
isValidColor(value)
{
	return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}
GetColor(color)
{
	switch (tolower(color))
	{
	case "red":
		return (0.960, 0.180, 0.180);

	case "black":
		return (0, 0, 0);

	case "grey":
		return (0.035, 0.059, 0.063);

	case "purple":
		return (1, 0.282, 1);

	case "pink":
		return (1, 0.623, 0.811);

	case "green":
		return (0, 0.69, 0.15);

	case "blue":
		return (0, 0, 1);

	case "lightblue":
	case "light blue":
		return (0.152, 0329, 0.929);

	case "lightgreen":
	case "light green":
		return (0.09, 1, 0.09);

	case "orange":
		return (1, 0662, 0.035);

	case "yellow":
		return (0.968, 0.992, 0.043);

	case "brown":
		return (0.501, 0.250, 0);

	case "cyan":
		return (0, 1, 1);

	case "white":
		return (1, 1, 1);
	}
}
CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isLevel)
{
	if (!isDefined(isLevel))
		hud = self createFontString(font, fontScale);
	else
		hud = level createServerFontString(font, fontScale);

	hud setText(input);

	hud.x = x;
	hud.y = y;
	hud.align = align;
	hud.horzalign = align;
	hud.vertalign = relative;

	hud setPoint(align, relative, x, y);

	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud.archived = 0;
	hud.hideWhenInMenu = 0;
	return hud;
}
CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha, islevel)
{
	if (isDefined(isLevel))
		boxElem = newhudelem();
	else
		boxElem = newclienthudelem(self);
	boxElem.elemType = "bar";
	boxElem.width = width;
	boxElem.height = height;
	boxElem.align = align;
	boxElem.relative = relative;
	boxElem.horzalign = align;
	boxElem.vertalign = relative;
	boxElem.xOffset = 0;
	boxElem.yOffset = 0;
	boxElem.children = [];
	boxElem.sort = sort;
	boxElem.color = color;
	boxElem.alpha = alpha;
	boxElem setParent(level.uiParent);
	boxElem setShader(shader, width, height);
	boxElem.hidden = 0;
	boxElem setPoint(align, relative, x, y);
	boxElem.hideWhenInMenu = 0;
	boxElem.archived = 0;
	return boxElem;
}

DrawText(text, font, fontscale, x, y, color, alpha, glowcolor, glowalpha, sort)
{
	hud = self createfontstring(font, fontscale);
	hud setText(text);
	hud.x = x;
	hud.y = y;
	hud.color = color;
	hud.alpha = alpha;
	hud.glowcolor = glowcolor;
	hud.glowalpha = glowalpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud.hideWhenInMenu = 0;
	hud.archived = 0;
	return hud;
}
DrawShader(shader, x, y, width, height, color, alpha, sort, align, relative, isLevel)
{
	if (isDefined(isLevel))
		hud = newhudelem();
	else
		hud = newclienthudelem(self);
	hud.elemtype = "icon";
	hud.color = color;
	hud.alpha = alpha;
	hud.sort = sort;
	hud.children = [];
	if (isDefined(align))
		hud.align = align;
	if (isDefined(relative))
		hud.relative = relative;
	hud setparent(level.uiparent);
	hud.x = x;
	hud.y = y;
	hud setshader(shader, width, height);
	hud.hideWhenInMenu = 0;
	hud.archived = 0;
	return hud;
}
// UI Animations
affectElement(type, time, value)
{
	if (type == "x" || type == "y")
		self moveOverTime(time);
	else
		self fadeOverTime(time);
	if (type == "x")
		self.x = value;
	if (type == "y")
		self.y = value;
	if (type == "alpha")
		self.alpha = value;
	if (type == "color")
		self.color = value;
}
