function [] = quickDepolarizingEvents_plottingFunction4(Vtraces_columns,time_axis,VpeaksIdcs_cellArray,baseline_Vs_cellArray)

plotWindow_startidx = -150;
plotWindow_endidx = 600;
windowed_time_axis = time_axis(1:751);

    tracei_baselineVsMins = zeros(length(VpeaksIdcs_cellArray),1);
    tracei_baselineVsMaxs = zeros(length(VpeaksIdcs_cellArray),1);
    for i = 1:length(VpeaksIdcs_cellArray)
        if ~isempty(VpeaksIdcs_cellArray{i})
        tracei_baselineVsMins(i) = min(baseline_Vs_cellArray{i});
        tracei_baselineVsMaxs(i) = max(baseline_Vs_cellArray{i});
        end
        tracei_baselineVsMins(tracei_baselineVsMins == 0) = [];
        tracei_baselineVsMaxs(tracei_baselineVsMaxs == 0) = [];
    end
% overall_min_baselineV = min(tracei_baselineVsMins);
% overall_max_baselineV = max(tracei_baselineVsMaxs);
% no_of_colors = ceil(overall_max_baselineV - overall_min_baselineV) + 1;
% colormap = parula(no_of_colors);



for i = 1:length(VpeaksIdcs_cellArray)
    if ~isempty(VpeaksIdcs_cellArray{i})
        tracei_V = Vtraces_columns(:,i);
        tracei_VpeaksIdcs = VpeaksIdcs_cellArray{i};
        tracei_baselineVs = baseline_Vs_cellArray{i};
%         tracei_QDE_colorNos = ceil(tracei_baselineVs - overall_min_baselineV) + 1;
        
        for j = 1:length(tracei_VpeaksIdcs)
            QDEj_Vtrace_baselined = tracei_V(plotWindow_startidx+tracei_VpeaksIdcs(j):tracei_VpeaksIdcs(j)+plotWindow_endidx) - tracei_baselineVs(j);
            plot(windowed_time_axis,QDEj_Vtrace_baselined,'k');
        end
    end
end
% bar = colorbar;
%     ticks = linspace(0,10,11);
%     tick_spacing = (overall_max_baselineV - overall_min_baselineV)/10;
%     ticks = overall_min_baselineV + (ticks * tick_spacing);
%     tickLabels = cell(11,1);
%     for i = 1:length(ticks)
%         tickLabels{i} = num2str(ticks(i));
%     end
% bar.TickLabels = tickLabels;
% bar.Label.String = 'baseline V';

end

