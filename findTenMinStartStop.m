function [tenMinuteStart,tenMinuteStop,missingFirstPulse]=findTenMinStartStop(pulseLoc,hourCounter)

% This function will give the start and end pulse count representing one 10
% minute segment

% Input         :   pulseLoc   : Location of each pulse in the signal
%               :   hourCounter: hour of recording

% Output        :   tenMinuteStart     : Ten minute start pulse
%               :   tenMinuteStop      : Ten minute stop pulse
%               :   missingFirstPulse  : '0' indicates false; i.e. first pulse is present
%                                      : '1' indicates true; i.e. first pulse is absent

% Developed by Muammar Kabir, UHN. 2017

missingFirstPulse=0;
 
pulseLocDerivative = diff(pulseLoc);

medianPulseDerivative=median(pulseLocDerivative);
pulseDerGreaterMedian=pulseLocDerivative(pulseLocDerivative>(median(pulseLocDerivative)+100));
medianPulseDerivativeLarge=median(pulseDerGreaterMedian);

%Thresholds
logicThresSmall=medianPulseDerivative*4;
logicThresLarge=medianPulseDerivativeLarge+(medianPulseDerivativeLarge/30); %16000, 10000;

pulseDisThresSmall=medianPulseDerivative-(medianPulseDerivative/4); %25, 16;
pulseDisThresLarge=medianPulseDerivativeLarge-(medianPulseDerivativeLarge/25); %14900, 9000;

%Logic
pulseLocLogical = pulseLocDerivative;
pulseLocLogical(pulseLocLogical<=logicThresSmall)=0;
pulseLocLogical(pulseLocLogical>logicThresSmall & pulseLocLogical<=logicThresLarge)=1;
pulseLocLogical(pulseLocLogical>logicThresLarge)=2;

pulseCounts1stHour   = [1 1 2 3 4 5 7];
pulseCountsOtherHour = [0 1 2 3 4 5 7];

addToTenMinCounter=0;

if pulseLocLogical(1)~=1
    if pulseLocLogical(1)==0 && pulseLocLogical(2)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2))*(-1);
        pulseCounts1stHour(2)=[];
        addToTenMinCounter=1;
        missingFirstPulse=1;
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:3))*(-1);
        pulseCounts1stHour(2:3)=[];
        addToTenMinCounter=2;
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==0 && pulseLocLogical(4)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:4))*(-1);
        pulseCounts1stHour(2:4)=[];
        addToTenMinCounter=3;
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==0 && pulseLocLogical(4)==0 && pulseLocLogical(5)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:5))*(-1);
        pulseCounts1stHour(2:5)=[];
        addToTenMinCounter=4;
    end
end


if hourCounter==1
    pulseNumber=cumsum(pulseCounts1stHour);
else
    pulseCountsOtherHourAdd=pulseCountsOtherHour;
    pulseCountsOtherHourAdd(1)=pulseCountsOtherHourAdd(1)+((23*(hourCounter-1))+1);
    pulseNumber=cumsum(pulseCountsOtherHourAdd);
end
    
tenMinuteStart=pulseNumber(1:end-1);
tenMinuteStop=pulseNumber(2:end);

if ~isrow(tenMinuteStart) && ~isrow(tenMinuteStop)
    tenMinuteStart=tenMinuteStart';
    tenMinuteStop=tenMinuteStop';
end