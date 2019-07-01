%% quick depolarizing events - analysis
%in Thy1 experiments, compare light-evoked and spontaneous QDEs, at different baseline voltages
%!! all scripts and functions are written so as to work well only for data recorded at 20kHz
clear all;
close all;

%analysis steps:
%1. looking at the raw data
%2. concatenating traces for analysis (and creating a datastructure to hold them all)
%3. getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces
%3b: getting amp, rise-time and half-width for all "clean" QDEs
%4: separating out QDEs happening under different (baselineV and light) conditions
%5: plotting things 
%% step1: looking at the raw data
%trace length should be the same for all concatenated traces
cell_name = '190527A';
fileList = dir('*_light_wholeField*.mat');
%% plotting all traces overlayed for each file
% for i = 1:length(fileList)
%     load(fileList(i).name)
%     V = rawData_traces.voltage;
%     I = rawData_traces.current;
%     TTL = rawData_traces.TTLpulse;
%     time_axis = rawData_traces.time_axis;
%     
%     figure;
%     ax(1) = subplot(2,1,1);hold on;
%     plot(time_axis,V,'b');
%         ylabel('voltage (mV)')
%         title(fileList(i).name);
%     ax(2) = subplot(2,1,2);hold on;
%     plot(time_axis,I,'r');
%     plot(time_axis,TTL,'k');
%         ylabel('red: current (pA)')
%         xlabel('time (ms)')
%     linkaxes(ax,'x')
% end

%% step2: concatenating files for analysis
%!! this script assumes that all files have the same length & sampling rate 
Vs = [];
Is = [];
TTLs = [];
for i = 4:length(fileList)
    load(fileList(i).name);
    vs = rawData_traces.voltage;
        meanVs = mean(vs);
    is = rawData_traces.current;
    ttl = rawData_traces.TTLpulse;
        is = is(:,meanVs<-40);
        ttl = ttl(:,meanVs<-40);
        vs = vs(:,meanVs<-40);
    Vs = [Vs vs];
    Is = [Is is];
    TTLs = [TTLs ttl];    
end
time_axis = rawData_traces.time_axis;
Vs_smoothed = smoothdata(Vs,2,'movmedian',10);

collectedQDEsData.voltage = Vs;
collectedQDEsData.smoothedVoltage = Vs_smoothed;
collectedQDEsData.current = Is;
collectedQDEsData.TTL = TTLs;
collectedQDEsData.time_axis = time_axis;
%% step3: getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces
%QDEs are detected by the finding_fastDepolarizingPotentials function, 
%which detects fast depolarizing events based on Vderivative and filters them based on amplitude, baselineV stability and decay back towards baseline
no_of_traces = length(collectedQDEsData.voltage(1,:));
Vpeaks_idcs = cell(1,no_of_traces);
baselineVs = cell(1,no_of_traces);

min_QDEamp = 2;
for i = 1:no_of_traces
[Vpeaks_idcs{i},baselineVs{i}] = finding_fastDepolarizingPotentials(collectedQDEsData.voltage(:,i),min_QDEamp);
%%plotting each Vtrace and corresponding TTL pulse, marking peaks and baselines on detected QDEs
% figure;hold on;
%     plot(collectedQDEsData.time_axis,collectedQDEsData.voltage(:,i),'b');
%     plot(collectedQDEsData.time_axis,smoothdata(collectedQDEsData.voltage(:,i),'movmedian',10),'k');
%     plot(collectedQDEsData.time_axis,collectedQDEsData.TTL(:,i)+mean(collectedQDEsData.voltage(:,i)),'r');
%     scatter(collectedQDEsData.time_axis(Vpeaks_idcs{i}),collectedQDEsData.voltage(Vpeaks_idcs{i},i),'r','filled');
%     scatter(collectedQDEsData.time_axis(Vpeaks_idcs{i} - 100),baselineVs{i},'g','filled');
% %filtering out spikes idcs
%     peakVs_i = collectedQDEsData.voltage(Vpeaks_idcs{i},i);
%     Vpeaks_idcs{i}(peakVs_i > 0) = [];
%     baselineVs{i}(peakVs_i > 0) = [];
end
%adding results into collectedData
collectedQDEsData.Vpeaks_idcs = Vpeaks_idcs;
collectedQDEsData.baselineVs = baselineVs;

