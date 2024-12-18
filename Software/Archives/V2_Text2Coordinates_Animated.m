%% PRELIMINARY THIN AND THICK TEXT FUNCTIONALITY

clc
clear all
close all

% Generate motion coordinates for input text
coordinatesMatrix = MotionAni(0, 60, 'Arial', 'normal', false);

function coordinatesMatrix = MotionAni(inputText, fontSize, fontName, fontStyle, thinOption)
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

    % Extract boundaries
    boundaries = bwboundaries(binaryImg, 'holes'); % Get both outer and inner boundaries

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
        boundaries = bwboundaries(thinnedImg, 'noholes'); % Get only outer boundaries
    end

    % Set up the animation
    figure;
    hold on;
    axis equal;
    axis off;
    xlim([0, size(binaryImg, 2) * scaleFactor]);
    ylim([0, size(binaryImg, 1) * scaleFactor]);
    set(gcf, 'Color', 'w');

    % Get the maximum Y-coordinate to flip the text right-side up
    maxY = size(binaryImg, 1) * scaleFactor; % Max Y for flipping

    % Initialize coordinates matrix
    coordinatesMatrix = []; % Initialize empty matrix to store coordinates; z = 0

    % Animate each boundary
    for k = 1:length(boundaries)
        boundary = boundaries{k};                 % Get the boundary points for each segment
        scaledBoundary = boundary * scaleFactor;  % Apply scaling to each boundary point

        % "Lift pen" to move to the start of a new segment
        if k > 1
            % Store a single point indicating a pen-up move to the start of the next segment
            xPenUp = scaledBoundary(1, 2);
            yPenUp = maxY - scaledBoundary(1, 1);
            coordinatesMatrix = [coordinatesMatrix; xPenUp, yPenUp, 0];
            disp('raised')
        end

        % Draw each boundary segment
        for pointIndex = 1:size(scaledBoundary, 1) - 1
            % Flip the Y-coordinates by subtracting from maxY
            x1 = scaledBoundary(pointIndex, 2);   % X-coordinate of the current point
            y1 = maxY - scaledBoundary(pointIndex, 1);   % Corrected Y-coordinate of the current point
            x2 = scaledBoundary(pointIndex + 1, 2); % X-coordinate of the next point
            y2 = maxY - scaledBoundary(pointIndex + 1, 1); % Corrected Y-coordinate of the next point

            % Store coordinates; append
            coordinatesMatrix = [coordinatesMatrix; x1, y1, 0];

            % Animate drawing; Comment to hide animation but still produce output matrix
            if ~debug
                plot([x1, x2], [y1, y2], 'k-', 'LineWidth', 2);
                drawnow;            % Update the plot immediately
                pause(pauseTime);   % Pause to create animation effect
            end
        end
    end

    % Offset coordinates
    xOffset = 20; % x-pos of the starting position relative to workspace global coordinates
    yOffset = 20; % y-pos of the starting position relative to workspace global coordinates
    zOffset = 0; % z-pos of the starting position relative to workspace global coordinates
    coordinatesMatrix(:, 1) = coordinatesMatrix(:, 1) - coordinatesMatrix(1, 1) + xOffset;
    coordinatesMatrix(:, 2) = coordinatesMatrix(:, 2) - coordinatesMatrix(1, 2) + yOffset;
    
    % coordinatesMatrix contains all the final coordinate output values in sequential order
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
