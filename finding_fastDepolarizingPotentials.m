function [VpeaksIdcs,baseline_Vs] = finding_fastDepolarizingPotentials(Vtrace,min_QDEamp)
%this function takes a voltage trace and returns a vector of indices
%marking "fast depolarizing potentials". 
%steps:
%1. smoothing Vtrace to take out some of the fast noise.
%2. using diff(Vtrace) to identify fast depolarizing events.
%2a substracting the worst of the noise from diff(Vtrace)
%2b identifying fast depolarizing events occuring over at least 2 consecutive indices in the cleaned diff(Vtrace)
%3. finding one peakV index for each fast-depolarizing-event candidate
%4. filtering FDE and peakV idcs for peak-amplitude and duplicates
%5. selecting peaks with a "good" baseline (no more than .2mV apart in the 4th and 6th ms before peak)
%6. filtering peaks that are <.5mV from baseline
%7. selecting peaks that reach at least baseline+0.2*peakAmp again within 3 - 40 ms


%step1: smoothing and differentiating
filteringCoeff = 10;%=smoothing over 0.2ms @20kHz sampling rate
    V_smooth = smoothdata(Vtrace,'movmedian',filteringCoeff);
    
%step2: using diff(Vtrace) to identify fast depolarizing events
    V_smooth_deriv = diff(V_smooth);
    %2a 'neatifying' the differentiated trace
    deriv_negativesZeroed = V_smooth_deriv;
    deriv_negativesZeroed(V_smooth_deriv < 0) = 0;
    %assumption: the smallest positive value in the differentiated trace is noise, but anything over that could represent a real event.
    deriv_allPosValues = deriv_negativesZeroed;
    deriv_allPosValues(deriv_negativesZeroed == 0) = [];
noiseValue = min(deriv_allPosValues);
    deriv_noiseSubstracted = deriv_negativesZeroed - noiseValue;
    deriv_noiseSubstracted(deriv_noiseSubstracted < 0) = 0;
    %2b finding fast depolarizations occurring over at least two consecutive indices
    idcs_derivAboveNoise = find(deriv_noiseSubstracted > 0);
    consecutiveness = diff(idcs_derivAboveNoise);
    consecutive_idcs = find(consecutiveness == 1);
    FDEstart_candidates_round1 = idcs_derivAboveNoise(consecutive_idcs);
    
%step3: finding peakV beloning to each round1 candidate as maxV in timewindow around candidateidx
window_in_indices = 250; %=25 ms @20kHz sampling rate (window on both sides)
        %if index is too close to the beginning or end of the trace, take it out and shorten spikeletPeakCandidates accordingly
    traceStartProx = FDEstart_candidates_round1 - window_in_indices;
    FDEstart_candidates_round1(traceStartProx < 1) = [];
    traceEndProx = FDEstart_candidates_round1 + 800;%this is the window in idcs where return-to-baseline is checked
    FDEstart_candidates_round1(traceEndProx > length(Vtrace)) = [];
    
        %find a peakV index to go with each round1 candidate 
    no_of_candidates = length(FDEstart_candidates_round1);
    VpeaksIdcsCandidates_round1 = zeros(no_of_candidates,1);
    for i = 1:no_of_candidates
        smoothV_around_index = V_smooth((FDEstart_candidates_round1(i) - window_in_indices):(FDEstart_candidates_round1(i) + window_in_indices));
        [~,peakVinwindowindex] = max(smoothV_around_index);
        spikeletIdx_to_peakVidx = peakVinwindowindex - window_in_indices - 1;
        peakVindex = FDEstart_candidates_round1(i) + spikeletIdx_to_peakVidx;
        VpeaksIdcsCandidates_round1(i) = peakVindex;
    end
    postVpeakWindow_in_idcs = 801;
    FDEstart_candidates_round1(VpeaksIdcsCandidates_round1+postVpeakWindow_in_idcs > length(Vtrace)) = [];
    VpeaksIdcsCandidates_round1(VpeaksIdcsCandidates_round1+postVpeakWindow_in_idcs > length(Vtrace)) = [];
    
