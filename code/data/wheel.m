clearvars
close all



%% LOAD FILES %%
disp('Loading files...')
abspos = load('abspos.csv');
ptgrey = load('ptgrey.csv');
raw_encoder = load('raw_encoder_signal.csv');
filename = 'epochlicktimestamp.csv';
[timestamp, epoch, lick] = importfile_lts(filename);
response = csvread('response.csv');
roi = load('roi.csv');
wheel_hi_res = load('wheel_hi_res.csv');
testresult = load('testresult.csv');
filename = 'mouse_name.csv';
mouse_name = importfile_name(filename);
trial_type = load('trial_type.csv');
%task_file = 'task_type.csv';
%task_type = importfile_name(task_file);
disp('Files loaded')



disp('Computing data...')
%% TOTAL HITRATE %%
total_hit_rate = length(response(:,3)==1) / length(trial_type); %%% calculate hit rate

%% ABSOLUTE POSITION %%
abspos = abspos-min(abspos); % subtract the minimum value to make it start at 0

%% SPEED %%
time_speed = (1:length(abspos))/1000;        %%% get time for each position in second. 1000Hz is the encoder data retrival frequency.

raw_encoder = raw_encoder(1:length(abspos)); %%% get encoder signal within the absolute position data

abspos(:,2) = time_speed;                    %%% time every absolute position 
raw_encoder(:,2) = time_speed;               %%% time every encoder signal 

speed = zeros(1,length(time_speed));         %%% create array for speed   
for i = 1:length(time_speed)-1
    speed(i) = (abspos(i+1)-abspos(i))/(time_speed(i+1)-time_speed(i)); %%% calculate speed for every second
end

speed(speed<=0) = 0; %%% remove speed below 0 (moving backwards)
average_speed = mean(speed); %%% calculate average speed

%% CONSTANTS %%
freq = 100;                         % sampling rate for licks
th_licks = 0.001;                   % threshold for lick detection
tmax = 2;                           % time interval to detect licks

%% REMOVE LICK SIGNALS THAT ARE TOO CLOSE %%
l_value = int8(lick)-1;                         % convert to zero and ones
l_ts = timestamp(l_value==1);                   % find lick timestamps
ili_l = [0; diff(l_ts)];                        % interlick interval (s)
bad_ones = find(ili_l<th_licks);                % bad ones (the ones that are too fast)
l_ts(bad_ones) = [];                            % remove licks/events that are too fast
 
