function generateSyncFiles(sndFolder, psgFolder, psgEventFolder, outFolder, syncChannel, generateFig)

% This function will generate the sync files for the patch and PSG data.
% The data will be written to a .xls file located in the outFolder. It will
% have the following format

%     New Sampling Rate    Sound Start     Sound End    RIP Start  RIP End
%             .                 .              .            .         .
%             .                 .              .            .         .
%             .                 .              .            .         .
%             .                 .              .            .         .
%             .                 .              .            .         .
%             .                 .              .            .         .


% Where the new sampling rate is the real samopling rate of the sound data,
% sound start and sound end are the start and end sample of each 10 minute
% interval of the hour long sound file generated by the patch using the new
% sampling rate. The RIP start and end are the samples of the RIP channel
% from the PSG data which correspond to the start and end point of the same
% 10 minute intervals as the sound data.

% The start and end poitns can be determined for all other data using this
% data as well as the sampling rate of the other PSG data

% Input         :   sndFolder   : Folder containing the SND and ACC data
%                   psgFolder   : Folder containing the PSG data
%                   outFolder   : Folder to output sync data
%                   syncChannel (Optional): The PSG channel you wish to
%                   synchronize with (default is Pressure)


% Developed by Bojan Gavrilovic, UHN. 2017
% Edited by Muammar Kabir, UHN. 2017

warning('off');

if nargin < 5
    syncChannel = 'RespitraceAbdom';
    generateFig=1;
elseif nargin < 6
    generateFig=1;   
end

soundFolder = {sndFolder};
psgFolder = {psgFolder};
outFolder = {outFolder};

tenMinuteStartSnd = [1 2 4 7 11 16];
tenMinuteStopSnd = [2 4 7 11 16 23];

pulseLoc=[];
matrixHrMinSyncPulseStart=[];
psgDataFs=[];

% Convert the Sound Files
Fs = 15300;
for folderNum = 1:length(soundFolder)
   sndList = dir(fullfile(soundFolder{folderNum}, 'SND*.DAT'));
   accList = dir(fullfile(soundFolder{folderNum}, 'ACC*.DAT'));
   psgList = dir(fullfile(psgFolder{folderNum}, '*.REC'));
   endOfSync = 0;
   for numFiles=1:length(sndList)
       syncData = [];
       trueFS = [];
       psgFs = [];
       sndPulseStartIndex = [];
       sndPulseStopIndex = []; 
       psgPulseStartIndex = [];
       psgPulseStopIndex = [];
       psgStartTimeHour1=[];
       pulseStartTimeHour1=[];
       
%       ------ The following Code is repeated per 1 hour recording -------

%       Load each hour sound and ACC file from the selected folder
       hour = numFiles;
             
%       Set the pulse number based on which hour you are examining. 
%       subtract one becuase usually the first pulse is missing from the PSG data 
       pulseNumber = 23*(hour-1)-1;
       sndFileName = fullfile(soundFolder{folderNum}, sndList(numFiles).name);
       accFileName = fullfile(soundFolder{folderNum}, accList(numFiles).name);
       disp(['Loading sound file... ', sndFileName]);
       pause(0.01);
       [rawSnd, Fs] = soundRead(sndFileName, Fs);
       [acc, syncACC] = acc_sync_import(accFileName,length(rawSnd),Fs);
       if ~isempty(syncACC.syncStart)           
           syncACCtemp=syncACC;
       elseif isempty(syncACC.syncStart) 
           syncACC=[];
           syncACC=syncACCtemp;
       end
       disp('Sound file loaded');
       
%      Load the PSG data and analysie the pulse signal
       if numFiles == 1
           psgFileName = fullfile(psgFolder{folderNum}, psgList(numFiles).name);
           pause(0.01);
           disp(['Loading PSG Data... ',psgFileName]);
