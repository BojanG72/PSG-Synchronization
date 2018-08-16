function [pulseLoc, pulseCount] = countSyncPulses (sync)
% This function will count the number of sync pulses in the sync signal
% from the PSG. It will return the total number of pulses and the location
% of each pulse in the sync signal

% Input         :   sync   : Sync data from the PSG (CPAP Flow channel)

% Output        :   pulseLoc     : Location of each pulse in the signal
%                   pulseCount   : Number of pulses in the signal

% Developed by Bojan Gavrilovic, UHN. 2017

%ToDO replace loops with function findpeaks
pulseLoc = 0;
pulseCount = 0;
% Start group Count at -1 or else the first group count of pulses will be
% off by one
groupCount = -1;
lastPulse = 0;
currentPulse = 0;
firstPulseCount = 0;
checkDistance = 0;
for i = 2:length(sync)
    if sync(i)>= 200 && sync(i-1) < 200
        lastPulse = currentPulse;
        currentPulse = i;
        pulseCount = pulseCount+1;
        groupCount = groupCount+1;
        pulseLoc(pulseCount) = i;
        checkDistance = 1;
    end
    if (currentPulse - lastPulse)>10000 && checkDistance
        firstPulseCount = firstPulseCount+1;
        firstPulseLoc(1,firstPulseCount) = currentPulse;
        firstPulseLoc(2,firstPulseCount) = groupCount;
        groupCount = 0;
        checkDistance = 0;
     end
end

end