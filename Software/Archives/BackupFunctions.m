% Backup Functions

%% ISSUE: Sometimes, you need to overlap a segment. But how do you know what segments are okay to retrace?
function filteredMatrix = removeDuplicatePairs(A)
    % Initialize an empty array to store unique pairs
    seenPairs = [];
    
    % Initialize an index for rows to keep
    rowsToKeep = true(size(A, 1), 1);
    
    % Loop through each row of the matrix
    for i = 1:size(A, 1)
        pair = A(i, 1:2);  % Get the pair (col1, col2)
        
        % Check if the pair has been seen before
        isDuplicate = false;
        for j = 1:size(seenPairs, 1)
            if all(seenPairs(j, :) == pair)  % If the pair already exists
                isDuplicate = true;
                break;  % No need to check further
            end
        end
        
        if isDuplicate
            rowsToKeep(i) = false;  % Mark this row for removal
        else
            % If the pair is new, add it to seenPairs
            seenPairs = [seenPairs; pair];
        end
    end
    
    % Filter out the rows that are marked for removal
    filteredMatrix = A(rowsToKeep, :);
end


%% ISSUE: Chunk reversal varies with letter and font
function sortedMatrix = reorderWithReverse(A)
    sortedMatrix = A;  % Start with the input matrix
    numRows = size(A, 1);
    second = false

    for i = 1:numRows - 1
        % Check for a discontinuity in column 1 or column 2
        if abs(diff([sortedMatrix(i + 1, 1) sortedMatrix(i, 1)])) > 5 || ...
           abs(diff([sortedMatrix(i + 1, 2) sortedMatrix(i, 2)])) > 5
    
            % Discontinuity detected, extract and reverse chunk
            chunk = sortedMatrix(1:i, :);
            reversedChunk = flipud(chunk);
            
            % Reinsert the reversed chunk into the matrix
            sortedMatrix(1:i, :) = reversedChunk;
                  
            chunk = sortedMatrix(i+1:end, :);
            reversedChunk = flipud(chunk);
            
            % Reinsert the reversed chunk into the matrix
            sortedMatrix(i+1:end, :) = reversedChunk;
    
            break;
        end
    end
end