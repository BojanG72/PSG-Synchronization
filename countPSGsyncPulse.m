function [pulseLoc, pulseCount] = countPSGsyncPulse(sync)

% This function will count the number of sync pulses in the sync signal
% from the PSG. It will return the total number of pulses and the location
% of each pulse in the sync signal

% Input         :   sync   : Sync data from the PSG (CPAP Flow channel)

% Output        :   pulseLoc     : Location of each pulse in the signal
%                   pulseCount   : Number of pulses in the signal

% Developed by Muammar Kabir, UHN. 2017


%Make sure pulses are always positive if inverted
sync=sync.^2;

%Bring baseline to zero and normalize pulse magnitude between 0-1
sync = sync-sync(1);
sync = sync/max(sync);

%Find pulses greater than 0.5 in magnitude, save as binary
%Find the start point of pulses where derivative is =1 i.e. >0
pulseLogical=diff(sync > 0.5) > 0;
pulseLoc=find(pulseLogical==1);

%Add one sample to take into account the effect of using derivative
pulseLoc=pulseLoc+1;

%Count pulses
pulseCount=length(pulseLoc);


