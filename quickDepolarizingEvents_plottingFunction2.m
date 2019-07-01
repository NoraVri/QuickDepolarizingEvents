function [] = quickDepolarizingEvents_plottingFunction2(Vtrace,time_axis,VpeaksIdcs,baseline_Vs)
if ~isempty(VpeaksIdcs)
window_for_plotting = [VpeaksIdcs - 150, VpeaksIdcs + 600];

QDEi_color_no = ceil(baseline_Vs - min(baseline_Vs)) + 1;
no_of_colors = max(QDEi_color_no);
colormap = parula(no_of_colors);


figure;hold on;
for i = 1:length(VpeaksIdcs)
    windowed_time_axis = time_axis(1:751);
    baselined_Vtrace = Vtrace(window_for_plotting(i,1):window_for_plotting(i,2)) - baseline_Vs(i);
    baselined_smoothVtrace = smoothdata(baselined_Vtrace,'movmedian',10);
%     plot(time_axis(window_for_plotting(i,1):window_for_plotting(i,2)),baselined_Vtrace,'b')
    plot(windowed_time_axis,baselined_smoothVtrace,'color',colormap(QDEi_color_no(i),:))
    xlabel('time (ms)')
    ylabel('voltage (mV)')
end
bar = colorbar;
    ticks = linspace(0,10,11);
    tick_spacing = (max(baseline_Vs) - min(baseline_Vs))/10;
    ticks = min(baseline_Vs) + (ticks * tick_spacing);
    tickLabels = cell(10,1);
    for i = 1:length(ticks)
        tickLabels{i} = num2str(ticks(i));
    end
bar.TickLabels = tickLabels;
bar.Label.String = 'baseline V';
end
end

