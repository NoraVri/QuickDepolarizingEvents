function [noSpikeEvoked_collectedQDEtraces] = get_noSpikeEvoked_traces(collectedQDEtracesData)
%takes a datastructure of the "collectedQDEsData" format, and
%returns only those traces where no spike was evoked by the light pulse.

    %method: filter traces where V > 0mV at time of TTL high (+10ms to account for slow ChR dynamics)
time_axis = collectedQDEtracesData.time_axis;
    extraTime_in_samples = length(time_axis(time_axis <= 10));
Vtraces = collectedQDEtracesData.voltage;
Itraces = collectedQDEtracesData.current;
TTLtraces = collectedQDEtracesData.TTL;
no_of_traces = length(Vtraces(1,:));

lightEvokedSpike_traces = zeros(1,no_of_traces);
lightEvoked_windows = zeros(2,no_of_traces);
%trace-wise selecting the relevant window for spike-filtering, since the duration of the light pulse can vary per trace
    for i = 1:no_of_traces
        TTLtrace = TTLtraces(:,i);
        Vtrace = Vtraces(:,i);
            TTLhigh_idcs = find(TTLtrace > 5);
            lightEvoked_windows(1,i) = TTLhigh_idcs(1);
            lightEvoked_windows(2,i) = TTLhigh_idcs(end)+extraTime_in_samples;
            relevantVsnippet = Vtrace(TTLhigh_idcs(1)-10:TTLhigh_idcs(end)+extraTime_in_samples);
            
%     figure;
%     plot(relevantVsnippet,'b');hold on;
%     plot(TTLtrace(TTLhigh_idcs(1)-10:TTLhigh_idcs(end)+extraTime_in_samples)+mean(relevantVsnippet),'k');
            
            if sum(relevantVsnippet > 0) > 0
                lightEvokedSpike_traces(i) = 1;
            end
    end
    
    noSpikeEvoked_traceIdcs = find(lightEvokedSpike_traces < 1);
    
    filtered_Vtraces = Vtraces(:,noSpikeEvoked_traceIdcs);
    filtered_Itraces = Itraces(:,noSpikeEvoked_traceIdcs);
    filtered_TTLtraces = TTLtraces(:,noSpikeEvoked_traceIdcs);
    filtered_windows = lightEvoked_windows(:,noSpikeEvoked_traceIdcs);

noSpikeEvoked_collectedQDEtraces.voltage = filtered_Vtraces;
noSpikeEvoked_collectedQDEtraces.current = filtered_Itraces;
noSpikeEvoked_collectedQDEtraces.TTL = filtered_TTLtraces;
noSpikeEvoked_collectedQDEtraces.time_axis = time_axis;
noSpikeEvoked_collectedQDEtraces.lightEvokedActivity_windows = filtered_windows;

end

