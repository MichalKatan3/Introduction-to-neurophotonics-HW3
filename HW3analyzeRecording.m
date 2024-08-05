function HW3analyzeRecording(subject, mainRecordIND)
%% Description
% Analyze the recording based on the given subject and recording type.

% In order to use this function the user must put the subject name he wants
% to anaylze: 'Alon' or 'Hana'.
% The mainRecordIND parameter indicates which record we should analyze:
% To analyze the 30 sec the user needs to set mainRecordIND=1 
% To analyze the 5 min hold breath record the user needs to set mainRecordIND=2

%% Check validity of inputs
validNames = {'Alon', 'Hana'};

% first input - 'Alon' or 'Hana' only
if ~ischar(subject)
    error('The first input of the function must be a char: ''Alon'' or ''Hana'' only!')
else
    if ~ismember(subject, validNames)
        error('Invalid input: The name must be either ''Alon'' or ''Hana''.');
    end
end

% second input - 1 or 2 only
if ~isnumeric(mainRecordIND)
    error('The second input of the function must be a number: 1 or 2 only!')
else
    if (mainRecordIND ~= 1) && (mainRecordIND ~= 2)
        error('The second input of the function must be a number: 1 or 2 only!')
    end
end

%% Asking user for recording path
recordingPath = uigetdir('Select the Recording Directory');

