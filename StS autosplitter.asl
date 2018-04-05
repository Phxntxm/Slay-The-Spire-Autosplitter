state("SlayTheSpire")
{
	
}
init
{
	// Get the path to the logfile we'll use
	string[] paths = game.MainModule.FileName.Split('\\');
	var logpath = paths.Take(Math.Max(0, paths.Count() - 1));
	vars.logpath = String.Join("\\", logpath) + "\\sendToDevs\\logs\\SlayTheSpire.log";
	
	// Open it, and create a streamreader (Note: the game has an active open write to it as well)
	FileStream fs = File.Open(vars.logpath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
	vars.sr = new StreamReader(fs, Encoding.Default);
}
startup
{
	string last_unlock = null; // The last boss we unlocked (controls our acts)
	vars.act = 0; // Which act we're on
	vars.starting_line = 0; // Which line the run has started on
	bool test = (last_unlock == "GHOST" || last_unlock == "GUARDIAN" || last_unlock == "SLIME");
}
start
{
	string line;
	string non_empty_line = null;
	int count = 0;
	
	// Read through the logfile
	while ((line = vars.sr.ReadLine()) != null)
	{
		// Take a count so we will know where our start is
		count += 1;
		// Get the "last" nonempty string
		if (! String.IsNullOrEmpty(line))
			non_empty_line = line;
	}
	// Seek back to the start of the file for the next read
	vars.sr.BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
	vars.sr.DiscardBufferedData();
	
	// Now check if we have started generating the seeds for the level, which means we've started a run
	if (non_empty_line.Contains("AbstractDungeon> Generating seeds:"))
	{
		vars.act = 1;
		vars.starting_line = count;
		vars.game_started = true;
		vars.game_exited = false;
		return true;
	}
}
split
{
	string line;
	string last_unlock = null;
	int count = 0;
	
	// Read through file
	while ((line = vars.sr.ReadLine()) != null)
	{
		count += 1;
		// Only check if we're past the point of the run start
		// Check if we've unlocked a boss
		if (count >= vars.starting_line & line.Contains("UnlockTracker> Hard Unlock:"))
			last_unlock = line.Split(' ').Last();
	}
	vars.sr.BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
	vars.sr.DiscardBufferedData();
	
	// Ensure the last unlock we've found happens when we're in the right act, to ensure no double-splits
	if (vars.act == 1) {
		if (last_unlock == "GHOST" || last_unlock == "GUARDIAN" || last_unlock == "SLIME")
		{
			vars.act = 2;
			return true;
		}
	}
	else if (vars.act == 2) {
		if (last_unlock == "CHAMP" || last_unlock == "COLLECTOR" || last_unlock == "AUTOMATON")
		{
			vars.act = 3;
			return true;
		}
	}
	else if (vars.act == 3) {
		if (last_unlock == "DONUT" || last_unlock == "WIZARD" || last_unlock == "CROW")
		{
			vars.act = 4;
			return true;
		}
	}
}
reset
{
	string line;
	int count = 0;
	// Read through and look for if we've gone  back to the main screen
	while ((line = vars.sr.ReadLine()) != null)
	{
		count += 1;
		if (count >= vars.starting_line & line.Contains("New Main Menu Screen"))
		{
			vars.sr.BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
			vars.sr.DiscardBufferedData();
			return true;
		}
	}
	vars.sr.BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
	vars.sr.DiscardBufferedData();
}
exit
{
	var model = new TimerModel() { CurrentState = timer };
	model.Reset();
}