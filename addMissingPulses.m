function [tenMinCounter,pulseCounter,pulseLoc,pulseLocDerivative,pulseLocLogical,endPulseNumber]=...
    addMissingPulses(pulseLoc,pulseLocDerivative,pulseLocLogical,startPulseNumber,endPulseNumber,tenMinCounter,pulseCounter,medianPulseDerivativeLarge,pulseDisThresSmall,pulseDisThresLarge,logicArray)

% This function will find the location and number of missing pulses and
% add binary values corresponding to the missing pulse(s) number
%
%Inputs :     pulseLoc                      : location of each pulse in the signal
%             pulseLocDerivative            : difference between pulse locations             
%             pulseLocLogical               : pulse location derivative converted to logicals 
%             startPulseNumber              : start number of pulse for a 10-minute segment
%             endPulseNumber                : end number of pulse for a
%                                             10-minute segment
%             tenMinCounter                 : count of the 10 minute segment in the current hour
%             pulseCounter                  : count of pulses
%             medianPulseDerivativeLarge    : the median of the distance between long-distant pulses
%             pulseDisThresSmall            : distance threshold between adjacent
%                                             pulses in one 10-minute segment
%             pulseDisThresLarge            : distance threshold between long-distant
%                                             pulses between two 10-minute segments
%             logicArray                    : Array storing pulse count [1:6] every hour as binary
%
%Output :     tenMinCounter                 : updated count of the 10 minute segment in the current hour             
%             pulseCounter                  : updated count of pulses
%             pulseLoc                      : updated location of each pulse in the signal 
%             pulseLocDerivative            : updated difference between pulse locations
%             pulseLocLogical               : updated pulse location derivative
%                                             converted to logicals
%             endPulseNumber                : updated end Pulse number for
%                                             the 10-minute segment
%
%Developed by: Muammar Kabir

locationLogicalTwo=find(pulseLocLogical(startPulseNumber:endPulseNumber)==2)+startPulseNumber-1;
valueLogicalTwo=pulseLocDerivative(locationLogicalTwo);
numberTenMinuteSeg=round(round(valueLogicalTwo/1000)/floor(medianPulseDerivativeLarge/1000));

missingTenMinPulseSeg=numberTenMinuteSeg-1;
missingTenMinCounterStart=tenMinCounter+1;
missingTenMinCounterEnd=tenMinCounter+missingTenMinPulseSeg;

%Update tenMinCounter to the start of the pulse after the last missing pulse
%While update pulseCounter till the end of mising pulses as it will be updated
%again later before entering value in the matrix
tenMinCounter=tenMinCounter+numberTenMinuteSeg;
pulseCounter=pulseCounter+missingTenMinPulseSeg;

if missingTenMinCounterStart<=7 && missingTenMinCounterEnd<=7
    locLogicArrayToAdd=missingTenMinCounterStart:missingTenMinCounterEnd;
elseif missingTenMinCounterStart>7 && missingTenMinCounterEnd-7<7
    missingTenMinCounterStart=missingTenMinCounterStart-7+1;
    missingTenMinCounterEnd=missingTenMinCounterEnd-7+1;
    locLogicArrayToAdd=missingTenMinCounterStart:missingTenMinCounterEnd;
elseif missingTenMinCounterStart<=7 && missingTenMinCounterEnd>7
    missingTenMinCounterEnd=missingTenMinCounterEnd-7+1;
    locLogicArrayToAdd=missingTenMinCounterStart:7;
    locLogicArrayToAdd=[locLogicArrayToAdd,2:missingTenMinCounterEnd];
end

pulseLocTemp=[];
pulseLocTemp=pulseLoc(1:locationLogicalTwo);
pulseLocTemp=[pulseLocTemp,pulseLocTemp(end)+pulseDisThresLarge];
for iArrayToAdd=1:length(locLogicArrayToAdd)
    temp=[];
    temp=logicArray{locLogicArrayToAdd(iArrayToAdd)};
    for iTemp=1:length(temp)-1
        pulseLocTemp=[pulseLocTemp,pulseLocTemp(end)+pulseDisThresSmall];
    end
    if iArrayToAdd<length(locLogicArrayToAdd)
        pulseLocTemp=[pulseLocTemp,pulseLocTemp(end)+pulseDisThresLarge];
    end
end
pulseLocTemp=[pulseLocTemp,pulseLoc(locationLogicalTwo+1:end)];

clear pulseLoc;
pulseLoc=pulseLocTemp;
clear pulseLocTemp;

pulseLocDerivative = diff(pulseLoc);

pulseLocLogicalTemp=pulseLocLogical(1:locationLogicalTwo);
pulseLocLogicalTemp(end)=1;
for iArrayToAdd=1:length(locLogicArrayToAdd)
    temp=[];
    temp=logicArray{locLogicArrayToAdd(iArrayToAdd)};
    pulseLocLogicalTemp=[pulseLocLogicalTemp,temp];
    endPulseNumber=endPulseNumber+length(temp);
end
pulseLocLogicalTemp=[pulseLocLogicalTemp,pulseLocLogical(locationLogicalTwo+1:end)];

clear pulseLocLogical;
pulseLocLogical=pulseLocLogicalTemp;
clear pulseLocLogicalTemp;