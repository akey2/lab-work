# lab-work

This is a library of Matlab code I use for analysis and data maintenance. The environment is set up primarily for use with Box Drive (or any other virtual drive - Dropbox, OneDrive, a mounted server, etc), but will work without one. Functions for analysis, plotting, etc can be used in any environment even if you don't want to use the virtual drive setup.

 ## Environment description
 
 Raw data files collected during experiments are on Box. Information about each participant/experiment is collected in a Matlab structure array (INFO) that also lives on Box (ideally, I wanted this to be on GitHub, but the file's too big already...). The user (you) will have a copy of this repository on your local machine, as well as a local folder where extracted data will be saved. You can use the tools in the "Database and File IO" folder of this repository to interact with the participant info structure and to extract and load data.
 
 The first time you load a dataset, it will extract the data from the raw files (*.eeg, *.vhdr, *.vmrk) and store a single *.mat file in your local data directory. This file should contain all necessary information to work with the data itself (info like sampling rate, channel impedances, etc., as well as the text of any stimulus file used and any event markers collected during the recording), so you only have to deal with that one file. Information about the experiment itself (which behaviors were performed and when they started/stopped, list of bad channels, etc) live in the INFO structure.
 
 After setting up the Matlab environment (instructions below), the workflow is something like:
  * Add participants/experiments to the INFO structure as needed using the PatientInfoGUI_v4 app (I'll fix the name eventually, maybe)
  * You can load in and search the INFO structure for participants/files that fit your analysis needs (e.g. participants with GPi implants who have done a particular task), or just use it as a helpful guide.
  * Load data using the LoadDatav2 function (again, I might fix the name eventually). If the file has already been extracted into your local data directory, then it will simply be loaded into Matlab. Otherwise, you can either supply a path to the raw files or the function will pop up a GUI for you to navigate to and select the raw files. It will then extract the data and save it into the local directory for future use. If you run out of space, you can always delete the local data files, you'll just have to re-extract them later if you want to use them again.
  * Use the analysis/plotting tools available in the library or your own. The PreProcessData function in /Signal Processing is a good general-purpose first step after loading in the data. Use the INFO structure to give the PreProcessData information on bad channels, etc.
    
## Setting up the environment

  * Copy the "startup_template.m" file to your Matlab starting directory (for windows, it's usually your "Documents/MATLAB" folder). 
  * Rename the file to "startup.m". 
  * Open up the file and change the directories to fit your local machine
    * Set which local folder will house your data files
    * Set a remote data directory where the raw data files are housed (if, say, you've got Box Drive installed). If there isn't a remote drive available, just set that variable to '.'
    * Set the location of the patient INFO file (this might be on Box Drive, or you may just have a copy downloaded to your local machine)
    * Set the location of your copy of this code repository
    * Set the location you'd like Matlab to move to by default (I move into my analysis folder, but it's up to you). Again, if you don't want to move, set that variable to '.'
    * You can alter which folders are added to the path, adding or subtracting as needed
  * Save the file, and it should run every time you open Matlab
    
