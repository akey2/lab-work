function id = getParticipantID(subjID, database)

if (nargin < 2 ||isempty(database))
    
    if (~isempty(getenv('REMOTEDATADIR')) && exist(fullfile(getenv('REMOTEDATADIR'), 'DBSdatabase csv file\DBSdatabase.csv'), 'file'))
        database = fullfile(getenv('REMOTEDATADIR'), 'DBSdatabase csv file\DBSdatabase.csv');
    else
        [dbfile, dbpath] = uigetfile('*.csv;*.xls;*.xlsx', 'Select DBS database' );
        if (dbfile == 0)
            error('Couldn''t find DBS database file');
        end
        database = fullfile(dbpath, dbfile);
    end
end

db = readtable(database, 'Range', 'A:B');

idx = find(contains(db.study_ID, subjID, 'IgnoreCase', true), 1);

id = num2str(db.participant_ID(idx), 15);