%%% This script should live in your Matlab startup folder (typically,
%%% for windows, your 'Documents\MATLAB' folder). Change the file paths
%%% below to suit your setup. Rename the file to "startup.m" - it will then
%%% execute every time Matlab starts.


setenv('LOCALDATADIR', 'C:\Users\irwin\Documents\Lab work\Data');       % local directory where data will be saved
setenv('REMOTEDATADIR', 'C:\Users\irwin\Box\Data');                     % remote location of raw data files (e.g. Box Drive folder)
                                                                        %   if no remote location available, set to '.'
setenv('INFOFILE', 'C:\Users\irwin\Box\Lab work\Irwin, Z\PT_INFO.mat'); % location of the patient info file

codedir = 'C:\Users\irwin\Documents\Lab work\Code\lab-work';            % directory that houses the code repository
cddir = 'C:\Users\irwin\Box\Lab work\Irwin, Z\Analysis';                % directory to set matlab's working directory to
                                                                        %   if not desired, set to '.'


addpath(codedir);
addpath(fullfile(codedir, 'Database and File IO'));
addpath(fullfile(codedir, 'Signal Processing'));
addpath(fullfile(codedir, 'Utilities'));
addpath(fullfile(codedir, 'Plotting'));
addpath(fullfile(codedir, 'External Toolboxes', 'plot2svg'));


if (exist(cddir, 'dir'))
    cd(cddir);
end

clear;
clc;