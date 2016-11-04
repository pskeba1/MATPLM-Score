% Modified by Patrick 5/5 to streamline code and avoid dangerous hardcoded
% fixes. This now correctly handles fractional seconds!


function [newPLM,h] = PLMApnea(PLM,ApneaData,HypnogramStart,lb,ub,fs)
%% [newPLM] = PLMApnea_Patrick(PLM,ApneaData,HypnogramStart,lb,ub,fs)
% PLMApnea adds Apnea Events to the 11th col of the PLM Matrix if there is
% a PLM within -lb,+ub seconds of the event endpoint
% ApneaData is the CISRE_Apnea matrix
% HypnogramStart is the first data point

% Form newAp, which is ApneaData with endpoint of event (in datapoints) 
% added to 4th col. This is calculated with HypnogramStart as datapoint 1

% There seem to be inconsistencies with how records without apnea or
% arousal data are coded. Sometimes it is a 1 x 3 vector of zeros, other
% times it is a 0 x 3 array (I don't even know what that means). We have to
% check for both, apparently.

tformat = 'yyyy-mm-ddTHH:MM:SS.fff';


if size(ApneaData, 1) == 0
    newPLM = PLM;
    newPLM(1,11) = 0;
    return
end
    
if ApneaData{1,1} == 0
    newPLM = PLM;
    newPLM(1,11) = 0;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
ap_ends = zeros(size(ApneaData,1),1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
start_vec = datevec(HypnogramStart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end

for ii = 1:size(ApneaData,1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
    ap_start = datevec(ApneaData{ii,1},tformat);
    ap_ends(ii) = (etime(ap_start,start_vec) + ...
        str2double(ApneaData{ii,3})) * fs + 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end    
end

newPLM=PLM;

for ii = 1:size(ApneaData, 1)
    for jj = 1:size(PLM, 1)
        %If 'lb' seconds before the apnea endpoint is within the PLM interval,
        %or if 'ub' seconds after the endpoint is within the PLM interval
        %or if the PLM interval is within the apnea interval
        if(ap_ends(ii) - fs*lb >= PLM(jj,1) && ap_ends(ii) - fs*lb <= PLM(jj,2)) ||...
                (ap_ends(ii) + fs*ub >= PLM(jj,1) && ap_ends(ii) + fs*ub <= PLM(jj,2)) ||...
                (ap_ends(ii) - fs*lb <= PLM(jj,1) && ap_ends(ii) + fs*ub >= PLM(jj,2))
            newPLM(jj,11) = 1; 
        end
    end
end

h = ap_ends;
end
    