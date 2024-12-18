clc;
clear all;
close all;

% Parameters
thinning = true;
image = true;
scaleFactor = 1;  % Set the desired scaling factor for font size
pauseTime = 0.001;  % Time delay between each movement (seconds)

% Create image from text if not uploading an image
if ~image
    % Styles: normal, bold
    % Thin Text: Font size of 15
    % Thick Text: Font size of 30 and turn thinning off. Creates double boundaries
    % Font size increases number of coordinates and text resolution
    createTextImage('test', 30, 10, 10, 'image.png', 'Arial', 'normal'); 
end

% Load and process image
img = imread('image.png'); % Load image
grayImg = rgb2gray(img); % Convert to grayscale
binaryImg = imbinarize(grayImg); % Binarize the image
binaryImg = ~binaryImg; % Invert image if needed (black text on white)

% Extract contours
boundaries = bwboundaries(binaryImg, 'holes');  % Find inner and outer boundaries

%% THINNING
if thinning == true
    % Thin slightly to preserve small components
    thinnedImg = bwmorph(binaryImg, 'thin', 1);       % Thin only once to avoid losing small dots
    
    % Extract contours (without holes, due to thickness)
    boundaries = bwboundaries(thinnedImg, 'noholes'); % Find boundaries of thinned text, but ignore holes (since we're thinning)
end
%%

% 3. Set up the Figure for Animation
figure;
hold on;
axis equal;
axis off; % Hide axes
xlim([0, size(binaryImg, 2) * scaleFactor]);  % Set X-axis limit
ylim([0, size(binaryImg, 1) * scaleFactor]);  % Set Y-axis limit
set(gcf, 'Color', 'w');  % Set the background color to white

% Get the maximum Y-coordinate to flip the text right-side up
maxY = size(binaryImg, 1) * scaleFactor;

% Initialize the coordinates matrix
% Each row is [x, y, z] with z = 0, and we'll add rows sequentially
coordinatesMatrix = [];  % Initialize empty matrix to store coordinates

% 4. Animate Drawing Each Boundary Segment and Store Coordinates
for k = 1:length(boundaries)
    boundary = boundaries{k};                 % Get the boundary points for each segment
    scaledBoundary = boundary * scaleFactor;  % Apply scaling to each boundary point
    
    % "Lift the pen" before moving to the start of a new boundary
    if k > 1
        % Store a single point indicating a pen-up move to the start of the next segment
        xPenUp = scaledBoundary(1, 2); 
        yPenUp = maxY - scaledBoundary(1, 1);
        coordinatesMatrix = [coordinatesMatrix; xPenUp, yPenUp, 0];
    end
    
    % Draw each point-to-point segment within this boundary
    for pointIndex = 1:size(scaledBoundary, 1) - 1
        % Flip the Y-coordinates by subtracting from maxY
        x1 = scaledBoundary(pointIndex, 2);   % X-coordinate of the current point
        y1 = maxY - scaledBoundary(pointIndex, 1);   % Corrected Y-coordinate of the current point
        x2 = scaledBoundary(pointIndex + 1, 2); % X-coordinate of the next point
        y2 = maxY - scaledBoundary(pointIndex + 1, 1); % Corrected Y-coordinate of the next point

        % Append the current point to coordinatesMatrix with z=0
        coordinatesMatrix = [coordinatesMatrix; x1, y1, 0];

        % Animate the drawing movement
        plot([x1, x2], [y1, y2], 'k-', 'LineWidth', 2);
        drawnow;            % Update the plot immediately
        pause(pauseTime);   % Pause to create animation effect
    end
end

% Scaling and Offset
xOffset = 20; % x-pos of the starting position relative to workspace global coordinates
yOffset = 20; % y-pos of the starting position relative to workspace global coordinates
zOffset = 0; % z-pos of the starting position relative to workspace global coordinates

coordinatesMatrix(:,1) = coordinatesMatrix(:,1) - coordinatesMatrix(1,1) + xOffset
coordinatesMatrix(:,2) = coordinatesMatrix(:,2) - coordinatesMatrix(1,2) + yOffset

% coordinatesMatrix contains all the final coordinate output values in sequential order

function createTextImage(inputText, fontSize, imageWidth, imageHeight, outputFileName, fontName, fontStyle)
    % Parameters:
    % inputText      : The text to be rendered (e.g., 'Hello World!')
    % fontSize       : Font size for the text (e.g., 30)
    % imageWidth     : Width of the image (e.g., 500)
    % imageHeight    : Height of the image (e.g., 100)
    % outputFileName : Output file name (e.g., 'text_image.png')
    % fontName       : Name of the font (e.g., 'Arial', 'Times New Roman')
    % fontStyle      : Font style ('normal', 'bold', 'italic', 'bolditalic')

    % Create a blank canvas (white background)
    figure;
    imshow(ones(imageHeight, imageWidth), 'InitialMagnification', 'fit'); % White canvas
    hold on;
    axis off;
    
    % Render the text on the canvas with the specified font and style
    text(imageWidth/2, imageHeight/2, inputText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', fontSize, 'FontName', fontName, 'FontWeight', fontStyle, 'Color', 'black');
    
    % Capture the figure as an image
    frame = getframe(gcf);          % Capture the figure content
    textImg = frame.cdata;          % Extract image data
    close;                          % Close the figure
    
    % Save the generated image to a file
    imwrite(textImg, outputFileName); % Save as PNG or any format

    % Inform the user
    disp(['Image saved as ' outputFileName]);
end