%step4: using round1 candidates and peakV idcs to filter out bad points
    FDEstart_candidates_round2 = FDEstart_candidates_round1;
    VpeaksIdcsCandidates_round2 = VpeaksIdcsCandidates_round1;
    %if peakV in window comes before candidateidx, take it out
    candidateidx_to_peakVidx = VpeaksIdcsCandidates_round1 - FDEstart_candidates_round1;
    FDEstart_candidates_round2(candidateidx_to_peakVidx < 1) = [];
    VpeaksIdcsCandidates_round2(candidateidx_to_peakVidx < 1) = [];
    %keep points only if V at peak is at least .3 mV higher than V at FDEcandidate
    Vs_at_FDEstart = V_smooth(FDEstart_candidates_round2);
    Vs_at_peaks = V_smooth(VpeaksIdcsCandidates_round2);
    Vdifferences = Vs_at_peaks - Vs_at_FDEstart;
    FDEstart_candidates_round2(Vdifferences < .3) = [];
    VpeaksIdcsCandidates_round2(Vdifferences < .3) = [];
    %keep points only when the same peak-point has been identified at least twice
    FDEstart_candidates_round2(diff(VpeaksIdcsCandidates_round2) ~= 0) = [];
    VpeaksIdcsCandidates_round2(diff(VpeaksIdcsCandidates_round2) ~= 0) = [];
    %keep only the first point for all duplicate Vpeakidcs
    FDEstart_candidates_round2(diff(VpeaksIdcsCandidates_round2) < 1) = [];
    VpeaksIdcsCandidates_round2(diff(VpeaksIdcsCandidates_round2) < 1) = [];
    
%step5: selecting peaks with a good baseline: V in the 4th and 6th ms before should be no more than .2mV apart
    VpeaksIdcsCandidates_round3 = VpeaksIdcsCandidates_round2;
window_4thmsPrePeak = [VpeaksIdcsCandidates_round3 - 80, VpeaksIdcsCandidates_round3 - 60];
window_6thmsPrePeak = [VpeaksIdcsCandidates_round3 - 120, VpeaksIdcsCandidates_round3 - 100];
    V4msPrePeak = zeros(length(VpeaksIdcsCandidates_round3),1);
    V6msPrePeak = zeros(size(V4msPrePeak));
    for i = 1:length(VpeaksIdcsCandidates_round3)
        V4msPrePeak(i) = mean(V_smooth(window_4thmsPrePeak(i,1):window_4thmsPrePeak(i,2)));
        V6msPrePeak(i) = mean(V_smooth(window_6thmsPrePeak(i,1):window_6thmsPrePeak(i,2)));
    end
    VbaselineDifference = abs(V4msPrePeak - V6msPrePeak);
VpeaksIdcsCandidates_round3(VbaselineDifference > .2) = [];

%step6: selecting peaks that are at least baseline + min_QDEamp
    VpeaksIdcsCandidates_round4 = VpeaksIdcsCandidates_round3;
window_forBaseline = [VpeaksIdcsCandidates_round4 - 120, VpeaksIdcsCandidates_round4 - 60];
    baseline_Vs = zeros(length(VpeaksIdcsCandidates_round4),1);
    for i = 1:length(VpeaksIdcsCandidates_round4)
        baseline_Vs(i) = mean(V_smooth(window_forBaseline(i,1):window_forBaseline(i,2)));
    end
    VbaselineToPeakDifference = Vtrace(VpeaksIdcsCandidates_round4) - baseline_Vs;
    VpeaksIdcsCandidates_round4(VbaselineToPeakDifference < min_QDEamp) = [];
    baseline_Vs(VbaselineToPeakDifference < min_QDEamp) = [];
    
%step7: selecting peaks that reach at least baseline+.2*peakAmp again within 3 - 40 ms
    Vs_atPeaksIdcs = V_smooth(VpeaksIdcsCandidates_round4);
    quickDepolarizingEvents_amps = Vs_atPeaksIdcs - baseline_Vs;
    VpeaksIdcsCandidates_round5 = VpeaksIdcsCandidates_round4;
window_forBaselineReReached = [VpeaksIdcsCandidates_round5 + 60, VpeaksIdcsCandidates_round5 + 800];
    baseline_reReached = zeros(741,length(VpeaksIdcsCandidates_round5));
    for i = 1:length(VpeaksIdcsCandidates_round5)
        baseline_reReached(:,i) = V_smooth(window_forBaselineReReached(i,1):window_forBaselineReReached(i,2));
    end
    minVs_inBaselineReachedWindow = min(baseline_reReached)';
    baselineWithLeaway = baseline_Vs + .2*quickDepolarizingEvents_amps;
    baselineReturnDifference = baselineWithLeaway - minVs_inBaselineReachedWindow;
    VpeaksIdcsCandidates_round5(baselineReturnDifference < 0) = [];
    baseline_Vs(baselineReturnDifference < 0) = [];
    
VpeaksIdcs = VpeaksIdcsCandidates_round5;

end

