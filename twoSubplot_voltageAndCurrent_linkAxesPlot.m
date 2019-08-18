function [ plots ] = twoSubplot_voltageAndCurrent_linkAxesPlot(voltage, current, time_axis, cell_name)

figure;
ax1 = subplot(2,1,1);
plot(time_axis,voltage);
    xlabel('time (ms)')
    ylabel('voltage (mV)')
    title(cell_name)
ax2 = subplot(2,1,2);
plot(time_axis,current);
    xlabel('time (ms)')
    ylabel('current (pA)')
    
    linkaxes([ax1,ax2],'x')

end