% Scan for Different Folders and Store in a Struct
folders = dir(recordingPath); % List all items in the recording path
folders = folders([folders.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'

% Create a struct to hold folder paths and names with additional information
recordsData = struct();
numFolders=length(folders);
for folder_Index = 1:numFolders
    recordsData(folder_Index).name = folders(folder_Index).name;
    recordsData(folder_Index).path = fullfile(recordingPath, folders(folder_Index).name);

    % Extract information from the folder name
    folderName = folders(folder_Index).name;
    parts = strsplit(folderName, '_');

    if startsWith(folderName, 'FR')
        recordsData(folder_Index).FR = str2double(extractBetween(parts{1}, 3, strlength(parts{1})-2)); % Extract FR value
        recordsData(folder_Index).Gain = str2double(extractBetween(parts{2}, 5, strlength(parts{2}))); % Extract Gain value
        recordsData(folder_Index).T = str2double(extractBetween(parts{3}, 5, strlength(parts{3})-2)); % Extract T value
        recordsData(folder_Index).Subject = parts{4}; % Subject name (Alon or Hana)
    elseif startsWith(folderName, 'Background')
        recordsData(folder_Index).Gain = str2double(extractBetween(parts{2}, 5, strlength(parts{2}))); % Extract Gain value
        recordsData(folder_Index).T = str2double(extractBetween(parts{3}, 5, strlength(parts{3})-2)); % Extract T value
        recordsData(folder_Index).Subject = parts{4}; % Subject name (Alon or Hana)
    elseif startsWith(folderName, 'ReadNoise')
        recordsData(folder_Index).Gain = str2double(extractBetween(parts{2}, 5, strlength(parts{2}))); % Extract Gain value
        recordsData(folder_Index).T = str2double(extractBetween(parts{3}, 5, strlength(parts{3})-2)); % Extract T value
        recordsData(folder_Index).Subject = ''; % No subject name for ReadNoise
    else
        warning('Folder name format not recognized: %s', folderName);
    end
end

% Assign indices based on subject
if strcmp(subject, 'Hana')==1 || isempty(subject)==1
    bgIND = 1;
    shortIND = 3;
    breathIND = 4;
    disp('Subject name is: Hana');
elseif strcmp(subject, 'Alon')==1
    bgIND = 2;
    shortIND = 5;
    breathIND = 6;
    disp('Subject name is: Alon');

else
    warning('Wrong subject name');

end
readnoiseIND = 7;

% Determine which index to use based on mainRecordingType
if any(mainRecordIND==1) || isempty(mainRecordIND)==1
    recordingIndex = shortIND;
    stringdisp='30 sec record';
    disp(['Recording to anlyze:',stringdisp]);

elseif any(mainRecordIND==2)
    stringdisp='breath hold recording 4.5 min';
    recordingIndex = breathIND;
        disp(['Recording to anlyze:',stringdisp]);

else
    warning('Wrong main recording index');
end

%% Determine an ROI (Region of Interest)
recordFramesName = dir(fullfile(recordsData(recordingIndex).path, '*.tiff'));
numRecordFrames = length(recordFramesName);
randomframeIndex = randi(numRecordFrames); % Use randi to ensure a valid index
exampleFrame = imread(fullfile(recordsData(recordingIndex).path, recordFramesName(randomframeIndex).name));

% Create figure to draw the circle at
f1 = figure('DefaultAxesFontUnits', 'Points', 'DefaultAxesFontSize', 18, 'DefaultAxesFontName', 'Times New Roman', ...
    'DefaultTextFontUnits', 'Points', 'DefaultTextFontSize', 20, 'DefaultTextFontName', 'Times New Roman', ...
    'DefaultLineLineWidth', 1, 'Color', 'White');
figWidth = 25; % Width in centimeters
figHeight = 11; % Height in centimeters
set(f1, 'Units', 'centimeters');
set(f1, 'Position', [2, 2, figWidth, figHeight]);

% Display the image and allow the user to draw a circle
subplot(1, 2, 1);
imshow(exampleFrame, []);
title('Adjust the circle and press ''OK''');
h = drawcircle;

% Wait for the user to press OK
uiwait(msgbox('Press OK to continue...'));

% Create and display the ROI mask after OK is pressed
roiMask = createMask(h);
subplot(1, 2, 2);
imagesc(roiMask);
title('ROI Mask');

pause('off')

%% Calculate Read Noise Matrix
% Define window size for local spatial noise
window_size = 7;
disp("Calculating read noise");
% Scan the desired folder for tiff files
readnoiseNames = dir(fullfile(recordsData(readnoiseIND).path, '*.tiff'));
numReadNoiseFrames = length(readnoiseNames);
for frameIndex = 1:numReadNoiseFrames
    frame(:,:,frameIndex) = imread(fullfile(recordsData(readnoiseIND).path, readnoiseNames(frameIndex).name));
    temp(:,:,frameIndex)=stdfilt(frame(:,:,frameIndex),ones(window_size));
end
% same as HW2: Local Spatial Noise with window size of 7 (after averaging in time)
sigma_ReadNoise=stdfilt(mean(frame,3),ones(window_size));
% Local Spatial Noise with window size of 7 per frame, then average over all frames.
sigma_ReadNoise_2=mean(temp,3);

f2 = figure('DefaultAxesFontUnits', 'Points', 'DefaultAxesFontSize', 18, 'DefaultAxesFontName', 'Times New Roman', ...
    'DefaultTextFontUnits', 'Points', 'DefaultTextFontSize', 20, 'DefaultTextFontName', 'Times New Roman', ...
    'DefaultLineLineWidth', 1, 'Color', 'White');
figWidth = 25; % Width in centimeters
figHeight = 11; % Height in centimeters
set(f2, 'Units', 'centimeters');
set(f2, 'Position', [2, 2, figWidth, figHeight]);
subplot(1,2,1)
imagesc(sigma_ReadNoise)
title({["Local Spatial Noise"]; ["average over time"]});
subplot(1,2,2)
imagesc(sigma_ReadNoise_2)
title({["Local Spatial Noise per frame"]; ["and average frames"]});

%% Calculate Pixels-Non-Uniformity
disp("Calculating Pixels-Non-Uniformity");

% Calculate the background and average it
backgroundNoiseName = dir(fullfile(recordsData(bgIND).path, '*.tiff'));
numBackgroundFrames=length(backgroundNoiseName);
for frameIndex = 1:numBackgroundFrames
    frameBG(:,:,frameIndex) = imread(fullfile(recordsData(bgIND).path, backgroundNoiseName(frameIndex).name));
end

% Calculate the recording and average it
if  recordingIndex==shortIND
    randEndpPoint=501;
else
    flag=1;
    while flag==1
        randEndpPoint=round(rand(1,1)*numRecordFrames);
        if randEndpPoint>500
            flag=0;
        end
    end
end
for frameIndex = (randEndpPoint-500):randEndpPoint
    recordTemp(:,:,frameIndex) = imread(fullfile(recordsData(recordingIndex).path, recordFramesName(frameIndex).name));
end

meanFrameBG=mean(frameBG,3); % Average the background
PixelsNonUniformty=mean(recordTemp,3)-meanFrameBG;
varianceFrameBG = stdfilt(mean(PixelsNonUniformty,3),ones(window_size)).^2; % Variance=std^2

f3 = figure('DefaultAxesFontUnits', 'Points', 'DefaultAxesFontSize', 18, 'DefaultAxesFontName', 'Times New Roman', ...
    'DefaultTextFontUnits', 'Points', 'DefaultTextFontSize', 20, 'DefaultTextFontName', 'Times New Roman', ...
    'DefaultLineLineWidth', 1, 'Color', 'White');
figWidth = 25; % Width in centimeters
figHeight = 11; % Height in centimeters
set(f3, 'Units', 'centimeters');
set(f3, 'Position', [2, 2, figWidth, figHeight]);

subplot(1,2,1)
imshow(PixelsNonUniformty)
title("PixelsNonUniformty");
subplot(1,2,2)
imagesc(varianceFrameBG)
title("varianceFrameBG");
clear('recordTemp'); % To manage the memory

%% 5. Calculate G[DU/e]
disp("Calculating G[DU/e]");

g_in=recordsData(recordingIndex).Gain;
G_in=10^(g_in/20);
g=20*log(recordsData(recordingIndex).Gain); %"g[dB] = 20*log(Gain)" Tirgul 3
N=12;
saturationCapcity=10500; %[e] from HW2
G_base=(2^N)/(saturationCapcity);
G = G_base*G_in; % Example value

%% Subtract Background for Every Frame
disp("Subtracting Background for Every Frame");
Kf=zeros(1,numRecordFrames);

for frameIndex = 1:numRecordFrames
    disp(frameIndex);
    I = double(imread(fullfile(recordsData(recordingIndex).path, recordFramesName(frameIndex).name)));
    I_window_AVG =imboxfilt(I,window_size); %stdfilt(I,ones(window_size));
    K_raw_per_window=(stdfilt(I_window_AVG)./(I_window_AVG)).^2;  %(stdfilt(I,ones(window_size))/mean(I_window)).^2;
    k_S=(g./I_window_AVG).^2; % Shot noise
    K_R=(sigma_ReadNoise./I_window_AVG).^2;
    K_SP=(PixelsNonUniformty./I_window_AVG).^2;
    K_q=(1/12).*(I_window_AVG.^2);

    Kf_matrix=(K_raw_per_window-k_S-K_R-K_SP-K_q);
    Kf(frameIndex)=mean(nonzeros(Kf_matrix.*roiMask));
end

%% Plot Kf^2 over time for the two recordings
disp('Ploting Kf^2 over time for the two recordings');

time = (1:numRecordFrames) / recordsData(recordingIndex).FR; % Assuming 20Hz frame rate
f4 = figure('DefaultAxesFontUnits', 'Points', 'DefaultAxesFontSize', 18, 'DefaultAxesFontName', 'Times New Roman', ...
    'DefaultTextFontUnits', 'Points', 'DefaultTextFontSize', 20, 'DefaultTextFontName', 'Times New Roman', ...
    'DefaultLineLineWidth', 1, 'Color', 'White');
figWidth = 30; % Width in centimeters
figHeight = 11; % Height in centimeters
set(f4, 'Units', 'centimeters');
set(f4, 'Position', [2, 2, figWidth, figHeight]);
plot(time,Kf);
xlabel('Time (s)');
ylabel('Fixed Contrast (Kf^2)');
title('Fixed Contrast Over Time');
xlim([0, time(end)])

%Only for the breath hold we need to mark the breath hold
if mainRecordIND==2    
    
    % Normal breathing: (30 sec each ht efirst 4 sections and 60 sec for the last one)
    taskColor = 'g';
    taskStart = 0+60*(0:4); 
    taskDuration = 30;
    ylims = get(gca,'YLim');
    for iter_i=1:numel(taskStart)
        if iter_i == 5
            taskDuration = 60;
            patch([taskStart(iter_i)  taskStart(iter_i)+taskDuration , taskStart(iter_i)+taskDuration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
        else
            patch([taskStart(iter_i)  taskStart(iter_i)+taskDuration , taskStart(iter_i)+taskDuration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
        end
    end
    hold on
    %breath hold: (30 sec each section)
    taskColor = 'r';
    taskStart = 30+60*(0:3); 
    taskDuration = 30;
    ylims = get(gca,'YLim');
    for iter_i=1:numel(taskStart)
            patch([taskStart(iter_i)  taskStart(iter_i)+taskDuration , taskStart(iter_i)+taskDuration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
    end    
    
    % fixing shift of 5 seconds, only for Alon:
    % Now for the breathing part (green) the first section is 35 sec, 
    % the last section is 55 sec and all other sections are 30 sec.
    if subject == 'Alon'
        f5 = figure('DefaultAxesFontUnits', 'Points', 'DefaultAxesFontSize', 18, 'DefaultAxesFontName', 'Times New Roman', ...
            'DefaultTextFontUnits', 'Points', 'DefaultTextFontSize', 20, 'DefaultTextFontName', 'Times New Roman', ...
            'DefaultLineLineWidth', 1, 'Color', 'White');
        figWidth = 30; % Width in centimeters
        figHeight = 11; % Height in centimeters
        set(f5, 'Units', 'centimeters');
        set(f5, 'Position', [2, 2, figWidth, figHeight]);
        plot(time,Kf);
        xlabel('Time (s)');
        ylabel('Fixed Contrast (Kf^2)');
        title('Fixed Contrast Over Time');
        xlim([0, time(end)])
        % Normal breathing:
        taskColor = 'g';
        taskStart = [0, 65:60:245]; % 0+60*(0:4); 
        taskDuration = [30, 35, 55];
        ylims = get(gca,'YLim');
        for iter_i=1:numel(taskStart)
            if iter_i == 1 %the first section is 35 seconds
                duration = taskDuration(2);
                patch([taskStart(iter_i)  taskStart(iter_i)+duration , taskStart(iter_i)+duration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
            elseif iter_i == 5 %the last section is 55 seconds
                duration = taskDuration(3);
                patch([taskStart(iter_i)  taskStart(iter_i)+duration , taskStart(iter_i)+duration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
            else % other sections are 30 seonds
                duration = taskDuration(1);
                patch([taskStart(iter_i)  taskStart(iter_i)+duration , taskStart(iter_i)+duration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);            
            end
        end
        hold on
        %breath hold:
        taskColor = 'r';
        taskStart = 35+60*(0:3); 
        taskDuration = 30;
        ylims = get(gca,'YLim');
        for iter_i=1:numel(taskStart)
                patch([taskStart(iter_i)  taskStart(iter_i)+taskDuration , taskStart(iter_i)+taskDuration taskStart(iter_i)],[ylims(1) ylims(1) ylims(2) ylims(2)], taskColor,'EdgeColor','none','FaceAlpha',0.15);
        end  
    end
    
end

end











