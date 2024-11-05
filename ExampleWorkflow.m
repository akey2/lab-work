% This script gives an example of a simple workflow using the lab code
% framework. It generates an event-related potential time-locked to a
% stimulus (in this case, the onset of a vibration). This is intended to be
% run after setting up the framework using the "startup_template" script

%% Get subject/file info structures:

info = getInfoFile();

sub_info = info({info.ID} == "BB021");
file_info = sub_info.File({sub_info.File.FileName} == "lfp");

%% Get data associated with subject/file:

id = getParticipantID("BB021");
[data, fi] = LoadDatav2("BB021", "lfp");

%% Get buzz/stimulus data:

stim = ParseStimulusTrials(fi);

%% Preprocess the data:

% extract DBS channels, filter, downsample, and re-reference:
[data_dbs, sr] = PreProcessData(data(file_info.DBSChans,:), [5, 100], file_info.SampleRate, 1000, [2, 3, 4; 5, 6, 7], file_info.BadDBSContacts);

%% Epoch the data around buzz and compute event-related potential:

% remember to convert the stimulus times from the original sampling rate to
% the downsampled rate
epochs = EpochData(data_dbs, round([stim.StimLoc_sample]*sr/file_info.SampleRate), [-100, 150]*sr/1000);

% average across epochs:
erp = mean(epochs, 3);

% time vector corresponding to the window entered into EpochData():
t_epoch = linspace(-100, 150, size(epochs, 2));

figure; plot(t_epoch, erp')