function [amps,riseTimes,halfWidths] = getQDEmeasures(Vtrace,VpeaksIdcs,baselineVs)
%this function takes Vtraces,VpeaksIdcs and baselineVs 
%and calculates amp, rise-time and half-width for each QDE. 
no_of_QDEs = length(VpeaksIdcs);

Vpeaks = Vtrace(VpeaksIdcs);
amps = Vpeaks - baselineVs;

riseTimes = zeros(no_of_QDEs,1);
halfWidths = zeros(no_of_QDEs,1);
for i = 1:no_of_QDEs
    QDEtrace = Vtrace(VpeaksIdcs(i)-120:VpeaksIdcs(i)+800);%window around QDEpeakidx
    QDEtrace_time_axis = -6:.05:40;
    
    risingTrace_i = QDEtrace(1:121) - baselineVs(i);%window from start to peak
    riseTimeTrace = find(risingTrace_i > .1*amps(i) & risingTrace_i < .9*amps(i));
riseTimes(i) = length(riseTimeTrace) / 20;
    
    risingDecayingTrace_i = smoothdata(QDEtrace - baselineVs(i),'movmedian',10);
    halfWidthTrace = find(risingDecayingTrace_i > .5*amps(i));
halfWidths(i) = length(halfWidthTrace) / 20;
    
    figure;hold on;
    plot(QDEtrace_time_axis,QDEtrace,'b')
    scatter(QDEtrace_time_axis(riseTimeTrace-1),QDEtrace(riseTimeTrace),'r');
    scatter(QDEtrace_time_axis(halfWidthTrace),QDEtrace(halfWidthTrace),'g');
    title(['QDE no' num2str(i)])
    xlim([-6 40])
end



end

