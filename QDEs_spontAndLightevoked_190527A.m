%% quick depolarizing events - analysis
%in Thy1 experiments, compare light-evoked and spontaneous QDEs, at different baseline voltages
%!! all scripts and functions are written so as to work well only for data recorded at 20kHz
clear all;
close all;

%analysis steps:
%1. looking at the raw data
%2. concatenating traces for analysis (and creating a datastructure to hold them all)
%3. getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces in a table
%4: separating out light-evoked and spontaneous QDEs into two tables
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
for i = 4:length(fileList)%!first three files were longer, leaving them out
    load(fileList(i).name);
    vs = rawData_traces.voltage;
        meanVs = mean(vs);
    is = rawData_traces.current;
    ttl = rawData_traces.TTLpulse;
        %%filtering out traces where cell has bad baselineV
minVrest = -40;
        is = is(:,meanVs<minVrest);
        ttl = ttl(:,meanVs<minVrest);
        vs = vs(:,meanVs<minVrest);
    Vs = [Vs vs];
    Is = [Is is];
    TTLs = [TTLs ttl];    
end
time_axis = rawData_traces.time_axis;

collectedQDEsData.voltage = Vs;
collectedQDEsData.current = Is;
collectedQDEsData.TTL = TTLs;
collectedQDEsData.time_axis = time_axis;
%% step3: getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces
%the getQuickDepolarizingEvents_inTable takes the collectedQDEsData
%structure and returns a table containing all "clean" QDEs (see function for criteria).
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width (!half-width can be off when decay isn't smooth)
min_QDEamp = 2;
max_QDEpeakV = -10;

[collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV);

%% step4: separating out light-evoked and spontaneous QDEs
[spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table);












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

