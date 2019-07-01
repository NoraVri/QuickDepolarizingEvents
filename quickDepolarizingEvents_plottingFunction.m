function [] = quickDepolarizingEvents_plottingFunction(Vtrace,time_axis,VpeaksIdcs,baseline_Vs)


window_for_plotting = [VpeaksIdcs - 150, VpeaksIdcs + 600];

for i = 1:length(VpeaksIdcs)
    figure;hold on;
    plot(time_axis(window_for_plotting(i,1):window_for_plotting(i,2)),Vtrace(window_for_plotting(i,1):window_for_plotting(i,2)),'b')
    plot(time_axis(window_for_plotting(i,1):window_for_plotting(i,2)),smoothdata(Vtrace(window_for_plotting(i,1):window_for_plotting(i,2)),'movmedian',10),'k','linewidth',2)
    scatter(time_axis(VpeaksIdcs(i)),Vtrace(VpeaksIdcs(i)),'r','filled');
    scatter(time_axis(VpeaksIdcs(i)-100),baseline_Vs(i),'g');
    xlabel('time within trace (ms)')
    ylabel('voltage (mV)')
    title(['QDE no' num2str(i)])
end


end

