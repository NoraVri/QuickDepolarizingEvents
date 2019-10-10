%% quick depolarizing events - analysis
%in Thy1 experiments, compare light-evoked and spontaneous QDEs, at different baseline voltages
%!! all scripts and functions are written so as to work well only for data recorded at 20kHz
clear all;
close all;

cd D:\neert\hujiGoogleDrive\research_YaromLabWork\data_elphys_andDirectlyRelatedThings\olive\myData_SmithLab\20190529A1A2

%analysis steps:
%1. looking at the raw data
%2. concatenating traces for analysis (and creating a datastructure to hold them all)
%3. getting all "clean" QDEs (peaksIdcs and baselineVs) in all traces in a table, and
%3b:separating out light-evoked and spontaneous QDEs into two tables

%4: looking at evoked events at baseline and hyperpolarized V
%% step1: looking at the raw data
%trace length should be the same for all concatenated traces
cell_name = '190529A1';
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
for i = 1:length(fileList)
    load(fileList(i).name);
    vs = rawData_traces.voltage;
        meanVs = mean(vs);
    is = rawData_traces.current;
    ttl = rawData_traces.TTLpulse;
        %%filtering out traces where cell has bad baselineV
minVrest = -35;
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
cd D:\neert\hujiGoogleDrive\research_YaromLabWork\data_elphys_andDirectlyRelatedThings\olive\myData_SmithLab\20190529A1A2

cell_name = '190529A1';
load('190529A1_collectedTraces_lightApplied');

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
min_QDEamp = 1.5;%!!larger than usual by 1mV
max_QDEpeakV = -10;

[collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV);

% 3b: separating out light-evoked and spontaneous QDEs
%!!light-evoked "QDEs" did not get detected at all (and jury's still out on whether they're all just degenerate spikes)
[spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table);



%% plotting things
%scatters of QDE measures, color-coded for light-evoked and spont
figure; hold on;
scatter(spontQDEs_table.baselineVs(spontQDEs_table.riseTimes<1.7),spontQDEs_table.amps(spontQDEs_table.riseTimes<1.7));
scatter(evokedQDEs_table.baselineVs(evokedQDEs_table.riseTimes<1.7),evokedQDEs_table.amps(evokedQDEs_table.riseTimes<1.7),'r','filled')
xlabel('baseline V'), ylabel('QDE amp')
title('blue: spontaneous events, red: light-evoked events')

%%
%plotting QDEs, raw, light-evoked and spontaneous in separate subplots
QDEtrace_length_in_samples = length(collectedQDEsData_table.QDEs_Vtraces(1,:));
QDE_time_axis = collectedQDEsData.time_axis(1:QDEtrace_length_in_samples);
figure;
subplot(1,2,1),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces)%(spontQDEs_table.riseTimes <= 1,:));
ylim([-63 -24])
xlabel('time (ms)')
ylabel('voltage (mV)')
title([cell_name 'raw data, spontaneous events'])
subplot(1,2,2),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces)%(evokedQDEs_table.riseTimes <= 1,:));
ylim([-63 -24])
xlabel('time (ms)')
title('light-evoked events')

%%
%plotting QDEs, baselined in two groups (resting and hyperpolarized V),
%light-evoked and spontaneous in separate subplots
baselineWindow = 40; %avg. of the first 40 samples of each QDEtrace will be used as baseline value
spontQDEs_baselineVs = mean(spontQDEs_table.QDEs_Vtraces(:,1:baselineWindow),2);
evokedQDEs_baselineVs = mean(evokedQDEs_table.QDEs_Vtraces(:,1:baselineWindow),2);
QDE_time_axis = collectedQDEsData.time_axis(1:length(collectedQDEsData_table.QDEs_Vtraces(1,:)));
baselineV_split = -55;

figure;
subplot(2,2,1),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs > baselineV_split,:)-spontQDEs_baselineVs(spontQDEs_baselineVs > baselineV_split));
ylim([-1 14])
ylabel('baselined voltage')
title([cell_name 'spont. events baselined, baselineV = Vrest (or higher)'])

subplot(2,2,2),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces(evokedQDEs_baselineVs > baselineV_split,:)-evokedQDEs_baselineVs(evokedQDEs_baselineVs > baselineV_split));
ylim([-1 14])
title('evoked events, baseline = dying Vrest')

subplot(2,2,3),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs < baselineV_split,:)-spontQDEs_baselineVs(spontQDEs_baselineVs < baselineV_split));
ylim([-1 14])
xlabel('time (ms)')
ylabel('baselined voltage')
title('spont. events, hyperpolarized baseline')

subplot(2,2,4),hold on;
plot(QDE_time_axis,evokedQDEs_table.QDEs_Vtraces(evokedQDEs_baselineVs < baselineV_split,:)-evokedQDEs_baselineVs(evokedQDEs_baselineVs < baselineV_split));
xlabel('time (ms)')
ylim([-1 14])
title('evoked events, hyperpolarized baseline')

%% 4a: getting only traces where light does NOT evoke a spike
[noSpikeEvoked_collectedQDEtraces] = get_noSpikeEvoked_traces(collectedQDEsData);
%% plotting traces individually, raw, in relevant window
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
% TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