%% EPOCH TIMESTAMPS %%
iti_all = find(epoch==0);                       % take indeces for all timestamps in iti phase
iti_a = find(diff(iti_all)>1)+1;                % take indeces for the beggining of iti phase 
iti = [iti_all(1) iti_all(iti_a)'];             % include the first trial
iti_start_ts = timestamp(iti);                  % take timestampos for iti beggining

cue_all = find(epoch==1);                       % take indeces for all timestamps in cue phase
delay_a = find(diff(cue_all)>1)+1;              % take indeces for the beggining of cue phase
cue = [cue_all(1) cue_all(delay_a)'];           % include the first trial
cue_start_ts = timestamp(cue);                  % take timestampos for cue beggining

delay_all = find(epoch==1);                     % take indeces for all timestamps in delay phase
delay_a = find(diff(delay_all)>1)+1;            % take indeces for the beggining of delay phase
delay = [delay_all(1) delay_all(delay_a)'];     % include the first trial
delay_start_ts = timestamp(delay);              % take timestampos for delay beggining

test_all = find(epoch==3);                      % take indeces for all timestamps in test phase
test_a = find(diff(test_all)>1)+1;              % take indeces for the beggining of test phases
test = [test_all(1) test_all(test_a)'];         % include the first trial 
test_start_ts = timestamp(test);                % take timestamps for test begginings

%% PSTH LICKS %%
time = -tmax:1/freq:tmax;                % time vector (s)

for i = length(test):-1:1                % go backward so you don't have to initialize it
   
    [counts,edges] = histcounts(l_ts-test_start_ts(i),time);   % for each stimulus, count ""licks"" around there
    lick_mat(:,i) = counts;                                    % put everything in a matrix
    
end
time_vec = time(1:end-1);                % actual time vector for plotting

%% REACTION TIME %%
rt = [];
for i=1:length(test_start_ts)
    for t=1:length(l_ts)
        rt(t,i) = l_ts(t)-test_start_ts(i);
    end    
end

rt(rt<=-1) = NaN;                                  %%% remove all licks -1s before stimulus onset
rt(rt>=5) = NaN;                                   %%% remove all licks 5s after stimulus onset

[a,edg] = histcounts(rt, 'Normalization','pdf');   %%% lick time distribution
edg = edg(2:end) - (edg(2)-edg(1))/2;               

%% STRUCT %%
props = dir(filename);
filedate = props.date;
cd ../

datafile = strcat('task_',mouse_name,'.mat');
if isfile(datafile)==1
    load(datafile);
    nsession = length(behavior)+1;  
else
    behavior = struct;
    nsession = 1;        
end

%% STRUCT HEADING %%
behavior(nsession).info = mouse_name;                                          % mouse name
behavior(nsession).date = filedate;                                            % session date
%data.behavior(nsession+1).task_type = task_type;

%% STRUCT DATA %%
behavior(nsession).data.ts{1} = iti_start_ts;                                       % phase for the 1st label of the photodiode
behavior(nsession).data.ts{2} = cue_start_ts;                                       % phase for the 2nd label of the photodiode
behavior(nsession).data.ts{3} = delay_start_ts;                                     % phase for the 3rd label of the photodiode
behavior(nsession).data.ts{4} = test_start_ts;                                      % phase for the 4rd label of the photodiode
behavior(nsession).data.lick_time = l_ts;                                           % lick timestamps
behavior(nsession).data.trial_type = trial_type(:,1);                               % zeros or ones (NO-GO, GO)
behavior(nsession).data.response = response(:,3);                                   % zeros or ones (no response, response)

save(datafile,'behavior')
disp('Data computed')
disp('Generating plots...')
%% PLOTS %%
figure
subplot(3,2,2)                                                 
plot(time_vec,smooth(mean(lick_mat,2),75),'r','LineWidth',2); hold on    
plot(time_vec,mean(lick_mat,2),'LineWidth',0.02,'Color',[0 0 0 0.1])  
title('Licks profile');
ylabel('# Licks')
xlabel('time (s)') 
h = gca; h.XAxis.Visible = 'on';
axis tight 
box off 
legend({'Licks (smoothed (r.av.))','Licks'},'box','off','Location','NorthWest') 
subplot(3,2,4) % lick PSTH
imagesc(time_vec,1:size(lick_mat,2),lick_mat') 
xlabel('time (s)') 
ylabel('Trial')  
title('Licks PSTH')
subplot(3,2,1)
plot(abspos(:,2), abspos(:,1))
title('Absolute position')
subplot(3,2,3)
plot(raw_encoder(:,2), raw_encoder(:,1))
title('Encoder raw signal')
subplot(3,2,5)
plot(smooth(speed(1:1000:end)),'r', 'LineWidth', 1.2)
title('Speed throught trial')
legend('Speed','Location','Northwest')
ylabel('Speed (cm/s)')
xlabel('Time (s)')
subplot(3,2,6)
speed_histo = histogram(smooth(speed(1:1000:end)));
title('Speed distribution')
xlabel('Speed (cm/s)')
ylabel('Frequency')

figure
subplot(2,2,1)
rt_hist = histogram(rt);
rt_hist.NumBins = 100;
title('Lick distribution around stimulus onset')
xlabel('Time (s)')
ylabel('frequency')
hold on
yyaxis right
ylabel('y2')
plot(edg, a)
disp('Plots ready')