function [tenMinCounter,hourCounter,pulseCounter,pulseNumber]=updateCounters(tenMinCounter,hourCounter,pulseCounter,pulseCountsOtherHour)

% This function will find the location and number of missing pulses and
% add binary values corresponding to the missing pulse(s) number
%
%Inputs :     tenMinCounter             : count of the 10 minute segment in the current hour
%             hourCounter               : current hour being analysed             
%             pulseCounter              : count of pulses 
%             pulseCountsOtherHour      : count of the pulse number such that the cumulative 
%                                         sum will indicate the start of a 10 minute segment
%                                         for hours other than the 1st hour
%                                           
%Output :     tenMinCounter             : updated count of the 10 minute segment in the current hour
%             hourCounter               : updated hour to be analysed 
%             pulseCounter              : updated count of pulses
%             pulseNumber               : the updated number of the starting pulse
%                                         in a 10 minute segment
%
%Developed by: Muammar Kabir

%In case of missing 10 minute segment: tenMinCounter > pulseCounter
%the updated tenMinCounter should be greater than the pulseCounter 
%as pulseCounter is being updated before writing into the matrix
if tenMinCounter==pulseCounter
    tenMinCounter=tenMinCounter-7+1;
    hourCounter=hourCounter+1;
    pulseCounter=pulseCounter-7;
else
    tenMinCounter=tenMinCounter-7+1;
    hourCounter=hourCounter+1;
    pulseCounter=pulseCounter-7+1;
end
    
pulseCountsOtherHourAdd=pulseCountsOtherHour;
pulseCountsOtherHourAdd(1)=pulseCountsOtherHourAdd(1)+((23*(hourCounter-1))+1);
pulseNumber=cumsum(pulseCountsOtherHourAdd);