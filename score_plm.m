function output = score_plm()
% output will only contain data for the last file processed to conserve
% memory.

[events_files,event_paths] = uigetfile('.txt','Select input event files:',...
    'sample_events/BC1-Events.txt','MultiSelect','on');

if ~iscellstr(events_files), events_files = {events_files}; end

button = questdlg(['Please specify which scoring options you would '...
    'like to use'],'Scoring Options','Standard','Most Recent','New','Standard');

switch button
    case ''
        return;
    case 'Standard'
        load('standard_defaults.mat','last_used');
        sleep_defaults = last_used.sleep_defaults;
        reap_options = {last_used.apnea_defaults;...
            last_used.arousal_defaults};
        lma_defaults = {last_used.lma_defaults;last_used.left_loc;...
            last_used.right_loc};
        col_defaults = last_used.col_defaults;
        params = last_used.params;
    case 'Most Recent'
        load('last_used_defaults.mat','last_used');
        sleep_defaults = last_used.sleep_defaults;
        reap_options = {last_used.apnea_defaults;...
            last_used.arousal_defaults};
        lma_defaults = {last_used.lma_defaults;last_used.left_loc;...
            last_used.right_loc};
        col_defaults = last_used.col_defaults;
        params = last_used.params;
    case 'New'
        load('last_used_defaults.mat','last_used');
        
        %%% begin event file column prompt
        [col_defaults,cancel] = colinput(last_used.col_defaults);
        if cancel, return; end
        
        %%% begin sleep stage prompt
        prompt = {'REM','WAKE','N1','N2','N3'};
        name = 'Sleep stage event names:';
        sleep_defaults = inputdlg(prompt,name,[1, length(name)+20],...
            last_used.sleep_defaults);
        
        if isempty(sleep_defaults), return; end
        
        %%% begin apnea/arousl event prompts
        prompt = {'Apnea','Arousal'};
        name = 'Names of Arousal and Apnea Events Scored:';
        reap_options = inputdlg(prompt,name,[10, length(name)+20],...
            {last_used.apnea_defaults,last_used.arousal_defaults});
        
        if isempty(reap_options), return; end
        
        %%% begin plm event desriptors
        prompt = {'LMA','Left Leg Location','Right Leg Location'};
        name = 'LM event descriptions:';
        lma_defaults = inputdlg(prompt,name,[2, length(name)+20],...
            {last_used.lma_defaults,last_used.left_loc,last_used.right_loc});
        
        if isempty(lma_defaults), return; end
        
        %%% save the defaults specified this time so we don't have to reenter
        last_used = struct();
        last_used(1).apnea_defaults = reap_options{1,1};
        last_used(1).arousal_defaults = reap_options{2,1};
        last_used(1).sleep_defaults = sleep_defaults';
        last_used.lma_defaults = lma_defaults{1,1};
        last_used.left_loc = lma_defaults{2,1};
        last_used.right_loc = lma_defaults{3,1};
        last_used.col_defaults = col_defaults;
        
        [params,cancel] = getInput2(1);
        last_used.params = params;
                
        save('last_used_defaults.mat','last_used');
        
        if cancel, return; end
end

splashy = SplashScreen( 'Splashscreen', 'images/platmab_logo.png', ...
'ProgressBar', 'on', ...
'ProgressPosition', 5, ...
'ProgressRatio', 0.4 );
splashy.addText(10, 25, 'Processing...Please Wait', 'FontSize', 15, 'Color', [0.3922    0.4745    0.6353]);


assignin('base','last_used',last_used); % save for later