window_length = 950;
min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV
Vrange_cutoff = 7;

figure;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);

    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    if Vrange_inSnippet >= min_Vrange_inSnippet
    
    t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
    
        if Vrange_inSnippet < Vrange_cutoff
            subplot(1,2,1),hold on;
            plot(t_axis,Vsnippet);
            ylim([-65 -25])
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
            ylim([-65 -25])
            xlabel('time (ms)')
            ylabel('voltage (mV)')
            title(['events with amp > ' num2str(Vrange_cutoff)])
            
%             subplot(1,2,1),hold on;
%             plot(t_axis(1:end-1),diff(smooth(Vsnippet,10)));
%             ylabel('derivative of V')
        end
    end
end


%% plotting overlay of relevant example-traces
voltages = noSpikeEvoked_collectedQDEtraces.voltage;
TTLs = noSpikeEvoked_collectedQDEtraces.TTL;
time_axis = noSpikeEvoked_collectedQDEtraces.time_axis;
Windows_idcs = noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows;

min_Vrange_inSnippet = .5;%I want to see only traces where there's a response of at least .5mV
meanVcap = -45;%filter out one trace with bad Vrest at time of light
window_length = 950;

Vsplit_upper = -50;
Vsplit_lower = -50;


figure; hold on;
for i = 1:length(noSpikeEvoked_collectedQDEtraces.voltage(1,:))
    Vsnippet = voltages(Windows_idcs(1,i):Windows_idcs(1,i)+window_length,i);
    meanV_inSnippet = mean(Vsnippet);
    Vrange_inSnippet = max(Vsnippet) - min(Vsnippet);
    Vderivative = diff(smooth(Vsnippet));
    if (meanV_inSnippet < meanVcap) && (Vrange_inSnippet >= min_Vrange_inSnippet) && (max(Vderivative) > .1) %this should filter out any traces where there isn't really a response to the light
        t_axis = time_axis(Windows_idcs(1,i):Windows_idcs(1,i)+window_length);
        
        baselined_Vsnippet = Vsnippet - mean(Vsnippet(1:40));
        %sort into groups (below and above -65mV); baseline; plot
        if meanV_inSnippet >= Vsplit_upper
            subplot(2,1,1),hold on;
            plot(t_axis,baselined_Vsnippet,'linewidth',2);
            ylim([-1 15])
            xlabel('trace start = light onset time')
            ylabel('baselined voltage (mV)')
            title(['baseline V > ' num2str(Vsplit_upper)])
        elseif meanV_inSnippet < Vsplit_lower
            subplot(2,1,2),hold on;
            plot(t_axis,baselined_Vsnippet,'linewidth',2);
            ylim([-1 15])
            xlabel('time (ms)')
            title(['baseline V < ' num2str(Vsplit_lower)])
        end
    end
end


%% plotting the stuff Yosi wants in a picture for the grant proposal
%subplot1: spont QDEs at hyperpolarized V, baselined, from automatic detection
%subplot2: evoked QDEs at hyperpolarized V, baselined, in illumination window (where lightOn idx happens to be the same in all traces in this recording)
QDE_time_axis = collectedQDEsData.time_axis(1:length(collectedQDEsData_table.QDEs_Vtraces(1,:)));

baselineWindow = 40; %avg. of the first 40 samples of each QDEtrace will be used as baseline value

spontQDEs_baselineVs = mean(spontQDEs_table.QDEs_Vtraces(:,1:baselineWindow),2);
evokedQDEs_baselineVs = mean(noSpikeEvoked_collectedQDEtraces.voltage(Windows_idcs(:,1):Windows_idcs(:,1)+baselineWindow,:));

baselineV_split = -55;

figure;
subplot(1,2,1),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs < baselineV_split,:)-spontQDEs_baselineVs(spontQDEs_baselineVs < baselineV_split),'linewidth',2);
ylim([-1 13])
ylabel('baselined voltage')
title('spont. events (peak-aligned), baselineV ~-60mV')

subplot(1,2,2),hold on;
evokedQDEs_Vtraces = noSpikeEvoked_collectedQDEtraces.voltage(noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows(1,:):noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows(1,:)+length(QDE_time_axis)-1,:);
plot(QDE_time_axis, evokedQDEs_Vtraces(:,evokedQDEs_baselineVs < baselineV_split) - evokedQDEs_baselineVs(evokedQDEs_baselineVs < baselineV_split),'linewidth',2);
ylim([-1 13])
xlabel('time (ms)')
title('light-evoked events (light onset aligned), baselineV ~-60mV')

%%
%1. finding one good example of an evoked QDE and substracting synapse-only response 
%and 2. an example of spont. event that looks the same (decay-wise)

%1
% for i = 1:length(evokedQDEs_Vtraces(1,:))
%     if evokedQDEs_baselineVs(i) < baselineV_split
%         figure;
%         plot(QDE_time_axis, evokedQDEs_Vtraces(:,i) - evokedQDEs_baselineVs(i),'linewidth',2);
%         ylim([-1 13])
%         xlabel('time (ms)')
%         title(['light-evoked event' num2str(i)])
%     end
% 
% end

