function matrixHrMinSyncPulseLoc = findBeginSyncPulse(pulseLoc)

% This function will find beginning of pulse sample for every 10 minute 
% of each hour and record location. It will return a matrix with rows
% indicating hours and columns representing beginning of 10 minute except
% for last column which gives the end of last 10 minute

% Input         :   pulseLoc   : Location of each pulse in the signal

% Output        :   matrixHrMinSyncPulseLoc     : matrix


% Developed by Muammar Kabir, UHN. 2017


%Get the difference between pulse locations
pulseLocDerivative = diff(pulseLoc);

%The differences between the pulses at the end of a 10 minute should be
%small while the difference between the last pulse of the 1st 10 minute and
%the first pulse of the next 10 minute should be large

%The number of adjacent pulses for every 10 minute is much higher than the
%number of 10 minutes recorded overnight; this implies that the number of
%smaller derivative values will be much higher than the higher derivative
%values
%mediean of the derivative would provide the median of the distance in
%samples between the short-distant pulses generated for every 10 minute
medianPulseDerivative=median(pulseLocDerivative);

%The sample distance between short-distant pulses ranges between 10-80 samples
%In order to make sure that we only locate and separate out the long-distant pulses,
%100 is being added to the median of pulse derivative
%Followed by finding the median of the distance between long-distant pulses
pulseDerGreaterMedian=pulseLocDerivative(pulseLocDerivative>(medianPulseDerivative+100));
medianPulseDerivativeLarge=median(pulseDerGreaterMedian);

%Adaptive Thresholds
%Logic thresholds
logicThresSmall=medianPulseDerivative*4;
logicThresLarge=medianPulseDerivativeLarge+(medianPulseDerivativeLarge/30); %16000, 10000;

%Distance thresholds
pulseDisThresSmall=medianPulseDerivative-(medianPulseDerivative/4); %25, 16;
pulseDisThresLarge=medianPulseDerivativeLarge-(medianPulseDerivativeLarge/25); %14900, 9000;

%Convert derivative to logicals based on the "logic thresholds"
%"0" indicates the sample difference between the pulses are small, hence
%belongs to the same 10 minute
%"1" indicates the sample difference between the pulses are large, hence
%they represent pulses between 2 adjacent 10 minute segment
%"2" indicates the sample difference between the pulses are larger than
%usual, hence representing pulses netween 10 minute segments with missing pulses in-between 
pulseLocLogical = pulseLocDerivative;
pulseLocLogical(pulseLocLogical<=logicThresSmall)=0;
pulseLocLogical(pulseLocLogical>logicThresSmall & pulseLocLogical<=logicThresLarge)=1;
pulseLocLogical(pulseLocLogical>logicThresLarge)=2;

%matrix with rows indicating hours and columns representing beginning of 10 minute except
%for last column which gives the end of last 10 minute
matrixHrMinSyncPulseLoc(9,7)=0;

%Counters
startPulseNumber=1;
endPulseNumber=1;
tenMinCounter=1;    %Counts 10 minute for every hour
hourCounter=1;      %Keeps count of the current hour of the file


%Array storing pulse count [1:6] every hour as binary
%The last number '3' represents the end of current hour and the beginning
%of next hour
logicArray=[];
logicArray{1}=[1];
logicArray{2}=[0 1];
logicArray{3}=[0 0 1];
logicArray{4}=[0 0 0 1];
logicArray{5}=[0 0 0 0 1];
logicArray{6}=[0 0 0 0 0 1];
logicArray{7}=[0 0 1];

%Keeping count of the pulse number such that the cumulative sum will indicate the start of a 10 minute segment 
%Without any missing pulses, the cumulative sum for 1st hour should be
%1,2,4,7,11,16,23
pulseCounts1stHour   = [1 1 2 3 4 5 7];
pulseCountsOtherHour = [0 1 2 3 4 5 7];

%In case of missing pulses, keep a count of 10 minute segments missed
addToTenMinCounter=0;

%Check for missing pulses and adjust pulseCounts accordingly
if pulseLocLogical(1)~=1
    %1st 10-minute pulse missing
    if pulseLocLogical(1)==0 && pulseLocLogical(2)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2))*(-1);
        pulseCounts1stHour(2)=[];
        addToTenMinCounter=1;
    %2nd 10-minute pulse missing    
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:3))*(-1);
        pulseCounts1stHour(2:3)=[];
        addToTenMinCounter=2;
    %3rd 10-minute pulse missing    
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==0 && pulseLocLogical(4)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:4))*(-1);
        pulseCounts1stHour(2:4)=[];
        addToTenMinCounter=3;
    %4th 10-minute pulse missing    
    elseif pulseLocLogical(1)==0 && pulseLocLogical(2)==0 && pulseLocLogical(3)==0 && pulseLocLogical(4)==0 && pulseLocLogical(5)==1
        pulseCountsOtherHour(1)=sum(pulseCounts1stHour(2:5))*(-1);
        pulseCounts1stHour(2:5)=[];
        addToTenMinCounter=4;
    end
end

%Making sure in hour>1 we are not entering 1st 10 minute data more than once  
firstTenMinDataEnter=0;

