%%% MULTI SESSION ANALYSIS %%%
close all
clearvars

%% Insert mouse code %%
prompt = {'Enter mouse code:'};
dlgtitle = 'Mouse info';
dims = [1 35];
definput = {'RM_0'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
mouse_code = char(answer(1));



%% Import data %%
d = ['task_', mouse_code, '.mat'];
data = load(d);



%% Compare lick profile between sessions %%
time = -tmax:1/freq:tmax;                                                                      % time vector (s)
licks = struct;
for f = 1:length(behavior)
    
    for i = length(test):-1:1                                                                  % go backward so you don't have to initialize it
   
        [counts,edges] = histcounts(behavior(f).data.lick_time-behavior(f).data.ts{4},time);   % for each stimulus, count ""licks"" around there
        licks(f).lick_mat(:,i) = counts;                                                       % put everything in a matrix
    
    end
end
time_vec = time(1:end-1); 



%% Compare reaction times distributions %%



%% Performance for each session %%


