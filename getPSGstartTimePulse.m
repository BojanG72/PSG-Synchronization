function [psgStartTime,pulseStartTime]=getPSGstartTimePulse(psgEventFolder,psgStartPulseSample,psgSampleFrequency)

psgStartTime=[];
pulseStartTime=[];
    
psgEventList = dir(fullfile(psgEventFolder, '*.txt'));

% Initialize variables
filename = fullfile(psgEventFolder, psgEventList(1).name);
delimiter = '\t';

% Read columns of data as strings
formatSpec = '%s%s%s%s%s%s%[^\n\r]';

% Open the text file.
fileID = fopen(filename,'r');

% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);

% Close the text file.
fclose(fileID);


% Study Start Time
    
if mean(dataArray{1,1}{5,1}=='Study Date:')==1
    
    psgStartTime=datestr(dataArray{1,2}{5,1},14);   
 
    addSec=psgStartPulseSample/psgSampleFrequency;
    R1=[];
    R1=addtodate(datenum(dataArray{1,2}{5,1}),addSec,'second');
    % datestr(R1,'dd.mm.yyyy HH:MM:SS');
    pulseStartTime=datestr(datevec(R1,'dd.mm.yyyy,HH:MM:SS'),14);
        
end
    
