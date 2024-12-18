clc
clear all
close all
coordinatesMatrix = motion3(0, 60, 'Calibri', 'normal', true);

function coordinatesMatrix = motion3(inputText, fontSize, fontName, fontStyle, thinOption)
    % Parameters
    thinning = thinOption;  % Reduce to skeleton
    scaleFactor = 1;  % Set the desired scaling factor for font size
    pauseTime = 0.001;  % Time delay between each movement (seconds)
    debug = false;  % Hide animations
    
    % Create image from text if not uploading an image
    if ~inputText == 0 % Enter 0 for using an image and not text
        % Styles: normal, bold
        % Font size (ideally 40+) increases number of coordinates and text resolution (dpi)
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
                coordinatesMatrix = [coordinatesMatrix; x1, y1, 0];
    
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
        
        disp('Next component')
        coordinatesMatrix = [coordinatesMatrix; NaN NaN NaN];

        if debug
            plot(coordinatesMatrix(:, 1), coordinatesMatrix(:, 2), '.-', 'LineWidth', 2)
        end

        if thinning
            break % Force exit if there are no "components"
        end
    end
    
    % Offset coordinates
    xOffset = 0; % x-pos of the starting position relative to workspace global coordinates
    yOffset = 20; % y-pos of the starting position relative to workspace global coordinates
    zOffset = -25; % z-pos of the starting position relative to workspace global coordinates
    
    coordinatesMatrix(:, 1) = coordinatesMatrix(:, 1) - coordinatesMatrix(1, 1) + xOffset;
    coordinatesMatrix(:, 2) = coordinatesMatrix(:, 2) - coordinatesMatrix(1, 2) + yOffset;
    coordinatesMatrix(:, 3) = coordinatesMatrix(:, 3) - coordinatesMatrix(1, 3) + zOffset;

    % coordinatesMatrix contains all the final coordinate output values in sequential order
end

function reduced = removeUnnecessaryRetraces(arr)
    for i = 2:size(arr, 1) - 1
        if isequal(arr(i - 1, :), arr(i + 1, :)) % Check if i-1 equals i+1 for both columns
            forward = i; % Store the index where the condition is met
            if size(arr, 1)/2 >= forward && isequal(arr(1:forward-1, :), flipud(arr(forward+1:forward*2-1, :)))
                arr = arr(forward:end, :);
            end
            break;
        end
    end
    for i = size(arr, 1) - 1:-1:2
        if isequal(arr(i - 1, :), arr(i + 1, :))
            reverse = i; % Store the index where the condition is met
            if size(arr, 1)/2 <= reverse && isequal(arr(reverse+1:end, :), flipud(arr(reverse-(end-reverse):reverse-1, :)))
                arr = arr(1:reverse, :);
            end
            break;
        end
    end
    reduced = arr;
end

function createTextImage(inputText, fontSize, imageWidth, imageHeight, outputFileName, fontName, fontStyle)
    % fontName       : Name of the font (e.g., 'Arial', 'Times New Roman')
    % fontStyle      : Font style ('normal', 'bold')

    % Create a blank canvas
    figure;
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
