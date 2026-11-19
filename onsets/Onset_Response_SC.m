clear;
clc;

%% Load Data
% Load subject data file
[file, path] = uigetfile('*.mat', 'Trial Spike Data File');

raw = load(fullfile(path, file));
varName = fieldnames(raw);
ts = raw.(varName{1});

[unitFile, unitPath] = uigetfile('*.mat', 'Unit Table');

unitRaw = load(fullfile(unitPath, unitFile));
unitvarName = fieldnames(unitRaw);
T = unitRaw.(unitvarName{1});

uniqueMice = unique(T.mouseNum);
allTables = cell(numel(uniqueMice), 1);

for m = 1:numel(uniqueMice) % Loop over all mouse tables
    thisMouse = uniqueMice(m);

    mouseCells = T(T.mouseNum == thisMouse, :);
    subjectData = ts(thisMouse).T;

    uniqueCellIDs = mouseCells.uID;
    
    nTrials = height(subjectData);
    nCells = numel(uniqueCellIDs);

    %% Extract spike data
    % Set Baseline and Onset Window
    
    baselineWindow = [-2 0];
    EonsetWindow = [0 0.4];
    LonsetWindow = [0.4 0.8];

    RecEonsetWindow = [0 0.4];
    RecLonsetWindow = [0.4 0.8];

    % Extract spike data
    slowTrials = sum(subjectData.speeds == 1);

    baselineCounts = zeros(slowTrials,nCells);
    EonsetCounts = zeros(slowTrials,nCells);
    LonsetCounts = zeros(slowTrials,nCells);
    RecEonsetCounts = zeros(slowTrials, nCells);
    RecLonsetCounts = zeros(slowTrials, nCells);


    
    baselineSR = zeros(slowTrials,nCells);
    EonsetSR = zeros(slowTrials,nCells);
    LonsetSR = zeros(slowTrials,nCells);
    RecEonsetSR = zeros(slowTrials, nCells);
    RecLonsetSR = zeros(slowTrials, nCells);

    t_idx = 0;
    for t = 1 : nTrials
        if subjectData.speeds(t) ~= 1; continue; end
            t_idx = t_idx + 1;
            spikeTimes = subjectData.raster{t};
            cellIDs = subjectData.cellIDs{t};
            
            % for baseline and onset period separately
            
            baselineIdx = spikeTimes >= baselineWindow(1) & spikeTimes <= baselineWindow(2) & spikeTimes ~= 0;
            baselineCells = cellIDs(baselineIdx);
            
            EonsetIdx = spikeTimes >= EonsetWindow(1) & spikeTimes <= EonsetWindow(2) & spikeTimes ~= 0;
            EonsetCells = cellIDs(EonsetIdx);
        
            LonsetIdx = spikeTimes >= LonsetWindow(1) & spikeTimes <= LonsetWindow(2) & spikeTimes ~= 0;
            LonsetCells = cellIDs(LonsetIdx);

            Ton_rec_rel = subjectData.Ton_rec(t) - subjectData.Ton(t);

            RecEonsetIdx   = spikeTimes >= (Ton_rec_rel + RecEonsetWindow(1)) & spikeTimes <= (Ton_rec_rel + RecEonsetWindow(2));
            RecEonsetCells = cellIDs(RecEonsetIdx);

            RecLonsetIdx   = spikeTimes >= (Ton_rec_rel + RecLonsetWindow(1)) & spikeTimes <= (Ton_rec_rel + RecLonsetWindow(2));
            RecLonsetCells = cellIDs(RecLonsetIdx);
            
            % Count spikes for each cell
            
            for c = 1 : nCells
        
                baselineCounts(t_idx, c) = sum(baselineCells == uniqueCellIDs(c));
                baselineSR(t_idx,c) = baselineCounts(t_idx, c)/abs(baselineWindow(1) - baselineWindow(2));
        
                EonsetCounts(t_idx, c) = sum(EonsetCells == uniqueCellIDs(c));
                EonsetSR(t_idx,c) = EonsetCounts(t_idx, c)/abs(EonsetWindow(1) - EonsetWindow(2));
        
                LonsetCounts(t_idx, c) = sum(LonsetCells == uniqueCellIDs(c));
                LonsetSR(t_idx,c) = LonsetCounts(t_idx, c)/abs(LonsetWindow(1) - LonsetWindow(2));

                RecEonsetCounts(t_idx, c) = sum(RecEonsetCells == uniqueCellIDs(c));
                RecEonsetSR(t_idx,c) = RecEonsetCounts(t_idx, c)/abs(RecEonsetWindow(1) - RecEonsetWindow(2));

                RecLonsetCounts(t_idx, c) = sum(RecLonsetCells == uniqueCellIDs(c));
                RecLonsetSR(t_idx,c) = RecLonsetCounts(t_idx, c)/abs(RecLonsetWindow(1) - RecLonsetWindow(2));
        
        
            end 
    end
    
    baselineMean = zeros(nCells, 1);
    baselineStd  = zeros(nCells, 1);
    
    for c = 1 : nCells
        allBaselineSR = baselineSR(:,c);
        baselineMean(c) = mean(allBaselineSR);
        baselineStd(c) = std(allBaselineSR);
        
        if baselineStd(c) < 0.5
            baselineStd(c) = 0.5;
        end
    end

    TrialSize = repmat((1:slowTrials)', nCells, 1);
    
    CellSize = repelem(uniqueCellIDs(:), slowTrials);
    
    spikesTable = table(...
        TrialSize, ...
        CellSize, ...
        baselineCounts(:), ...
        baselineSR(:), ...
        EonsetCounts(:), ...
        EonsetSR(:), ...
        LonsetCounts(:), ...
        LonsetSR(:), ...
        'VariableNames', ...
        {'TrialID', 'CellID', 'BaselineSC', 'BaselineSR', 'EOnsetSC', 'EOnsetSR', 'LOnsetSC','LOnsetSR'});

    RecspikesTable = table(...
        TrialSize, ...
        CellSize, ...
        baselineCounts(:), ...
        baselineSR(:), ...
        RecEonsetCounts(:), ...
        RecEonsetSR(:), ...
        RecLonsetCounts(:), ...
        RecLonsetSR(:), ...
        'VariableNames', ...
        {'TrialID', 'CellID', 'BaselineSC', 'BaselineSR', 'RecEOnsetSC', 'RecEOnsetSR', 'RecLOnsetSC','RecLOnsetSR'});
    
    %% Wilcoxon Signed Rank & Friedman Test
    
    
    resultsFR = [];
    resultsWSR = [];
    direction = strings(nCells, 1);

    RecresultsFR = [];
    RecresultsWSR = [];
    Recdirection = strings(nCells, 1);
    
    for w = 1 : nCells
    
        cellID = uniqueCellIDs(w);
        
        thisCell = spikesTable.CellID == cellID;
        
    
        baseline = spikesTable.BaselineSR(thisCell);
        Eonset = spikesTable.EOnsetSR(thisCell);
        Lonset = spikesTable.LOnsetSR(thisCell);

        thisRecCell = RecspikesTable.CellID == cellID;
        RecEonset = RecspikesTable.RecEOnsetSR(thisRecCell);
        RecLonset = RecspikesTable.RecLOnsetSR(thisRecCell);
    
        SR_Across = [baseline(:), Eonset(:), Lonset(:)];
        [pOverall, tbl, stats] = friedman(SR_Across, 1, 'off');

        Rec_SR_Across = [baseline(:), RecEonset(:), RecLonset(:)];
        [RecpOverall, Rectbl, Recstats] = friedman(Rec_SR_Across, 1, 'off');
    
        resultsFR(w,:) = pOverall;

        RecresultsFR(w,:) = RecpOverall;
    
        differenceBE = median(baseline - Eonset);
        [BEp, BEh] = signrank(baseline, Eonset);
        BEresult = [BEp, BEh];
    
        differenceBL = median(baseline - Lonset);
        [BLp, BLh] = signrank(baseline, Lonset);
        BLresult = [BLp, BLh];
    
        differenceEL = median(Eonset - Lonset);
        [ELp, ELh] = signrank(Eonset, Lonset);
        ELresult = [ELp, ELh];

        RecdifferenceBE = median(baseline - RecEonset);
        [RecBEp, RecBEh] = signrank(baseline, RecEonset);
        RecBEresult = [RecBEp, RecBEh];
    
        RecdifferenceBL = median(baseline - RecLonset);
        [RecBLp, RecBLh] = signrank(baseline, RecLonset);
        RecBLresult = [RecBLp, RecBLh];
    
        RecdifferenceEL = median(RecEonset - RecLonset);
        [RecELp, RecELh] = signrank(RecEonset, RecLonset);
        RecELresult = [RecELp, RecELh];
    
        if BEp > 0.01 && BLp > 0.01
            direction(w) = "No change";
        elseif differenceBE > 0 && differenceBL > 0 
            direction(w) = "Suppression";
        elseif differenceBE < 0 && ELp < 0.01
            direction(w) = "Transient Excitation";
        elseif differenceBE < 0 && ELp > 0.01
            direction(w) = "Sustained Excitation";
        else
            direction(w) = "Not defined";
        end
        resultsWSR(w,:) = [BEresult, BLresult, ELresult];

        if RecBEp > 0.01 && RecBLp > 0.01
            Recdirection(w) = "No change";
        elseif RecdifferenceBE > 0 && RecdifferenceBL > 0 
            Recdirection(w) = "Suppression";
        elseif RecdifferenceBE < 0 && RecELp < 0.01
            Recdirection(w) = "Transient Excitation";
        elseif RecdifferenceBE < 0 && RecELp > 0.01
            Recdirection(w) = "Sustained Excitation";
        else
            Recdirection(w) = "Not defined";
        end
        RecresultsWSR(w,:) = [RecBEresult, RecBLresult, RecELresult];
       
    end
    
    WSRTable = table(...
        uniqueCellIDs, ...
        baselineMean, ...
        baselineStd, ...
        resultsFR, ...
        resultsWSR(:, 1), ...
        resultsWSR(:, 3), ...
        resultsWSR(:, 5), ...
        direction, ...
        'VariableNames', ...
        {'CellID','Baseline_M', 'Baseline_Std', 'Friedman', 'BE_p-Value', 'BL_p-Value', 'EL_p-Value', 'Direction'});

    WSRTable = innerjoin(WSRTable,...
        mouseCells(:, {'uID', 'ordinal', 'mouseID'}), 'LeftKeys', 'CellID', 'RightKeys', 'uID');

    allTables{m} = WSRTable;

    RecWSRTable = table(...
        uniqueCellIDs, ...
        baselineMean, ...
        baselineStd, ...
        RecresultsFR, ...
        RecresultsWSR(:, 1), ...
        RecresultsWSR(:, 3), ...
        RecresultsWSR(:, 5), ...
        Recdirection, ...
        'VariableNames', ...
        {'CellID','Baseline_M', 'Baseline_Std', 'Friedman', 'BE_p-Value', 'BL_p-Value', 'EL_p-Value', 'Direction'});

    RecWSRTable = innerjoin(RecWSRTable,...
        mouseCells(:, {'uID', 'ordinal', 'mouseID'}), 'LeftKeys', 'CellID', 'RightKeys', 'uID');

    RecallTables{m} = RecWSRTable;

end

WSR = vertcat(allTables{:});

RecWSR = vertcat(RecallTables{:});

WSR_v2 = WSR;
WSR_v2.Properties.VariableNames = strrep(WSR_v2.Properties.VariableNames, 'WSR', 'labels');
% rename the table variable itself:
labels = WSR;

[saveFile, savePath] = uiputfile('*.mat', 'Save results table', 'classification_v2.mat');
if ~isequal(saveFile, 0)
    save(fullfile(savePath, saveFile), 'labels');
end

labels = RecWSR;

[saveFile, savePath] = uiputfile('*.mat', 'Save results table', 'classification_v3.mat');
if ~isequal(saveFile, 0)
    save(fullfile(savePath, saveFile), 'labels');
end