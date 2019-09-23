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
clear all;
cd D:\neert\hujiGoogleDrive\research_YaromLabWork\data_elphys_andDirectlyRelatedThings\olive\myData_SmithLab\20190527A
cell_name = '190527A';
load([cell_name '_collectedTraces_lightApplied']);

figure;
ax(1) = subplot(3,1,[1 2]);
plot(collectedQDEsData.time_axis,collectedQDEsData.voltage);
ylabel('voltage (mV)')
ax(2) = subplot(3,1,3);hold on;
plot(collectedQDEsData.time_axis,collectedQDEsData.current);
plot(collectedQDEsData.time_axis,collectedQDEsData.TTL,'k','linewidth',2);
xlabel('time (ms)')
linkaxes(ax,'x')


%% step3: getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces
%the getQuickDepolarizingEvents_inTable takes the collectedQDEsData
%structure and returns a table containing all "clean" QDEs (see function for criteria).
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width (!half-width can be off when decay isn't smooth)
min_QDEamp = .5;
max_QDEpeakV = -10;

[collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV);

% 3b: separating out light-evoked and spontaneous QDEs
[spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table);

%% plotting stuff
%scatters of QDE measures
figure; hold on;
scatter(spontQDEs_table.baselineVs(spontQDEs_table.riseTimes<1.7),spontQDEs_table.amps(spontQDEs_table.riseTimes<1.7));
scatter(evokedQDEs_table.baselineVs(evokedQDEs_table.riseTimes<1.7),evokedQDEs_table.amps(evokedQDEs_table.riseTimes<1.7),'r','filled')
xlabel('baseline V'), ylabel('QDE amp')
title([cell_name 'blue: spontaneous events, red: light-evoked events'])
%%
%plotting QDEs, raw, light-evoked and spontaneous in separate subplots
QDEtrace_length_in_samples = length(collectedQDEsData_table.QDEs_Vtraces(1,:));
QDE_time_axis = collectedQDEsData.time_axis(1:QDEtrace_length_in_samples);
figure;
subplot(1,2,1),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_table.riseTimes <= 1.7,:));
ylim([-80 -40])
xlabel('time (ms)')
ylabel('voltage (mV)')
title([cell_name 'raw data, spontaneous events'])
subplot(1,2,2),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces(evokedQDEs_table.riseTimes <= 1.7,:));
ylim([-80 -40])
xlabel('time (ms)')
title('light-evoked events')
%%
%plotting QDEs, baselined in two groups (resting and hyperpolarized V),
%light-evoked and spontaneous in separate subplots
baselineWindow = 40; %avg. of the first 40 samples of each QDEtrace will be used as baseline value
spontQDEs_baselineVs = mean(spontQDEs_table.QDEs_Vtraces(:,1:baselineWindow),2);
evokedQDEs_baselineVs = mean(evokedQDEs_table.QDEs_Vtraces(:,1:baselineWindow),2);
QDE_time_axis = collectedQDEsData.time_axis(1:length(collectedQDEsData_table.QDEs_Vtraces(1,:)));

figure;
subplot(2,2,1),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs > -65,:)-spontQDEs_baselineVs(spontQDEs_baselineVs > -65));
ylim([-1 10])
ylabel('baselined voltage')
title([cell_name 'baselined data, spont. events, baselineV = Vrest'])

subplot(2,2,2),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces(evokedQDEs_baselineVs > -65,:)-evokedQDEs_baselineVs(evokedQDEs_baselineVs > -65));
ylim([-1 10])
title('evoked events, baseline = Vrest')

subplot(2,2,3),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs < -65,:)-spontQDEs_baselineVs(spontQDEs_baselineVs < -65));
ylim([-1 10])
xlabel('time (ms)')
ylabel('baselined voltage')
title('spont. events, hyperpolarized baseline')

subplot(2,2,4),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces(evokedQDEs_baselineVs < -65,:)-evokedQDEs_baselineVs(evokedQDEs_baselineVs < -65));
xlabel('time (ms)')
ylim([-1 10])
title('evoked events, hyperpolarized baseline')

%% 4: looking at ALL evoked events (within illumination window) at baseline and hyperpolarized V
%% 4a: getting only traces where light does NOT evoke a spike
[noSpikeEvoked_collectedQDEtraces] = get_noSpikeEvoked_traces(collectedQDEsData);
%% plotting traces individually, raw, in relevant window
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV
extraIdcs_inPlotWindow = 200;

window_length = 400;
Vrange_cutoff = 2;

figure;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);

    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    if Vrange_inSnippet >= min_Vrange_inSnippet
    
    t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
    
        if Vrange_inSnippet < Vrange_cutoff
            subplot(1,2,1),hold on;
            plot(t_axis,Vsnippet);
%             ylim([-55 -45])
            xlabel('time (ms)')
            ylabel('voltage (mV)')
            title([cell_name 'raw data, events in light-evoked window with amp <' num2str(Vrange_cutoff)])
%             
%             subplot(1,2,2),hold on;
%             plot(t_axis(1:end-1),diff(smooth(Vsnippet,10)));
%             ylabel('derivative of V')
        
        elseif Vrange_inSnippet > Vrange_cutoff
            subplot(1,2,2),hold on;
            plot(t_axis,Vsnippet);
%             ylim([-80 0])
            xlabel('time (ms)')
            ylabel('voltage (mV)')
            title(['events with amp > ' num2str(Vrange_cutoff)])
            
%             subplot(1,2,1),hold on;
%             plot(t_axis(1:end-1),diff(smooth(Vsnippet,10)));
%             ylabel('derivative of V')
        end
    end
end

%% plotting overlay of relevant example-traces, baselined
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV
meanVcap = -45;%filter out one trace with bad Vrest at time of light
window_length = 400;

figure; hold on;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);
    meanV_inSnippet = mean(Vsnippet);
    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    Vderivative = diff(smooth(Vsnippet));
    if (meanV_inSnippet < meanVcap) && (Vrange_inSnippet >= min_Vrange_inSnippet) && (max(Vderivative) > .1) %this should filter out any traces where there isn't really a response to the light
        t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
        
        baselined_Vsnippet = Vsnippet - mean(Vsnippet(1:window_length/10));
        %sort into groups (below and above -65mV); baseline; plot
        if meanV_inSnippet > -65
            subplot(2,1,1),hold on;
            plot(t_axis,baselined_Vsnippet,'linewidth',2);
            ylim([-1 10])
            xlabel('trace start = light onset time')
            ylabel('baselined voltage (mV)')
            title('-60mV < baseline V < -50mV')
        elseif meanV_inSnippet < -65
            subplot(2,1,2),hold on;
            plot(t_axis,baselined_Vsnippet,'linewidth',2);
            ylim([-1 10])
            xlabel('time (ms)')
            ylabel('-78mV < baseline V < -73mV')
        end
    end
end




