function [collectedQDEsData_table] = getQuickDepolarizingEvents_inTable(collectedQDEsData,min_QDEamp,max_QDEpeakV)
%getQuickDepolarizingEvents Takes a RawData structure and returns a table listing all 'clean' QDEs in the data.
%   QDEs are detected in multiple steps based on diff(V) in the smoothed Vtrace (with some de-noising tricks applied), 
%   and filtered based on criteria for baselineV, min amplitude, maxV of the peak (to filter out spikes) and decay back to baseline. 
%QDEs are indexed by the trace no. they were in and the idx of the QDE peak within that trace (first two columns)
%The table also contains the QDE in a window around the peak (third column), 
%and the amplitude, rise-time and half-width (!half-width can be off when decay isn't smooth)

%%settings:
sr = 20;%number of samples per ms
%smoothing factor to apply to the raw data
smoothing_factor = 4;%no. of indices over which smoothing is applied;
%window in which to search for Vpeak after candidate-point has been selected based on diff(V)
peakFindingWindow = 12.5;%in ms
QDE_peakFindingWindow = peakFindingWindow * sr;%in indices
%two 1-ms windows in which to test pre-peak baselineV stability
baselineTestWindow1 = [-6 -5];
baselineTestWindow2 = [-4 -3];
QDE_baselineTestWindow1 = baselineTestWindow1 * sr;
QDE_baselineTestWindow2 = baselineTestWindow2 * sr;
%leniency factor on how far baseline in these windows can vary
baselineV_maxMismatch = .2;%mV
%window in which to test post-peak return to baselineV
backToBaselineWindow = [3 40];
QDE_backToBaselineWindow = backToBaselineWindow * sr;
%leniency factor on how close back to baseline the QDE should decay 
backToBaselineV_maxMismatch = .5;%QDEamplitude factor
%window around QDEpeak for Vtrace extraction
prePeakWindow = 6;%in ms
QDE_prePeakWindow = prePeakWindow * sr;%in indices
postPeakWindow = 40;%in ms
QDE_postPeakWindow = postPeakWindow * sr;%in indices
%

Vtraces = collectedQDEsData.voltage;
no_of_traces = length(Vtraces(1,:));

collectedQDEsData_table = [];

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
        if ~isempty(QDEstartsCandidates)
            QDE_VpeaksCandidates = finding_QDE_Vpeaks(singleVtrace,smoothVtrace,QDEstartsCandidates,QDE_peakFindingWindow,QDE_postPeakWindow);
        else
            QDE_VpeaksCandidates = [];
        end

        %step3: keeping only those Vpeaks that have a "good" baselineV, amplitude and decay-back-to-baseline
        %   baselineV pre-peak has to be no more than baseline_deviationAmp
        %   apart in the two pre-peak windows; amp from baseline to peakV has
        %   to be no less than minAmp, and post-peak V should reach
        %   baseline+leniencyFactor within postPeak_decayWindow.
        if ~isempty(QDE_VpeaksCandidates)
            [QDEs_VpeaksIdcs,QDEs_baselineVs,QDEs_amps] = filter_QDE_VpeaksCandidates(singleVtrace,smoothVtrace,QDE_VpeaksCandidates,QDE_baselineTestWindow1,QDE_baselineTestWindow2,QDE_backToBaselineWindow,baselineV_maxMismatch,backToBaselineV_maxMismatch,min_QDEamp,max_QDEpeakV);
        else
            QDEs_VpeaksIdcs = [];
        end

        %step4: extracting QDE_Vtraces and getting rise-time and halfwidth
        if ~isempty(QDEs_VpeaksIdcs)
            [QDEs_Vtraces,QDEs_riseTimes,QDEs_halfWidths] = get_QDEs_traces_and_measures(smoothVtrace,QDEs_VpeaksIdcs,QDEs_baselineVs,QDEs_amps,QDE_prePeakWindow,QDE_postPeakWindow,sr);
        end
        
        %step5: tabularizing results and appending it to collectedQDEsDataTable
        if ~isempty(QDEs_VpeaksIdcs)
            singleVtrace_no_of_QDEs = length(QDEs_VpeaksIdcs);
            traceNo = ones(singleVtrace_no_of_QDEs,1)*trace_no;
            
            singleVtrace_QDEsTable = table(traceNo,QDEs_VpeaksIdcs,QDEs_Vtraces,QDEs_baselineVs,QDEs_amps,QDEs_riseTimes,QDEs_halfWidths);
            
            collectedQDEsData_table = [collectedQDEsData_table; singleVtrace_QDEsTable];
        end
        
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

function[QDE_VpeaksCandidates] = finding_QDE_Vpeaks(singleVtrace,smoothVtrace,QDEstartsCandidates,QDE_peakFindingWindow,QDE_postPeakWindow)
    %taking out QDEstartsCandidates that are too close to the start/end of the Vtrace for the peak-finding window to fit around them
    traceStartProx = QDEstartsCandidates - QDE_peakFindingWindow;
    QDEstartsCandidates(traceStartProx < 1) = [];
    traceEndProx = QDEstartsCandidates + QDE_peakFindingWindow;
    QDEstartsCandidates(traceEndProx > length(smoothVtrace)) = [];
    
    %finding a peakV index to go with each QDEstartCandidate 
    no_of_candidates = length(QDEstartsCandidates);
    QDE_VpeaksCandidates = zeros(no_of_candidates,1);
    for i = 1:no_of_candidates
        V_inWindow = smoothVtrace((QDEstartsCandidates(i) - QDE_peakFindingWindow):(QDEstartsCandidates(i) + QDE_peakFindingWindow));
        [~,peakVinwindowindex] = max(V_inWindow);
        spikeletIdx_to_peakVidx = peakVinwindowindex - QDE_peakFindingWindow - 1;
        peakVindex = QDEstartsCandidates(i) + spikeletIdx_to_peakVidx;
        QDE_VpeaksCandidates(i) = peakVindex;
    end
    %taking out VpeaksCandidates that are too close to the end of the Vtrace to fit decay-testing window
    QDEstartsCandidates(QDE_VpeaksCandidates+QDE_postPeakWindow > length(singleVtrace)) = [];
    QDE_VpeaksCandidates(QDE_VpeaksCandidates+QDE_postPeakWindow > length(singleVtrace)) = [];
    
    %if peakV in window comes before candidateidx, take it out
    candidateidx_to_peakVidx = QDE_VpeaksCandidates - QDEstartsCandidates;
    QDE_VpeaksCandidates(candidateidx_to_peakVidx < 1) = [];
    %keep points only when the same peak-point has been identified at least twice
    QDE_VpeaksCandidates(diff(QDE_VpeaksCandidates) ~= 0) = [];
    %keep only the first point for all duplicate Vpeakidcs
    QDE_VpeaksCandidates(diff(QDE_VpeaksCandidates) < 1) = [];
end

function [QDEs_VpeaksIdcs,QDEs_baselineVs,QDEs_amps] = filter_QDE_VpeaksCandidates(singleVtrace,smoothVtrace,QDE_VpeaksCandidates,QDE_baselineTestWindow1,QDE_baselineTestWindow2,QDE_backToBaselineWindow,baselineV_maxMismatch,backToBaselineV_maxMismatch,min_QDEamp,max_QDEpeakV)
%filtering out QDEpeaksCandidates that are actually spikes
Vs_at_candidateQDEpeaks = singleVtrace(QDE_VpeaksCandidates);
QDE_VpeaksCandidates(Vs_at_candidateQDEpeaks > max_QDEpeakV) = [];

no_of_VpeaksCandidates = length(QDE_VpeaksCandidates);
%filtering out QDE_VpeaksCandidates if the difference between baselineVs in
%two windows pre-peak is more than maxMismatch factor and getting baselineVs
baselineTestWindows1 = [QDE_VpeaksCandidates + QDE_baselineTestWindow1(1), QDE_VpeaksCandidates + QDE_baselineTestWindow1(2)];
baselineTestWindows2 = [QDE_VpeaksCandidates + QDE_baselineTestWindow2(1), QDE_VpeaksCandidates + QDE_baselineTestWindow2(2)];

baselineVs_inWindow1 = zeros(no_of_VpeaksCandidates,1);
baselineVs_inWindow2 = zeros(no_of_VpeaksCandidates,1);
QDEs_baselineVs = zeros(no_of_VpeaksCandidates,1);
    for i = 1:no_of_VpeaksCandidates
        baselineVs_inWindow1(i) = mean(smoothVtrace(baselineTestWindows1(i,1):baselineTestWindows1(i,2)));
        baselineVs_inWindow2(i) = mean(smoothVtrace(baselineTestWindows2(i,1):baselineTestWindows2(i,2)));
        QDEs_baselineVs(i) = mean(smoothVtrace(baselineTestWindows1(i,1):baselineTestWindows2(i,2)));
    end
    VbaselineDifference = abs(baselineVs_inWindow1 - baselineVs_inWindow2);
QDE_VpeaksCandidates(VbaselineDifference > baselineV_maxMismatch) = [];
QDEs_baselineVs(VbaselineDifference > baselineV_maxMismatch) = [];

%getting QDEamps for each QDE_VpeakIdx and filtering out QDEs < minAmp
Vs_at_QDEs = singleVtrace(QDE_VpeaksCandidates);
QDEs_amps = Vs_at_QDEs - QDEs_baselineVs;
QDE_VpeaksCandidates(QDEs_amps < min_QDEamp) = [];
QDEs_baselineVs(QDEs_amps < min_QDEamp) = [];
QDEs_amps(QDEs_amps < min_QDEamp) = [];

no_of_VpeaksCandidates = length(QDE_VpeaksCandidates);
%filtering out peaks that do not reach baselineV + max.mismatch within back-to-baseline window
baselineReReach_traces = zeros(length(QDE_backToBaselineWindow(1):QDE_backToBaselineWindow(2)),length(QDE_VpeaksCandidates));
baselineReReach_windows = [QDE_VpeaksCandidates+QDE_backToBaselineWindow(1),QDE_VpeaksCandidates+QDE_backToBaselineWindow(2)];
    for i = 1:no_of_VpeaksCandidates
        baselineReReach_traces(:,i) = smoothVtrace(baselineReReach_windows(i,1):baselineReReach_windows(i,2));
    end
    minVs_inBaselineReReachWindows = min(baselineReReach_traces)';
    minBaselineV_criterions = QDEs_baselineVs + backToBaselineV_maxMismatch * QDEs_amps;
    baselineReturnDifferences = minBaselineV_criterions - minVs_inBaselineReReachWindows;
    QDE_VpeaksCandidates(baselineReturnDifferences < 0) = [];
    QDEs_baselineVs(baselineReturnDifferences < 0) = [];
    QDEs_amps(baselineReturnDifferences < 0) = [];
    
    QDEs_VpeaksIdcs = QDE_VpeaksCandidates;
end

function [QDEs_Vtraces,QDEs_riseTimes,QDEs_halfWidths] = get_QDEs_traces_and_measures(smoothVtrace,QDEs_VpeaksIdcs,QDEs_baselineVs,QDEs_amps,QDE_prePeakWindow,QDE_postPeakWindow,sr)
%!!issue: QDE decays are not always smooth, and halfWidth measurement can be off when additional depolarizing events hit in the first half of the post-peak window

no_of_QDEs = length(QDEs_VpeaksIdcs);

QDEtraceLength = length((-1*QDE_prePeakWindow):QDE_postPeakWindow);
QDEtrace_time_axis = (-1*QDE_prePeakWindow:QDE_postPeakWindow)/sr;

QDEs_Vtraces = zeros(no_of_QDEs,QDEtraceLength);
QDEs_riseTimes = zeros(no_of_QDEs,1);
QDEs_halfWidths = zeros(no_of_QDEs,1);

    for i = 1:no_of_QDEs
        %getting Vtrace in window around QDEpeak
        QDE_Vtrace_i = smoothVtrace((QDEs_VpeaksIdcs(i)-QDE_prePeakWindow):(QDEs_VpeaksIdcs(i)+QDE_postPeakWindow));
    QDEs_Vtraces(i,:) = QDE_Vtrace_i';
        %getting QDE rise-time (time to go from 10%-90% QDE amp, in ms)
        risingTrace_i = QDE_Vtrace_i(1:QDE_prePeakWindow) - QDEs_baselineVs(i);
        riseTimeTrace = find(risingTrace_i > .1*QDEs_amps(i) & risingTrace_i < .9*QDEs_amps(i));
    QDEs_riseTimes(i) = length(riseTimeTrace)/sr;
        %getting QDE half-width (QDE width in ms, at .5 amp)
        risingDecayingTrace_i = QDE_Vtrace_i(1:(QDE_postPeakWindow/2)) - QDEs_baselineVs(i);
        halfWidthTrace = find(risingDecayingTrace_i > .5*QDEs_amps(i));
            halfWidthTrace_consecutiveness = find(diff(halfWidthTrace) > 1,1);
            if ~isempty(halfWidthTrace_consecutiveness)
                halfWidthTrace = halfWidthTrace(1:halfWidthTrace_consecutiveness);
            end
    QDEs_halfWidths(i) = length(halfWidthTrace)/sr;
    
%plotting each QDE_Vtrace with its measures marked 
figure;hold on;
    plot(QDEtrace_time_axis,QDE_Vtrace_i,'b');
    scatter(QDEtrace_time_axis(riseTimeTrace),QDE_Vtrace_i(riseTimeTrace),'r');
    scatter(QDEtrace_time_axis(halfWidthTrace),ones(1,length(halfWidthTrace))*.5*QDEs_amps(i)+QDEs_baselineVs(i),'g');
    scatter(QDEtrace_time_axis(1:(QDE_prePeakWindow/2)),ones(1,length(1:(QDE_prePeakWindow/2)))*QDEs_baselineVs(i),'k')
    xlabel('time (ms)')
    ylabel('voltage (mV)')
    xlim([QDEtrace_time_axis(1) QDEtrace_time_axis(end)])
    ylim([QDEs_baselineVs(i)-2, QDEs_baselineVs(i)+15])
    end
end