i1 = 19;
i2 = 20;
figure;hold on;
subplot(1,2,1),hold on;
plot(QDE_time_axis,evokedQDEs_Vtraces(:,[i1 i2])-evokedQDEs_baselineVs([i1 i2]));
subplot(1,2,2),hold on;
plot(QDE_time_axis,(evokedQDEs_Vtraces(:,i1)-evokedQDEs_baselineVs(i1))- (evokedQDEs_Vtraces(:,i2)-evokedQDEs_baselineVs(i2)));
%%
evokedQDEtrace = (evokedQDEs_Vtraces(:,i1)-evokedQDEs_baselineVs(i1)) - (evokedQDEs_Vtraces(:,i2)-evokedQDEs_baselineVs(i2));
[~,evokedQDEtrace_peakIdx] = max(evokedQDEtrace);
evokedQDEtrace_shortened = evokedQDEtrace(evokedQDEtrace_peakIdx-50:evokedQDEtrace_peakIdx+250);
QDE_time_axis_shortened = QDE_time_axis(1:length(evokedQDEtrace_shortened));
%2
for i = 1:height(spontQDEs_table)
    if spontQDEs_baselineVs(i) < baselineV_split
        Vtrace = spontQDEs_table.QDEs_Vtraces(i,:);
        QDEamp = max(Vtrace) - min(Vtrace);
        if QDEamp > 6 && QDEamp < 8
            [~,spontQDEtrace_peakIdx] = max(Vtrace);
            spontQDEtrace_shortened = Vtrace(spontQDEtrace_peakIdx-50:spontQDEtrace_peakIdx+250);
            
            figure;hold on;
            plot(QDE_time_axis_shortened,spontQDEtrace_shortened-spontQDEs_baselineVs(i),'b','linewidth',2);
            plot(QDE_time_axis_shortened,evokedQDEtrace_shortened,'r','linewidth',2)
            ylim([-1 13])
            xlabel('time (ms)')
            title(['red: evoked event; blue: spont. event' num2str(i)])
        end
    end
end

%%
%panel 1: spont. events (as before, just fewer) - manually deleting
%panel 2: evoked events (as before, just fewer)
%panel3: single example spont, shorter time scale
%panel 4: two examples evoked (synapse and QDE), shorter time scale 
%panel 3: the example of evokedQDE-synapse overlayed with spont

spont_i = 23; %the example for comparison with evoked
spont_Vtrace = spontQDEs_table.QDEs_Vtraces(spont_i,:);

figure;
subplot(2,6,[1 2 3]),hold on;
plot(QDE_time_axis,spontQDEs_table.QDEs_Vtraces(spontQDEs_baselineVs < baselineV_split,:)-spontQDEs_baselineVs(spontQDEs_baselineVs < baselineV_split),'linewidth',2);
plot(QDE_time_axis,spont_Vtrace-spontQDEs_baselineVs(spont_i),'k','linewidth',2)
ylim([-1 13])
ylabel('baselined voltage (mV)')
xlabel('time (ms)')
title('spont. events (aligned to peak), baselineV ~-60mV')

subplot(2,6,[4 5 6]),hold on;
evokedQDEs_Vtraces = noSpikeEvoked_collectedQDEtraces.voltage(noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows(1,:):noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows(1,:)+length(QDE_time_axis)-1,:);
plot(QDE_time_axis, evokedQDEs_Vtraces(:,evokedQDEs_baselineVs < baselineV_split) - evokedQDEs_baselineVs(evokedQDEs_baselineVs < baselineV_split),'linewidth',2);
ylim([-1 13])
xlabel('time (ms)')
title('light-evoked events (aligned to light onset), baselineV ~-60mV')

subplot(2,6,[7 8]),hold on;
[~,spontQDEtrace_peakIdx] = max(spont_Vtrace);
spontQDEtrace_shortened = spont_Vtrace(spontQDEtrace_peakIdx-50:spontQDEtrace_peakIdx+250);
plot(QDE_time_axis_shortened,spontQDEtrace_shortened-spontQDEs_baselineVs(spont_i),'b','linewidth',2);
ylim([-1 8])
xlabel('time (ms)')
title('spont. event, single example')

subplot(2,6,[9 10]),hold on;
plot(QDE_time_axis_shortened,spontQDEtrace_shortened-spontQDEs_baselineVs(spont_i),'b','linewidth',2);
plot(QDE_time_axis_shortened,evokedQDEtrace_shortened,'k','linewidth',2);
ylim([-1 8])
xlabel('time (ms)')
title('visual comparison')

subplot(2,6,[11 12]),hold on;
plot(QDE_time_axis,evokedQDEs_Vtraces(:,[i1 i2])-evokedQDEs_baselineVs([i1 i2]));
plot(QDE_time_axis,(evokedQDEs_Vtraces(:,i1)-evokedQDEs_baselineVs(i1))- (evokedQDEs_Vtraces(:,i2)-evokedQDEs_baselineVs(i2)),'k','linewidth',2);
ylim([-1 13])
xlabel('time (ms)')
title('evoked events w(/o) fast event, and substraction')