%        Read PSG Data
           [psgHeader, psgData] = edfread(psgFileName);
           if ~max(ismember(psgHeader.label,syncChannel))
              if strcmp(syncChannel,'RespitraceSum') && max(ismember(psgHeader.label,'SUM')), syncChannel = 'SUM'; 
              elseif strcmp(syncChannel,'Pressure') && max(ismember(psgHeader.label,'NASALPRESSURE')), syncChannel = 'NASALPRESSURE';
              elseif strcmp(syncChannel,'SpO2') && max(ismember(psgHeader.label,'SaO2')), syncChannel = 'SaO2';
              end   
           end
           if max(ismember(psgHeader.label,'CPAPFlow'))
              syncInd = find(ismember(psgHeader.label,'CPAPFlow')); 
           elseif max(ismember(psgHeader.label,'CFlow'))
              syncInd = find(ismember(psgHeader.label,'CFlow')); 
           end
           if max(ismember(psgHeader.label,'LegR'))
              legInd = find(ismember(psgHeader.label,'LegR'));
           elseif max(ismember(psgHeader.label,'RLEG2'))
              legInd = find(ismember(psgHeader.label,'RLEG2'));  
           end
           channelInd = find(ismember(psgHeader.label,syncChannel));
           
%        Get indices and frequencies of other channels
         ekgFs=0; respFs=0; presFs=0; SpO2Fs=0; C3Fs=0;
         %EKG
           if max(ismember(psgHeader.label,'EKG'))
               ekgInd = find(ismember(psgHeader.label,'EKG'));
           elseif max(ismember(psgHeader.label,'EKG1'))
               ekgInd = find(ismember(psgHeader.label,'EKG1'));
           end
           ekgFs = psgHeader.frequency(ekgInd);
         %Respitrace Sum
           if max(ismember(psgHeader.label,'RespitraceSum'))
               respInd = find(ismember(psgHeader.label,'RespitraceSum'));
           elseif max(ismember(psgHeader.label,'SUM'))
               respInd = find(ismember(psgHeader.label,'SUM'));
           end
           respFs = psgHeader.frequency(respInd);
         %Pressure
           if max(ismember(psgHeader.label,'Pressure'))
               presInd = find(ismember(psgHeader.label,'Pressure'));
           elseif max(ismember(psgHeader.label,'NASALPRESSURE'))
               presInd = find(ismember(psgHeader.label,'NASALPRESSURE'));
           end
           presFs = psgHeader.frequency(presInd);
         %SaO2
           if max(ismember(psgHeader.label,'SpO2'))
               SpO2Ind = find(ismember(psgHeader.label,'SpO2'));
           elseif max(ismember(psgHeader.label,'SaO2'))
               SpO2Ind = find(ismember(psgHeader.label,'SaO2'));
           end
           SpO2Fs = psgHeader.frequency(SpO2Ind);
         %C3
           if max(ismember(psgHeader.label,'C3'))
               C3Ind = find(ismember(psgHeader.label,'C3'));
           end
           C3Fs = psgHeader.frequency(C3Ind);
%        Examine EMG Data to determine total PSG time becuase it has the
%        highest sampling rate
           emgLeg = psgData(legInd,:);
           emgFs = psgHeader.frequency(legInd);
           psgTime = length(emgLeg)/emgFs; % Seconds
           channel = psgData(channelInd,:);
           channelFs = psgHeader.frequency(channelInd);
%        Cut the recorded sync signal to the total length of the PSG
           sync = psgData(syncInd,:);
           syncFs = psgHeader.frequency(syncInd);
           syncLength = psgTime*syncFs;
           sync = sync(1:syncLength);
%        This is a custom function which will count the number of pulses    
           [pulseLoc, pulseCount] = countPSGsyncPulse(sync);
           
          % Get the matrix containing the start sample points of all pulses per hour per 10 minute 
           matrixHrMinSyncPulseStart = findBeginSyncPulse(pulseLoc);
           
           pulseLoc = (pulseLoc/syncFs)*channelFs;
           matrixHrMinSyncPulseStart = (matrixHrMinSyncPulseStart./syncFs)*channelFs;
           
           psgDataFs=[respFs, presFs, SpO2Fs, ekgFs, C3Fs, emgFs];
       end
       
       [tenMinuteStartPSG,tenMinuteStopPSG,missingFirstPulse]=findTenMinStartStop(pulseLoc,hour);
       

       pulseLocAcc = round(syncACC.syncStart*(Fs/256));
       pulseLocSnd = round(syncACC.syncStart*(Fs));
       xDirAcc = acc.x;
       
       pulseLocAcc(pulseLocAcc==0)=1;
       pulseLocSnd(pulseLocSnd==0)=1;
       
       MatPSGdata=[];
       totMatCol=18;
       
