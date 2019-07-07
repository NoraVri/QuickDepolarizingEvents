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
cell_name = '190529B';
fileList = dir('*_light*.mat');
%% plotting all traces overlayed for each file
for i = 1:length(fileList)
    load(fileList(i).name)
    V = rawData_traces.voltage;
    I = rawData_traces.current;
    TTL = rawData_traces.TTLpulse;
    time_axis = rawData_traces.time_axis;
    
    figure;
    ax(1) = subplot(2,1,1);hold on;
    plot(time_axis,V,'b');
        ylabel('voltage (mV)')
        title(fileList(i).name);
    ax(2) = subplot(2,1,2);hold on;
    plot(time_axis,I,'r');
    plot(time_axis,TTL,'k');
        ylabel('red: current (pA)')
        xlabel('time (ms)')
    linkaxes(ax,'x')
end

%% step2: concatenating files for analysis
%!! this script assumes that all files have the same length & sampling rate 
Vs = [];
Is = [];
TTLs = [];
for i = 1:length(fileList)%
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
min_QDEamp = .5;
max_QDEpeakV = -10;

[collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV);

%% step4: separating out light-evoked and spontaneous QDEs
[spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table);



%% plotting things
figure; hold on;
scatter(spontQDEs_table.baselineVs(spontQDEs_table.riseTimes<1.7),spontQDEs_table.amps(spontQDEs_table.riseTimes<1.7));
scatter(evokedQDEs_table.baselineVs(evokedQDEs_table.riseTimes<1.7),evokedQDEs_table.amps(evokedQDEs_table.riseTimes<1.7),'r','filled')
xlabel('baseline V'), ylabel('QDE amp')
title('blue: spontaneous events, red: light-evoked events')