%Keeping count of pulses
pulseCounter=0;

while startPulseNumber<=length(pulseLocLogical)
    
    %Get pulse numbers
    if hourCounter==1                           %First hour
        pulseNumber=cumsum(pulseCounts1stHour); %Pulse numbers that correspond to start/end of a 10-minute segment
    else                                        %For other hours adjust the 1st pulse numebr based on the hour and the number of missing pulses before cumsum
        pulseCountsOtherHourAdd=pulseCountsOtherHour;
        pulseCountsOtherHourAdd(1)=pulseCountsOtherHourAdd(1)+((23*(hourCounter-1))+1);
        pulseNumber=cumsum(pulseCountsOtherHourAdd);
    end
    
    %Check and store start sample points of each sync pulses
    if startPulseNumber==1 && pulseLocLogical(startPulseNumber)==1                        %Check for 1st pulse and store location
        pulseCounter=pulseCounter+1;
        matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
        startPulseNumber=2;
    elseif hourCounter>1 && tenMinCounter==1 && firstTenMinDataEnter==0 %For hour>1 and 1st 10 minute 
        pulseCounter=pulseCounter+1;
        matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
        firstTenMinDataEnter=1;
    else                                        
        if hourCounter==1 && startPulseNumber==1                                 %if first pulse(s) is/are missing in 1st hour
            tenMinCounter=tenMinCounter+addToTenMinCounter;
        else
            tenMinCounter=tenMinCounter+1;
        end
        
        %Location of last pulse at the start/end of 10-minute segment =>
        %location of '1' in the logicArray
        endPulseNumber=find(pulseLocLogical(startPulseNumber:end)==1, 1)+startPulseNumber-1;
        
        %Check if the determined pulse location logical matches the default logicArray 
        if length(logicArray{tenMinCounter})==length(pulseLocLogical(startPulseNumber:endPulseNumber)) && mean(logicArray{tenMinCounter}==pulseLocLogical(startPulseNumber:endPulseNumber))==1
            pulseCounter=pulseCounter+1;
            matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
        else  
            %there is missing pulse
            %break the bigger segment with missing pulse in-between into 2 smaller segments: before and after '2'
            if any(2==pulseLocLogical(startPulseNumber:endPulseNumber)) 
                
                %sub-segment 1
                startPt_1=startPulseNumber;
                endPt_1=find(pulseLocLogical(startPulseNumber:endPulseNumber)==2, 1)+startPulseNumber-1;
                pulseLocLogical_1=pulseLocLogical(startPt_1:endPt_1);
                pulseLocLogical_1(end)=1;
                
                %sub-segment 2
                startPt_2=endPt_1+1;
                endPt_2=endPulseNumber;
                pulseLocLogical_2=pulseLocLogical(startPt_2:endPt_2);
                
                %Check if the determined pulse location logical (sub-segment 1) matches the default logicArray
                if length(logicArray{tenMinCounter})==length(pulseLocLogical_1) && mean(logicArray{tenMinCounter}==pulseLocLogical_1)==1
                    pulseCounter=pulseCounter+1;
                    matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
                end
                
                %check if it reached the end of one hour file 
                %reset and add pulse location for 1st 10 minute of next hour
                if tenMinCounter==7
                    [tenMinCounter,hourCounter,pulseCounter,pulseNumber]=updateCounters(tenMinCounter,hourCounter,pulseCounter,pulseCountsOtherHour);

                    pulseCounter=pulseCounter+1;
                    matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
                end
                
                
                %%%%%% Add missing pulses %%%%
                
                [tenMinCounter,pulseCounter,pulseLoc,pulseLocDerivative,pulseLocLogical,endPulseNumber]=...
                    addMissingPulses(pulseLoc,pulseLocDerivative,pulseLocLogical,startPulseNumber,endPulseNumber,...
                    tenMinCounter,pulseCounter,medianPulseDerivativeLarge,pulseDisThresSmall,pulseDisThresLarge,logicArray);
                
                
                if tenMinCounter>7                  
                    [tenMinCounter,hourCounter,pulseCounter,pulseNumber]=updateCounters(tenMinCounter,hourCounter,pulseCounter,pulseCountsOtherHour);
                end
                
                if length(logicArray{tenMinCounter})==length(pulseLocLogical_2) && mean(logicArray{tenMinCounter}==pulseLocLogical_2)==1
                    pulseCounter=pulseCounter+1;
                    matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=pulseLoc(pulseNumber(pulseCounter));
                end 
            end
        end
        startPulseNumber=endPulseNumber+1;
    end
    
    if tenMinCounter==7  
        [tenMinCounter,hourCounter,pulseCounter,~]=updateCounters(tenMinCounter,hourCounter,pulseCounter,pulseCountsOtherHour);        
        firstTenMinDataEnter=0;
    end
end

% -1 in matrix indicating end of file/pulses
if tenMinCounter==7
    tenMinCounter=1;
    hourCounter=hourCounter+1;
    matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=-1;
else
    tenMinCounter=tenMinCounter+1;
    matrixHrMinSyncPulseLoc(hourCounter,tenMinCounter)=-1;
end