%   Calculate the true sampling rate per 10 min interval
        for index = 1:1:length(tenMinuteStartSnd)
            if hour==1
                if  matrixHrMinSyncPulseStart(hour,index)~=0 && matrixHrMinSyncPulseStart(hour,index+1)~=0
                    if index==1 && missingFirstPulse==0
                        channelData = channel(matrixHrMinSyncPulseStart(hour,index):matrixHrMinSyncPulseStart(hour,index+1));
                        accData = xDirAcc(pulseLocAcc(tenMinuteStartSnd(index)):pulseLocAcc(tenMinuteStopSnd(index)));
                        ratioAcc = length(accData)/(Fs/256);
                        ratioRip = length(channelData)/channelFs;
                        trueFS(index,1) = (length(accData)/(length(channelData)/channelFs))*256;
                        psgFs(index,1) = channelFs;

                        sndPulseStartIndex(index,1) = pulseLocSnd(tenMinuteStartSnd(index));
                        sndPulseStopIndex(index,1) = pulseLocSnd(tenMinuteStopSnd(index));
                        psgPulseStartIndex(index,1)=matrixHrMinSyncPulseStart(hour,index);
                        psgPulseStopIndex(index,1)=matrixHrMinSyncPulseStart(hour,index+1);
                        
                        for iPSGmat=1:3:totMatCol
                            tempPSGfsInd=[];tempFs=[];
                            tempPSGfsInd=(iPSGmat+2)/3;
                            tempFs=psgDataFs(tempPSGfsInd);
                            MatPSGdata(index,iPSGmat)=tempFs;
                            MatPSGdata(index,iPSGmat+1)=(psgPulseStartIndex(index,1)/psgFs(index,1))*tempFs;
                            MatPSGdata(index,iPSGmat+2)=(psgPulseStopIndex(index,1)/psgFs(index,1))*tempFs;
                        end
                        
                        psgStartTime=[]; pulseStartTime=[];
                        [psgStartTime,pulseStartTime]=getPSGstartTimePulse(psgEventFolder,psgPulseStartIndex(index,1),psgFs(index,1));
                        
                        psgStartTimeHour1{index,1}=psgStartTime;
                        pulseStartTimeHour1{index,1}=pulseStartTime;

                        if generateFig
                            t1 = 0:1/(Fs/256):(length(accData)-1)/(Fs/256);
                            t2 = 0:1/channelFs:(length(channelData)-1)/channelFs;
                            figure
                            p1 = subplot(2,1,1);
                            plot(t1,accData);
                            title(sprintf('%s%s%s%s','Time Span (min): ',num2str((matrixHrMinSyncPulseStart(hour,index)/channelFs)/60,'%.0f'),' - ',num2str((matrixHrMinSyncPulseStart(hour,index+1)/channelFs)/60,'%.0f')));
                            p2 = subplot(2,1,2);
                            plot(t2,channelData);
                            linkaxes([p1,p2],'x');
                        end
                    elseif index==1 && missingFirstPulse==1
                        disp('');
                    else
                        channelData = channel(matrixHrMinSyncPulseStart(hour,index):matrixHrMinSyncPulseStart(hour,index+1));
                        accData = xDirAcc(pulseLocAcc(tenMinuteStartSnd(index)):pulseLocAcc(tenMinuteStopSnd(index)));
                        ratioAcc = length(accData)/(Fs/256);
                        ratioRip = length(channelData)/channelFs;
                        trueFS(index,1) = (length(accData)/(length(channelData)/channelFs))*256;
                        psgFs(index,1) = channelFs;

                        sndPulseStartIndex(index,1) = pulseLocSnd(tenMinuteStartSnd(index));
                        sndPulseStopIndex(index,1) = pulseLocSnd(tenMinuteStopSnd(index));
                        psgPulseStartIndex(index,1)=matrixHrMinSyncPulseStart(hour,index);
                        psgPulseStopIndex(index,1)=matrixHrMinSyncPulseStart(hour,index+1);
                        
                        for iPSGmat=1:3:totMatCol
                            tempPSGfsInd=[];tempFs=[];
                            tempPSGfsInd=(iPSGmat+2)/3;
                            tempFs=psgDataFs(tempPSGfsInd);
                            MatPSGdata(index,iPSGmat)=tempFs;
                            MatPSGdata(index,iPSGmat+1)=(psgPulseStartIndex(index,1)/psgFs(index,1))*tempFs;
                            MatPSGdata(index,iPSGmat+2)=(psgPulseStopIndex(index,1)/psgFs(index,1))*tempFs;
                        end
                        
                        psgStartTime=[]; pulseStartTime=[];
                        [psgStartTime,pulseStartTime]=getPSGstartTimePulse(psgEventFolder,psgPulseStartIndex(index,1),psgFs(index,1));
                        
                        psgStartTimeHour1{index,1}=psgStartTime;
                        pulseStartTimeHour1{index,1}=pulseStartTime;

                        if generateFig
                            t1 = 0:1/(Fs/256):(length(accData)-1)/(Fs/256);
                            t2 = 0:1/channelFs:(length(channelData)-1)/channelFs;
                            figure
                            p1 = subplot(2,1,1);
                            plot(t1,accData);
                            title(sprintf('%s%s%s%s','Time Span (min): ',num2str((matrixHrMinSyncPulseStart(hour,index)/channelFs)/60,'%.0f'),' - ',num2str((matrixHrMinSyncPulseStart(hour,index+1)/channelFs)/60,'%.0f')));
                            p2 = subplot(2,1,2);
                            plot(t2,channelData);
                            linkaxes([p1,p2],'x');
                        end
                    end
                elseif matrixHrMinSyncPulseStart(hour,index)~=0 && matrixHrMinSyncPulseStart(hour,index+1)==0
                    if index+2<=7 && matrixHrMinSyncPulseStart(hour,index+2)>0
                        channelData = channel(matrixHrMinSyncPulseStart(hour,index):matrixHrMinSyncPulseStart(hour,index+2));
                        accData = xDirAcc(pulseLocAcc(tenMinuteStartSnd(index)):pulseLocAcc(tenMinuteStopSnd(index+1)));
                        ratioAcc = length(accData)/(Fs/256);
                        ratioRip = length(channelData)/channelFs;
                        trueFS(index,1) = (length(accData)/(length(channelData)/channelFs))*256;
                        psgFs(index,1) = channelFs;

                        sndPulseStartIndex(index,1) = pulseLocSnd(tenMinuteStartSnd(index));
                        sndPulseStopIndex(index,1) = pulseLocSnd(tenMinuteStopSnd(index+1));
                        psgPulseStartIndex(index,1)=matrixHrMinSyncPulseStart(hour,index);
                        psgPulseStopIndex(index,1)=matrixHrMinSyncPulseStart(hour,index+2);
                        
                        for iPSGmat=1:3:totMatCol
                            tempPSGfsInd=[];tempFs=[];
                            tempPSGfsInd=(iPSGmat+2)/3;
                            tempFs=psgDataFs(tempPSGfsInd);
                            MatPSGdata(index,iPSGmat)=tempFs;
                            MatPSGdata(index,iPSGmat+1)=(psgPulseStartIndex(index,1)/psgFs(index,1))*tempFs;
                            MatPSGdata(index,iPSGmat+2)=(psgPulseStopIndex(index,1)/psgFs(index,1))*tempFs;
                        end
                        
                        psgStartTime=[]; pulseStartTime=[];
                        [psgStartTime,pulseStartTime]=getPSGstartTimePulse(psgEventFolder,psgPulseStartIndex(index,1),psgFs(index,1));
                        
                        psgStartTimeHour1{index,1}=psgStartTime;
                        pulseStartTimeHour1{index,1}=pulseStartTime;

                        if generateFig
                            t1 = 0:1/(Fs/256):(length(accData)-1)/(Fs/256);
                            t2 = 0:1/channelFs:(length(channelData)-1)/channelFs;
                            figure
                            p1 = subplot(2,1,1);
                            plot(t1,accData);
                            title(sprintf('%s%s%s%s','Time Span (min): ',num2str((matrixHrMinSyncPulseStart(hour,index)/channelFs)/60,'%.0f'),' - ',num2str((matrixHrMinSyncPulseStart(hour,index+2)/channelFs)/60,'%.0f')));
                            p2 = subplot(2,1,2);
                            plot(t2,channelData);
                            linkaxes([p1,p2],'x');
                        end
                    end
                end
                
            else
                if  tenMinuteStopPSG(index) < pulseCount && (matrixHrMinSyncPulseStart(hour,index)~=0 && matrixHrMinSyncPulseStart(hour,index+1)~=0)                   
                    channelData = channel(matrixHrMinSyncPulseStart(hour,index):matrixHrMinSyncPulseStart(hour,index+1));
                    accData = xDirAcc(pulseLocAcc(tenMinuteStartSnd(index)):pulseLocAcc(tenMinuteStopSnd(index)));
                    ratioAcc = length(accData)/(Fs/256);
                    ratioRip = length(channelData)/channelFs;
                    trueFS(index,1) = (length(accData)/(length(channelData)/channelFs))*256;
                    psgFs(index,1) = channelFs;

                    sndPulseStartIndex(index,1) = pulseLocSnd(tenMinuteStartSnd(index));
                    sndPulseStopIndex(index,1) = pulseLocSnd(tenMinuteStopSnd(index));
                    psgPulseStartIndex(index,1)=matrixHrMinSyncPulseStart(hour,index);
                    psgPulseStopIndex(index,1)=matrixHrMinSyncPulseStart(hour,index+1);
                    
                    for iPSGmat=1:3:totMatCol
                        tempPSGfsInd=[];tempFs=[];
                        tempPSGfsInd=(iPSGmat+2)/3;
                        tempFs=psgDataFs(tempPSGfsInd);
                        MatPSGdata(index,iPSGmat)=tempFs;
                        MatPSGdata(index,iPSGmat+1)=(psgPulseStartIndex(index,1)/psgFs(index,1))*tempFs;
                        MatPSGdata(index,iPSGmat+2)=(psgPulseStopIndex(index,1)/psgFs(index,1))*tempFs;
                    end

                    if generateFig
                        t1 = 0:1/(Fs/256):(length(accData)-1)/(Fs/256);
                        t2 = 0:1/channelFs:(length(channelData)-1)/channelFs;
                        figure
                        p1 = subplot(2,1,1);
                        plot(t1,accData);
                        title(sprintf('%s%s%s%s','Time Span (min): ',num2str((matrixHrMinSyncPulseStart(hour,index)/channelFs)/60,'%.0f'),' - ',num2str((matrixHrMinSyncPulseStart(hour,index+1)/channelFs)/60,'%.0f')));
                        p2 = subplot(2,1,2);
                        plot(t2,channelData);
                        linkaxes([p1,p2],'x');       
                    end
                elseif tenMinuteStopPSG(index) < pulseCount && (matrixHrMinSyncPulseStart(hour,index)~=0 && matrixHrMinSyncPulseStart(hour,index+1)==0)
                    if index+2<=7 && matrixHrMinSyncPulseStart(hour,index+2)>0
                        channelData = channel(matrixHrMinSyncPulseStart(hour,index):matrixHrMinSyncPulseStart(hour,index+2));
                        accData = xDirAcc(pulseLocAcc(tenMinuteStartSnd(index)):pulseLocAcc(tenMinuteStopSnd(index+1)));
                        ratioAcc = length(accData)/(Fs/256);
                        ratioRip = length(channelData)/channelFs;
                        trueFS(index,1) = (length(accData)/(length(channelData)/channelFs))*256;
                        psgFs(index,1) = channelFs;

                        sndPulseStartIndex(index,1) = pulseLocSnd(tenMinuteStartSnd(index));
                        sndPulseStopIndex(index,1) = pulseLocSnd(tenMinuteStopSnd(index+1));
                        psgPulseStartIndex(index,1)=matrixHrMinSyncPulseStart(hour,index);
                        psgPulseStopIndex(index,1)=matrixHrMinSyncPulseStart(hour,index+2);
                        
                        for iPSGmat=1:3:totMatCol
                            tempPSGfsInd=[];tempFs=[];
                            tempPSGfsInd=(iPSGmat+2)/3;
                            tempFs=psgDataFs(tempPSGfsInd);
                            MatPSGdata(index,iPSGmat)=tempFs;
                            MatPSGdata(index,iPSGmat+1)=(psgPulseStartIndex(index,1)/psgFs(index,1))*tempFs;
                            MatPSGdata(index,iPSGmat+2)=(psgPulseStopIndex(index,1)/psgFs(index,1))*tempFs;
                        end

                        if generateFig
                            t1 = 0:1/(Fs/256):(length(accData)-1)/(Fs/256);
                            t2 = 0:1/channelFs:(length(channelData)-1)/channelFs;
                            figure
                            p1 = subplot(2,1,1);
                            plot(t1,accData);
                            title(sprintf('%s%s%s%s','Time Span (min): ',num2str((matrixHrMinSyncPulseStart(hour,index)/channelFs)/60,'%.0f'),' - ',num2str((matrixHrMinSyncPulseStart(hour,index+2)/channelFs)/60,'%.0f')));
                            p2 = subplot(2,1,2);
                            plot(t2,channelData);
                            linkaxes([p1,p2],'x');
                        end
                    end
                elseif (tenMinuteStopPSG(index) > pulseCount)
                    endOfSync = 1;
                    break;
                end
            end
        end
        
