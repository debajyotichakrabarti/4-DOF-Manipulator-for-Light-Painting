function coordinatesMatrix = motion(inputText, fontSize, fontName, fontStyle, thinOption)
    % Parameters
    thinning = thinOption;  % Reduce to skeleton; turn off for images
    xOffset = 19; % [16 to 19] cm
    scaleFactor = 1;  % Initial scale factor; untuned
    pauseTime = 0.001;  % Time delay between each movement (seconds)
    debug = false;  % Hide animations?
    spherical = true; % Print fisheyed or planar (false)?
    jerk = 3; % Magnitude of jerkiness; reduces fidelity to compensate for position control and jerky movements
    
    % Create image from text if not uploading an image
    if ~inputText == 0 % Enter 0 for using an image and not text
        % Styles: normal, bold
        % Font size (ideally 40+) increases number of coordinates and text resolution (dpi).
            % Reduce font size if text is getting truncated
        createTextImage(inputText, fontSize, 10, 10, 'image.png', fontName, fontStyle); 
    end

    % Load and process the image
    img = imread('image.png');         % Load image
    grayImg = rgb2gray(img);           % Convert to grayscale
    binaryImg = imbinarize(grayImg);   % Binarize the image
    binaryImg = ~binaryImg;            % Invert (black text on white)
    
    % Remove edge artifacts and small noise
    binaryImg = imclearborder(binaryImg);  % Clear objects connected to the image border
    binaryImg = bwareaopen(binaryImg, 10); % Remove small objects (noise)
    
    % Identify connected components (each letter or shape)
    cc = bwconncomp(binaryImg);  % Find connected components (letters)
    coordinatesMatrix = [];  % Initialize coordinates matrix
    maxY = size(binaryImg, 1) * scaleFactor;  % Flip Y-coordinates based on image height
    
    % Set up the animation
    figure;
    hold on;
    axis equal;
    axis off;
    xlim([0, size(binaryImg, 2) * scaleFactor]);
    ylim([0, size(binaryImg, 1) * scaleFactor]);
    set(gcf, 'Color', 'w');
    
    % Loop through each connected component
    for i = 1:cc.NumObjects
        % Create a mask for the current connected component
        componentMask = false(size(binaryImg));
        componentMask(cc.PixelIdxList{i}) = true;
    
        % Extract boundaries for this component (outer and inner boundaries)
        componentBoundaries = bwboundaries(componentMask, 'holes');  % Include inner holes
    
        % Optional thinning
        if thinning
            thinnedImg = bwmorph(binaryImg, 'thin', Inf); % Skeletonize the binary image
    
            % Retain components with area between 1 and 10 pixels (adjust thresholds as needed)        
            dotMask = bwareaopen(thinnedImg, 1) & ~bwareaopen(thinnedImg, 10); 
        
            % Prune small spurs (short branches)
            prunedImg = bwmorph(thinnedImg, 'spur', 5); % Removes branches shorter than 5 pixels
        
            % Combine the pruned image with preserved dots
            thinnedImg = prunedImg | dotMask;
    
            % Extract contours (without holes, due to thickness)
            componentBoundaries = bwboundaries(thinnedImg, 'noholes'); % Get only outer boundaries
        end
    
        % Draw all boundaries for this letter/component
        for k = 1:length(componentBoundaries)
            boundary = componentBoundaries{k};
            scaledBoundary = boundary * scaleFactor;
            
            scaledBoundary = removeUnnecessaryRetraces(scaledBoundary);
    
            % "Lift pen" before moving to the start of a new boundary
            if k > 1
                if thinning
                    disp('Next component')
                    coordinatesMatrix = [coordinatesMatrix; NaN NaN NaN];
                else
                    disp('Inner boundary')
                    coordinatesMatrix = [coordinatesMatrix; NaN NaN NaN];
                end
                xPenUp = scaledBoundary(1, 2);
                yPenUp = maxY - scaledBoundary(1, 1);
                coordinatesMatrix = [coordinatesMatrix; xPenUp, yPenUp, 0];               
            end
    
            % Draw and store the current boundary points
            for pointIndex = 1:size(scaledBoundary, 1) - 1
                x1 = scaledBoundary(pointIndex, 2);
                y1 = maxY - scaledBoundary(pointIndex, 1);
                x2 = scaledBoundary(pointIndex + 1, 2);
                y2 = maxY - scaledBoundary(pointIndex + 1, 1);
    
                % Append the current point to the coordinates matrix
                % disp('Light on')
                if isnan(x1)
                    coordinatesMatrix = [coordinatesMatrix; x1, y1, NaN];
                else
                    coordinatesMatrix = [coordinatesMatrix; x1, y1, 0];
                end
    
                % Animate the drawing; uncomment to see trace cursor
                if ~debug
                    plot([x1, x2], [y1, y2], 'k-', 'LineWidth', 2);
                    %currentPoint = plot(x1, y1, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r'); % Cursor point
                    drawnow;
                    pause(pauseTime);
                    %delete(currentPoint); % Remove the cursor
                end
            end
        end
        
        disp('Next component / End')
        coordinatesMatrix = [coordinatesMatrix; NaN NaN NaN];
       
        if thinning
            break % Force exit if there are no "components"
        end
    end
    
    % Reorganize to print on yz plane
    temp = coordinatesMatrix(:, 1:2);
    coordinatesMatrix(:, 1) = coordinatesMatrix(:, 3);
    coordinatesMatrix(:, 2:3) = temp;
    
    % Offset and rescale coordinates
    max_Y_len = max(coordinatesMatrix(:, 2)) - min(coordinatesMatrix(:, 2))
    max_Z_len = max(coordinatesMatrix(:, 3)) - min(coordinatesMatrix(:, 3))
    constrainingDim = max(max_Y_len, max_Z_len);

    if spherical
        lim = 1;
    else
        lim = 0.8; % 80% downsize to reduce edge warping
    end

    scaleFactor = scaleFactor * (xOffset - 1) * lim / constrainingDim

    coordinatesMatrix = scaleFactor * coordinatesMatrix;

    noNaN = rmmissing(coordinatesMatrix);

    mids = min(noNaN) + (max(noNaN) - min(noNaN)) / 2;

    yOffset = -mids(2);
    zOffset = -mids(3);

    coordinatesMatrix(:, 1) = coordinatesMatrix(:, 1) + xOffset;
    coordinatesMatrix(:, 2) = coordinatesMatrix(:, 2) + yOffset;
    coordinatesMatrix(:, 3) = coordinatesMatrix(:, 3) + zOffset + max(coordinatesMatrix(:, 3) + zOffset);

    % Reduction
    if jerk > 0
        coordinatesMatrix = pointReduction(coordinatesMatrix, jerk);
    end
    
    if debug
        plot(coordinatesMatrix(:, 2), coordinatesMatrix(:, 3), '.-', 'LineWidth', 2); % Plotting on yz graph
        xlim([min(coordinatesMatrix(:, 2)) max(coordinatesMatrix(:, 2))]);
        ylim([min(coordinatesMatrix(:, 3)) max(coordinatesMatrix(:, 3))]); % y axis plots physical z coordinates
        disp(['ylim: ', num2str([min(coordinatesMatrix(:, 2)) max(coordinatesMatrix(:, 2))])])
        disp(['zlim: ', num2str([min(coordinatesMatrix(:, 3)) max(coordinatesMatrix(:, 3))])])
    end

    % Add z-offset (link 1 length)
    zOffset = 16;
    coordinatesMatrix(:, 3) = coordinatesMatrix(:, 3) + zOffset;

    % coordinatesMatrix contains all the final coordinate output values in sequential order relative to the base frame origin
end

function filtered = pointReduction(arr, jerk)
    % Logical array to identify rows with [NaN NaN NaN]
    is_nan_row = all(isnan(arr), 2);
    
    % % Logical array for alternating rows
    % alternating_rows = false(size(arr, 1), 1);
    % alternating_rows(1:1+jerk:end) = true; % Mark every other row
    % 
    % % Combine conditions: keep rows that are either NaN or not part of alternating rows
    % rows_to_keep = is_nan_row | ~alternating_rows;

    % Create a logical mask for rows to keep
    rows_to_keep = false(size(arr, 1), 1);
    counter = 1;
        
    % Iterate through rows and decide which to keep
    while counter <= size(arr, 1)
        % Keep the current row
        rows_to_keep(counter) = true;
        
        % Skip the specified number of rows to remove
        counter = counter + jerk + 1;
    end
    
    % Combine conditions: keep rows with [NaN NaN NaN] or rows marked to keep
    rows_to_keep = is_nan_row | rows_to_keep;
    
    % Filter the matrix
    filtered = arr(rows_to_keep, :);
end

function reduced = removeUnnecessaryRetraces(arr)
    % Initialize the reduced array
    reduced = [];
    
    % Keep track of previously encountered sets
    uniqueSets = [];
    
    % Flag to track if a discontinuity has been inserted
    discontinuityInserted = false;
    
    % Iterate through the rows of arr
    i = 1;
    while i <= size(arr, 1)
        % Look ahead to find the end of the current set
        j = i;
        while j <= size(arr, 1) && isequal(arr(j, :), arr(i, :))
            j = j + 1;
        end
        
        % Extract the current set
        currentSet = arr(i:j-1, :);
        
        % Check if this set is unique
        if isempty(uniqueSets) || ~ismember(currentSet, uniqueSets, 'rows')
            % Append the current set to the reduced array
            reduced = [reduced; currentSet];
            
            % Mark this set as unique
            uniqueSets = [uniqueSets; currentSet];
            
            % Reset the discontinuity flag
            discontinuityInserted = false;
        else
            % Insert [NaN NaN] only once per removed chunk
            if ~discontinuityInserted && ~isempty(reduced) && ~isequal(reduced(end, :), [NaN NaN])
                reduced = [reduced; NaN NaN]; % Note: PENUP will not displayed but coordinatesMatrix will reflect it
                % disp('Next Component')
                discontinuityInserted = true;
            end
        end
        
        % Move to the next set
        i = j;
    end
end

function createTextImage(inputText, fontSize, imageWidth, imageHeight, outputFileName, fontName, fontStyle)
    % fontName       : Name of the font (e.g., 'Arial', 'Times New Roman')
    % fontStyle      : Font style ('normal', 'bold')

    % Create a blank canvas
    figure('Visible', 'off');
    imshow(ones(imageHeight, imageWidth), 'InitialMagnification', 'fit'); % White canvas
    hold on;
    axis off;

    % Render the text with specified font and style
    text(imageWidth / 2, imageHeight / 2, inputText, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', fontSize, 'FontName', fontName, 'FontWeight', fontStyle, ...
        'Color', 'black');

    % Capture the figure as an image
    frame = getframe(gcf);          % Capture the figure content
    textImg = frame.cdata;          % Extract image data
    close;                          % Close the figure
    
    % Save the generated image to a file
    imwrite(textImg, outputFileName); % Save as PNG or any format
    
    % Inform the user
    disp(['Image saved as ' outputFileName]);
end