apnea_defaults = cellstr(reap_options{1,1});
arousal_defaults = cellstr(reap_options{2,1});
sleep_defaults = cellstr(sleep_defaults');
lm_ids = cellstr(lma_defaults{1,1});
left_loc = cellstr(lma_defaults{2,1});
right_loc = cellstr(lma_defaults{3,1});

for each_file = 1:length(events_files)
    
    outfile_file = [events_files{each_file}(1:end-4), '.report'];
    outfile_path = [event_paths, outfile_file];
    
    fid = fopen([event_paths, events_files{each_file}]);
    
    tline = fgetl(fid);
    indata = false;
    while ~feof(fid)
        
        % Is this language dependent? Also, may be able to automatically
        % extract time format from this file
        if ~isempty(strfind(tline,'Time [hh:mm:ss.xxx]')) ||...
                ~isempty(strfind(tline,'Time [hh:mm:ss]'))
            
            if strfind(tline,'Time [hh:mm:ss.xxx]')
                tformat = 'yyyy-mm-ddTHH:MM:SS.fff';
            else
                tformat = 'yyyy-mm-ddTHH:MM:SS';
            end
            indata=true;
            label_line = {'Time','Event','Duration','Location'};
            
            sleep_stages = cell2table(cell(0,4),'VariableNames',label_line');
            arousals = cell2table(cell(0,4),'VariableNames',label_line');
            apneas = cell2table(cell(0,4),'VariableNames',label_line');
            lms = cell2table(cell(0,4),'VariableNames',label_line');
        end
        
        tline = fgetl(fid);
        
        % if the last line was the start of the data part of the file, we'll
        % begin processing things
        if indata
            dataline = strsplit(tline,'\t'); % should be tab delineated
            
            %if size(strmatch(dataline(2),event_types.Sleep_Stages),1) > 0
            if size(strmatch(dataline(col_defaults.event),sleep_defaults),1) > 0
                sleep_stages = [sleep_stages; cell2table(dataline,'VariableNames',label_line)];
            elseif size(strmatch(dataline(col_defaults.event),arousal_defaults),1) > 0
                arousals = [arousals; cell2table(dataline,'VariableNames',label_line)];
            elseif size(strmatch(dataline(col_defaults.event),apnea_defaults),1) > 0
                apneas = [apneas; cell2table(dataline,'VariableNames',label_line)];
            elseif size(strmatch(dataline(col_defaults.event),lm_ids),1) > 0
                lms = [lms; cell2table(dataline,'VariableNames',label_line)];
            end
        end
        
    end
    
    fclose(fid);
    
    if ~params.ars, arousals = table(); end
    if ~params.aps, apneas = table(); end
    
    % At the moment, we expect that Remlogic output will contain 30 second
    % epochs for sleep staging. Also, hopefully all the events will contain a
    % number or REM to indicate stage. This could be tough if the format is
    % very different in international versions.
    T = sleep_stages{:,col_defaults.event};
    ep = zeros(size(T,1),1);
    ep(~cellfun('isempty', strfind(T,sleep_defaults{3}))) = 1;
    ep(~cellfun('isempty', strfind(T,sleep_defaults{4}))) = 2;
    ep(~cellfun('isempty', strfind(T,sleep_defaults{5}))) = 3;
    %ep(~cellfun('isempty', strfind(T,'4'))) = 4; % This should never happen
    ep(~cellfun('isempty', strfind(T,sleep_defaults{1}))) = 5;
    
    % Select left and right LMs
    lLM_tbl = cell2table(cell(0,4),'VariableNames',label_line);
    rLM_tbl = cell2table(cell(0,4),'VariableNames',label_line);
    if ~isempty(lms)
        for which_name = 1:length(left_loc)
            lLM_tbl = [lLM_tbl ; lms(~cellfun('isempty',...
                strfind(lms{:,col_defaults.loc},left_loc{which_name})),:)];
        end
        for which_name = 1:length(right_loc)
            rLM_tbl = [rLM_tbl ; lms(~cellfun('isempty',... 
                strfind(lms{:,col_defaults.loc},right_loc{which_name})),:)];
        end
    else
        lLM_tbl = [];
        rLM_tbl = [];
    end
    
    start_time = datenum(sleep_stages{1,col_defaults.time},tformat);
    
    % Remember, we're going to just assume 500 hz becuase it's purely arbitrary
    % past the detection step.
    if ~isempty(lLM_tbl)
        lLM = round((datenum(lLM_tbl{:,col_defaults.time},tformat)-start_time) * 86500 * 500);
        
        lLM(:,2) = lLM(:,1) + 500 * cellfun(@str2double, lLM_tbl{:,col_defaults.dur});
    else
        lLM = [];
    end
    
    if ~isempty(rLM_tbl)
        rLM = round((datenum(rLM_tbl{:,col_defaults.time},tformat)-start_time) * 86500 * 500);
        rLM(:,2) = rLM(:,1) + 500 * cellfun(@str2double, rLM_tbl{:,col_defaults.dur});
    else
        rLM = [];
    end
    
    arcell = {}; apcell = {};
    colsneeded = [col_defaults.time col_defaults.event col_defaults.dur];
    if ~isempty(arousals), arcell = table2cell(arousals(:,colsneeded)); end
    if ~isempty(apneas), apcell = table2cell(apneas(:,colsneeded)); end
           
    % chop off location column for apnea/arousal
    % remember: CLMr are included in these arrays, we must remove them for
    % PLM nr
        CLMwr = candidate_lms(rLM,lLM,ep,params,tformat,apcell,arcell,start_time);
    if sum(CLMwr) == 0 
        msgbox(sprintf('No candidate LMS for file %s',outfile_file),'Warning');
        continue;        
    end
    
    % get rid of apnea related events and recalulate imi
    CLMnr = CLMwr(CLMwr(:,11) == 0,:);
    CLMnr(2:end,4) = diff(CLMnr(:,1))/500;
    CLMnr(CLMnr(:,4) > params.maxIMI,9) = 1;
    
    
    % Remember to do one without apnea events
    x = periodic_lms(CLMnr,params);
    xr = periodic_lms(CLMwr,params);
    
    plm_results = struct();
    plm_results.PLMr = xr;
    plm_results.PLM = x;
    plm_results.PLMS = x(x(:,6) > 0,:);
    plm_results.CLMr = CLMwr;
    plm_results.CLM = CLMnr;
    plm_results.CLMS = CLMnr(CLMnr(:,6) > 0,:);    
    plm_results.epochstage = ep;
    
    ID = events_files{each_file}(1:end-4);
    assignin('base','left_loc',cellstr(lma_defaults{2,1}));
    assignin('base','right_loc',cellstr(lma_defaults{3,1}));    
    generate_report(plm_results,arousals,apneas,ID);    
    
    output = struct('sleepstages',sleep_stages,'arousals',arousals,...
       'apneas',apneas,'lms',lms,'tformat',tformat,'plm_results',plm_results);
    
end
delete(splashy);
end

function [in,cancel] = getInput2(ask)

if ~ask
    in = struct('ars',true,'aps',true,'maxdur',10,'bmaxdur',15,...
        'minIMI',10,'maxIMI',90,'lb1',0.5,'ub1',0.5,'lb2',0.5,'ub2',0.5,...
        'inlm',true,'minNumIMI',3,'maxcomb',4);
    
    cancel = false;
else
    
    Title = 'MATPLM Parameters';
    
    %%%% SETTING DIALOG OPTIONS
    Options.Resize = 'on';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ButtonNames = {'OK','Cancel'}; %<- default names, included here just for illustration
    Option.Dim = 4; % Horizontal dimension in fields
    
    Prompt = {};
    Formats = {};
    DefAns = struct([]);
    
    Prompt(1,:) = {'Arousal Events' 'ars',[]};
    Formats(1,1).type = 'check';
    DefAns(1).ars = true;
    
    Prompt(end+1,:) = {'Respiratory Events' 'aps',[]};
    Formats(1,2).type = 'check';
    DefAns.aps = true;
    
    Prompt(end+1,:) = {'Arousal Assoc. Pre   ', 'lb2','s'};
    Formats(2,1).type = 'edit';
    Formats(2,1).format = 'float';
    Formats(2,1).size = 50;
    DefAns.lb2 = 0.5;
    
    Prompt(end+1,:) = {'Respiratory Assoc. Pre  ', 'lb1','s'};
    Formats(2,2).type = 'edit';
    Formats(2,2).format = 'float';
    Formats(2,2).size = 50;
    DefAns.lb1 = 2;
    
    Prompt(end+1,:) = {'Arousal Assoc. Post ', 'ub2','s'};
    Formats(3,1).type = 'edit';
    Formats(3,1).format = 'float';
    Formats(3,1).size = 50;
    DefAns.ub2 = 0.5;
    
    Prompt(end+1,:) = {'Respiratory Assoc. Post', 'ub1','s'};
    Formats(3,2).type = 'edit';
    Formats(3,2).format = 'float';
    Formats(3,2).size = 50;
    DefAns.ub1 = 10.25;
    
    Prompt(end+1,:) = {'Max Monolateral Dur', 'maxdur','s'};
    Formats(4,1).type = 'edit';
    Formats(4,1).format = 'float';
    Formats(4,1).size = 50;
    DefAns.maxdur = 10;
    
    Prompt(end+1,:) = {'Max Bilateral Dur           ', 'bmaxdur','s'};
    Formats(4,2).type = 'edit';
    Formats(4,2).format = 'float';
    Formats(4,2).size = 50;
    DefAns.bmaxdur = 15;
    
    Prompt(end+1,:) = {'Intervening LM Breakpoint' 'inlm',[]};
    Formats(5,1).type = 'check';
    DefAns.inlm = true;
    
    Prompt(end+1,:) = {'Max Comb. Movements', 'maxcomb',[]};
    Formats(6,1).type = 'edit';
    Formats(6,1).format = 'integer';
    Formats(6,1).size = 50; % automatically assign the height
    DefAns.maxcomb = 4;
    
    Prompt(end+1,:) = {'Min num IMI for PLM run', 'minNumIMI',[]};
    Formats(6,2).type = 'edit';
    Formats(6,2).format = 'integer';
    Formats(6,2).size = 50; % automatically assign the height
    DefAns.minNumIMI = 3;
    
    Prompt(end+1,:) = {'Min IMI for PLM             ', 'minIMI','s'};
    Formats(7,1).type = 'edit';
    Formats(7,1).format = 'float';
    Formats(7,1).size = 50; % automatically assign the height
    DefAns.minIMI = 10;
    
    Prompt(end+1,:) = {'Max IMI for PLM             ', 'maxIMI','s'};
    Formats(7,2).type = 'edit';
    Formats(7,2).format = 'float';
    Formats(7,2).size = 50; % automatically assign the height
    DefAns.maxIMI = 90;
    
    [in,cancel] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
    in.fs = 500; % this is abitrary since our event files have time
end

end

function [in,cancel] = colinput(col_defaults)

Title = 'Enter Column No. of Each Variable:';

%%%% SETTING DIALOG OPTIONS
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ButtonNames = {'OK','Cancel'};
%Option.Dim = 4;

Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Time','time',[]};
Formats(1,1).type = 'list';
Formats(1,1).style = 'radiobutton';
Formats(1,1).format = 'integer';
Formats(1,1).items = [1; 2; 3; 4; 5; 6];
DefAns(1).time = col_defaults.time;

Prompt(end+1,:) = {'Event' 'event',[]};
Formats(1,2).type = 'list';
Formats(1,2).style = 'radiobutton';
Formats(1,2).format = 'integer';
Formats(1,2).items = [1; 2; 3; 4; 5; 6];
DefAns.event = col_defaults.event;
 
Prompt(end+1,:) = {'Duration' 'dur',[]};
Formats(1,3).type = 'list';
Formats(1,3).style = 'radiobutton';
Formats(1,3).format = 'integer';
Formats(1,3).items = [1; 2; 3; 4; 5; 6];
DefAns.dur = col_defaults.dur;

Prompt(end+1,:) = {'Location' 'loc',[]};
Formats(1,4).type = 'list';
Formats(1,4).style = 'radiobutton';
Formats(1,4).format = 'integer';
Formats(1,4).items = [1; 2; 3; 4; 5; 6];
DefAns.loc = col_defaults.loc;

[in,cancel] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end