%% 3b: getting amp, rise-time and half-width for all "clean" QDEs
QDEamps = cell(1,no_of_traces);
QDEriseTimes = cell(1,no_of_traces);
QDEhalfWidths = cell(1,no_of_traces);
for i = 1:no_of_traces
    [QDEamps{i},QDEriseTimes{i},QDEhalfWidths{i}] = getQDEmeasures(collectedQDEsData.voltage(:,i),collectedQDEsData.Vpeaks_idcs{i},collectedQDEsData.baselineVs{i});
    %%plotting code runs from inside the getQDEmeasures function
end
collectedQDEsData.amps = QDEamps;
collectedQDEsData.riseTimes = QDEriseTimes;
collectedQDEsData.halfWidths = QDEhalfWidths;
%% step4: separating out QDEs happening under different (baselineV and light) conditions
%%4a: separating by spont or light-evoked
%for each trace, get the idx numbers where light turns on and off
TTLon_idcs = zeros(1,no_of_traces);
TTLoff_idcs = zeros(1,no_of_traces);
for i = 1:no_of_traces
    tracei_TTLon = find(collectedQDEsData.TTL(:,i)>9);
    TTLon_idcs(i) = tracei_TTLon(1);
    TTLoff_idcs(i) = tracei_TTLon(end);
end

spontQDEs_peaksIdcs = cell(no_of_traces,1);
spontQDEs_baselineVs = cell(no_of_traces,1);
evokedQDEs_peaksIdcs = cell(no_of_traces,1);
evokedQDEs_baselineVs = cell(no_of_traces,1);
    ChRtime_prePeak_inidcs = 20*2;%2 ms to account for time it takes to activate axons
    ChRtime_inidcs = 20*15;%15 ms or so times the number of samples per ms
for i = 1:no_of_traces
    tracei_Vpeaks_idcs = Vpeaks_idcs{i};
    tracei_baselineVs = baselineVs{i};
    
    spontQDEs_peaksIdcs{i} = tracei_Vpeaks_idcs(tracei_Vpeaks_idcs < (TTLon_idcs(i)+ChRtime_prePeak_inidcs) | tracei_Vpeaks_idcs > (TTLoff_idcs(i) + ChRtime_inidcs));
    spontQDEs_baselineVs{i} = tracei_baselineVs(tracei_Vpeaks_idcs < (TTLon_idcs(i)+ChRtime_prePeak_inidcs) | tracei_Vpeaks_idcs > (TTLoff_idcs(i) + ChRtime_inidcs));
    evokedQDEs_peaksIdcs{i} = tracei_Vpeaks_idcs(tracei_Vpeaks_idcs >= (TTLon_idcs(i)+ChRtime_prePeak_inidcs) & tracei_Vpeaks_idcs <= (TTLoff_idcs(i) + ChRtime_inidcs));
    evokedQDEs_baselineVs{i} = tracei_baselineVs(tracei_Vpeaks_idcs >= (TTLon_idcs(i)+ChRtime_prePeak_inidcs) & tracei_Vpeaks_idcs <= (TTLoff_idcs(i) + ChRtime_inidcs));
end
%adding results into collectedData
collectedQDEsData.spontQDEs_idcs = spontQDEs_peaksIdcs;
collectedQDEsData.spontQDEs_baselineVs = spontQDEs_baselineVs;
collectedQDEsData.evokedQDEs_idcs = evokedQDEs_peaksIdcs;
collectedQDEsData.evokedQDEs_baselineVs = evokedQDEs_baselineVs;

%%4b: separating by baseline V
lowBaselineQDEs_peaksIdcs = cell(no_of_traces,1);
lowBaselineQDEs_baselineVs = cell(no_of_traces,1);
highBaselineQDEs_peaksIdcs = cell(no_of_traces,1);
highBaselineQDEs_baselineVs = cell(no_of_traces,1);
    lowBaseline_maxV = -65;
    highBaseline_minV = -60;
