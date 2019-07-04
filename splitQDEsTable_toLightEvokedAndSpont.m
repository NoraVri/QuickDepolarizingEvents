function [spontQDEs_table,evokedQDEs_table] = splitQDEsTable_toLightEvokedAndSpont(collectedQDEsData,collectedQDEsData_table)
sr = 20;
TTLs = collectedQDEsData.TTL;

no_of_traces = length(TTLs(1,:));
%getting the idx numbers where light turns on and off for each trace
TTLon_idcs = zeros(1,no_of_traces);
TTLoff_idcs = zeros(1,no_of_traces);
for i = 1:no_of_traces
    tracei_TTLon = find(collectedQDEsData.TTL(:,i)>9);
    TTLon_idcs(i) = tracei_TTLon(1);
    TTLoff_idcs(i) = tracei_TTLon(end);
end
%ChR activates rather slowly, need to take that into account both at the beginning and end of the light pulse
ChR_minActivationTime_inIdcs = 2*sr;%2ms to take into account ChR activation, times sampling interval
ChR_postActivationTime_inIdcs = 10*sr;%after 10ms ChR can be still depolarizing the axons
lightEvoked_startIdcs = TTLon_idcs + ChR_minActivationTime_inIdcs;
lightEvoked_endIdcs = TTLoff_idcs + ChR_postActivationTime_inIdcs;

is_evoked = zeros(height(collectedQDEsData_table),1);
is_spont = zeros(size(is_evoked));
for i = 1:height(collectedQDEsData_table)
    traceNo_i = collectedQDEsData_table{i,'traceNo'};
    VpeakIdx_i = collectedQDEsData_table{i,'QDEs_VpeaksIdcs'};
    if VpeakIdx_i > lightEvoked_startIdcs(traceNo_i) && VpeakIdx_i < lightEvoked_endIdcs(traceNo_i)
        is_evoked(i) = 1;
    else
        is_spont(i) = 1;
    end
end


spontQDEs_table = collectedQDEsData_table((is_spont == 1),:);
evokedQDEs_table = collectedQDEsData_table((is_evoked == 1),:);

end

