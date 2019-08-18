%% quick depolarizing events - cell 20190812A
% using the "getQuickDepolarizingEvents"-function to find spikelets and other events

%!! all scripts and functions are written so as to work well only for data recorded at 20kHz
clear all;
close all;

%analysis steps:
%1. looking at the raw data
%2. getting "clean" QDEs (peaksIdcs and baselineVs) in a table
%3: plotting things 
%% step1: looking at the raw data and saving as .mat files
cell_name = '190812A';
fileList = dir('gapFree_*.abf');
is_paired = str2double(cell_name(end));

for i = 1:length(fileList)
    loadData_abf_GapFree(fileList(i).name,cell_name,is_paired);
end


%% step2: getting "clean" QDEs (peaksIdcs and baselineVs) from a trace into a table
%the getQuickDepolarizingEvents_inTable takes a datastructure containing at least one column-vector of voltage data,
%and returns a table containing all "clean" QDEs (see function for criteria).
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width of each event (!half-width can be off when decay isn't smooth)

%!set minimal amplitude and max.peakV (to filter out events that are too small, or that are actual spikes)
min_QDEamp = 1; %in mV
max_QDEpeakV = -10; 

%% 2a: in a trace without blockers
load('190812A_gapFree_0001.mat') 
[depolarizingEvents_withoutBlockers_table] = getQuickDepolarizingEvents_inTable(gap_freeTrace,min_QDEamp,max_QDEpeakV);
title('without blockers')

quickDepolarizingEvents_plottingFunction2(gap_freeTrace.voltage,gap_freeTrace.time_axis,depolarizingEvents_withoutBlockers_table.QDEs_VpeaksIdcs,depolarizingEvents_withoutBlockers_table.baselineVs);
title('automatically extracted depolarizing events - without blockers')
%% 2b: in a trace with blockers
load('190812A_gapFree_withBlockers_0003.mat')
[depolarizingEvents_withBlockers_table] = getQuickDepolarizingEvents_inTable(gap_freeTrace,min_QDEamp,max_QDEpeakV);
title('with blockers')

quickDepolarizingEvents_plottingFunction2(gap_freeTrace.voltage,gap_freeTrace.time_axis,depolarizingEvents_withBlockers_table.QDEs_VpeaksIdcs,depolarizingEvents_withBlockers_table.baselineVs)
title('automatically extracted depolarizing events - with blockers')



