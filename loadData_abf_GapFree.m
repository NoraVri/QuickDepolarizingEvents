function [ ] = loadData_abf_GapFree(file_name,cell_name,is_paired)
%imports a gap_free file by name and plots the data,
%then the file is converted to a standard mat-file for saving.

%based on the is_paired argument passed into the function, 
%either two or four channels are plotted and saved.

%single_channel recordings
if isnan(is_paired)
    %load file, make time axis, plot data 
    [data,sampling_interval,infos] = abfload(file_name);
    time_axis = linspace(0,length(data(:,1))*sampling_interval*1E-3,length(data(:,1)))';

    voltage = data(:,1);
    current = data(:,2);

    twoSubplot_voltageAndCurrent_linkAxesPlot(voltage,current,time_axis,cell_name);
    title(file_name(1:end-4));

%     %get user input on whether data should be saved
%     worthSaving = input('is this a good data file? Press 0 for no, 1 for yes');
%         if worthSaving == 1
%     %get user input on whether window should be applied; if yes, get window and apply
%         windowingNeeded = input('does a window need to be applied? Press 0 for no, 1 for yes');
% 
%             if windowingNeeded == 1
%                 window_start = input('window start (ms)');
%                 window_end = input('window end (ms)');
%                 time_window = [window_start window_end];
%                 data = [voltage current];
%                 [windowed_data,windowed_time_axis] = apply_window(time_window,time_axis,data);
%                 voltage = windowed_data(:,1);
%                 current = windowed_data(:,2);
%                 time_axis = time_axis(1:length(windowed_time_axis));
%             end

        gap_freeTrace.voltage = voltage;
        gap_freeTrace.current = current;
        gap_freeTrace.time_axis = time_axis;
        gap_freeTrace.infos = infos;

        save(strcat(cell_name,'_',file_name(1:end-4)),'gap_freeTrace')

%         else gap_freeTrace = [];
%         end
        
        
%paired recordings
else 
    %load file, make time axis, plot data 
    [data,sampling_interval,infos] = abfload(file_name);
    time_axis = linspace(0,length(data(:,1))*sampling_interval*1E-3,length(data(:,1)))';

    V1 = data(:,1);
    I1 = data(:,2);
    V2 = data(:,3);
    I2 = data(:,4);

    twoChannels_GapFreeRecording_linkAxesPlot(V1, I1, V2, I2, time_axis, cell_name)
    title(file_name(1:end-4));
    
    %get user input on whether data should be saved
%     worthSaving = input('is this a good data file? Press 0 for no, 1 for yes');
%         if worthSaving == 1
%     %get user input on whether window should be applied; if yes, get window and apply
% %         windowingNeeded = input('does a window need to be applied? Press 0 for no, 1 for timewindowing, 2 for channel chopping');
%         windowingNeeded = input('does a window need to be applied? Press 0 for no, 1 for timewindowing both channels');
%         if windowingNeeded == 1
%                 window_start = input('window start (ms)');
%                 window_end = input('window end (ms)');
%                 time_window = [window_start window_end];
%                 data = [V1 I1 V2 I2];
%                 [windowed_data,windowed_time_axis] = apply_window(time_window,time_axis,data);
%                 V1 = windowed_data(:,1);
%                 I1 = windowed_data(:,2);
%                 V2 = windowed_data(:,3);
%                 I2 = windowed_data(:,4);
%                 time_axis = time_axis(1:length(windowed_time_axis));
% %         elseif windowingNeeded == 2
%             
%         end
%         
        
        twoCh_gapFreeTrace.V1 = V1;
        twoCh_gapFreeTrace.I1 = I1;
        twoCh_gapFreeTrace.V2 = V2;
        twoCh_gapFreeTrace.I2 = I2;
        twoCh_gapFreeTrace.time_axis = time_axis;
        twoCh_gapFreeTrace.infos = infos;
        
        save(strcat(cell_name,'_',file_name(1:end-4)),'twoCh_gapFreeTrace')
        
%         else twoCh_gapFreeTrace = [];
%         end
        
end

    
end

