%% quick depolarizing events - analysis
%in Thy1 experiments, compare light-evoked and spontaneous QDEs, at different baseline voltages
%!! all scripts and functions are written so as to work well only for data recorded at 20kHz
clear all;
close all;

cd D:\neert\hujiGoogleDrive\research_YaromLabWork\data_elphys_andDirectlyRelatedThings\olive\myData_SmithLab\20190527A

%analysis steps:
%1. looking at the raw data
%2. concatenating traces for analysis (and creating a datastructure to hold them all)
%3. getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces in a table, and
%3b:separating out light-evoked and spontaneous QDEs into two tables

%4: looking at evoked events at baseline and hyperpolarized V
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
minVrest = -45;
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

%% step2a: saving all 'good' data in one datastructure
save([cell_name,'_collectedTraces_lightApplied'],'collectedQDEsData');

%% step2b: loading prepared, saved data
clear all;close all;
load('190527A_collectedTraces_lightApplied');

%% step3: getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces
%the getQuickDepolarizingEvents_inTable takes the collectedQDEsData
%structure and returns a table containing all "clean" QDEs (see function for criteria).
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width (!half-width can be off when decay isn't smooth)
min_QDEamp = .5;
max_QDEpeakV = -10;

[collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV);

%% 3b: separating out light-evoked and spontaneous QDEs
[spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table);

%% plotting stuff
figure; hold on;
scatter(spontQDEs_table.baselineVs(spontQDEs_table.riseTimes<1.7),spontQDEs_table.amps(spontQDEs_table.riseTimes<1.7));
scatter(evokedQDEs_table.baselineVs(evokedQDEs_table.riseTimes<1.7),evokedQDEs_table.amps(evokedQDEs_table.riseTimes<1.7),'r','filled')
xlabel('baseline V'), ylabel('QDE amp')
title('blue: spontaneous events, red: light-evoked events')




%% 4: looking at evoked events at baseline and hyperpolarized V
%% 4a: getting only traces where light does NOT evoke a spike
[noSpikeEvoked_collectedQDEtraces] = get_noSpikeEvoked_traces(collectedQDEsData);
%% plotting traces individually, in relevant window
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV
extraIdcs_inPlotWindow = 200;

window_length = 400;

figure;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
%     Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(2,i)+extraIdcs_inPlotWindow,i);
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);

    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    if Vrange_inSnippet >= min_Vrange_inSnippet
    
%     t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(2,i)+extraIdcs_inPlotWindow);
%     shiftedTTL = TTLs(Windows_idcs(1,i):Windows_idcs(2,i)+extraIdcs_inPlotWindow,i) + mean(Vsnippet);
    t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
    
%         if Vrange_inSnippet < 3
%             subplot(1,2,1),hold on;
%             plot(t_axis,Vsnippet);
%             %plot(t_axis,shiftedTTL,'k')
%             ylim([-80 -35])
%             xlabel('time (ms)')
%             ylabel('voltage (mV)')
%             
%             subplot(1,2,2),hold on;
%             plot(t_axis(1:end-1),diff(smooth(Vsnippet,10)));
%             ylabel('derivative of V')
        
        if Vrange_inSnippet > 3
            subplot(1,2,2),hold on;
            plot(t_axis,Vsnippet);
            ylim([-80 -35])
            xlabel('time (ms)')
            ylabel('voltage (mV)')
            
            subplot(1,2,1),hold on;
            plot(t_axis(1:end-1),diff(smooth(Vsnippet,10)));
            ylabel('derivative of V')
        end
    end
end

%% plotting overlay of relevant example-traces
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV

window_length = 400;

figure; hold on;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);
    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    Vderivative = diff(smooth(Vsnippet));
    if (Vrange_inSnippet >= min_Vrange_inSnippet) && max(Vderivative) > .1 %this should filter out any traces where there isn't really a response to the light
        t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
        
        plot(t_axis,Vsnippet);
        xlabel('time (ms)')
        ylabel('voltage (mV)')
        
    end
end




