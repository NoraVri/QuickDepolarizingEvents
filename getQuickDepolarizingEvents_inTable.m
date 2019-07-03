function [QDEs_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV)
%getQuickDepolarizingEvents Takes a RawData structure and returns a table listing all 'clean' QDEs in the data.
%   QDEs are detected in multiple steps based on diff(V) in the smoothed Vtrace (with some de-noising tricks applied), 
%   and filtered based on criteria for baselineV, min amplitude, maxV of the peak (to filter out spikes) and decay back to baseline. 
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width (!half-width can be off when decay isn't smooth)

%%settings:
%smoothing factor to apply to the raw data
smoothing_factor = 10;%no. of indices over which smoothing is applied; .5ms in this case
%window in which to search for Vpeak after candidate-point has been selected based on diff(V)
peakFindingWindow = 12.5;%in ms
QDE_peakFindingWindow = 12.5*20;%in indices
%windows in which to test pre-peak baselineV stability

%window in which to test post-peak return to baselineV

%window around QDEpeak for Vtrace extraction
prePeakWindow = 6;%in ms
QDE_prePeakWindow = prePeakWindow * 20;%in indices
postPeakWindow = 40;%in ms
QDE_postPeakWindow = postPeakWindow * 20;%in indices
%

Vtraces = collectedQDEsData.voltage;
no_of_traces = length(Vtraces(1,:));

table = [];

    for trace_no = 1:no_of_traces

        singleVtrace = Vtraces(:,trace_no);

    %step1: identifying QDE-candidates based on diff(smooth(V)).
    %   The smallest positive value in the differentiated trace is considered
    %   noise; any points where diff(smooth(V)) is larger than this for at
    %   least two consecutive indices is identified as a QDE-peak candidate.
        smoothVtrace = smoothdata(singleVtrace,'movmedian',smoothing_factor);
        QDEstartsCandidates = finding_quickDepolarizingPoints(smoothVtrace);

    %step2: identifying Vpeaks to go with each QDEstart-candidate and filtering out bad ones.
    %   Vpeaks are identified as maxV in the peakFindingWindow around QDEstartCandidate;
    %   points are considered bad if Vpeak is too close to the beginning or end of the trace;
    %   if Vpeak comes before QDEstart; if the same Vpeak point is selected only once. 
        QDE_VpeaksCandidates = finding_QDE_Vpeaks(smoothVtrace,QDEstartsCandidates,QDE_peakFindingWindow,QDE_postPeakWindow);
    
    %step3: keeping only those Vpeaks that have a "good" baselineV, amplitude and decay-back-to-baseline
    %   baselineV pre-peak has to be no more than baseline_deviationAmp
    %   apart in the two pre-peak windows; amp from baseline to peakV has
    %   to be no less than minAmp, and post-peak V should reach
    %   baseline+leniencyFactor within postPeak_decayWindow.
    
    end



end

function[QDEstartsCandidates] = finding_quickDepolarizingPoints(smoothVtrace)
    V_smooth_deriv = diff(smoothVtrace);
    %'neatifying' the differentiated trace
    deriv_negativesZeroed = V_smooth_deriv;
    deriv_negativesZeroed(V_smooth_deriv < 0) = 0;
    %assumption: the smallest positive value in the differentiated trace is noise, but anything over that could represent a real event.
    deriv_allPosValues = deriv_negativesZeroed;
    deriv_allPosValues(deriv_negativesZeroed == 0) = [];
noiseValue = min(deriv_allPosValues);
    deriv_noiseSubstracted = deriv_negativesZeroed - noiseValue;
    deriv_noiseSubstracted(deriv_noiseSubstracted < 0) = 0;
    
    %finding fast depolarizations occurring over at least two consecutive indices
    idcs_derivAboveNoise = find(deriv_noiseSubstracted > 0);
    consecutiveness = diff(idcs_derivAboveNoise);
    QDEstartsCandidates = idcs_derivAboveNoise(consecutiveness == 1);
end

function[QDE_VpeaksCandidates] = finding_QDE_Vpeaks(smoothVtrace,QDEstartsCandidates,QDE_peakFindingWindow,QDE_postPeakWindow)
    %taking out QDEstartsCandidates that are too close to the start/end of the Vtrace for the peak-finding window to fit around them
    traceStartProx = QDEstartsCandidates - QDE_peakFindingWindow;
    QDEstartsCandidates(traceStartProx < 1) = [];
    traceEndProx = QDEstartsCandidates + QDE_peakFindingWindow;
    QDEstartsCandidates(traceEndProx > length(smoothVtrace)) = [];
    
    %finding a peakV index to go with each QDEstartCandidate 
    no_of_candidates = length(QDEstartsCandidates);
    QDE_VpeaksCandidates = zeros(no_of_candidates,1);
    for i = 1:no_of_candidates
        smoothV_inWindow = smoothVtrace((QDEstartsCandidates(i) - QDE_peakFindingWindow):(QDEstartsCandidates(i) + QDE_peakFindingWindow));
        [~,peakVinwindowindex] = max(smoothV_inWindow);
        spikeletIdx_to_peakVidx = peakVinwindowindex - QDE_peakFindingWindow - 1;
        peakVindex = QDEstartsCandidates(i) + spikeletIdx_to_peakVidx;
        QDE_VpeaksCandidates(i) = peakVindex;
    end
    %taking out VpeaksCandidates that are too close to the end of the Vtrace to fit decay-testing window
    QDEstartsCandidates(QDE_VpeaksCandidates+QDE_postPeakWindow > length(Vtrace)) = [];
    QDE_VpeaksCandidates(QDE_VpeaksCandidates+QDE_postPeakWindow > length(Vtrace)) = [];
    
    %if peakV in window comes before candidateidx, take it out
    candidateidx_to_peakVidx = QDE_VpeaksCandidates - QDEstartsCandidates;
    QDE_VpeaksCandidates(candidateidx_to_peakVidx < 1) = [];
    %keep points only when the same peak-point has been identified at least twice
    QDE_VpeaksCandidates(diff(QDE_VpeaksCandidates) ~= 0) = [];
    %keep only the first point for all duplicate Vpeakidcs
    QDE_VpeaksCandidates(diff(QDE_VpeaksCandidates) < 1) = [];
end