%         close all;
        
%         Write data to .xls file
        if(hour == 1)
            %syncData = horzcat(trueFS,sndPulseStartIndex,sndPulseStopIndex,psgFs,psgPulseStartIndex,psgPulseStopIndex);
            syncData = horzcat(trueFS,sndPulseStartIndex,sndPulseStopIndex,MatPSGdata);
            syncData = num2cell(syncData);
            syncDataExtend = [syncData,psgStartTimeHour1,pulseStartTimeHour1];
            %header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','Channel Sampling Rate',sprintf('%s%s',syncChannel,' Start Sample'),sprintf('%s%s',syncChannel,' Stop Sample'),'PSG Start Time','PSG Pulse Start Time'};
            header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','RespitraceSum Sampling Rate','RespitraceSum Start Sample','RespitraceSum Stop Sample','Pressure Sampling Rate','Pressure Start Sample','Pressure Stop Sample','SpO2 Sampling Rate','SpO2 Start Sample','SpO2 Stop Sample','EKG Sampling Rate','EKG Start Sample','EKG Stop Sample','C3 Sampling Rate','C3 Start Sample','C3 Stop Sample','LegR Sampling Rate','LegR Start Sample','LegR Stop Sample','PSG Start Time','PSG Pulse Start Time'};
            syncData = [header;syncDataExtend];
            syncFile = sprintf('%s%s%d%s',outFolder{1},'/syncDataHour',hour,'.xls');
            xlswrite(syncFile,syncData);
        elseif(endOfSync)
            for index = 1:length(trueFS)
                pause(0.01)
                %syncData(index,:) = horzcat(trueFS(index),sndPulseStartIndex(index),sndPulseStopIndex(index),psgFs(index),psgPulseStartIndex(index),psgPulseStopIndex(index));
                syncData(index,:) = horzcat(trueFS(index),sndPulseStartIndex(index),sndPulseStopIndex(index),MatPSGdata(index,:));
            end
            syncData = num2cell(syncData);
            %header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','Channel Sampling Rate',sprintf('%s%s',syncChannel,' Start Sample'),sprintf('%s%s',syncChannel,' Stop Sample')};
            header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','RespitraceSum Sampling Rate','RespitraceSum Start Sample','RespitraceSum Stop Sample','Pressure Sampling Rate','Pressure Start Sample','Pressure Stop Sample','SpO2 Sampling Rate','SpO2 Start Sample','SpO2 Stop Sample','EKG Sampling Rate','EKG Start Sample','EKG Stop Sample','C3 Sampling Rate','C3 Start Sample','C3 Stop Sample','LegR Sampling Rate','LegR Start Sample','LegR Stop Sample'};
            syncData = [header;syncData];
            syncFile = sprintf('%s%s%d%s',outFolder{1},'/syncDataHour',hour,'.xls');
            xlswrite(syncFile,syncData);
            break
        else
            %syncData = horzcat(trueFS,sndPulseStartIndex,sndPulseStopIndex,psgFs,psgPulseStartIndex,psgPulseStopIndex);
            syncData = horzcat(trueFS,sndPulseStartIndex,sndPulseStopIndex,MatPSGdata);
            syncData = num2cell(syncData);
            %header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','Channel Sampling Rate',sprintf('%s%s',syncChannel,' Start Sample'),sprintf('%s%s',syncChannel,' Stop Sample')};
            header = {'True Sampling Rate','Sound Start Sample','Sound Stop Sample','RespitraceSum Sampling Rate','RespitraceSum Start Sample','RespitraceSum Stop Sample','Pressure Sampling Rate','Pressure Start Sample','Pressure Stop Sample','SpO2 Sampling Rate','SpO2 Start Sample','SpO2 Stop Sample','EKG Sampling Rate','EKG Start Sample','EKG Stop Sample','C3 Sampling Rate','C3 Start Sample','C3 Stop Sample','LegR Sampling Rate','LegR Start Sample','LegR Stop Sample'};            
            syncData = [header;syncData];
            syncFile = sprintf('%s%s%d%s',outFolder{1},'/syncDataHour',hour,'.xls');
            xlswrite(syncFile,syncData);
        end

    end
end

end