for i = 1:no_of_traces
    tracei_Vpeaks_idcs = Vpeaks_idcs{i};
    tracei_baselineVs = baselineVs{i};
    
    lowBaselineQDEs_peaksIdcs{i} = tracei_Vpeaks_idcs(tracei_baselineVs < lowBaseline_maxV);
    lowBaselineQDEs_baselineVs{i} = tracei_baselineVs(tracei_baselineVs < lowBaseline_maxV);
    highBaselineQDEs_peaksIdcs{i} = tracei_Vpeaks_idcs(tracei_baselineVs > highBaseline_minV);
    highBaselineQDEs_baselineVs{i} = tracei_baselineVs(tracei_baselineVs > highBaseline_minV);
end
%adding results into collectedData
collectedQDEsData.lowBaselineQDEs_peaksIdcs = lowBaselineQDEs_peaksIdcs;
collectedQDEsData.lowBaselineQDEs_baselineVs = lowBaselineQDEs_baselineVs;
collectedQDEsData.highBaselineQDEs_peaksIdcs = highBaselineQDEs_peaksIdcs;
collectedQDEsData.highBaselineQDEs_baselineVs = highBaselineQDEs_baselineVs;
%% step5: plotting 
%low-baseline spont
lowBaseline_spontQDEs_peaksIdcs = intersecting_vectors_in_cells(lowBaselineQDEs_peaksIdcs,spontQDEs_peaksIdcs);
lowBaseline_spontQDEs_baselineVs = intersecting_vectors_in_cells(lowBaselineQDEs_baselineVs,spontQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,collectedQDEsData.time_axis,lowBaseline_spontQDEs_peaksIdcs,lowBaseline_spontQDEs_baselineVs);
%overlay low-baseline evoked
lowBaseline_evokedQDEs_peaksIdcs = intersecting_vectors_in_cells(lowBaselineQDEs_peaksIdcs,evokedQDEs_peaksIdcs);
lowBaseline_evokedQDEs_baselineVs = intersecting_vectors_in_cells(lowBaselineQDEs_baselineVs,evokedQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction4(collectedQDEsData.voltage,collectedQDEsData.time_axis,lowBaseline_evokedQDEs_peaksIdcs,lowBaseline_evokedQDEs_baselineVs);
title('low-baseline QDEs, black = light-evoked')

%high-baseline spont
highBaseline_spontQDEs_peaksIdcs = intersecting_vectors_in_cells(highBaselineQDEs_peaksIdcs,spontQDEs_peaksIdcs);
highBaseline_spontQDEs_baselineVs = intersecting_vectors_in_cells(highBaselineQDEs_baselineVs,spontQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,collectedQDEsData.time_axis,highBaseline_spontQDEs_peaksIdcs,highBaseline_spontQDEs_baselineVs);
%overlay high-baseline evoked
highBaseline_evokedQDEs_peaksIdcs = intersecting_vectors_in_cells(highBaselineQDEs_peaksIdcs,evokedQDEs_peaksIdcs);
highBaseline_evokedQDEs_baselineVs = intersecting_vectors_in_cells(highBaselineQDEs_baselineVs,evokedQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction4(collectedQDEsData.voltage,collectedQDEsData.time_axis,highBaseline_evokedQDEs_peaksIdcs,highBaseline_evokedQDEs_baselineVs);
title('high-baseline QDEs, black = light-evoked')

%% 5b: plotting normalized amplitude
%low-baseline spont
lowBaseline_spontQDEs_peaksIdcs = intersecting_vectors_in_cells(lowBaselineQDEs_peaksIdcs,spontQDEs_peaksIdcs);
lowBaseline_spontQDEs_baselineVs = intersecting_vectors_in_cells(lowBaselineQDEs_baselineVs,spontQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction5_normalizedAmps(collectedQDEsData.voltage,collectedQDEsData.time_axis,lowBaseline_spontQDEs_peaksIdcs,lowBaseline_spontQDEs_baselineVs);
%overlay low-baseline evoked
lowBaseline_evokedQDEs_peaksIdcs = intersecting_vectors_in_cells(lowBaselineQDEs_peaksIdcs,evokedQDEs_peaksIdcs);
lowBaseline_evokedQDEs_baselineVs = intersecting_vectors_in_cells(lowBaselineQDEs_baselineVs,evokedQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction6_normalizedAmps(collectedQDEsData.voltage,collectedQDEsData.time_axis,lowBaseline_evokedQDEs_peaksIdcs,lowBaseline_evokedQDEs_baselineVs);
title('low-baseline QDEs, amp normalized, black = light-evoked')

%high-baseline spont
highBaseline_spontQDEs_peaksIdcs = intersecting_vectors_in_cells(highBaselineQDEs_peaksIdcs,spontQDEs_peaksIdcs);
highBaseline_spontQDEs_baselineVs = intersecting_vectors_in_cells(highBaselineQDEs_baselineVs,spontQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction5_normalizedAmps(collectedQDEsData.voltage,collectedQDEsData.time_axis,highBaseline_spontQDEs_peaksIdcs,highBaseline_spontQDEs_baselineVs);
%overlay high-baseline evoked
highBaseline_evokedQDEs_peaksIdcs = intersecting_vectors_in_cells(highBaselineQDEs_peaksIdcs,evokedQDEs_peaksIdcs);
highBaseline_evokedQDEs_baselineVs = intersecting_vectors_in_cells(highBaselineQDEs_baselineVs,evokedQDEs_baselineVs);
quickDepolarizingEvents_plottingFunction6_normalizedAmps(collectedQDEsData.voltage,collectedQDEsData.time_axis,highBaseline_evokedQDEs_peaksIdcs,highBaseline_evokedQDEs_baselineVs);
title('high-baseline QDEs, amp normalized, black = light-evoked')

%%
quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,collectedQDEsData.time_axis,spont_VpeaksIdcs_lowBaseline,spont_baselineVsIdcs_lowBaseline);
ylim([-1 9])
title('spontaneously occurring quick depolarizing events; baseline <-65')
quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,spontData.time_axis,spont_VpeaksIdcs_highBaseline,spont_baselineVsIdcs_highBaseline);
ylim([-1 9])
title('spontaneously occurring quick depolarizing events; baseline >-60')

quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,collectedQDEsData.time_axis,evoked_VpeaksIdcs_lowBaseline,evoked_baselineVsIdcs_lowBaseline);
ylim([-1 9])
title('quick depolarizing events evoked by light; baseline <-65')
quickDepolarizingEvents_plottingFunction3(collectedQDEsData.voltage,collectedQDEsData.time_axis,evoked_VpeaksIdcs_highBaseline,evoked_baselineVsIdcs_highBaseline);
ylim([-1 9])
title('quick depolarizing events evoked by light; baseline >-60')
%%
quickDepolarizingEvents_plottingFunction3(spontData.voltage,spontData.time_axis,spont_VpeaksIdcs_highBaseline,spont_baselineVsIdcs_highBaseline);
ylim([-1 9])
title('spontaneously occurring quick depolarizing events; baseline >-60')
quickDepolarizingEvents_plottingFunction4(lightEvokedData.voltage,lightEvokedData.time_axis,evoked_VpeaksIdcs_highBaseline,evoked_baselineVsIdcs_highBaseline);
%%
quickDepolarizingEvents_plottingFunction3(spontData.voltage,spontData.time_axis,spont_VpeaksIdcs_lowBaseline,spont_baselineVsIdcs_lowBaseline);
ylim([-1 9])
title('spontaneously occurring quick depolarizing events; baseline >-60')
quickDepolarizingEvents_plottingFunction4(lightEvokedData.voltage,lightEvokedData.time_axis,evoked_VpeaksIdcs_lowBaseline,evoked_baselineVsIdcs_lowBaseline);


%% scrap paper
%scatters of amp, halfwidth, risetime and baselineV
